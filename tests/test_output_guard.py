from src.workflows.gfd_workflow.utils.output_guard import cited_lines, safety_claims, check_explanation


def test_cited_lines_reads_single_lines_and_ranges():
    assert cited_lines("`L12` and `L13-L15`, also dòng L20–22 and line L7 — L8") == [12, 13, 15, 20, 22, 7, 8]
    assert cited_lines("`L29`–`L31` update state") == [29, 31]
    assert cited_lines("HTML5 or URL9 are not line refs") == []
    assert cited_lines("Chuỗi nào (PoS hay PoW, L2 có sequencer)") == []   # layer-2, not a line


def test_lines_inside_the_function_pass():
    assert check_explanation("**Evidence:** `L12` calls out before `L14` updates the balance.", 9, 16) == []


def test_lines_outside_the_function_are_reported():
    problems = check_explanation("Evidence: `L3` and `L40-L42`.", 9, 16)
    assert len(problems) == 1 and "L3" in problems[0] and "L42" in problems[0]


def test_affirmative_safety_claims_are_reported():
    for text in ["The function is safe.", "This contract looks completely secure.", "There is no vulnerability here.",
                 "Hàm này an toàn.", "Mã hoàn toàn an toàn.", "Hợp đồng không có lỗ hổng nào."]:
        assert safety_claims(text), text


def test_negated_or_caveated_phrases_pass():
    for text in ["Kết luận: Không an toàn.", "The function is not safe.", "This does not mean the code is safe.",
                 "Chưa thể kết luận mã an toàn.", "We cannot say the contract is secure.",
                 "Không thể kết luận hợp đồng không có lỗ hổng.", "Cảnh báo này không phải dương tính giả."]:
        assert safety_claims(text) == [], text


def test_a_clean_vietnamese_explanation_passes():
    text = ("1. **Evidence:** Dòng `L13` gọi ra ngoài trước khi `L14` cập nhật số dư.\n"
            "2. **Impact:** Kẻ tấn công rút tiền lặp lại.\n"
            "3. **Needs manual review:** Kiểm tra các hàm khác; điều này không có nghĩa phần còn lại an toàn.")
    assert check_explanation(text, 9, 16) == []


class _FakeLLM:
    """Returns the queued answers in order and records the prompts it was given."""
    def __init__(self, *answers):
        self.answers, self.prompts = list(answers), []

    def invoke(self, prompt):
        self.prompts.append(prompt)
        return type("R", (), {"content": self.answers.pop(0)})()


FUNC = {"function_name": "C.f()", "function_code": "function f() public {\n  x = now;\n}", "lines": [5, 7], "prediction": 1}


def test_a_broken_answer_is_rewritten_once():
    from src.workflows.gfd_workflow.nodes.func_vul_explainer import explain_one
    llm = _FakeLLM("Evidence: `L99`. The function is safe.", "Evidence: `L6` reads `now`.")
    out = explain_one(llm, FUNC, "timestamp", "en")
    assert out["guard"] == {"ok": True, "problems": [], "rewritten": True}
    assert "broke these rules" in llm.prompts[1] and out["explanation"] == "Evidence: `L6` reads `now`."


def test_still_broken_after_rewrite_is_flagged_for_manual_review():
    from src.workflows.gfd_workflow.nodes.func_vul_explainer import explain_one
    from src.services.findings import summarize
    llm = _FakeLLM("Hàm này an toàn.", "Mã hoàn toàn an toàn.")
    out = explain_one(llm, FUNC, "timestamp", "vi")
    assert out["guard"]["ok"] is False and out["explanation"].startswith("> ⚠")
    events = [{"node": "detect_vulnerability_src", "vulnerability": "timestamp", "output": {"predicted_class": "Vulnerable", "confidence_score": 0.9}},
              {"node": "detect_vulnerability_func", "vulnerability": "timestamp", "output": {"func_vulnerability_predictions": [FUNC]}},
              {"node": "explain_vulnerability_func", "vulnerability": "timestamp", "output": {"explanations": [out]}}]
    manual = summarize(events, ["timestamp"])["manual_review"]
    assert {"vulnerability": "timestamp", "reason": "explanation_failed_check", "function_name": "C.f()"} in manual
