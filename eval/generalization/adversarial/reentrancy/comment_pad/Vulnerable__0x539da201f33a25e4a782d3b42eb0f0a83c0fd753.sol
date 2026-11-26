pragma solidity 0.5.2;
contract MultiSigWallet {
	uint constant public MAX_OWNER_COUNT = 50;
	event Confirmation(address indexed sender, uint indexed transactionId);
	event Revocation(address indexed sender, uint indexed transactionId);
	event Submission(uint indexed transactionId);
	event Execution(uint indexed transactionId);
	event ExecutionFailure(uint indexed transactionId);
	event Deposit(address indexed sender, uint value);
	event OwnerAddition(address indexed owner);
	event OwnerRemoval(address indexed owner);
	event RequirementChange(uint required);
	mapping (uint => Transaction) public transactions;
	mapping (uint => mapping (address => bool)) public confirmations;
	mapping (address => bool) public isOwner;
	address[] public owners;
	uint public required;
	uint public transactionCount;
	struct Transaction {
 address destination;
 uint value;
 bytes data;
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
	modifier transactionExists(uint transactionId) {
 if (transactions[transactionId].destination == address(0))
 revert();
 _;
	}
	modifier confirmed(uint transactionId, address owner) {
 if (!confirmations[transactionId][owner])
 revert();
 _;
	}
	modifier notConfirmed(uint transactionId, address owner) {
 if (confirmations[transactionId][owner])
 revert();
 _;
	}
	modifier notExecuted(uint transactionId) {
 if (transactions[transactionId].executed)
 revert();
 _;
	}
	modifier notNull(address _address) {
 if (_address == address(0))
 revert();
 _;
	}
	modifier validRequirement(uint ownerCount, uint _required) {
 if ( ownerCount > MAX_OWNER_COUNT
 || _required > ownerCount
 || _required == 0
 || ownerCount == 0)
 revert();
 _;
	}
	function()
	external
	payable
	{
 if (msg.value > 0)
 emit Deposit(msg.sender, msg.value);
	}
	constructor(address[] memory _owners, uint _required)
	public
	validRequirement(_owners.length, _required)
	{
 for (uint i=0; i<_owners.length; i++) {
 if (isOwner[_owners[i]] || _owners[i] == address(0))
 revert();
 isOwner[_owners[i]] = true;
 }
 owners = _owners;
 required = _required;
	}
	function addOwner(address owner)
	public
	onlyWallet
	ownerDoesNotExist(owner)
	notNull(owner)
	validRequirement(owners.length + 1, required)
	{
 isOwner[owner] = true;
 owners.push(owner);
 emit OwnerAddition(owner);
	}
	function removeOwner(address owner)
	public
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
 emit OwnerRemoval(owner);
	}
	function replaceOwner(address owner, address newOwner)
	public
	onlyWallet
	ownerExists(owner)
	ownerDoesNotExist(newOwner)
	{
 for (uint i=0; i<owners.length; i++)
 if (owners[i] == owner) {
 owners[i] = newOwner;
 break;
 }
 isOwner[owner] = false;
 isOwner[newOwner] = true;
 emit OwnerRemoval(owner);
 emit OwnerAddition(newOwner);
	}
	function changeRequirement(uint _required)
	public
	onlyWallet
	validRequirement(owners.length, _required)
	{
 required = _required;
 emit RequirementChange(_required);
	}
	function submitTransaction(address destination, uint value, bytes memory data)
	public
	returns (uint transactionId)
	{
 transactionId = addTransaction(destination, value, data);
 confirmTransaction(transactionId);
	}
	function confirmTransaction(uint transactionId)
	public
	ownerExists(msg.sender)
	transactionExists(transactionId)
	notConfirmed(transactionId, msg.sender)
	{
 confirmations[transactionId][msg.sender] = true;
 emit Confirmation(msg.sender, transactionId);
 executeTransaction(transactionId);
	}
	function revokeConfirmation(uint transactionId)
	public
	ownerExists(msg.sender)
	confirmed(transactionId, msg.sender)
	notExecuted(transactionId)
	{
 confirmations[transactionId][msg.sender] = false;
 emit Revocation(msg.sender, transactionId);
	}
	function executeTransaction(uint transactionId)
	public
	notExecuted(transactionId)
	{
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (isConfirmed(transactionId)) {
 Transaction storage transaction = transactions[transactionId];
 transaction.executed = true;
 bool success;
 bytes memory _returnData;
 (success, _returnData) = transaction.destination.call.value(transaction.value)(transaction.data);
 if (success)
 emit Execution(transactionId);
 else {
 emit ExecutionFailure(transactionId);
 transaction.executed = false;
 }
 }
	}
	function isConfirmed(uint transactionId)
	public
	view
	returns (bool)
	{
 uint count = 0;
 for (uint i=0; i<owners.length; i++) {
 if (confirmations[transactionId][owners[i]])
 count += 1;
 if (count == required)
 return true;
 }
	}
	function addTransaction(address destination, uint value, bytes memory data)
	internal
	notNull(destination)
	returns (uint transactionId)
	{
 transactionId = transactionCount;
 transactions[transactionId] = Transaction({
 destination: destination,
 value: value,
 data: data,
 executed: false
 });
 transactionCount += 1;
 emit Submission(transactionId);
	}
	function getConfirmationCount(uint transactionId)
	public
	view
	returns (uint count)
	{
 for (uint i=0; i<owners.length; i++)
 if (confirmations[transactionId][owners[i]])
 count += 1;
	}
	function getTransactionCount(bool pending, bool executed)
	public
	view
	returns (uint count)
	{
 for (uint i=0; i<transactionCount; i++)
 if ( pending && !transactions[i].executed
 || executed && transactions[i].executed)
 count += 1;
	}
	function getOwners()
	public
	view
	returns (address[] memory)
	{
 return owners;
	}
	function getConfirmations(uint transactionId)
	public
	view
	returns (address[] memory _confirmations)
	{
 address[] memory confirmationsTemp = new address[](owners.length);
 uint count = 0;
 uint i;
 for (i=0; i<owners.length; i++)
 if (confirmations[transactionId][owners[i]]) {
 confirmationsTemp[count] = owners[i];
 count += 1;
 }
 _confirmations = new address[](count);
 for (i=0; i<count; i++)
 _confirmations[i] = confirmationsTemp[i];
	}
	function getTransactionIds(uint from, uint to, bool pending, bool executed)
	public
	view
	returns (uint[] memory _transactionIds)
	{
 uint[] memory transactionIdsTemp = new uint[](transactionCount);
 uint count = 0;
 uint i;
 for (i=0; i<transactionCount; i++)
 if ( pending && !transactions[i].executed
 || executed && transactions[i].executed)
 {
 transactionIdsTemp[count] = i;
 count += 1;
 }
 _transactionIds = new uint[](to - from);
 for (i=from; i<to; i++)
 _transactionIds[i - from] = transactionIdsTemp[i];
	}
}