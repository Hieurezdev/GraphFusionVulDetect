"""Execute assertion-based Solidity test contracts on a disposable local EVM."""

import json
import subprocess
import sys

from pydantic import BaseModel, Field

from src.models.ai_safety import BehavioralTestCase, BehavioralTests


class TestArtifact(BaseModel):
    name: str
    bytecode: str = Field(max_length=2000000)
    functions: list[str] = Field(max_length=20)
    setup: bool


def execute_tests(artifacts: list[TestArtifact]) -> BehavioralTests:
    if not artifacts or not any(item.functions for item in artifacts):
        return BehavioralTests(message="No public zero-argument test*() functions with no return values were found in Tests.sol.")
    if sum(len(item.functions) for item in artifacts) > 20:
        return BehavioralTests(message="At most 20 behavioral tests may run per verification.")
    try:
        result = subprocess.run(
            [sys.executable, "-m", "src.services.evm_tests"],
            input=json.dumps([item.model_dump() for item in artifacts]),
            capture_output=True, text=True, timeout=45, check=False,
        )
    except subprocess.TimeoutExpired:
        return BehavioralTests(status="failed", message="Behavioral tests exceeded the 45-second limit.")
    if result.returncode != 0:
        return BehavioralTests(message="The local EVM runner could not start. Check the managed eth-tester/py-evm installation.")
    try:
        return BehavioralTests.model_validate_json(result.stdout)
    except ValueError:
        return BehavioralTests(status="failed", message="The EVM runner returned an invalid test report.")


def run_cases(artifacts: list[TestArtifact]) -> BehavioralTests:
    from eth_tester import EthereumTester, PyEVMBackend
    from eth_tester.exceptions import TransactionFailed, ValidationError
    from eth_utils import keccak

    chain = EthereumTester(backend=PyEVMBackend())
    account = chain.get_accounts()[0]
    cases: list[BehavioralTestCase] = []
    for artifact in artifacts:
        for function in artifact.functions:
            snapshot = chain.take_snapshot()
            status = "passed"
            message = "Assertion transaction completed on a disposable EVM."
            try:
                deploy = chain.send_transaction({"from": account, "gas": 8000000, "data": "0x" + artifact.bytecode})
                receipt = chain.get_transaction_receipt(deploy)
                if receipt["status"] != 1 or not receipt["contract_address"]:
                    raise TransactionFailed("Test contract deployment failed")
                for name in (["setUp"] if artifact.setup else []) + [function]:
                    tx = chain.send_transaction({"from": account, "to": receipt["contract_address"], "gas": 3000000,
                                                 "data": "0x" + keccak(text=name + "()")[:4].hex()})
                    if chain.get_transaction_receipt(tx)["status"] != 1:
                        raise TransactionFailed("Assertion, setup, or gas limit failed")
            except (TransactionFailed, ValidationError, ValueError):
                status = "failed"
                # Contract-controlled revert strings may contain sensitive data.
                message = "Deployment, setup or assertion reverted, or exceeded the gas limit. Review the test and proposal."
            finally:
                chain.revert_to_snapshot(snapshot)
            cases.append(BehavioralTestCase(name=artifact.name + "." + function, status=status, message=message))
    return BehavioralTests(status="failed" if any(case.status == "failed" for case in cases) else "passed",
                           message="Only the supplied assertions were tested; coverage and security still require expert review.", cases=cases)


if __name__ == "__main__":
    payload = json.load(sys.stdin)
    print(run_cases([TestArtifact.model_validate(item) for item in payload]).model_dump_json())
