"""Run the existing local detector against synthetic, reviewable challenge cases."""

import argparse
import contextlib
import csv
import hashlib
import io
import json
import platform
import re
import subprocess
import time
import traceback
from datetime import datetime, timezone
from pathlib import Path
from typing import Literal

from pydantic import BaseModel, Field, model_validator

Label = Literal["positive", "negative"]
Group = Literal["baseline", "repaired", "hard_positive", "hard_negative", "adversarial", "long_function", "large_contract"]
Outcome = Literal["TP", "TN", "FP", "FN"]


class Evidence(BaseModel):
    start_line: int = Field(ge=1)
    end_line: int = Field(ge=1)


class ExpertReview(BaseModel):
    status: Literal["pending", "confirmed", "disputed"]
    label: Label | None
    reviewer: str | None
    reviewed_at: datetime | None
    rationale: str | None
    source_sha256: str | None


class Case(BaseModel):
    case_id: str = Field(pattern=r"^case-\d{2}$")
    file: str
    family_id: str
    group: Group
    target_function: str
    compiler: Literal["0.4.24"]
    source_sha256: str = Field(pattern=r"^[a-f0-9]{64}$")
    reference_label: Label
    reference_rationale: str
    evidence: Evidence
    variant_of: str | None
    intended_behavior_preserving: bool
    expert_review: ExpertReview

    @model_validator(mode="after")
    def check_expert_record(self) -> "Case":
        review = self.expert_review
        if review.status == "confirmed" and (not review.label or not review.reviewer or not review.reviewed_at
                or not review.rationale or review.source_sha256 != self.source_sha256):
            raise ValueError("An expert label requires a named, dated rationale bound to this source hash")
        return self


class Manifest(BaseModel):
    schema_version: Literal[1]
    suite_id: str
    provenance: str
    label_policy: str
    expert_review_complete: bool
    generalization_claim: str
    cases: list[Case]


class CaseResult(BaseModel):
    case_id: str
    family_id: str
    group: Group
    file: str
    source_sha256: str
    target_function: str
    evidence: Evidence
    reference_label: Label
    expert_label: Label | None = None
    expert_review_status: Literal["pending", "confirmed", "disputed"]
    analysis_status: Literal["completed", "error"]
    elapsed_seconds: float
    source_lines: int
    graph_nodes: int | None = None
    contract_prediction: int | None = None
    contract_score: float | None = None
    target_prediction: int | None = None
    target_score: str | None = None
    function_stage_skipped: bool = False
    flagged_functions: list[str] = Field(default_factory=list)
    target_tokens: int | None = None
    tokenizer_limit: int | None = None
    bundled_function_overlap: list[str] = Field(default_factory=list)
    contract_reference_outcome: Outcome | None = None
    target_reference_outcome: Outcome | None = None
    contract_expert_outcome: Outcome | None = None
    target_expert_outcome: Outcome | None = None
    error: str | None = None


class Metrics(BaseModel):
    evaluated: int
    tp: int
    tn: int
    fp: int
    fn: int
    precision: float | None
    recall: float | None
    f1: float | None


def outcome(label: Label, prediction: int) -> Outcome:
    if label == "positive":
        return "TP" if prediction == 1 else "FN"
    return "FP" if prediction == 1 else "TN"


def metrics(outcomes: list[Outcome]) -> Metrics:
    tp, tn, fp, fn = (outcomes.count(value) for value in ["TP", "TN", "FP", "FN"])
    precision = tp / (tp + fp) if tp + fp else None
    recall = tp / (tp + fn) if tp + fn else None
    f1 = 2 * tp / (2 * tp + fp + fn) if 2 * tp + fp + fn else None
    return Metrics(evaluated=len(outcomes), tp=tp, tn=tn, fp=fp, fn=fn, precision=precision, recall=recall, f1=f1)


_LEXEMES = re.compile(r'''//[^\r\n]*|/\*.*?\*/|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\w+|[^\s]''', re.DOTALL)


def code_fingerprint(code: str) -> str:
    tokens = [token for token in _LEXEMES.findall(code) if not token.startswith(("//", "/*"))]
    return hashlib.sha256("\x1f".join(tokens).encode()).hexdigest()


