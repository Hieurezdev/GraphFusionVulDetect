pragma solidity ^0.4.21;
interface ContractReceiver {
 function tokenFallback( address from, uint value, bytes data ) external;
}
contract SafeMath {
 function safeSub(uint a, uint b) internal pure returns (uint) {
 assert(b <= a);
 return a - b;
 }
 function safeAdd(uint a, uint b) internal pure returns (uint) {
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
contract RUNEToken is SafeMath
{
 string public name = "Rune";
 string public symbol = "RUNE";
 uint256 public decimals = 18;
 uint256 public totalSupply = 1000000000 * (10 ** decimals);
 mapping( address => uint256 ) balances_;
 mapping( address => mapping(address => uint256) ) allowances_;
 function RUNEToken() public {
 balances_[msg.sender] = totalSupply;
 emit Transfer( address(0), msg.sender, totalSupply );
 }
 function() public payable { revert(); }
 event Approval( address indexed owner,
 address indexed spender,
 uint value );
 event Transfer( address indexed from,
 address indexed to,
 uint256 value );
 function balanceOf( address owner ) public constant returns (uint) {
 return balances_[owner];
 }
 function approve( address spender, uint256 value ) public returns (bool success) {
 allowances_[msg.sender][spender] = value;
 emit Approval( msg.sender, spender, value );
 return true;
 }
 function safeApprove( address _spender,uint256 _currentValue,uint256 _value ) public returns (bool success) {
 if (allowances_[msg.sender][_spender] == _currentValue)
 return approve(_spender, _value);
 return false;
 }
 function allowance( address owner, address spender ) public constant returns (uint256 remaining) {
 return allowances_[owner][spender];
 }
 function transfer(address to, uint256 value) public returns (bool success) {
 bytes memory empty;
 _transfer( msg.sender, to, value, empty );
 return true;
 }
 function transferFrom( address from, address to, uint256 value ) public returns (bool success) {
 require( value <= allowances_[from][msg.sender] );
 allowances_[from][msg.sender] -= value;
 bytes memory empty;
 _transfer( from, to, value, empty );
 return true;
 }
 function transfer( address to, uint value, bytes data, string custom_fallback ) public returns (bool success) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 _transfer( msg.sender, to, value, data );
 if ( isContract(to) ) {
 ContractReceiver rx = ContractReceiver( to );
 require(address(rx).call.value(0)(bytes4(keccak256(custom_fallback)), msg.sender, value, data) );
 }
 return true;
 }
 function transfer( address to, uint value, bytes data ) public returns (bool success) {
 if (isContract(to)) {
 return transferToContract( to, value, data );
 }
 _transfer(msg.sender, to, value, data );
 return true;
 }
 function transferToContract( address to, uint value, bytes data ) private returns (bool success) {
 _transfer(msg.sender, to, value, data );
 ContractReceiver rx = ContractReceiver(to);
 rx.tokenFallback( msg.sender, value, data );
 return true;
 }
 function isContract( address _addr ) private constant returns (bool) {
 uint length;
 assembly { length := extcodesize(_addr) }
 return (length > 0);
 }
 function _transfer( address from, address to, uint value, bytes data ) internal {
 require( to != 0x0 );
 require( balances_[from] >= value );
 require( balances_[to] + value > balances_[to] );
 balances_[from] -= value;
 balances_[to] += value;
 bytes memory empty;
 empty = data;
 emit Transfer( from, to, value );
 }
 event Burn( address indexed from, uint256 value );
 function burn( uint256 value ) public returns (bool success) {
 require( balances_[msg.sender] >= value );
 balances_[msg.sender] -= value;
 totalSupply -= value;
 emit Burn( msg.sender, value );
 return true;
 }
 function burnFrom( address from, uint256 value ) public returns (bool success) {
 require( balances_[from] >= value );
 require( value <= allowances_[from][msg.sender] );
 balances_[from] -= value;
 allowances_[from][msg.sender] -= value;
 totalSupply -= value;
 emit Burn( from, value );
 return true;
 }
}