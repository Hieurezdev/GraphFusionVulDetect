pragma solidity ^0.4.15;
contract ERC20 {
 uint256 public totalSupply;
 function balanceOf(address who) constant returns (uint256 balance);
 function allowance(address owner, address spender) constant returns (uint256 remaining);
 function transfer(address to, uint256 value) returns (bool ok);
 function transferFrom(address from, address to, uint256 value) returns (bool ok);
 function approve(address spender, uint256 value) returns (bool ok);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract MultiSigTokenWallet {
 address[] public owners;
 address[] public tokens;
 mapping (uint => Transaction) public transactions;
 mapping (uint => mapping (address => bool)) public confirmations;
 uint public transactionCount;
 mapping (address => uint) public tokenBalances;
 mapping (address => bool) public isOwner;
 mapping (address => address[]) public userList;
 uint public required;
 uint public nonce;
 struct Transaction {
 address destination;
 uint value;
 bytes data;
 bool executed;
 }
 uint constant public MAX_OWNER_COUNT = 50;
 event Confirmation(address indexed _sender, uint indexed _transactionId);
 event Revocation(address indexed _sender, uint indexed _transactionId);
 event Submission(uint indexed _transactionId);
 event Execution(uint indexed _transactionId);
 event ExecutionFailure(uint indexed _transactionId);
 event Deposit(address indexed _sender, uint _value);
 event TokenDeposit(address _token, address indexed _sender, uint _value);
 event OwnerAddition(address indexed _owner);
 event OwnerRemoval(address indexed _owner);
 event RequirementChange(uint _required);
 modifier onlyWallet() {
 require (msg.sender == address(this));
 _;
 }
 modifier ownerDoesNotExist(address owner) {
 require (!isOwner[owner]);
 _;
 }
 modifier ownerExists(address owner) {
 require (isOwner[owner]);
 _;
 }
 modifier transactionExists(uint transactionId) {
 require (transactions[transactionId].destination != 0);
 _;
 }
 modifier confirmed(uint transactionId, address owner) {
 require (confirmations[transactionId][owner]);
 _;
 }
 modifier notConfirmed(uint transactionId, address owner) {
 require(!confirmations[transactionId][owner]);
 _;
 }
 modifier notExecuted(uint transactionId) {
 require (!transactions[transactionId].executed);
 _;
 }
 modifier notNull(address _address) {
 require (_address != 0);
 _;
 }
 modifier validRequirement(uint ownerCount, uint _required) {
 require (ownerCount <= MAX_OWNER_COUNT && _required <= ownerCount && _required != 0 && ownerCount != 0);
 _;
 }
 function()
 payable
 {
 if (msg.value > 0)
 Deposit(msg.sender, msg.value);
 }
 function constructor(address[] _owners, uint _required)
 public
 validRequirement(_owners.length, _required)
 {
 require(owners.length == 0 && required == 0);
 for (uint i = 0; i < _owners.length; i++) {
 require(!isOwner[_owners[i]] && _owners[i] != 0);
 isOwner[_owners[i]] = true;
 }
 owners = _owners;
 required = _required;
 }
 function depositToken(address _token, bytes _data)
 public
 {
 address sender = msg.sender;
 uint amount = ERC20(_token).allowance(sender, this);
 deposit(sender, amount, _token, _data);
 }
 function deposit(address _from, uint256 _amount, address _token, bytes _data)
 public
 {
 if (_from == address(this))
 return;
 uint _nonce = nonce;
 bool result = ERC20(_token).transferFrom(_from, this, _amount);
 assert(result);
 if (nonce == _nonce) {
 _deposited(_from, _amount, _token, _data);
 }
 }
 function watch(address _tokenAddr)
 ownerExists(msg.sender)
 {
 uint oldBal = tokenBalances[_tokenAddr];
 uint newBal = ERC20(_tokenAddr).balanceOf(this);
 if (newBal > oldBal) {
 _deposited(0x0, newBal-oldBal, _tokenAddr, new bytes(0));
 }
 }
 function setMyTokenList(address[] _tokenList)
 public
 {
 userList[msg.sender] = _tokenList;
 }
 function setTokenList(address[] _tokenList)
 onlyWallet
 {
 tokens = _tokenList;
 }
 function tokenFallback(address _from, uint _amount, bytes _data)
 public
 {
 _deposited(_from, _amount, msg.sender, _data);
 }
 function receiveApproval(address _from, uint256 _amount, address _token, bytes _data) {
 deposit(_from, _amount, _token, _data);
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
 OwnerAddition(owner);
 }
 function removeOwner(address owner)
 public
 onlyWallet
 ownerExists(owner)
 {
 isOwner[owner] = false;
 uint _len = owners.length - 1;
 for (uint i = 0; i < _len; i++) {
 if (owners[i] == owner) {
 owners[i] = owners[owners.length - 1];
 break;
 }
 }
 owners.length -= 1;
 if (required > owners.length)
 changeRequirement(owners.length);
 OwnerRemoval(owner);
 }
 function replaceOwner(address owner, address newOwner)
 public
 onlyWallet
 ownerExists(owner)
 ownerDoesNotExist(newOwner)
 {
 for (uint i = 0; i < owners.length; i++) {
 if (owners[i] == owner) {
 owners[i] = newOwner;
 break;
 }
 }
 isOwner[owner] = false;
 isOwner[newOwner] = true;
 OwnerRemoval(owner);
 OwnerAddition(newOwner);
 }
 function releaseWallet(address _dest)
 public
 notNull(_dest)
 ownerDoesNotExist(_dest)
 onlyWallet
 {
 address[] memory _owners = owners;
 uint numOwners = _owners.length;
 addOwner(_dest);
 for (uint i = 0; i < numOwners; i++) {
 removeOwner(_owners[i]);
 }
 }
 function changeRequirement(uint _required)
 public
 onlyWallet
 validRequirement(owners.length, _required)
 {
 required = _required;
 RequirementChange(_required);
 }
 function submitTransaction(address destination, uint value, bytes data)
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
 Confirmation(msg.sender, transactionId);
 executeTransaction(transactionId);
 }
 function revokeConfirmation(uint transactionId)
 public
 ownerExists(msg.sender)
 confirmed(transactionId, msg.sender)
 notExecuted(transactionId)
 {
 confirmations[transactionId][msg.sender] = false;
 Revocation(msg.sender, transactionId);
 }
 function executeTransaction(uint transactionId)
 public
 notExecuted(transactionId)
 {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (isConfirmed(transactionId)) {
 Transaction storage txx = transactions[transactionId];
 txx.executed = true;
 if (txx.destination.call.value(txx.value)(txx.data)) {
 Execution(transactionId);
 } else {
 ExecutionFailure(transactionId);
 txx.executed = false;
 }
 }
 }
 function withdrawEverything(address _dest)
 public
 notNull(_dest)
 onlyWallet
 {
 withdrawAllTokens(_dest);
 _dest.transfer(this.balance);
 }
 function withdrawAllTokens(address _dest)
 public
 notNull(_dest)
 onlyWallet
 {
 address[] memory _tokenList;
 if (userList[_dest].length > 0) {
 _tokenList = userList[_dest];
 } else {
 _tokenList = tokens;
 }
 uint len = _tokenList.length;
 for (uint i = 0;i < len; i++) {
 address _tokenAddr = _tokenList[i];
 uint _amount = tokenBalances[_tokenAddr];
 if (_amount > 0) {
 delete tokenBalances[_tokenAddr];
 ERC20(_tokenAddr).transfer(_dest, _amount);
 }
 }
 }
 function withdrawToken(address _tokenAddr, address _dest, uint _amount)
 public
 notNull(_dest)
 onlyWallet
 {
 require(_amount > 0);
 uint _balance = tokenBalances[_tokenAddr];
 require(_amount <= _balance);
 tokenBalances[_tokenAddr] = _balance - _amount;
 bool result = ERC20(_tokenAddr).transfer(_dest, _amount);
 assert(result);
 }
 function isConfirmed(uint transactionId)
 public
 constant
 returns (bool)
 {
 uint count = 0;
 for (uint i = 0; i < owners.length; i++) {
 if (confirmations[transactionId][owners[i]])
 count += 1;
 if (count == required)
 return true;
 }
 }
 function addTransaction(address destination, uint value, bytes data)
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
 Submission(transactionId);
 }
 function _deposited(address _from, uint _amount, address _tokenAddr, bytes)
 internal
 {
 TokenDeposit(_tokenAddr,_from,_amount);
 nonce++;
 if (tokenBalances[_tokenAddr] == 0) {
 tokens.push(_tokenAddr);
 tokenBalances[_tokenAddr] = ERC20(_tokenAddr).balanceOf(this);
 } else {
 tokenBalances[_tokenAddr] += _amount;
 }
 }
 function getConfirmationCount(uint transactionId)
 public
 constant
 returns (uint count)
 {
 for (uint i = 0; i < owners.length; i++) {
 if (confirmations[transactionId][owners[i]])
 count += 1;
 }
 }
 function getTransactionCount(bool pending, bool executed)
 public
 constant
 returns (uint count)
 {
 for (uint i = 0; i < transactionCount; i++) {
 if (pending && !transactions[i].executed || executed && transactions[i].executed)
 count += 1;
 }
 }
 function getOwners()
 public
 constant
 returns (address[])
 {
 return owners;
 }
 function getTokenList()
 public
 constant
 returns (address[])
 {
 return tokens;
 }
 function getConfirmations(uint transactionId)
 public
 constant
 returns (address[] _confirmations)
 {
 address[] memory confirmationsTemp = new address[](owners.length);
 uint count = 0;
 uint i;
 for (i = 0; i < owners.length; i++) {
 if (confirmations[transactionId][owners[i]]) {
 confirmationsTemp[count] = owners[i];
 count += 1;
 }
 }
 _confirmations = new address[](count);
 for (i = 0; i < count; i++) {
 _confirmations[i] = confirmationsTemp[i];
 }
 }
 function getTransactionIds(uint from, uint to, bool pending, bool executed)
 public
 constant
 returns (uint[] _transactionIds)
 {
 uint[] memory transactionIdsTemp = new uint[](transactionCount);
 uint count = 0;
 uint i;
 for (i = 0; i < transactionCount; i++) {
 if (pending && !transactions[i].executed || executed && transactions[i].executed) {
 transactionIdsTemp[count] = i;
 count += 1;
 }
 }
 _transactionIds = new uint[](to - from);
 for (i = from; i < to; i++) {
 _transactionIds[i - from] = transactionIdsTemp[i];
 }
 }
}