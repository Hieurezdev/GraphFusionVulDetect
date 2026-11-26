pragma solidity ^0.4.20;
interface tokenRecipient {
 function receiveApproval( address from, uint256 value, bytes data ) external;
}
interface ContractReceiver {
 function tokenFallback( address from, uint value, bytes data ) external;
}
contract owned {
 address public owner;
 function owned() public {
 owner = msg.sender;
 }
 function changeOwner( address _miner ) public onlyOwner {
 owner = _miner;
 }
 modifier onlyOwner {
 require (msg.sender == owner);
 _;
 }
}
contract MineableToken is owned {
 string public name;
 string public symbol;
 uint8 public decimals;
 uint256 public totalSupply;
 uint256 public supplyCap;
 mapping( address => uint256 ) balances_;
 mapping( address => mapping(address => uint256) ) allowances_;
 event Approval( address indexed owner,
 address indexed spender,
 uint value );
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Burn( address indexed from,
 uint256 value );
 function MineableToken() public {
 decimals = uint8(18);
 supplyCap = 4 * 1e9 * 10**uint256(decimals);
 name = "Jbox";
 symbol = "JBX";
 }
 function mine( uint256 qty ) public onlyOwner {
 require((totalSupply + qty) > totalSupply && (totalSupply + qty) <= supplyCap);
 totalSupply += qty;
 balances_[owner] += qty;
 Transfer( address(0), owner, qty );
 }
 function cap() public constant returns(uint256) {
 return supplyCap;
 }
 function balanceOf( address owner ) public constant returns (uint) {
 return balances_[owner];
 }
 function approve( address spender, uint256 value ) public
 returns (bool success)
 {
 allowances_[msg.sender][spender] = value;
 Approval( msg.sender, spender, value );
 return true;
 }
 function safeApprove( address _spender,
 uint256 _currentValue,
 uint256 _value ) public
 returns (bool success)
 {
 if (allowances_[msg.sender][_spender] == _currentValue)
 return approve(_spender, _value);
 return false;
 }
 function allowance( address owner, address spender ) public constant
 returns (uint256 remaining)
 {
 return allowances_[owner][spender];
 }
 function transfer(address to, uint256 value) public returns (bool success) {
 bytes memory empty;
 _transfer(msg.sender, to, value, empty);
 return true;
 }
 function transferFrom( address from, address to, uint256 value ) public returns (bool success) {
 require( value <= allowances_[from][msg.sender] );
 allowances_[from][msg.sender] -= value;
 bytes memory empty;
 _transfer(from, to, value, empty);
 return true;
 }
 function approveAndCall( address spender,uint256 value, bytes context ) public returns (bool success) {
 if ( approve(spender, value) )
 {
 tokenRecipient recip = tokenRecipient( spender );
 if (isContract(recip))
 recip.receiveApproval( msg.sender, value, context );
 return true;
 }
 return false;
 }
 function burn( uint256 value ) public
 returns (bool success)
 {
 require( balances_[msg.sender] >= value );
 balances_[msg.sender] -= value;
 totalSupply -= value;
 Burn( msg.sender, value );
 return true;
 }
 function burnFrom( address from, uint256 value ) public
 returns (bool success)
 {
 require( balances_[from] >= value );
 require( value <= allowances_[from][msg.sender] );
 balances_[from] -= value;
 allowances_[from][msg.sender] -= value;
 totalSupply -= value;
 Burn( from, value );
 return true;
 }
 function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool success) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 _transfer( msg.sender, to, value, data );
 require(address(to).call.value(0)(bytes4(keccak256(custom_fallback)), msg.sender, value, data));
 return true;
 }
 function transfer( address to, uint value, bytes data ) public returns (bool success) {
 if (isContract(to)) {
 return transferToContract( to, value, data );
 }
 _transfer( msg.sender, to, value, data );
 return true;
 }
 function transferToContract( address to, uint value, bytes data ) private returns (bool success) {
 _transfer( msg.sender, to, value, data );
 ContractReceiver rx = ContractReceiver(to);
 if (isContract(rx)) {
 rx.tokenFallback( msg.sender, value, data );
 return true;
 }
 return false;
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
 bytes memory ignore;
 ignore = data;
 Transfer( from, to, value );
 }
}