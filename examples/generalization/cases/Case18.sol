pragma solidity 0.4.24;

contract Probe {
    bool public accepted;
    uint256 public recorded;
    uint256 public trusted = 7;
    event Observed(address caller, uint256 at, uint256 value);

    address public beneficiary;

    function execute(uint256 ticket) public {
        require(block.timestamp % 17 == ticket);
        beneficiary = msg.sender;
        accepted = true;
    }
}
