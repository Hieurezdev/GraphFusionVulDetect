pragma solidity ^0.4.16;
interface Token {
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}
contract ASCCrowdsale {
 Token public tokenReward;
 address public creator;
 address public owner = 0xb99776950E24a1D580d8c1622ab6C92002aEc169;
 uint256 public price;
 uint256 public startDate;
 uint256 public endDate;
 event FundTransfer(address backer, uint amount, bool isContribution);
 function ASCCrowdsale() public {
 creator = msg.sender;
 startDate = 1452038400;
 endDate = 1521586800;
 price = 72000;
 tokenReward = Token(0x9A7fF9c99ECa95Faea0d866a4cdaceaFf276D948);
 }
 function setOwner(address _owner) public {
 require(msg.sender == creator);
 owner = _owner;
 }
 function setCreator(address _creator) public {
 require(msg.sender == creator);
 creator = _creator;
 }
 function setPrice(uint256 _price) public {
 require(msg.sender == creator);
 price = _price;
 }
 function kill() public {
 require(msg.sender == creator);
 selfdestruct(owner);
 }
 function () payable public {
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

 require(msg.value > 0);
 require(now > startDate);
 require(now < endDate);
 uint256 _price = price / 10;
 if(now > startDate && now < 1516230000) {
 _price *= 6;
 _price += price;
 }
 if(now > 1516230000 && now < 1517439600) {
 _price *= 4;
 _price += price;
 }
 if(now > 1517439600 && now < 1518649200) {
 _price *= 2;
 _price += price;
 }
 if(now > 1518649200 && now < 1519858800) {
 _price += price;
 }
 uint amount = msg.value;
 amount /= 10 finney;
 tokenReward.transferFrom(owner, msg.sender, amount);
 FundTransfer(msg.sender, amount, true);
 owner.transfer(msg.value);
 }
}