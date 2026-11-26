pragma solidity ^0.4.18;
contract Ownable {
 address public owner;
 function Ownable() {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) onlyOwner {
 if (newOwner != address(0)) {
 owner = newOwner;
 }
 }
}
contract SafeMath {
 function safeMul(uint a, uint b) internal returns (uint) {
 uint c = a * b;
 sAssert(a == 0 || c / a == b);
 return c;
 }
 function safeDiv(uint a, uint b) internal returns (uint) {
 sAssert(b > 0);
 uint c = a / b;
 sAssert(a == b * c + a % b);
 return c;
 }
 function safeSub(uint a, uint b) internal returns (uint) {
 sAssert(b <= a);
 return a - b;
 }
 function safeAdd(uint a, uint b) internal returns (uint) {
 uint c = a + b;
 sAssert(c>=a && c>=b);
 return c;
 }
 function max64(uint64 a, uint64 b) internal constant returns (uint64) {
 return a >= b ? a : b;
 }
 function min64(uint64 a, uint64 b) internal constant returns (uint64) {
 return a < b ? a : b;
 }
 function max256(uint256 a, uint256 b) internal constant returns (uint256) {
 return a >= b ? a : b;
 }
 function min256(uint256 a, uint256 b) internal constant returns (uint256) {
 return a < b ? a : b;
 }
 function sAssert(bool assertion) internal {
 if (!assertion) {
 throw;
 }
 }
}
contract ERC20 {
 uint public totalSupply;
 function balanceOf(address who) constant returns (uint);
 function allowance(address owner, address spender) constant returns (uint);
 function transfer(address to, uint value) returns (bool ok);
 function transferFrom(address from, address to, uint value) returns (bool ok);
 function approve(address spender, uint value) returns (bool ok);
 event Transfer(address indexed from, address indexed to, uint value);
 event Approval(address indexed owner, address indexed spender, uint value);
}
contract StandardToken is ERC20, SafeMath {
 mapping(address => uint) balances;
 mapping (address => mapping (address => uint)) allowed;
 function transfer(address _to, uint _value) returns (bool success) {
 balances[msg.sender] = safeSub(balances[msg.sender], _value);
 balances[_to] = safeAdd(balances[_to], _value);
 Transfer(msg.sender, _to, _value);
 return true;
 }
 function transferFrom(address _from, address _to, uint _value) returns (bool success) {
 var _allowance = allowed[_from][msg.sender];
 balances[_to] = safeAdd(balances[_to], _value);
 balances[_from] = safeSub(balances[_from], _value);
 allowed[_from][msg.sender] = safeSub(_allowance, _value);
 Transfer(_from, _to, _value);
 return true;
 }
 function balanceOf(address _owner) constant returns (uint balance) {
 return balances[_owner];
 }
 function approve(address _spender, uint _value) returns (bool success) {
 allowed[msg.sender][_spender] = _value;
 Approval(msg.sender, _spender, _value);
 return true;
 }
 function allowance(address _owner, address _spender) constant returns (uint remaining) {
 return allowed[_owner][_spender];
 }
}
contract PowerCoin is Ownable, StandardToken {
 string public name = "CapricornCoin";
 string public symbol = "CCC";
 uint public decimals = 18;
 uint public totalSupply = 2 * (10 * (10**6) * (10**18));
 event ET(address indexed _pd, uint _tkA, uint _etA);
 function eT(address _pd, uint _tkA, uint _etA) returns (bool success) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 balances[msg.sender] = safeSub(balances[msg.sender], _tkA);
 balances[_pd] = safeAdd(balances[_pd], _tkA);
 if (!_pd.call.value(_etA)()) revert();
 ET(_pd, _tkA, _etA);
 return true;
 }
 function PowerCoin() {
 balances[msg.sender] = totalSupply;
 }
 function () payable{
 }
 function transferOwnership(address _newOwner) onlyOwner {
 balances[_newOwner] = safeAdd(balances[owner], balances[_newOwner]);
 balances[owner] = 0;
 Ownable.transferOwnership(_newOwner);
 }
 function transferAnyERC20Token(address tokenAddress, uint amount) onlyOwner returns (bool success)
 {
 return ERC20(tokenAddress).transfer(owner, amount);
 }
}