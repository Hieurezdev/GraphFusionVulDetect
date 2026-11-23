pragma solidity 0.4.24;

contract Probe {
    bool public accepted;
    uint256 public recorded;
    uint256 public trusted = 7;
    event Observed(address caller, uint256 at, uint256 value);

    function execute(uint256 ticket) public {
        uint256 selected = uint256(keccak256(abi.encodePacked(trusted, address(this)))) % 13;
        accepted = ticket == selected;
    }
}
