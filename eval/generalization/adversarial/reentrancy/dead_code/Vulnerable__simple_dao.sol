pragma solidity ^0.4.2;
contract SimpleDAO {
 mapping (address => uint) public credit;
 function donate(address to) payable {
 credit[to] += msg.value;
 }
 function withdraw(uint amount) {
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

 if (credit[msg.sender]>= amount) {
 bool res = msg.sender.call.value(amount)();
 credit[msg.sender]-=amount;
 }
 }
 function queryCredit(address to) returns (uint){
 return credit[to];
 }
}