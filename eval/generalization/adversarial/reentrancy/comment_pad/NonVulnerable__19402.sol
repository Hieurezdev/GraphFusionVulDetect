pragma solidity ^0.4.18;
contract SafeMath {
 function safeMul(uint a, uint b) internal returns (uint) {
 uint c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function safeSub(uint a, uint b) internal returns (uint) {
 assert(b <= a);
 return a - b;
 }
 function safeAdd(uint a, uint b) internal returns (uint) {
 uint c = a + b;
 assert(c>=a && c>=b);
 return c;
 }
 function assert(bool assertion) internal {
 if (!assertion) throw;
 }
}
contract Token {
 function totalSupply() constant returns (uint256 supply) {}
 function balanceOf(address _owner) constant returns (uint256 balance) {}
 function transfer(address _to, uint256 _value) returns (bool success) {}
 function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
 function approve(address _spender, uint256 _value) returns (bool success) {}
 function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract StandardToken is Token {
 function transfer(address _to, uint256 _value) returns (bool success) {
 if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
 balances[msg.sender] -= _value;
 balances[_to] += _value;
 Transfer(msg.sender, _to, _value);
 return true;
 } else { return false; }
 }
 function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
 if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
 balances[_to] += _value;
 balances[_from] -= _value;
 allowed[_from][msg.sender] -= _value;
 Transfer(_from, _to, _value);
 return true;
 } else { return false; }
 }
 function balanceOf(address _owner) constant returns (uint256 balance) {
 return balances[_owner];
 }
 function approve(address _spender, uint256 _value) returns (bool success) {
 allowed[msg.sender][_spender] = _value;
 Approval(msg.sender, _spender, _value);
 return true;
 }
 function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
 return allowed[_owner][_spender];
 }
 mapping(address => uint256) balances;
 mapping (address => mapping (address => uint256)) allowed;
 uint256 public totalSupply;
}
contract monechainToken is StandardToken, SafeMath {
 string public name = "monechain token";
 string public symbol = "MONE";
 uint public decimals = 18;
 uint crowdSalePrice = 300000;
 uint totalPeriod = 256 * 24 * 365;
 uint public startBlock = 5278735;
 uint public endBlock = startBlock + totalPeriod;
 address public founder = 0x466ea8E1003273AE4471c903fBA7D8edF834970a;
 uint256 bountyAllocation = 4500000000 * 10**(decimals);
 uint256 public crowdSaleCap = 1000000000 * 10**(decimals);
 uint256 public candyCap = 4500000000 * 10**(decimals);
 uint256 public candyPrice = 1000;
 uint256 public crowdSaleSoldAmount = 0;
 uint256 public candySentAmount = 0;
 mapping(address => bool) candyBook;
 event Buy(address indexed sender, uint eth, uint fbt);
 function monechainToken() {
 balances[founder] = bountyAllocation;
 totalSupply = bountyAllocation;
 Transfer(address(0), founder, bountyAllocation);
 }
 function price() constant returns(uint) {
 if (block.number<startBlock || block.number > endBlock) return 0;
 else return crowdSalePrice;
 }
 function() public payable {
 if(msg.value == 0) {
 sendCandy(msg.sender);
 } else {
 buyToken(msg.sender, msg.value);
 }
 }
 function sendCandy(address recipient) internal {
 if (candyBook[recipient] || candySentAmount>=candyCap) revert();
 else {
 uint candies = candyPrice * 10**(decimals);
 candyBook[recipient] = true;
 balances[recipient] = safeAdd(balances[recipient], candies);
 candySentAmount = safeAdd(candySentAmount, candies);
 totalSupply = safeAdd(totalSupply, candies);
 Transfer(address(0), recipient, candies);
 }
 }
 function buyToken(address recipient, uint256 value) internal {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (block.number<startBlock || block.number>endBlock) throw;
 uint tokens = safeMul(value, price());
 if(safeAdd(crowdSaleSoldAmount, tokens)>crowdSaleCap) throw;
 balances[recipient] = safeAdd(balances[recipient], tokens);
 crowdSaleSoldAmount = safeAdd(crowdSaleSoldAmount, tokens);
 totalSupply = safeAdd(totalSupply, tokens);
 Transfer(address(0), recipient, tokens);
 if (!founder.call.value(value)()) throw;
 Buy(recipient, value, tokens);
 }
 function checkCandy(address recipient) constant returns (uint256 remaining) {
 if(candyBook[recipient]) return 0;
 else return candyPrice;
 }
 function changeFounder(address newFounder) {
 if (msg.sender!=founder) throw;
 founder = newFounder;
 }
}