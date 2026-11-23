import csv
from pathlib import Path

import pytest
from pydantic import ValidationError

from src.evaluation.generalization import Case, CaseResult, apply_reviews, code_fingerprint, load_cases, outcome, summarize

MANIFEST = Path(__file__).resolve().parents[1] / 'examples/generalization/manifest.json'


def test_source_changes_invalidate_saved_evidence(tmp_path):
    source = load_cases(MANIFEST)
    case = source.cases[0]
    destination = tmp_path / case.file
    destination.parent.mkdir(parents=True)
    destination.write_bytes((MANIFEST.parent / case.file).read_bytes())
    manifest = source.model_copy(update={'cases': [case]})
    path = tmp_path / 'manifest.json'
    path.write_text(manifest.model_dump_json())
    assert load_cases(path).cases[0].source_sha256 == case.source_sha256
    destination.write_text(destination.read_text() + '\n// changed source\n')
    with pytest.raises(ValueError, match='source changed'):
        load_cases(path)


def test_unattributed_expert_labels_are_rejected():
    data = load_cases(MANIFEST).cases[0].model_dump()
    data['expert_review']['status'] = 'confirmed'
    data['expert_review']['label'] = 'positive'
    with pytest.raises(ValidationError, match='named, dated rationale'):
        Case.model_validate(data)


def test_metrics_keep_pending_expert_labels_errors_and_overlap_separate():
    cases = load_cases(MANIFEST).cases

    def result(case, prediction):
        return CaseResult(case_id=case.case_id, family_id=case.family_id, group=case.group, file=case.file,
            source_sha256=case.source_sha256, target_function=case.target_function, evidence=case.evidence,
            reference_label=case.reference_label, expert_review_status='pending', analysis_status='completed',
            elapsed_seconds=1, source_lines=20, contract_prediction=prediction, target_prediction=prediction,
            contract_reference_outcome=outcome(case.reference_label, prediction), target_reference_outcome=outcome(case.reference_label, prediction))

    positive = result(cases[0], 0)
    negative = result(cases[1], 1)
    failed = positive.model_copy(update={'analysis_status': 'error', 'contract_reference_outcome': None, 'target_reference_outcome': None})
    overlap = negative.model_copy(update={'bundled_function_overlap': ['train']})
    summary = summarize([positive, negative, failed, overlap])
    assert summary['contract_reference_only'].evaluated == 2
    assert summary['contract_reference_only'].fn == summary['contract_reference_only'].fp == 1
    assert summary['target_function_expert_reviewed'].evaluated == 0
    assert summary['target_function_expert_reviewed'].recall is None


def test_lexical_overlap_check_ignores_comments_but_preserves_string_and_token_boundaries():
    assert code_fingerprint('function f() { return 7; }') == code_fingerprint('function f(){/* comment */return 7;}')
    assert code_fingerprint('emit E("// not a comment");') != code_fingerprint('emit E("different");')
    assert code_fingerprint('a b') != code_fingerprint('ab')


def test_review_sheet_requires_complete_source_bound_attestations(tmp_path):
    manifest = load_cases(MANIFEST)
    case = manifest.cases[0]
    path = tmp_path / 'reviews.csv'
    row = {'case_id': case.case_id, 'source_sha256': case.source_sha256, 'status': 'confirmed',
           'expert_label': 'positive', 'reviewer': 'Synthetic test reviewer', 'reviewed_at': '2026-01-01T00:00:00Z',
           'rationale': 'Fixture rationale for source-bound review import.'}

    def write():
        with path.open('w', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=list(row))
            writer.writeheader()
            writer.writerow(row)

    write()
    reviewed = apply_reviews(manifest, path)
    assert reviewed.cases[0].expert_review.status == 'confirmed'
    assert manifest.cases[0].expert_review.status == 'pending'
    row['source_sha256'] = '0' * 64
    write()
    with pytest.raises(ValueError, match='different source'):
        apply_reviews(manifest, path)
