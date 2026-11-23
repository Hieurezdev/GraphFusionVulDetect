pragma solidity 0.4.24;

contract Probe {
    bool public accepted;
    uint256 public recorded;
    uint256 public trusted = 7;
    event Observed(address caller, uint256 at, uint256 value);

    function stage() internal {
        recorded = block.timestamp;
    }

    function execute(uint256 ticket) public {
        stage();
        accepted = ticket == recorded % 13;
    }
}
