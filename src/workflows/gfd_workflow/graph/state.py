from typing import Annotated, TypedDict, Optional, List, Any

# Vulnerability types /analyze can scan for -> the name shown in explanations and SARIF.
VULNERABILITIES = {"timestamp": "Timestamp Dependency", "reentrancy": "Reentrancy"}

# State TypedDict including new fields for the subquery workflow
class State(TypedDict):
    sol_file_path: str
    fcg_save_dir: str
    fcg_file_path: Optional[str]
    fcg_edges: Optional[List[tuple]]
    predicted_class: Optional[str]
    confidence_score: Optional[float]
    func_vulnerability_predictions: Optional[List[dict]]
    func_vulnerability_explanations: Optional[List[dict]]
    language: Optional[str]
    vulnerability: Optional[str]
    allow_llm: Optional[bool]
    plain: Optional[bool]  # explanations for a non-technical reader
    # Step 2.7: prediction of the shadow candidate on the same graph (stored for comparison, not shown to users)
    shadow: Optional[dict]