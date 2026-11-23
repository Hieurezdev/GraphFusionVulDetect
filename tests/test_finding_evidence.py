from src.services.finding_evidence import FunctionFinding, byte_location, locate_snippet, sarif_report


def test_unicode_byte_mapping_and_legacy_snippet_locations_agree():
    source = '// tên người dùng\r\ncontract Demo {\r\n  function set() public {}\r\n}\r\n'
    snippet = 'function set() public {}'
    raw = source.encode()
    location = byte_location(raw, raw.index(snippet.encode()), len(snippet.encode()), 'Demo.sol')
    assert location.start_line == location.end_line == 3
    assert locate_snippet(source, snippet, 'Demo.sol') == location
    assert locate_snippet(source + source, snippet, 'Demo.sol') is None
    assert byte_location(raw, len(raw), 10, 'Demo.sol') is None


def test_sarif_keeps_evidence_but_never_invents_a_precise_location():
    source = 'contract Demo {\n  function set() public {}\n}'
    findings = [FunctionFinding(function_name='Demo.set()', function_code='function set() public {}', prediction=1, confidence='91.00%')]
    report = sarif_report(source, 'Demo.sol', findings, True, True)
    result = report['runs'][0]['results'][0]
    assert result['locations'][0]['physicalLocation']['region'] == {'startLine': 2, 'endLine': 2}
    assert result['properties']['reviewRequired'] and not result['properties']['securityVerified']
    findings[0].function_code = 'not present in the uploaded source'
    assert 'locations' not in sarif_report(source, 'Demo.sol', findings, True, True)['runs'][0]['results'][0]
    contract_result = sarif_report(source, 'Demo.sol', [], True, True)['runs'][0]['results'][0]
    assert 'region' not in contract_result['locations'][0]['physicalLocation']
    empty = sarif_report(source, 'Demo.sol', [], False, False)['runs'][0]
    assert empty['results'] == [] and not empty['invocations'][0]['executionSuccessful']
