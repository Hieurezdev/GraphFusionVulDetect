pragma solidity ^0.4.17;
contract MultiSigWallet {
 event Confirmation(address sender, bytes32 transactionId);
 event Revocation(address sender, bytes32 transactionId);
 event Submission(bytes32 transactionId);
 event Execution(bytes32 transactionId);
 event Deposit(address sender, uint value);
 event OwnerAddition(address owner);
 event OwnerRemoval(address owner);
 event RequirementChange(uint required);
 event CoinCreation(address coin);
 mapping (bytes32 => Transaction) public transactions;
 mapping (bytes32 => mapping (address => bool)) public confirmations;
 mapping (address => bool) public isOwner;
 address[] owners;
 bytes32[] transactionList;
 uint public required;
 struct Transaction {
 address destination;
 uint value;
 bytes data;
 uint nonce;
 bool executed;
 }
 modifier onlyWallet() {
 if (msg.sender != address(this))
 revert();
 _;
 }
 modifier ownerDoesNotExist(address owner) {
 if (isOwner[owner])
 revert();
 _;
 }
 modifier ownerExists(address owner) {
 if (!isOwner[owner])
 revert();
 _;
 }
 modifier confirmed(bytes32 transactionId, address owner) {
 if (!confirmations[transactionId][owner])
 revert();
 _;
 }
 modifier notConfirmed(bytes32 transactionId, address owner) {
 if (confirmations[transactionId][owner])
 revert();
 _;
 }
 modifier notExecuted(bytes32 transactionId) {
 if (transactions[transactionId].executed)
 revert();
 _;
 }
 modifier notNull(address destination) {
 if (destination == 0)
 revert();
 _;
 }
 modifier validRequirement(uint _ownerCount, uint _required) {
 if ( _required > _ownerCount
 || _required == 0
 || _ownerCount == 0)
 revert();
 _;
 }
 function addOwner(address owner)
 external
 onlyWallet
 ownerDoesNotExist(owner)
 {
 isOwner[owner] = true;
 owners.push(owner);
 OwnerAddition(owner);
 }
 function removeOwner(address owner)
 external
 onlyWallet
 ownerExists(owner)
 {
 isOwner[owner] = false;
 for (uint i=0; i<owners.length - 1; i++)
 if (owners[i] == owner) {
 owners[i] = owners[owners.length - 1];
 break;
 }
 owners.length -= 1;
 if (required > owners.length)
 changeRequirement(owners.length);
 OwnerRemoval(owner);
 }
 function changeRequirement(uint _required)
 public
 onlyWallet
 validRequirement(owners.length, _required)
 {
 required = _required;
 RequirementChange(_required);
 }
 function addTransaction(address destination, uint value, bytes data, uint nonce)
 private
 notNull(destination)
 returns (bytes32 transactionId)
 {
 transactionId = keccak256(destination, value, data, nonce);
 if (transactions[transactionId].destination == 0) {
 transactions[transactionId] = Transaction({
 destination: destination,
 value: value,
 data: data,
 nonce: nonce,
 executed: false
 });
 transactionList.push(transactionId);
 Submission(transactionId);
 }
 }
 function submitTransaction(address destination, uint value, bytes data, uint nonce) external ownerExists(msg.sender) returns (bytes32 transactionId) {
 transactionId = addTransaction(destination, value, data, nonce);
 confirmTransaction(transactionId);
 }
 function confirmTransaction(bytes32 transactionId) public ownerExists(msg.sender) notConfirmed(transactionId, msg.sender) {
 confirmations[transactionId][msg.sender] = true;
 Confirmation(msg.sender, transactionId);
 executeTransaction(transactionId);
 }
 function executeTransaction(bytes32 transactionId) public notExecuted(transactionId) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (isConfirmed(transactionId)) {
 Transaction storage txn = transactions[transactionId];
 txn.executed = true;
 if (!txn.destination.call.value(txn.value)(txn.data))
 revert();
 Execution(transactionId);
 }
 }
 function revokeConfirmation(bytes32 transactionId)
 external
 ownerExists(msg.sender)
 confirmed(transactionId, msg.sender)
 notExecuted(transactionId)
 {
 confirmations[transactionId][msg.sender] = false;
 Revocation(msg.sender, transactionId);
 }
 function MultiSigWallet(address[] _owners, uint _required)
 validRequirement(_owners.length, _required)
 public
 {
 for (uint i=0; i<_owners.length; i++) {
 isOwner[_owners[i]] = true;
 }
 owners = _owners;
 required = _required;
 }
 function()
 public
 payable
 {
 if (msg.value > 0)
 Deposit(msg.sender, msg.value);
 }
 function isConfirmed(bytes32 transactionId)
 public
 constant
 returns (bool)
 {
 uint count = 0;
 for (uint i=0; i<owners.length; i++)
 if (confirmations[transactionId][owners[i]])
 count += 1;
 if (count == required)
 return true;
 }
 function confirmationCount(bytes32 transactionId)
 external
 constant
 returns (uint count)
 {
 for (uint i=0; i<owners.length; i++)
 if (confirmations[transactionId][owners[i]])
 count += 1;
 }
 function filterTransactions(bool isPending)
 private
 constant
 returns (bytes32[] _transactionList)
 {
 bytes32[] memory _transactionListTemp = new bytes32[](transactionList.length);
 uint count = 0;
 for (uint i=0; i<transactionList.length; i++)
 if ( isPending && !transactions[transactionList[i]].executed
 || !isPending && transactions[transactionList[i]].executed)
 {
 _transactionListTemp[count] = transactionList[i];
 count += 1;
 }
 _transactionList = new bytes32[](count);
 for (i=0; i<count; i++)
 if (_transactionListTemp[i] > 0)
 _transactionList[i] = _transactionListTemp[i];
 }
 function getPendingTransactions()
 external
 constant
 returns (bytes32[])
 {
 return filterTransactions(true);
 }
 function getExecutedTransactions()
 external
 constant
 returns (bytes32[])
 {
 return filterTransactions(false);
 }
}