// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Vault {
    address public owner = msg.sender;
    uint256 public value;

    function set(uint256 next) external {
        require(msg.sender == owner, "Owner only");
        value = next;
    }
}