def load_cases(manifest_path: Path) -> Manifest:
    manifest = Manifest.model_validate_json(manifest_path.read_text(encoding="utf-8"))
    if len({case.case_id for case in manifest.cases}) != len(manifest.cases):
        raise ValueError("Case identifiers must be unique")
    ids = {case.case_id for case in manifest.cases}
    by_id = {case.case_id: case for case in manifest.cases}
    for case in manifest.cases:
        path = (manifest_path.parent / case.file).resolve()
        if not path.is_relative_to(manifest_path.parent.resolve()) or path.suffix != ".sol":
            raise ValueError("Case files must stay inside the manifest directory")
        raw = path.read_bytes()
        if hashlib.sha256(raw).hexdigest() != case.source_sha256:
            raise ValueError("Case source changed; update its evidence and review before evaluating: " + case.case_id)
        if case.evidence.end_line < case.evidence.start_line or case.evidence.end_line > len(raw.decode().splitlines()):
            raise ValueError("Invalid source evidence range: " + case.case_id)
        if case.variant_of and case.variant_of not in ids:
            raise ValueError("Unknown variant parent: " + case.case_id)
        if case.variant_of:
            parent = by_id[case.variant_of]
            if parent.family_id != case.family_id:
                raise ValueError("Related variants must remain in the same family: " + case.case_id)
            if case.intended_behavior_preserving and parent.reference_label != case.reference_label:
                raise ValueError("Intended invariance pairs must have the same reference label: " + case.case_id)
    if manifest.expert_review_complete and any(case.expert_review.status != "confirmed" for case in manifest.cases):
        raise ValueError("Expert review completion must match the individual records")
    return manifest


def bundled_fingerprints() -> dict[str, set[str]]:
    corpora = {}
    for split in ["train", "test"]:
        path = Path("assets/datasets/FunctionSyntaxDataset/TimestampDependencyDataset") / (split + ".csv")
        with path.open(newline="", encoding="utf-8") as source:
            corpora[split] = {code_fingerprint(row["function"]) for row in csv.DictReader(source)}
    return corpora


def apply_reviews(manifest: Manifest, path: Path) -> Manifest:
    """Import explicit reviewer records without modifying the source manifest."""
    by_id = {case.case_id: case for case in manifest.cases}
    seen: set[str] = set()
    with path.open(newline="", encoding="utf-8-sig") as stream:
        for row in csv.DictReader(stream):
            identifier = row["case_id"]
            if identifier in seen or identifier not in by_id:
                raise ValueError("Unknown or duplicate review case: " + identifier)
            seen.add(identifier)
            case = by_id[identifier]
            if row["source_sha256"] != case.source_sha256:
                raise ValueError("The review is for different source: " + identifier)
            review = ExpertReview.model_validate({"status": row["status"], "label": row["expert_label"] or None,
                "reviewer": row["reviewer"] or None, "reviewed_at": row["reviewed_at"] or None,
                "rationale": row["rationale"] or None, "source_sha256": row["source_sha256"]})
            by_id[identifier] = Case.model_validate({**case.model_dump(), "expert_review": review.model_dump()})
    cases = [by_id[case.case_id] for case in manifest.cases]
    return manifest.model_copy(update={"cases": cases, "expert_review_complete": all(case.expert_review.status == "confirmed" for case in cases)})


def summarize(results: list[CaseResult]) -> dict[str, Metrics]:
    valid = [item for item in results if item.analysis_status == "completed" and not item.bundled_function_overlap]
    return {
        "contract_reference_only": metrics([item.contract_reference_outcome for item in valid if item.contract_reference_outcome]),
        "target_function_reference_only": metrics([item.target_reference_outcome for item in valid if item.target_reference_outcome]),
        "contract_expert_reviewed": metrics([item.contract_expert_outcome for item in valid if item.contract_expert_outcome]),
        "target_function_expert_reviewed": metrics([item.target_expert_outcome for item in valid if item.target_expert_outcome]),
    }


