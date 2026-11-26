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


class GFDWorkflow:
    def __init__(self):
        self.device = torch.device(settings.DEVICE)
        self.models = {}  # vulnerability -> {embedd_tokenizer, embedd_model, graph_vul_model, node_vul_model}
        self.llm = None

    def initialize(self):
        """Called ONCE during app startup."""
        seed_everything(settings.SEED)
        prepare_solc_artifacts()

        for name, spec in MODEL_SPECS.items():
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
        from langchain_openai import ChatOpenAI

        self.llm = ChatOpenAI(
            model_name=settings.MODEL_NAME,
            api_key=settings.GEMINI_API_KEY1,
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
