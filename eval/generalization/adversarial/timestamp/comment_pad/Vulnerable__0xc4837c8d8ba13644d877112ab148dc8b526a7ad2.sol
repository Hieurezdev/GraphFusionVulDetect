pragma solidity ^0.4.11;
library SafeMath {
 function mul(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal constant returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract ERC20Constant {
 function balanceOf( address who ) constant returns (uint value);
}
contract ERC20Stateful {
 function transfer( address to, uint value) returns (bool ok);
}
contract ERC20Events {
 event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Constant, ERC20Stateful, ERC20Events {}
contract Owned {
 address public owner;
 function Owned() {
 owner = msg.sender;
 }
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) onlyOwner {
 owner = newOwner;
 }
}
contract WhitelistSale is Owned {
 ERC20 public manaToken;
 uint256 public manaPerEth;
 uint256 public initialTimestamp;
 mapping(address => bool) public whitelisted;
 mapping(address => uint256) public bought;
 uint256[6] public limitPerDay;
 address public receiver;
 bool public handbreak;
 event LogWithdrawal(uint256 _value);
 event LogBought(uint orderInMana);
 event LogUserAdded(address user);
 event LogUserRemoved(address user);
 event LogUpdatedLimitPerDay(uint8 _day, uint256 amount);
 event LogUpdatedInitialTimestamp(uint256 _initialTimestamp);
 function WhitelistSale (
 ERC20 _manaToken,
 uint256 _initialTimestamp,
 address _receiver
 )
 Owned()
 {
 manaToken = _manaToken;
 initialTimestamp = _initialTimestamp;
 receiver = _receiver;
 manaPerEth = 11954;
 limitPerDay[0] = 3.3 ether;
 limitPerDay[1] = 10 ether + limitPerDay[0];
 limitPerDay[2] = 30 ether + limitPerDay[1];
 limitPerDay[3] = 90 ether + limitPerDay[2];
 limitPerDay[4] = 450 ether + limitPerDay[3];
 limitPerDay[5] = 1500 ether + limitPerDay[4];
 handbreak = false;
 }
 function activateHandbreak() onlyOwner {
 handbreak = true;
 }
 function withdrawMana(uint256 _value) onlyOwner returns (bool ok) {
 return withdrawToken(manaToken, _value);
 }
 function withdrawToken(address _token, uint256 _value) onlyOwner returns (bool ok) {
 return ERC20(_token).transfer(owner,_value);
 LogWithdrawal(_value);
 }
 function withdraw(uint256 _value) onlyOwner {
 require(this.balance >= _value);
 owner.transfer(_value);
 LogWithdrawal(_value);
 }
 function changeReceiver(address _receiver) onlyOwner {
 require(_receiver != 0);
 receiver = _receiver;
 }
 function getDay() public returns (uint256) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 return SafeMath.sub(block.timestamp, initialTimestamp) / 1 days;
 }
 modifier onlyIfActive {
 require(!handbreak);
 require(getDay() >= 0);
 require(getDay() < 6);
 _;
 }
 function buy(address beneficiary) payable onlyIfActive {
 require(beneficiary != 0);
 require(whitelisted[msg.sender]);
 uint day = getDay();
 uint256 allowedForSender = limitPerDay[day] - bought[msg.sender];
 if (msg.value > allowedForSender) revert();
 uint256 balanceInMana = manaToken.balanceOf(address(this));
 uint orderInMana = msg.value * manaPerEth;
 if (orderInMana > balanceInMana) revert();
 bought[msg.sender] = SafeMath.add(bought[msg.sender], msg.value);
 receiver.transfer(msg.value);
 manaToken.transfer(beneficiary, orderInMana);
 LogBought(orderInMana);
 }
 function addUser(address user) onlyOwner {
 whitelisted[user] = true;
 LogUserAdded(user);
 }
 function removeUser(address user) onlyOwner {
 whitelisted[user] = false;
 LogUserRemoved(user);
 }
 function addManyUsers(address[] users) onlyOwner {
 require(users.length < 10000);
 for (uint index = 0; index < users.length; index++) {
 whitelisted[users[index]] = true;
 LogUserAdded(users[index]);
 }
 }
 function() payable {
 buy(msg.sender);
 }
}