def write_report(output: Path, manifest: Manifest, results: list[CaseResult], provenance: dict[str, str | int], complete: bool) -> None:
    output.mkdir(parents=True, exist_ok=True)
    summary = summarize(results)
    groups = {group: {key: value.model_dump() for key, value in summarize([item for item in results if item.group == group]).items()} for group in sorted({item.group for item in results})}
    report = {"suite_id": manifest.suite_id, "created_at": datetime.now(timezone.utc).isoformat(), "complete": complete,
              "provenance": provenance, "external_ai_used": False, "case_count": len(manifest.cases),
              "completed_cases": sum(item.analysis_status == "completed" for item in results),
              "error_cases": sum(item.analysis_status == "error" for item in results),
              "expert_reviewed_cases": sum(item.expert_review_status == "confirmed" for item in results),
              "warning": "Synthetic author reference labels are provisional. No professional review, production-project generalization, calibrated confidence or security proof is implied.",
              "metrics": {key: value.model_dump() for key, value in summary.items()}, "by_group": groups,
              "results": [item.model_dump(mode="json") for item in results]}
    (output / "results.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n")
    with (output / "results.csv").open("w", newline="", encoding="utf-8") as stream:
        columns = ["case_id", "group", "family_id", "file", "start_line", "end_line", "reference_label", "expert_review_status", "expert_label", "analysis_status", "contract_prediction", "contract_reference_outcome", "target_prediction", "target_reference_outcome", "function_stage_skipped", "flagged_functions", "target_tokens", "tokenizer_limit", "elapsed_seconds", "error"]
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        for item in results:
            row = item.model_dump()
            row.update(start_line=item.evidence.start_line, end_line=item.evidence.end_line)
            row["flagged_functions"] = " | ".join(item.flagged_functions)
            writer.writerow({key: row.get(key) for key in columns})
    lines = ["# Challenge-suite results", "", report["warning"], "",
        "The following comparisons use author reference labels. Expert-reviewed metrics remain separate and are unavailable until source-bound reviewer records are supplied.", "",
        "| Assessment | Evaluated | TP | TN | FP | FN | Precision | Recall | F1 |", "|---|---:|---:|---:|---:|---:|---:|---:|---:|"]
    for name, value in summary.items():
        rates = ["unavailable" if number is None else f"{number:.3f}" for number in [value.precision, value.recall, value.f1]]
        lines.append(f"| {name} | {value.evaluated} | {value.tp} | {value.tn} | {value.fp} | {value.fn} | " + " | ".join(rates) + " |")
    lines += ["", "Target-function matching is strict. Warnings on related helper functions are listed for manual adjudication and do not count as a target-function hit. A source-level negative suppresses function analysis and can create an end-to-end miss. Compiler/runtime errors are reported separately, never counted as negatives.", "",
        "| Case | Evidence | Reference | Contract | Target function | Target tokens | Other flagged functions |",
        "|---|---|---|---|---|---:|---|"]
    for item in results:
        link = f"[{item.case_id}](../{item.file}#L{item.evidence.start_line})"
        location = f"{item.evidence.start_line}–{item.evidence.end_line}"
        lines.append(f"| {link} | {location} | {item.reference_label} | {item.contract_reference_outcome or item.analysis_status} | {item.target_reference_outcome or item.analysis_status} | {item.target_tokens or 'unavailable'} | " + ", ".join(item.flagged_functions) + " |")
    lines += ["", "## Review priorities", "",
        "- Inspect the long-function pair case-14/case-21, which moves the same evidence before or after a long comment block. Compare the recorded predictions with the 512-token embedding window; a causal attribution still needs a controlled ablation.",
        "- Inspect case-01/case-11 for sensitivity to a Unicode comment; both have the same intended executable behavior.",
        "- Review event-only timestamps, coarse time locks and unreachable code (case-17/case-19/case-20) against the label policy before confirming any false-positive conclusion.",
        "- Review cross-function evidence (case-05/case-07) alongside all flagged helper functions before adjudicating localization misses.",
        "- No independent production-project holdout study or professional audit has been performed by this script.", ""]
    (output / "analysis.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=Path("examples/generalization/manifest.json"))
    parser.add_argument("--output", type=Path, default=Path("examples/generalization/results"))
    parser.add_argument("--work-dir", type=Path, default=Path("storage/evaluation/timestamp-challenge-v1"))
    parser.add_argument("--case", action="append", dest="case_ids")
    parser.add_argument("--reviews", type=Path, help="Import a completed source-bound review worksheet")
    args = parser.parse_args()
    manifest = load_cases(args.manifest)
    if args.reviews:
        manifest = apply_reviews(manifest, args.reviews)
    if args.case_ids:
        wanted = set(args.case_ids)
        if wanted - {case.case_id for case in manifest.cases}:
            raise ValueError("Unknown requested case identifier")
        manifest = manifest.model_copy(update={"cases": [case for case in manifest.cases if case.case_id in wanted]})

    import torch
    from langsmith import tracing_context
    from src.config.settings import settings
    from src.workflows.gfd_workflow.workflow import GFDWorkflow
    from src.workflows.gfd_workflow.utils.helper import seed_everything

    torch.set_num_threads(2)
    seed_everything(settings.SEED)
    workflow = GFDWorkflow()
    # Load only the local detector lifecycle. No LLM client or explanation call is needed.
    with tracing_context(enabled=False):
        workflow._load_embedding_model()
        workflow._load_graph_model()
        workflow._load_node_model()
    graph = workflow.build_pipeline()
    config = {"configurable": {"embedd_tokenizer": workflow.embedd_tokenizer, "embedd_model": workflow.embedd_model,
                               "graph_vul_model": workflow.graph_vul_model, "node_vul_model": workflow.node_vul_model, "llm": None}}
    provenance: dict[str, str | int] = {"seed": settings.SEED, "python": platform.python_version(), "torch": torch.__version__,
        "torch_threads": 2, "embedding": settings.EMBEDDING_MODEL_PATH,
        "embedding_revision": workflow.embedd_model.config._commit_hash or "not recorded",
        "tokenizer_limit": workflow.embedd_tokenizer.model_max_length,
        "graph_weights_sha256": hashlib.sha256(Path(settings.GRAPH_VUL_MODEL_PATH).read_bytes()).hexdigest(),
        "node_weights_sha256": hashlib.sha256(Path(settings.NODE_VUL_MODEL_PATH).read_bytes()).hexdigest(),
        "manifest_sha256": hashlib.sha256(args.manifest.read_bytes()).hexdigest()}
    if args.reviews:
        provenance["review_sheet_sha256"] = hashlib.sha256(args.reviews.read_bytes()).hexdigest()
    provenance["compiler_image_id"] = subprocess.run(["docker", "image", "inspect", "--format", "{{.Id}}", "ethereum/solc:0.4.24"], capture_output=True, text=True, check=True, timeout=10).stdout.strip()
    for name in ["nodes/fcg_converter/embedding_generator.py", "nodes/fcg_converter/graph_converter.py", "nodes/src_vul_detector.py", "nodes/func_vul_detector.py", "graph/builder.py", "graph/state.py"]:
        provenance["pipeline_sha256:" + name] = hashlib.sha256((Path("src/workflows/gfd_workflow") / name).read_bytes()).hexdigest()
    corpora = bundled_fingerprints()
    results: list[CaseResult] = []
    for case in manifest.cases:
        started = time.monotonic()
        source_path = args.manifest.parent / case.file
        code = source_path.read_text(encoding="utf-8")
        common = {"case_id": case.case_id, "family_id": case.family_id, "group": case.group, "file": case.file,
                  "source_sha256": case.source_sha256, "target_function": case.target_function, "evidence": case.evidence,
                  "reference_label": case.reference_label, "expert_review_status": case.expert_review.status,
                  "expert_label": case.expert_review.label if case.expert_review.status == "confirmed" else None,
                  "source_lines": len(code.splitlines())}
        try:
            # The production graph contains its real source-level gate and local-only explanation stage.
            with tracing_context(enabled=False), contextlib.redirect_stdout(io.StringIO()):
                state = graph.invoke({"sol_file_path": str(source_path), "fcg_save_dir": str(args.work_dir / case.case_id), "language": "en"}, config)
            if state.get("predicted_class") not in {"Vulnerable", "Non-Vulnerable"}:
                raise RuntimeError("The detector did not produce a contract decision")
            mapping = json.loads(Path(state["mapping_file_path"]).read_text(encoding="utf-8"))
            target_code = mapping.get("code", {}).get(case.target_function)
            if not target_code:
                raise ValueError("Target function is absent from the generated source mapping")
            fingerprint = code_fingerprint(target_code)
            overlap = [split for split, hashes in corpora.items() if fingerprint in hashes]
            contract_prediction = int(state["predicted_class"] == "Vulnerable")
            skipped = contract_prediction == 0
            predictions = state.get("func_vulnerability_predictions") or []
            target = next((item for item in predictions if item["function_name"] == case.target_function), None)
            if not skipped and target is None:
                raise RuntimeError("The function stage ran without a target-function decision")
            target_prediction = 0 if skipped else int(target["prediction"])
            expert = common["expert_label"]
            result = CaseResult(**common, analysis_status="completed", elapsed_seconds=round(time.monotonic() - started, 3),
                graph_nodes=len(mapping.get("node", {})), contract_prediction=contract_prediction, contract_score=state.get("confidence_score"),
                target_prediction=target_prediction, target_score=None if skipped else target["confidence"],
                flagged_functions=[item["function_name"] for item in predictions if item["prediction"] == 1],
                function_stage_skipped=skipped, target_tokens=len(workflow.embedd_tokenizer.encode(target_code, truncation=False, verbose=False)),
                tokenizer_limit=workflow.embedd_tokenizer.model_max_length, bundled_function_overlap=overlap,
                contract_reference_outcome=outcome(case.reference_label, contract_prediction), target_reference_outcome=outcome(case.reference_label, target_prediction),
                contract_expert_outcome=outcome(expert, contract_prediction) if expert else None,
                target_expert_outcome=outcome(expert, target_prediction) if expert else None)
        except Exception as error:
            # Preserve the traceback and explicit error status; a failed case is never scored as a negative.
            error_dir = args.output / "errors"
            error_dir.mkdir(parents=True, exist_ok=True)
            (error_dir / (case.case_id + ".txt")).write_text(traceback.format_exc())
            result = CaseResult(**common, analysis_status="error", elapsed_seconds=round(time.monotonic() - started, 3), error=type(error).__name__ + ": " + str(error)[:1000])
        results.append(result)
        write_report(args.output, manifest, results, provenance, complete=len(results) == len(manifest.cases))
        print(case.case_id, result.analysis_status, "contract=" + str(result.contract_reference_outcome), "function=" + str(result.target_reference_outcome), flush=True)
    print("Reports:", args.output / "results.csv", args.output / "results.json")
    return int(any(item.analysis_status == "error" for item in results))


if __name__ == "__main__":
    raise SystemExit(main())
