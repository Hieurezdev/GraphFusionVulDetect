from src.services import metrics


def test_render_exposes_counters_gauges_and_histograms_in_prometheus_format():
    metrics.inc("t_requests_total", help_text="test", route="/x", status=200)
    metrics.inc("t_requests_total", route="/x", status=200)
    metrics.gauge_add("t_running", 1)
    metrics.observe("analysis_duration_seconds", 7.0, outcome="t")
    text = metrics.render()
    assert 't_requests_total{route="/x",status="200"} 2' in text
    assert "t_running 1" in text and "# TYPE analysis_duration_seconds histogram" in text
    assert 'analysis_duration_seconds_bucket{outcome="t",le="10"} 1' in text and 'analysis_duration_seconds_bucket{outcome="t",le="5"} 0' in text


def test_llm_tokens_are_counted_from_usage_metadata():
    r = type("R", (), {"usage_metadata": {"input_tokens": 120, "output_tokens": 30}})()
    metrics.record_llm_call(1.5, ok=True, response=r, purpose="t")
    text = metrics.render()
    assert 'llm_tokens_total{direction="input",purpose="t"} 120' in text and 'llm_calls_total{outcome="ok",purpose="t"} 1' in text
