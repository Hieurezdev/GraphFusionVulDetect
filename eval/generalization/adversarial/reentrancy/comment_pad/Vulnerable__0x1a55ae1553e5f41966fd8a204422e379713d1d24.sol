pragma solidity ^0.4.15;
contract MultiOwner {
 event OwnerAdded(address newOwner);
 event OwnerRemoved(address oldOwner);
	event RequirementChanged(uint256 newRequirement);
 uint256 public ownerRequired;
 mapping (address => bool) public isOwner;
	address[] owners;
	function MultiOwner(address[] _owners, uint256 _required) public {
 ownerRequired = _required;
 isOwner[msg.sender] = true;
 owners.push(msg.sender);
 for (uint256 i = 0; i < _owners.length; ++i){
 require(!isOwner[_owners[i]]);
 isOwner[_owners[i]] = true;
 owners.push(_owners[i]);
 }
 }
	modifier onlyOwner {
 require(isOwner[msg.sender]);
 _;
 }
	modifier ownerDoesNotExist(address owner) {
 require(!isOwner[owner]);
 _;
 }
 modifier ownerExists(address owner) {
 require(isOwner[owner]);
 _;
 }
 function addOwner(address owner) onlyOwner ownerDoesNotExist(owner) external{
 isOwner[owner] = true;
 owners.push(owner);
 OwnerAdded(owner);
 }
	function numberOwners() public constant returns (uint256 NumberOwners){
 NumberOwners = owners.length;
	}
 function removeOwner(address owner) onlyOwner ownerExists(owner) external{
 require(owners.length > 2);
 isOwner[owner] = false;
 for (uint256 i=0; i<owners.length - 1; i++){
 if (owners[i] == owner) {
 owners[i] = owners[owners.length - 1];
 break;
 }
 }
 owners.length -= 1;
 OwnerRemoved(owner);
 }
	function changeRequirement(uint _newRequired) onlyOwner external {
 require(_newRequired >= owners.length);
 ownerRequired = _newRequired;
 RequirementChanged(_newRequired);
 }
}
contract VVToken is MultiOwner{
	event SubmitTransaction(bytes32 transactionHash);
	event Confirmation(address sender, bytes32 transactionHash);
	event Execution(bytes32 transactionHash);
	event FrozenFunds(address target, bool frozen);
	event Transfer(address indexed from, address indexed to, uint256 value);
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	uint256 public EthPerToken = 300;
	mapping(address => uint256) public balanceOf;
	mapping(address => bool) public frozenAccount;
	mapping (bytes32 => mapping (address => bool)) public Confirmations;
	mapping (bytes32 => Transaction) public Transactions;
	struct Transaction {
 address destination;
 uint value;
 bytes data;
 bool executed;
 }
	modifier notNull(address destination) {
 require (destination != 0x0);
 _;
 }
	modifier confirmed(bytes32 transactionHash) {
 require (Confirmations[transactionHash][msg.sender]);
 _;
 }
 modifier notConfirmed(bytes32 transactionHash) {
 require (!Confirmations[transactionHash][msg.sender]);
 _;
 }
	modifier notExecuted(bytes32 TransHash) {
 require (!Transactions[TransHash].executed);
 _;
 }
	function VVToken(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol, address[] _owners, uint256 _required) MultiOwner(_owners, _required) public {
 decimals = decimalUnits;
 totalSupply = initialSupply * 10 ** uint256(decimals);
 balanceOf[msg.sender] = totalSupply;
 name = tokenName;
 symbol = tokenSymbol;
 }
 function _transfer(address _from, address _to, uint256 _value) internal {
 require (_to != 0x0);
 require (balanceOf[_from] > _value);
 require (balanceOf[_to] + _value > balanceOf[_to]);
 require(!frozenAccount[_from]);
 uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
 balanceOf[_from] -= _value;
 balanceOf[_to] += _value;
 Transfer(_from, _to, _value);
 assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
 }
	function transfer(address _to, uint256 _value) public {
 _transfer(msg.sender, _to, _value);
	}
	function setPrices(uint256 newValue) onlyOwner public {
 EthPerToken = newValue;
 }
 function freezeAccount(address target, bool freeze) onlyOwner public {
 frozenAccount[target] = freeze;
 FrozenFunds(target, freeze);
 }
	function() payable {
 revert();
 }
	function remainBalanced() public constant returns (uint256){
 return balanceOf[this];
 }
	function execute(address _to, uint _value, bytes _data) notNull(_to) onlyOwner external returns (bytes32 _r) {
 _r = addTransaction(_to, _value, _data);
 confirmTransaction(_r);
 }
	function addTransaction(address destination, uint value, bytes data) private notNull(destination) returns (bytes32 TransHash){
 TransHash = sha3(destination, value, data);
 if (Transactions[TransHash].destination == 0) {
 Transactions[TransHash] = Transaction({
 destination: destination,
 value: value,
 data: data,
 executed: false
 });
 SubmitTransaction(TransHash);
 }
 }
	function addConfirmation(bytes32 TransHash) private onlyOwner notConfirmed(TransHash){
 Confirmations[TransHash][msg.sender] = true;
 Confirmation(msg.sender, TransHash);
 }
	function isConfirmed(bytes32 TransHash) public constant returns (bool){
 uint count = 0;
 for (uint i=0; i<owners.length; i++)
 if (Confirmations[TransHash][owners[i]])
 count += 1;
 if (count == ownerRequired)
 return true;
 }
	function confirmationCount(bytes32 TransHash) external constant returns (uint count){
 for (uint i=0; i<owners.length; i++)
 if (Confirmations[TransHash][owners[i]])
 count += 1;
 }
 function confirmTransaction(bytes32 TransHash) public onlyOwner(){
 addConfirmation(TransHash);
 executeTransaction(TransHash);
 }
 function executeTransaction(bytes32 TransHash) public notExecuted(TransHash){
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (isConfirmed(TransHash)) {
 Transactions[TransHash].executed = true;
 require(Transactions[TransHash].destination.call.value(Transactions[TransHash].value)(Transactions[TransHash].data));
 Execution(TransHash);
 }
 }
	function kill() onlyOwner() private {
 selfdestruct(msg.sender);
 }
}