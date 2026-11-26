pragma solidity ^0.4.11;
contract Owned {
 address public contractOwner;
 address public pendingContractOwner;
 function Owned() {
 contractOwner = msg.sender;
 }
 modifier onlyContractOwner() {
 if (contractOwner == msg.sender) {
 _;
 }
 }
 function destroy() onlyContractOwner {
 suicide(msg.sender);
 }
 function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
 if (_to == 0x0) {
 return false;
 }
 pendingContractOwner = _to;
 return true;
 }
 function claimContractOwnership() returns(bool) {
 if (pendingContractOwner != msg.sender) {
 return false;
 }
 contractOwner = pendingContractOwner;
 delete pendingContractOwner;
 return true;
 }
}
contract ERC20Interface {
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed from, address indexed spender, uint256 value);
 string public symbol;
 function totalSupply() constant returns (uint256 supply);
 function balanceOf(address _owner) constant returns (uint256 balance);
 function transfer(address _to, uint256 _value) returns (bool success);
 function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 function approve(address _spender, uint256 _value) returns (bool success);
 function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}
contract Object is Owned {
 uint constant OK = 1;
 uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;
 function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
 for(uint i=0;i<tokens.length;i++) {
 address token = tokens[i];
 uint balance = ERC20Interface(token).balanceOf(this);
 if(balance != 0)
 ERC20Interface(token).transfer(_to,balance);
 }
 return OK;
 }
 function checkOnlyContractOwner() internal constant returns(uint) {
 if (contractOwner == msg.sender) {
 return OK;
 }
 return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
 }
}
contract MultiEventsHistoryAdapter {
 function _self() constant internal returns (address) {
 return msg.sender;
 }
}
contract DelayedPaymentsEmitter is MultiEventsHistoryAdapter {
 event Error(bytes32 message);
 function emitError(bytes32 _message) {
 Error(_message);
 }
}
contract Lockup6m is Object {
 uint constant TIME_LOCK_SCOPE = 51000;
 uint constant TIME_LOCK_TRANSFER_ERROR = TIME_LOCK_SCOPE + 10;
 uint constant TIME_LOCK_TRANSFERFROM_ERROR = TIME_LOCK_SCOPE + 11;
 uint constant TIME_LOCK_BALANCE_ERROR = TIME_LOCK_SCOPE + 12;
 uint constant TIME_LOCK_TIMESTAMP_ERROR = TIME_LOCK_SCOPE + 13;
 uint constant TIME_LOCK_INVALID_INVOCATION = TIME_LOCK_SCOPE + 17;
 struct accountData {
 uint balance;
 uint releaseTime;
 }
 address public eventsHistory;
 address asset;
 accountData lock;
 function Lockup6m(address _asset) {
 asset = _asset;
 }
 function _error(uint _errorCode, bytes32 _message) internal returns(uint) {
 DelayedPaymentsEmitter(eventsHistory).emitError(_message);
 return _errorCode;
 }
 function setupEventsHistory(address _eventsHistory) returns(uint errorCode) {
 errorCode = checkOnlyContractOwner();
 if (errorCode != OK) {
 return errorCode;
 }
 if (eventsHistory != 0x0 && eventsHistory != _eventsHistory) {
 return TIME_LOCK_INVALID_INVOCATION;
 }
 eventsHistory = _eventsHistory;
 return OK;
 }
 function payIn() onlyContractOwner returns(uint errorCode) {
 uint amount = ERC20Interface(asset).balanceOf(this);
 if(lock.balance != 0) {
 if(lock.balance != amount) {
 lock.balance == amount;
 return OK;
 }
 return TIME_LOCK_INVALID_INVOCATION;
 }
 if (amount == 0) {
 return TIME_LOCK_BALANCE_ERROR;
 }
 lock = accountData(amount, 1523624400);
 return OK;
 }
 function payOut(address _getter) onlyContractOwner returns(uint errorCode) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 uint amount = lock.balance;
 if (now < lock.releaseTime) {
 return TIME_LOCK_TIMESTAMP_ERROR;
 }
 if (amount == 0) {
 return TIME_LOCK_BALANCE_ERROR;
 }
 if(!ERC20Interface(asset).transfer(_getter,amount)) {
 return TIME_LOCK_TRANSFER_ERROR;
 }
 selfdestruct(msg.sender);
 return OK;
 }
 function getLockedFunds() constant returns (uint) {
 return lock.balance;
 }
 function getLockedFundsReleaseTime() constant returns (uint) {
 return lock.releaseTime;
 }
}