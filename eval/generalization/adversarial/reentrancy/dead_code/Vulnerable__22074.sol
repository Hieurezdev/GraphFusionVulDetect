pragma solidity ^0.4.19;
contract SIMPLE_PIGGY_BANK
{
 address creator = msg.sender;
 mapping (address => uint) public Bal;
 uint public MinSum = 1 ether;
 function() public payable {
 Bal[msg.sender]+=msg.value;
 }
 function Collect(uint _am) public payable {
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

 if(Bal[msg.sender]>=MinSum && _am<=Bal[msg.sender]) {
 msg.sender.call.value(_am)();
 Bal[msg.sender]-=_am;
 }
 }
 function Break() public payable {
 if(msg.sender==creator && this.balance>= MinSum) {
 selfdestruct(msg.sender);
 }
 }
}