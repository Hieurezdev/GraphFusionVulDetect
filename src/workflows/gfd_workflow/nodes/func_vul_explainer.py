# File: src/nodes/func_vul_explainer.py

import json
import os

import dgl
import torch
import torch.nn.functional as F
from langchain_core.runnables import RunnableConfig
import logging
from src.workflows.gfd_workflow.graph.state import State
from src.utils.language import language_instruction


def explain_vulnerability_func(state: State, config: RunnableConfig) -> State:
    llm = config["configurable"]["llm"]
    func_vulnerability_predictions = state.get("func_vulnerability_predictions", [])
    
    if not llm or not func_vulnerability_predictions:
        state["func_vulnerability_explanations"] = []
        return state

    explanations = []
    for func_info in func_vulnerability_predictions:
        if func_info["prediction"] != 1:
            continue  # Only explain functions predicted as vulnerable
        func_name = func_info["function_name"]
        func_code = func_info["function_code"]
        first_line = (func_info.get("lines") or [1])[0]
        numbered = "\n".join(f"{first_line + i:>4} | {line}" for i, line in enumerate(func_code.splitlines()))
        prompt = (
            "You are a smart contract security auditor reviewing a machine-learning alert. "
            f"A model flagged the following Solidity function as potentially vulnerable to **Timestamp Dependency** "
            f"(confidence {func_info.get('confidence', 'unknown')}). The alert may be a false positive.\n\n"
            f"Function Name: `{func_name}` (lines are numbered as in the original file)\n"
            f"```solidity\n{numbered}\n```\n\n"
            "Answer briefly, with only these headings:\n"
            "1.  **Evidence:** Quote the exact line(s) that support the alert, citing them as `Lx`. "
            "If no line supports it, say the alert looks like a false positive and why.\n"
            "2.  **Impact:** The potential consequences if it is exploitable.\n"
            "3.  **Needs manual review:** What an auditor must still check (callers, deployment context, other attack classes).\n"
            "Never state or imply the code is safe, secure or free of vulnerabilities.\n"
        ) + language_instruction(state.get("language"))
        try:
            response = llm.invoke(prompt)
            answer = response.content.strip()
            if "</think>" in answer:
                answer = answer.split("</think>")[1].strip()
            explanations.append({"function_name": func_name, "explanation": answer})
        except Exception as e:
            explanations.append({"function_name": func_name, "explanation": f"Error generating explanation: {e}"})

    state["func_vulnerability_explanations"] = explanations
    return state