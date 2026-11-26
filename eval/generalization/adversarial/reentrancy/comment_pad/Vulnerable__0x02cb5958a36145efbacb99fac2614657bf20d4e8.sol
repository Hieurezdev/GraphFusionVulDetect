pragma solidity ^0.4.11;
contract ERC223 {
 uint public totalSupply;
 function balanceOf(address who) public view returns (uint);
 function name() public view returns (string _name);
 function symbol() public view returns (string _symbol);
 function decimals() public view returns (uint8 _decimals);
 function totalSupply() public view returns (uint256 _supply);
 function transfer(address to, uint value) public returns (bool ok);
 function transfer(address to, uint value, bytes data) public returns (bool ok);
 function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
 event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
contract ContractReceiver {
 function tokenFallback(address _from, uint _value, bytes _data) public;
}
contract SafeMath {
 uint256 constant public MAX_UINT256 =
 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
 function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
 if (x > MAX_UINT256 - y) revert();
 return x + y;
 }
 function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
 if (x < y) revert();
 return x - y;
 }
 function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
 if (y == 0) return 0;
 if (x > MAX_UINT256 / y) revert();
 return x * y;
 }
}
contract GwbToken is ERC223, SafeMath {
 mapping(address => uint) balances;
 string public name = "GoWeb";
 string public symbol = "GWT";
 uint8 public decimals = 8;
 uint256 public totalSupply = 3000000000000000;
 event Transfer(address indexed from, address indexed to, uint value);
 constructor () public {
 balances[tx.origin] = totalSupply;
 }
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
 function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if(isContract(_to)) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
 balances[_to] = safeAdd(balanceOf(_to), _value);
 assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
 emit Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 else {
 return transferToAddress(_to, _value, false, _data);
 }
 }
 function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
 if(isContract(_to)) {
 return transferToContract(_to, _value, false, _data);
 }
 else {
 return transferToAddress(_to, _value, false, _data);
 }
 }
 function transfer(address _to, uint _value) public returns (bool success) {
 bytes memory empty;
 if(isContract(_to)) {
 return transferToContract(_to, _value, true, empty);
 }
 else {
 return transferToAddress(_to, _value, true, empty);
 }
 }
 function transferToAddress(address _to, uint _value, bool isErc20Transfer, bytes _data) private returns (bool success) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
 balances[_to] = safeAdd(balanceOf(_to), _value);
 if (isErc20Transfer)
 emit Transfer(msg.sender, _to, _value);
 else
 emit Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 function transferToContract(address _to, uint _value, bool isErc20Transfer, bytes _data) private returns (bool success) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
 balances[_to] = safeAdd(balanceOf(_to), _value);
 ContractReceiver receiver = ContractReceiver(_to);
 receiver.tokenFallback(msg.sender, _value, _data);
 if (isErc20Transfer)
 emit Transfer(msg.sender, _to, _value);
 else
 emit Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 function isContract(address _addr) private view returns (bool is_contract) {
 uint length;
 assembly {
 length := extcodesize(_addr)
 }
 return (length>0);
 }
 function balanceOf(address _owner) public view returns (uint balance) {
 return balances[_owner];
 }
}