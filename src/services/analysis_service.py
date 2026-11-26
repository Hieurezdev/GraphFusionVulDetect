from src.utils.language import normalize_language
import asyncio
import json
import tempfile
import os
from typing import AsyncGenerator, Dict, Any, Tuple
from anyio import to_thread

# Define a unique sentinel object to signal the end of the iterator
_SENTINEL = object()

ANALYSIS_SLOTS = 2
_ANALYSIS_SLOTS = asyncio.Semaphore(ANALYSIS_SLOTS)

class VulnerabilityAnalysisService:
    """Service for handling vulnerability analysis operations"""
    
    def __init__(self):
        self.app_graph = None
        
    def _initialize_if_needed(self):
        """Initialize models if not already done"""
        if self.app_graph is None:
            # Import here to avoid circular imports
            from .graph_loader import get_app_graph, get_models_config
            
            self.app_graph = get_app_graph()
            
            if self.app_graph is None or get_models_config() is None:
                raise RuntimeError("Models not loaded. Please ensure the application has started properly.")
    
    def _get_next_or_sentinel(self, sync_iterator):
        """
        Calls next() on the iterator. If StopIteration is raised,
        returns the sentinel value instead.
        """
        try:
            return next(sync_iterator)
        except StopIteration:
            return _SENTINEL
    
    async def _run_sync_iterator_in_thread(self, sync_iterator) -> AsyncGenerator[Dict[str, Any], None]:
        """
        Wraps a synchronous iterator in an async generator, running the
        blocking `next()` calls in a separate thread using a sentinel
        to gracefully handle the end of the iterator.
        """
        while True:
            # Run our helper in a worker thread. It will return an item
            # or the sentinel when the iterator is exhausted.
            item = await to_thread.run_sync(self._get_next_or_sentinel, sync_iterator)

            if item is _SENTINEL:
                # The iterator is exhausted, so we're done.
                break
            else:
                # We have a valid item, yield it.
                yield item
    
    def _format_node_output(self, node_name: str, node_output_state: Dict[str, Any]) -> Dict[str, Any]:
        """
        Format the output from each node to provide clean data to the client
        """
        output_data = {"node": node_name, "output": {}}
        
        if "error" in node_output_state:
            output_data["output"]["error"] = node_output_state["error"]
        elif node_name == "convert_to_fcg":
            output_data["output"] = {
                k: v for k, v in node_output_state.items() 
                if k in ["fcg_file_path", "mapping_file_path"]
            }
        elif node_name == "detect_vulnerability_src":
            output_data["output"] = {
                k: v for k, v in node_output_state.items() 
                if k in ["predicted_class", "confidence_score"]
            }
        elif node_name == "detect_vulnerability_func":
            output_data["output"] = {
                k: v for k, v in node_output_state.items() 
                if k in ["func_vulnerability_predictions", "fcg_edges"]
            }
        elif node_name == "explain_vulnerability_func":
            output_data["output"] = {
                "explanations": node_output_state.get("func_vulnerability_explanations")
            }
        else:
            # For any other nodes, include all non-internal data
            output_data["output"] = {
                k: v for k, v in node_output_state.items() 
                if not k.startswith('_')
            }
        
        return output_data
    
    async def analyze_solidity_file(self, file_path: str, temp_dir: str, language: str = "en") -> AsyncGenerator[str, None]:
        """
        Scan a Solidity file for every loaded vulnerability type at once and stream the results as NDJSON.

        One pipeline run per vulnerability type, side by side; every event carries the type it belongs to.
        The stream opens with a "start" event (the types being scanned) and closes with a "summary" event
        (one verdict per type, the conclusion for the contract, what still needs manual review).
        """
        self._initialize_if_needed()
        from .graph_loader import get_models_config, get_vulnerabilities
        from .findings import summarize

        vulnerabilities = get_vulnerabilities()
        yield json.dumps({"node": "start", "output": {"vulnerabilities": vulnerabilities}}) + "\n"

        queue: asyncio.Queue = asyncio.Queue()

        async def scan(vulnerability: str):
            try:
                initial_state = {
                    "sol_file_path": file_path,
                    "fcg_save_dir": os.path.join(temp_dir, vulnerability),  # the two runs write graph files with the same name
                    "language": normalize_language(language),
                    "vulnerability": vulnerability,
                }
                async for event in self._run_sync_iterator_in_thread(self.app_graph.stream(initial_state, get_models_config(vulnerability))):
                    node_name, node_output_state = list(event.items())[0]
                    if node_name == "convert_to_fcg" and not str(node_output_state.get("fcg_file_path", "")).endswith(".fcg"):
                        raise RuntimeError("Could not build the call graph: the contract did not compile with the solc version of its pragma, "
                                           "or it imports files that were not uploaded. It needs a manual review.")
                    await queue.put({**self._format_node_output(node_name, node_output_state), "vulnerability": vulnerability})
            except Exception as e:  # one scan failing must not hide the other's result
                await queue.put({"node": "error", "vulnerability": vulnerability, "output": {"error": str(e)}})
            finally:
                await queue.put(None)

        # One GPU and the compiler/Slither are shared by every user: run at most ANALYSIS_SLOTS contracts at once, queue the rest.
        async with _ANALYSIS_SLOTS:
            tasks = [asyncio.create_task(scan(v)) for v in vulnerabilities]
            events, running = [], len(tasks)
            try:
                while running:
                    event = await queue.get()
                    if event is None:
                        running -= 1
                        continue
                    events.append(event)
                    yield json.dumps(event) + "\n"
            finally:
                # Client gone (or an error): stop the scans, or they keep the GPU busy after this slot is freed.
                # A scan stops after the pipeline step its worker thread is in; the thread cannot be interrupted mid-step.
                for task in tasks:
                    task.cancel()

            summary = summarize(events, vulnerabilities)
            if all(v["status"] == "failed" for v in summary["vulnerabilities"].values()):
                raise RuntimeError("; ".join(f"{v['label']}: {v['error']}" for v in summary["vulnerabilities"].values()))
            yield json.dumps({"node": "summary", "output": summary}) + "\n"
    
    
    def validate_solidity_file(self, filename: str, content: bytes) -> Tuple[bool, str]:
        """
        Validate uploaded Solidity file
        
        Args:
            filename: Name of the uploaded file
            content: File content
            
        Returns:
            Tuple of (is_valid, error_message)
        """
        # Check file extension
        if not filename.endswith(".sol"):
            return False, "Invalid file type. Please upload a .sol file."
        
        # Check file size (limit to 10MB)
        if len(content) > 10 * 1024 * 1024:  # 10MB
            return False, "File size must be less than 10MB"
        
        # Check if file is not empty
        if len(content) == 0:
            return False, "File cannot be empty"
        
        # Basic content validation (check if it contains some Solidity-like content)
        try:
            content_str = content.decode('utf-8')
            if 'contract' not in content_str.lower() and 'pragma solidity' not in content_str.lower():
                return False, "File does not appear to be a valid Solidity contract"
        except UnicodeDecodeError:
            return False, "File must be a valid text file"
        
        return True, ""

# Singleton service instance
vulnerability_analysis_service = VulnerabilityAnalysisService()
