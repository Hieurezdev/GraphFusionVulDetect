pragma solidity 0.4.21;
contract ERC20Basic {
 function totalSupply() public view returns (uint256);
 function balanceOf(address who) public view returns (uint256);
 function transfer(address to, uint256 value) public returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
 if (a == 0) {
 return 0;
 }
 c = a * b;
 assert(c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 return a / b;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract ERC223 {
 function transfer(address _to, uint _value, bytes _data) public returns (bool success);
 function transfer(address _to, uint _value, bytes _data, string _fallback) public returns (bool success);
 event Transfer(address indexed from, address indexed to, uint value, bytes data);
}
contract ERC223ReceivingContract {
 function tokenFallback(address _from, uint _value, bytes _data);
}
contract PGGamePlatform is ERC223, ERC20Basic {
 using SafeMath for uint256;
 string public name;
 string public symbol;
 uint8 public decimals;
 uint256 public totalSupply;
 mapping(address => uint256) public balances;
 function name() public view returns (string _name) {
 return name;
 }
 function symbol() public view returns (string _symbol) {
 return symbol;
 }
 function decimals() public view returns (uint8 _decimals) {
 return decimals;
 }
 function totalSupply() public view returns (uint256 _totalSupply) {
 return totalSupply;
 }
 function balanceOf(address _owner) public view returns (uint256 _balance) {
 return balances[_owner];
 }
 function PGGamePlatform() public{
 name = "PG Game Platform";
 symbol = "PGG";
 decimals = 4;
 totalSupply = 10000000000 * 10 ** uint(decimals);
 balances[msg.sender] = totalSupply;
 }
 function transfer(address _to, uint256 _value, bytes _data, string _fallback) public returns (bool _success) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (isContract(_to)) {
 if (balanceOf(msg.sender) < _value)
 revert();
 balances[msg.sender] = balanceOf(msg.sender).sub(_value);
 balances[_to] = balanceOf(_to).add(_value);
 assert(_to.call.value(0)(bytes4(keccak256(_fallback)), msg.sender, _value, _data));
 Transfer(msg.sender, _to, _value, _data);
 return true;
 } else {
 return transferToAddress(_to, _value, _data);
 }
 }
 function transfer(address _to, uint256 _value, bytes _data) public returns (bool _success) {
 if (isContract(_to)) {
 return transferToContract(_to, _value, _data);
 } else {
 return transferToAddress(_to, _value, _data);
 }
 }
 function transfer(address _to, uint256 _value) public returns (bool _success) {
 bytes memory empty;
 if (isContract(_to)) {
 return transferToContract(_to, _value, empty);
 } else {
 return transferToAddress(_to, _value, empty);
 }
 }
 function isContract(address _addr) private view returns (bool _isContract) {
 uint length;
 assembly {
 length := extcodesize(_addr)
 }
 return (length > 0);
 }
 function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool _success) {
 if (balanceOf(msg.sender) < _value)
 revert();
 balances[msg.sender] = balanceOf(msg.sender).sub(_value);
 balances[_to] = balanceOf(_to).add(_value);
 Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool _success) {
 if (balanceOf(msg.sender) < _value) {
 revert();
 }
 balances[msg.sender] = balanceOf(msg.sender).sub(_value);
 balances[_to] = balanceOf(_to).add(_value);
 ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
 receiver.tokenFallback(msg.sender, _value, _data);
 Transfer(msg.sender, _to, _value, _data);
 return true;
 }
}