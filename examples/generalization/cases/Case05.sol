pragma solidity 0.4.24;

contract Probe {
    bool public accepted;
    uint256 public recorded;
    uint256 public trusted = 7;
    event Observed(address caller, uint256 at, uint256 value);

    function sample() internal view returns (uint256) {
        return block.timestamp;
    }

    function choose(uint256 value) internal pure returns (uint256) {
        return value % 13;
    }

    function execute(uint256 ticket) public {
        uint256 selected = choose(sample());
        accepted = ticket == selected;
    }
}
