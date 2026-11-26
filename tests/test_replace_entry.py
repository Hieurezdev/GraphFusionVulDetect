from src.services.findings import replace_entry


def test_replace_entry_keeps_user_text_literal():
    entry = {"vulnerability": "timestamp", "function_name": "C.f()", "note": "$where: 1", "suggested_code": "$$ROOT"}
    update = replace_entry("reviews", entry)
    new_list = update[0]["$set"]["reviews"]["$concatArrays"]
    assert new_list[1] == [{"$literal": entry}]  # "$..." in user text must not become an expression
    cond = new_list[0]["$filter"]["cond"]["$not"][0]["$and"]
    assert {"$eq": ["$$e.function_name", "C.f()"]} in cond
