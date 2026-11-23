pragma solidity 0.4.24;

contract Probe {
    bool public accepted;
    uint256 public recorded;
    uint256 public trusted = 7;
    event Observed(address caller, uint256 at, uint256 value);

    address public beneficiary = msg.sender;
    uint256 public unlockAt = 1800000000;

    function execute(uint256 ticket) public {
        require(msg.sender == beneficiary);
        require(block.timestamp >= unlockAt + 1 days);
        accepted = ticket == trusted;
    }
}
