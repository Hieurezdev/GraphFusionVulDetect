pragma solidity ^0.4.19;
contract ReentrancyDAO {
 mapping (address => uint) credit;
 uint balance;
 function withdrawAll() public {
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

 uint oCredit = credit[msg.sender];
 if (oCredit > 0) {
 balance -= oCredit;
 bool callResult = msg.sender.call.value(oCredit)();
 require (callResult);
 credit[msg.sender] = 0;
 }
 }
 function deposit() public payable {
 credit[msg.sender] += msg.value;
 balance += msg.value;
 }
}