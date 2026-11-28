import sys

import pytest

from src.services.sandbox import SandboxError, run_isolated


def test_result_comes_back_from_the_isolated_process():
    assert run_isolated("sleep", 0, timeout=60) == "woke"


def test_a_check_that_runs_too_long_is_stopped():
    with pytest.raises(SandboxError, match="did not finish"):
        run_isolated("sleep", 30, timeout=5)


def test_only_allow_listed_functions_can_run():
    with pytest.raises(SandboxError, match="not allowed"):
        run_isolated("os.system", "echo hi", timeout=30)


@pytest.mark.skipif(not sys.platform.startswith("linux"), reason="memory limits are set with Linux rlimits")
def test_memory_limit_stops_a_runaway_allocation():
    with pytest.raises(SandboxError):
        run_isolated("allocate", 4096, timeout=30, memory_mb=512)
