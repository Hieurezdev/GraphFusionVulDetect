pragma solidity ^0.4.20;
contract ERC20 {
 function totalSupply() public constant returns (uint256 supply);
 function balanceOf(address _owner) public constant returns (uint256 balance);
 function transfer(address _to, uint256 _value) public returns (bool success);
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
 function approve(address _spender, uint256 _value) public returns (bool success);
 function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Owned {
 address public owner;
 address public newOwnerCandidate;
 event OwnershipRequested(address indexed by, address indexed to);
 event OwnershipTransferred(address indexed from, address indexed to);
 event OwnershipRemoved();
 function Owned() public {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require (msg.sender == owner);
 _;
 }
 function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
 newOwnerCandidate = _newOwnerCandidate;
 OwnershipRequested(msg.sender, newOwnerCandidate);
 }
 function acceptOwnership() public {
 require(msg.sender == newOwnerCandidate);
 address oldOwner = owner;
 owner = newOwnerCandidate;
 newOwnerCandidate = 0x0;
 OwnershipTransferred(oldOwner, owner);
 }
 function changeOwnership(address _newOwner) public onlyOwner {
 require(_newOwner != 0x0);
 address oldOwner = owner;
 owner = _newOwner;
 newOwnerCandidate = 0x0;
 OwnershipTransferred(oldOwner, owner);
 }
 function removeOwnership(address _dac) public onlyOwner {
 require(_dac == 0xdac);
 owner = 0x0;
 newOwnerCandidate = 0x0;
 OwnershipRemoved();
 }
}
contract Escapable is Owned {
 address public escapeHatchCaller;
 address public escapeHatchDestination;
 mapping (address=>bool) private escapeBlacklist;
 function Escapable(address _escapeHatchCaller, address _escapeHatchDestination) public {
 escapeHatchCaller = _escapeHatchCaller;
 escapeHatchDestination = _escapeHatchDestination;
 }
 modifier onlyEscapeHatchCallerOrOwner {
 require ((msg.sender == escapeHatchCaller)||(msg.sender == owner));
 _;
 }
 function blacklistEscapeToken(address _token) internal {
 escapeBlacklist[_token] = true;
 EscapeHatchBlackistedToken(_token);
 }
 function isTokenEscapable(address _token) view public returns (bool) {
 return !escapeBlacklist[_token];
 }
 function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {
 require(escapeBlacklist[_token]==false);
 uint256 balance;
 if (_token == 0x0) {
 balance = this.balance;
 escapeHatchDestination.transfer(balance);
 EscapeHatchCalled(_token, balance);
 return;
 }
 ERC20 token = ERC20(_token);
 balance = token.balanceOf(this);
 require(token.transfer(escapeHatchDestination, balance));
 EscapeHatchCalled(_token, balance);
 }
 function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
 escapeHatchCaller = _newEscapeHatchCaller;
 }
 event EscapeHatchBlackistedToken(address token);
 event EscapeHatchCalled(address token, uint amount);
}
contract Multiplexor is Escapable {
 function Multiplexor() Escapable(0, 0) public {}
 function init(address _escapeHatchCaller, address _escapeHatchDestination) public {
 require(escapeHatchCaller == 0);
 require(_escapeHatchCaller != 0);
 require(_escapeHatchDestination != 0);
 escapeHatchCaller = _escapeHatchCaller;
 escapeHatchDestination = _escapeHatchDestination;
 }
 function multiTransferTightlyPacked(bytes32[] _addressAndAmount) payable public returns(bool) {
 for (uint i = 0; i < _addressAndAmount.length; i++) {
 _safeTransfer(address(_addressAndAmount[i] >> 96), uint(uint96(_addressAndAmount[i])));
 }
 return true;
 }
 function multiTransfer(address[] _address, uint[] _amount) payable public returns(bool) {
 for (uint i = 0; i < _address.length; i++) {
 _safeTransfer(_address[i], _amount[i]);
 }
 return true;
 }
 function multiCallTightlyPacked(bytes32[] _addressAndAmount) payable public returns(bool) {
 for (uint i = 0; i < _addressAndAmount.length; i++) {
 _safeCall(address(_addressAndAmount[i] >> 96), uint(uint96(_addressAndAmount[i])));
 }
 return true;
 }
 function multiCall(address[] _address, uint[] _amount) payable public returns(bool) {
 for (uint i = 0; i < _address.length; i++) {
 _safeCall(_address[i], _amount[i]);
 }
 return true;
 }
 function multiERC20TransferTightlyPacked(ERC20 _token, bytes32[] _addressAndAmount) public returns(bool) {
 for (uint i = 0; i < _addressAndAmount.length; i++) {
 _safeERC20Transfer(_token, address(_addressAndAmount[i] >> 96), uint(uint96(_addressAndAmount[i])));
 }
 return true;
 }
 function multiERC20Transfer(ERC20 _token, address[] _address, uint[] _amount) public returns(bool) {
 for (uint i = 0; i < _address.length; i++) {
 _safeERC20Transfer(_token, _address[i], _amount[i]);
 }
 return true;
 }
 function _safeTransfer(address _to, uint _amount) internal {
 require(_to != 0);
 _to.transfer(_amount);
 }
 function _safeCall(address _to, uint _amount) internal {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(_to != 0);
 require(_to.call.value(_amount)());
 }
 function _safeERC20Transfer(ERC20 _token, address _to, uint _amount) internal {
 require(_to != 0);
 require(_token.transferFrom(msg.sender, _to, _amount));
 }
}