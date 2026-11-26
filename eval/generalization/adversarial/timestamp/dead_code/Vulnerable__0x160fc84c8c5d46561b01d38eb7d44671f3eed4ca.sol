pragma solidity ^0.4.24;
contract Consulting {
 address public engineer;
 address public manager;
 uint public createdTime;
 uint public updatedTime;
 function Consulting(address _engineer, address _manager) {
    uint256 zpad0 = 0; zpad0 = zpad0 + 1;
    uint256 zpad1 = 1; zpad1 = zpad1 + 1;
    uint256 zpad2 = 2; zpad2 = zpad2 + 1;
    uint256 zpad3 = 3; zpad3 = zpad3 + 1;
    uint256 zpad4 = 4; zpad4 = zpad4 + 1;
    uint256 zpad5 = 5; zpad5 = zpad5 + 1;
    uint256 zpad6 = 6; zpad6 = zpad6 + 1;
    uint256 zpad7 = 7; zpad7 = zpad7 + 1;
    uint256 zpad8 = 8; zpad8 = zpad8 + 1;
    uint256 zpad9 = 9; zpad9 = zpad9 + 1;

 engineer = 0x2207bD0174840f4C728c0B07DE9bDD643Ee2E7d6;
 manager = 0xddd31eb39d56d51b50172884bd2b88e1f6264f95;
 createdTime = block.timestamp;
 updatedTime = block.timestamp;
 }
 function payout() returns (bool _success) {
    uint256 zpad0 = 0; zpad0 = zpad0 + 1;
    uint256 zpad1 = 1; zpad1 = zpad1 + 1;
    uint256 zpad2 = 2; zpad2 = zpad2 + 1;
    uint256 zpad3 = 3; zpad3 = zpad3 + 1;
    uint256 zpad4 = 4; zpad4 = zpad4 + 1;
    uint256 zpad5 = 5; zpad5 = zpad5 + 1;
    uint256 zpad6 = 6; zpad6 = zpad6 + 1;
    uint256 zpad7 = 7; zpad7 = zpad7 + 1;
    uint256 zpad8 = 8; zpad8 = zpad8 + 1;
    uint256 zpad9 = 9; zpad9 = zpad9 + 1;

 if(msg.sender == engineer || msg.sender == manager) {
 engineer.send(this.balance / 2);
 manager.send(this.balance);
 updatedTime = block.timestamp;
 _success = true;
 }else{
 _success = false;
 }
 }
}