from langgraph.graph import END, StateGraph, START
from src.workflows.chatbot_workflow.graph.state import State
from src.workflows.chatbot_workflow.nodes.analyze_code import analyze_code
from src.workflows.chatbot_workflow.nodes.generate_suggestions import generate_refactoring_suggestions
from src.workflows.chatbot_workflow.nodes.handle_conversation import handle_conversation
from src.workflows.chatbot_workflow.nodes.validate_refactoring import validate_refactoring


def decide_start_node(state: State) -> str:
    """
    Decide where to start the workflow.
    If conversation history exists, we skip analysis/suggestions and go straight to conversation.
    Otherwise (initial run), we start with analysis.
    """
    if state.get("conversation_history"):
        return "handle_conversation"
    return "analyze_code"


def check_issue_exists(state: State) -> str:
    """Initial analysis ends before repair; an owned human review unlocks chat."""
    return "end"


def build_graph() -> StateGraph:
    """
    Build the chatbot refactoring workflow graph.
    
    Returns:
        Compiled StateGraph for the chatbot workflow
    """
    graph_builder = StateGraph(State)
    
    # Add nodes
    graph_builder.add_node("analyze_code", analyze_code)
    graph_builder.add_node("generate_suggestions", generate_refactoring_suggestions)
    graph_builder.add_node("handle_conversation", handle_conversation)
    graph_builder.add_node("validate_refactoring", validate_refactoring)
    
    # Define start behavior
    graph_builder.add_conditional_edges(
        START,
        decide_start_node,
        {
            "analyze_code": "analyze_code",
            "handle_conversation": "handle_conversation"
        }
    )
    
    # After analysis, check if we have an issue description
    graph_builder.add_conditional_edges(
        "analyze_code",
        check_issue_exists,
        {
            "generate_suggestions": "generate_suggestions",
            "end": END
        }
    )
    
    # After generating suggestions, go to validation
    graph_builder.add_edge("generate_suggestions", "validate_refactoring")
    
    # Missing context/tools require user input; actual compiler failures get bounded repairs.
    graph_builder.add_conditional_edges("validate_refactoring", after_validation, {
        "repair": "generate_suggestions", "done": END
    })
    
    # Chat proposals receive the same deterministic checks as initial suggestions.
    graph_builder.add_edge("handle_conversation", "validate_refactoring")
    
    return graph_builder.compile()


def after_validation(state: State) -> str:
    result = state.get("validation_result") or {}
    if result.get("status") == "failed" and state.get("suggested_code") and (state.get("repair_attempts") or 0) < 2:
        return "repair"
    return "done"
