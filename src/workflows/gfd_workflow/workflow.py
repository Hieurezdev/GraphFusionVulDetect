import hashlib
import logging
import os

from .utils.helper import seed_everything, prepare_solc_artifacts
from .graph.builder import build_graph
from src.infrastructure.analysis_model.GraphClasifier import GraphNN
from src.infrastructure.analysis_model.NodeDetector import NodeClassifierGNN
from src.config.settings import settings
import torch

logger = logging.getLogger(__name__)

# Each vulnerability type has its own encoder and GNN pair; the contract-level GNNs were trained with different shapes.
MODEL_SPECS = {
    "timestamp": dict(encoder=settings.EMBEDDING_MODEL_PATH, graph=settings.GRAPH_VUL_MODEL_PATH, node=settings.NODE_VUL_MODEL_PATH,
                      graph_arch=dict(mtype=["GCN"], n_gph=0, num_query_vectors=2)),
    "reentrancy": dict(encoder=settings.REENTRANCY_EMBEDDING_MODEL_PATH, graph=settings.REENTRANCY_GRAPH_VUL_MODEL_PATH,
                       node=settings.REENTRANCY_NODE_VUL_MODEL_PATH, graph_arch=dict(mtype=["GAT"], n_gph=2, num_query_vectors=1)),
}


def checkpoint_version(*paths: str) -> str:
    """Short, stable id of the checkpoints in use: file names + a hash of their bytes (a retrained file gets a new id)."""
    digest = hashlib.sha256()
    for p in paths:
        with open(p, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                digest.update(chunk)
    return f"{os.path.basename(paths[0])}@{digest.hexdigest()[:12]}"


def load_temperature(vulnerability: str, version: str) -> float:
    """Contract-level temperature fitted for this checkpoint (eval/calibration/fit_temperature.py), else 1.0.

    A temperature belongs to the checkpoint it was fitted on: after retraining, the old value is ignored, not reused.
    """
    import json
    try:
        with open(settings.CALIBRATION_PATH, encoding="utf-8") as f:
            entry = json.load(f).get(vulnerability) or {}
    except (OSError, ValueError):
        return 1.0
    if entry.get("model_version") != version:
        if entry:
            logger.warning("%s calibration ignored: fitted for %s, loaded checkpoint is %s", vulnerability, entry.get("model_version"), version)
        return 1.0
    return float(entry.get("temperature", 1.0))


class GFDWorkflow:
    def __init__(self):
        self.device = torch.device(settings.DEVICE)
        self.models = {}  # vulnerability -> {embedd_tokenizer, embedd_model, graph_vul_model, node_vul_model}
        self.versions = {}  # vulnerability -> "<checkpoint file>@<sha256 prefix>", stored on every scan and label
        self.temperatures = {}  # vulnerability -> contract-level temperature (1.0 = uncalibrated)
        self.llm = None

    def initialize(self):
        """Called ONCE during app startup."""
        seed_everything(settings.SEED)
        prepare_solc_artifacts()
        if settings.DEVICE.startswith("cuda") and 0 < settings.GPU_MEMORY_FRACTION < 1 and torch.cuda.is_available():
            torch.cuda.set_per_process_memory_fraction(settings.GPU_MEMORY_FRACTION)
            logger.info("GPU memory capped at %.0f%% of the device", settings.GPU_MEMORY_FRACTION * 100)

        from src.services.model_registry import active_graph_path
        for name, spec in MODEL_SPECS.items():
            # Step 1.9: a retrained checkpoint that passed the gate replaces the original one via models/registry.json
            spec = {**spec, "graph": active_graph_path(name, spec["graph"])}
            missing = [p for p in (spec["graph"], spec["node"]) if not os.path.exists(p)]
            if missing and name != "timestamp":
                logger.warning("%s scanning disabled: checkpoint not found: %s", name, ", ".join(missing))
                continue
            tokenizer, encoder = self._load_embedding_model(spec["encoder"])
            self.models[name] = {
                "embedd_tokenizer": tokenizer,
                "embedd_model": encoder,
                "graph_vul_model": self._load_graph_model(spec["graph"], spec["graph_arch"]),
                "node_vul_model": self._load_node_model(spec["node"]),
            }
            self.versions[name] = checkpoint_version(spec["graph"], spec["node"])
            self.temperatures[name] = load_temperature(name, self.versions[name])
            self.models[name]["temperature"] = self.temperatures[name]
            # Step 2.7: a candidate in shadow mode is scored next to the active model, never shown to users
            from src.services.model_registry import shadow_graph_path
            shadow = shadow_graph_path(name)
            if shadow:
                self.models[name]["shadow_graph_model"] = self._load_graph_model(shadow, spec["graph_arch"])
                self.models[name]["shadow_version"] = checkpoint_version(shadow, spec["node"])
        self._load_llm()

    def _load_embedding_model(self, emb_path):
        from transformers import RobertaTokenizer, RobertaModel

        return RobertaTokenizer.from_pretrained(emb_path), RobertaModel.from_pretrained(emb_path).to(self.device).eval()

    # GNNs stay on CPU: the PyPI dgl build has no CUDA; only CodeBERT follows settings.DEVICE.
    def _load_graph_model(self, path, arch):
        model = GraphNN(
            infeats=768,
            hfeats=[2048, 2048],
            fc1_layer=256, fc2_layer=64,
            outclass=2,
            gptype="max", ginfeat=1024,
            **arch,
        )
        model.load_state_dict(torch.load(path, map_location="cpu"))
        return model.eval()

    def _load_node_model(self, path):
        model = NodeClassifierGNN(
            mtype=["GAT", ""],
            infeats=768, hfeats=[256, 128],
            fc1_layer=256, fc2_layer=64,
            outclass=2, ginfeat=1024
        )
        model.load_state_dict(torch.load(path, map_location="cpu"))
        return model.eval()

    def _load_llm(self):
        if settings.LOCAL_LLM_MODEL:
            from src.infrastructure.chat_model.local_llm import get_local_llm
            self.llm = get_local_llm()
            return
        from langchain_openai import ChatOpenAI

        self.llm = ChatOpenAI(
            model_name=settings.MODEL_NAME,
            api_key=settings.CLAUDE_API_KEY,
            base_url=settings.BASE_URL,
            temperature=settings.CHATBOT_TEMPERATURE,
            max_tokens=settings.CHATBOT_MAX_TOKENS,
            max_retries=3,
            request_timeout=50
        )

    def build_pipeline(self):
        """Build graph AFTER loading all models."""
        return build_graph()


# Singleton workflow instance
gfd_workflow = GFDWorkflow()
