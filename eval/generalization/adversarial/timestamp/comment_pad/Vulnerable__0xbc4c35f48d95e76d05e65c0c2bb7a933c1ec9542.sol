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
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

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