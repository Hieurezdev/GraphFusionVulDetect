pragma solidity ^0.4.4;
contract Token {
 function transfer(address _to, uint _value) returns (bool);
 function balanceOf(address owner) returns(uint);
}
contract Owned {
 address public owner;
 function Owned() {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 if (msg.sender != owner) throw;
 _;
 }
 address newOwner;
 function changeOwner(address _newOwner) onlyOwner {
 newOwner = _newOwner;
 }
 function acceptOwnership() {
 if (msg.sender == newOwner) {
 owner = newOwner;
 }
 }
}
contract TokenReceivable is Owned {
 event logTokenTransfer(address token, address to, uint amount);
 function claimTokens(address _token, address _to) onlyOwner returns (bool) {
 Token token = Token(_token);
 uint balance = token.balanceOf(this);
 if (token.transfer(_to, balance)) {
 logTokenTransfer(_token, _to, balance);
 return true;
 }
 return false;
 }
}
contract FunFairSale is Owned, TokenReceivable {
 uint public deadline;
 uint public startTime = 123123;
 uint public saleTime = 14 days;
 uint public capAmount;
 function FunFairSale() {
 deadline = startTime + saleTime;
 }
 function setSoftCapDeadline(uint t) onlyOwner {
 if (t > deadline) throw;
 deadline = t;
 }
 function launch(uint _cap) onlyOwner {
 if (this.balance > 0) throw;
 capAmount = _cap;
 }
 function () payable {
 if (block.timestamp < startTime || block.timestamp >= deadline) throw;
 if (this.balance >= capAmount) throw;
 if (this.balance + msg.value >= capAmount) {
 deadline = block.timestamp;
 }
 }
 function withdraw() onlyOwner {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (block.timestamp < deadline) throw;
 if (!owner.call.value(this.balance)()) throw;
 }
 function setStartTime(uint _startTime, uint _deadline) onlyOwner {
 if (_deadline < _startTime) throw;
 startTime = _startTime;
 deadline = _deadline;
 }
}