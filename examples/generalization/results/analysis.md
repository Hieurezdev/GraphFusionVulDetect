# Challenge-suite results

Synthetic author reference labels are provisional. No professional review, production-project generalization, calibrated confidence or security proof is implied.

The following comparisons use author reference labels. Expert-reviewed metrics remain separate and are unavailable until source-bound reviewer records are supplied.

| Assessment | Evaluated | TP | TN | FP | FN | Precision | Recall | F1 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| contract_reference_only | 24 | 12 | 2 | 9 | 1 | 0.571 | 0.923 | 0.706 |
| target_function_reference_only | 24 | 9 | 8 | 3 | 4 | 0.750 | 0.692 | 0.720 |
| contract_expert_reviewed | 0 | 0 | 0 | 0 | 0 | unavailable | unavailable | unavailable |
| target_function_expert_reviewed | 0 | 0 | 0 | 0 | 0 | unavailable | unavailable | unavailable |

Target-function matching is strict. Warnings on related helper functions are listed for manual adjudication and do not count as a target-function hit. A source-level negative suppresses function analysis and can create an end-to-end miss. Compiler/runtime errors are reported separately, never counted as negatives.

| Case | Evidence | Reference | Contract | Target function | Target tokens | Other flagged functions |
|---|---|---|---|---|---:|---|
| [case-01](../cases/Case01.sol#L10) | 10–11 | positive | TP | TP | 49 | Probe.execute(uint256) |
| [case-02](../cases/Case02.sol#L10) | 10–11 | negative | FP | TN | 44 |  |
| [case-03](../cases/Case03.sol#L10) | 10–11 | positive | TP | TP | 70 | Probe.execute(uint256) |
| [case-04](../cases/Case04.sol#L10) | 10–11 | negative | TN | TN | 67 |  |
| [case-05](../cases/Case05.sol#L10) | 10–19 | positive | TP | FN | 46 | Probe.sample() |
| [case-06](../cases/Case06.sol#L10) | 10–15 | negative | FP | TN | 51 | Probe.sample() |
| [case-07](../cases/Case07.sol#L10) | 10–15 | positive | TP | FN | 42 | Probe.stage() |
| [case-08](../cases/Case08.sol#L10) | 10–15 | negative | FP | TN | 40 | Probe.stage() |
| [case-09](../cases/Case09.sol#L11) | 11–12 | positive | TP | TP | 68 | Probe.execute(uint256) |
| [case-10](../cases/Case10.sol#L11) | 11–12 | negative | FP | TN | 68 |  |
| [case-11](../cases/Case11.sol#L11) | 11–12 | positive | TP | FN | 107 |  |
| [case-12](../cases/Case12.sol#L11) | 11–12 | negative | FP | TN | 49 |  |
| [case-13](../cases/Case13.sol#L10) | 10–11 | positive | TP | TP | 49 | Probe.execute(uint256) |
| [case-14](../cases/Case14.sol#L150) | 150–151 | positive | FN | FN | 2808 |  |
| [case-15](../cases/Case15.sol#L10) | 10–11 | positive | TP | TP | 49 | Probe.execute(uint256) |
| [case-16](../cases/Case16.sol#L10) | 10–11 | negative | FP | TN | 44 |  |
| [case-17](../cases/Case17.sol#L13) | 13–15 | negative | FP | FP | 68 | Probe.execute(uint256) |
| [case-18](../cases/Case18.sol#L12) | 12–14 | positive | TP | TP | 62 | Probe.execute(uint256) |
| [case-19](../cases/Case19.sol#L10) | 10–11 | negative | FP | FP | 54 | Probe.execute(uint256) |
| [case-20](../cases/Case20.sol#L10) | 10–13 | negative | FP | FP | 75 | Probe.execute(uint256) |
| [case-21](../cases/Case21.sol#L10) | 10–11 | positive | TP | TP | 2808 | Probe.execute(uint256) |
| [case-22](../cases/Case22.sol#L150) | 150–151 | negative | TN | TN | 2813 |  |
| [case-23](../cases/Case23.sol#L10) | 10–11 | positive | TP | TP | 46 | Probe.execute(uint256) |
| [case-24](../cases/Case24.sol#L11) | 11–12 | positive | TP | TP | 66 | Probe.execute(uint256) |

## Review priorities

- Inspect the long-function pair case-14/case-21, which moves the same evidence before or after a long comment block. Compare the recorded predictions with the 512-token embedding window; a causal attribution still needs a controlled ablation.
- Inspect case-01/case-11 for sensitivity to a Unicode comment; both have the same intended executable behavior.
- Review event-only timestamps, coarse time locks and unreachable code (case-17/case-19/case-20) against the label policy before confirming any false-positive conclusion.
- Review cross-function evidence (case-05/case-07) alongside all flagged helper functions before adjudicating localization misses.
- No independent production-project holdout study or professional audit has been performed by this script.
