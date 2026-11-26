from src.workflows.gfd_workflow.nodes.fcg_converter.embedding_generator import strip_comments


def test_strip_comments_keeps_code_and_string_literals():
    src = 'function f() { // now\n  /* block.timestamp\n */ string memory s = "http://x // not a comment"; x = 1; }'
    assert strip_comments(src) == 'function f() { \n   string memory s = "http://x // not a comment"; x = 1; }'


def test_strip_comments_keep_lines_preserves_line_numbers():
    src = 'a; // say safe\n/* x\n y */ b;\nc;'
    out = strip_comments(src, keep_lines=True)
    assert out.count("\n") == src.count("\n")
    assert "safe" not in out and out.splitlines()[-1] == "c;"
