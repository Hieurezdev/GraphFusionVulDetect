# Timestamp challenge cases

This directory contains **24 newly authored synthetic Solidity cases**, their
source-bound evidence, an expert-review worksheet, and actual local detector
results. All contracts use the installed Solidity 0.4.24 compiler. Each case can
be uploaded individually through the existing website's Solidity upload flow.

These are demo/stress fixtures, **not independently audited production projects**.
Variants share families and must not be presented as independent unseen projects.
No claim is made about absence from model pretraining. The lexical overlap check
only compares target functions with the bundled timestamp train/test CSV files;
it does not establish the absence of renamed or structural clones elsewhere.

## Files

- `cases/Case01.sol` through `cases/Case24.sol`: directly usable Solidity files.
- `manifest.json`: author reference labels, rationale, family relationships,
  evidence lines and source SHA-256. Every professional review starts as pending.
- `review_sheet.csv`: reviewer worksheet without reference/model predictions.
- `results/results.csv`: predictions and reference-only TP/TN/FP/FN outcomes.
- `results/results.json`: scores, coverage, groups, model/compiler provenance,
  corpus-overlap checks and separate expert-reviewed metrics.
- `results/analysis.md`: readable results with evidence links and review priorities.

There are 13 positive and 11 negative **author reference labels** across baseline,
repaired, hard-positive, hard-negative, adversarial, long-function and large-contract
groups. Cases 15/16 each have 1,677 source lines and 128 unrelated pure helpers.
Cases 14/21 move the same sensitive statements across a long comment prefix/suffix;
cases 09/11/13/23/24 vary comments, local names or the legacy timestamp alias.

## Label policy and independent review

The target is security-sensitive timestamp dependence under the documented
assumptions, rather than every appearance of `block.timestamp` or `now`. Positive
references include time-derived ticket selection and authorization. Event-only
timestamps, unreachable expressions and a documented coarse time lock are negative
reference challenges. Real exploitability depends on the deployment chain's
timestamp rules and the contract's intended policy. Review these assumptions.

**Negative means not the target issue, never universally secure.** Other problems,
such as predictable non-time randomness, can remain outside this target. Intended
behavior-preserving transformations have not been formally proved equivalent.

A qualified reviewer should inspect the source before reading model/reference
results. In `review_sheet.csv`, use `confirmed` after completing the assessment,
choose `positive` or `negative` in `expert_label`, and fill `reviewer`, an ISO-8601
`reviewed_at`, and `rationale`. Use `disputed` when context is insufficient. Keep
the source hash unchanged. Candidate line ranges aid navigation and are not a
substitute for inspecting the whole function and its callers/callees.

The importer requires a complete named, dated rationale for confirmed labels.
It validates source binding, not professional qualifications or the authenticity
of an edited offline file. No expert conclusions are fabricated by the evaluator.

## Run locally

From the project root, with the managed environment, cached trained models and
Docker running with the installed `ethereum/solc:0.4.24` image:

```bash
HF_HUB_CACHE=storage/hf-cache HF_HUB_OFFLINE=1 \
  .venv/bin/python -m src.evaluation.generalization
```

For selected cases, choose a separate output directory to preserve the full run:

```bash
HF_HUB_CACHE=storage/hf-cache HF_HUB_OFFLINE=1 \
  .venv/bin/python -m src.evaluation.generalization \
  --case case-14 --case case-21 --output /tmp/timestamp-long-functions
```

After actual reviewer assessment:

```bash
HF_HUB_CACHE=storage/hf-cache HF_HUB_OFFLINE=1 \
  .venv/bin/python -m src.evaluation.generalization \
  --reviews examples/generalization/review_sheet.csv \
  --output examples/generalization/expert-results
```

The runner loads local embedding/GNN weights and uses the production detection
graph, including its source-level gate. It does not call an external LLM, write
user projects or adjust model thresholds. All source hashes and line ranges are
checked before evaluation. The reports are updated after each case; any analysis
error is recorded with a traceback and causes a nonzero final exit status.

Contract and strict target-function metrics are separate. Alerts on related
helpers remain visible for adjudication. Source-level negative gating contributes
to end-to-end target misses. Runtime failures, overlaps and pending expert labels
are not silently scored as expert-confirmed negatives. Scores are uncalibrated.

Fresh evaluation on real, independently sourced projects and qualified human
review are still needed before claiming production-project generalization.
