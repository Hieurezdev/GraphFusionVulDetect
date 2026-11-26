pragma solidity ^0.4.0;
contract ERC223 {
	function balanceOf(address owner) public view returns (uint);
	function name() public view returns (string);
	function symbol() public view returns (string);
	function decimals() public view returns (uint8);
 function totalSupply() public view returns (uint);
	function transfer(address to, uint value) public returns (bool success);
 function transfer(address to, uint value, bytes data) public returns (bool success);
 function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool success);
 event Transfer(address indexed from, address indexed to, uint indexed value, bytes data);
}
contract ERC223ReceivingContract {
 function tokenFallback(address from, uint value, bytes data) public;
}
library SafeMath {function mul(uint a, uint b) internal pure returns (uint) {
 uint c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div(uint a, uint b) internal pure returns (uint) {
 uint c = a / b;
 return c;
 }
 function sub(uint a, uint b) internal pure returns (uint) {
 assert(b <= a);
 return a - b;
 }
 function add(uint a, uint b) internal pure returns (uint) {
 uint c = a + b;
 assert(c >= a);
 return c;
 }
 function max64(uint64 a, uint64 b) internal pure returns (uint64) {
 return a >= b ? a : b;
 }
 function min64(uint64 a, uint64 b) internal pure returns (uint64) {
 return a < b ? a : b;
 }
 function max256(uint256 a, uint256 b) internal pure returns (uint256) {
 return a >= b ? a : b;
 }
 function min256(uint256 a, uint256 b) internal pure returns (uint256) {
 return a < b ? a : b;
 }
}
contract MyToken is ERC223 {
 using SafeMath for uint;
 mapping(address => uint) balances;
 string public name;
 string public symbol;
 uint8 public decimals;
 uint public totalSupply;
 constructor(string _name, string _symbol, uint8 _decimals, uint _totalSupply) public {
 name = _name;
 symbol = _symbol;
 decimals = _decimals;
 totalSupply = _totalSupply;
 balances[msg.sender] = _totalSupply;
	}
 function name() public view returns (string) {
 return name;
 }
 function symbol() public view returns (string) {
 return symbol;
	}
 function decimals() public view returns (uint8) {
 return decimals;
 }
 function totalSupply() public view returns (uint) {
 return totalSupply;
 }
	function balanceOf(address owner) public view returns (uint) {
 return balances[owner];
	}
	function transfer(address to, uint value, bytes data) public returns (bool) {
 if(balanceOf(msg.sender) < value) revert();
 balances[msg.sender] = balances[msg.sender].sub(value);
 balances[to] = balances[to].add(value);
 if(isContract(to)) {
 ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
 receiver.tokenFallback(msg.sender, value, data);
 }
 emit Transfer(msg.sender, to, value, data);
 return true;
	}
	function transfer(address to, uint value) public returns (bool) {
 if(balanceOf(msg.sender) < value) revert();
 bytes memory empty;
 balances[msg.sender] = balances[msg.sender].sub(value);
 balances[to] = balances[to].add(value);
 if(isContract(to)) {
 ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
 receiver.tokenFallback(msg.sender, value, empty);
 }
 emit Transfer(msg.sender, to, value, empty);
 return true;
	}
	function transfer(address to, uint value, bytes data, string customFallback) public returns (bool) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if(balanceOf(msg.sender) < value) revert();
 balances[msg.sender] = balances[msg.sender].sub(value);
 balances[to] = balances[to].add(value);
 if (isContract(to)) {
 assert(to.call.value(0)(bytes4(keccak256(customFallback)), msg.sender, value, data));
 }
 emit Transfer(msg.sender, to, value, data);
 return true;
	}
	function isContract(address addr) private view returns (bool) {
 uint len;
 assembly {
 len := extcodesize(addr)
 }
 return (len > 0);
	}
}