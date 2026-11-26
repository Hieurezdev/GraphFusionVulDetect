pragma solidity ^0.4.19;
contract ContractReceiver {
 struct TKN {
 address sender;
 uint value;
 bytes data;
 bytes4 sig;
 }
 function tokenFallback(address _from, uint _value, bytes _data) public pure {
 TKN memory tkn;
 tkn.sender = _from;
 tkn.value = _value;
 tkn.data = _data;
 uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
 tkn.sig = bytes4(u);
 }
}
contract Ownable {
 address public owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 function Ownable() public {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) public onlyOwner {
 require(newOwner != address(0));
 OwnershipTransferred(owner, newOwner);
 owner = newOwner;
 }
}
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 assert(c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract ERC223 {
 uint public totalSupply;
 function name() public view returns (string _name);
 function symbol() public view returns (string _symbol);
 function decimals() public view returns (uint8 _decimals);
 function totalSupply() public view returns (uint256 _supply);
 function balanceOf(address who) public view returns (uint);
 function transfer(address to, uint value) public returns (bool ok);
 function transfer(address to, uint value, bytes data) public returns (bool ok);
 function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
 event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
contract INZEI is ERC223, Ownable {
 using SafeMath for uint256;
 string public name = "INZEI";
 string public symbol = "INZ";
 uint8 public decimals = 8;
 uint256 public initialSupply = 10e9 * 1e8;
 uint256 public totalSupply;
 uint256 public distributeAmount = 0;
 bool public mintingFinished = false;
 mapping (address => uint) balances;
 mapping (address => bool) public frozenAccount;
 mapping (address => uint256) public unlockUnixTime;
 event FrozenFunds(address indexed target, bool frozen);
 event LockedFunds(address indexed target, uint256 locked);
 event Burn(address indexed burner, uint256 value);
 event Mint(address indexed to, uint256 amount);
 event MintFinished();
 function INZEI() public {
 totalSupply = initialSupply;
 balances[msg.sender] = totalSupply;
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
 function balanceOf(address _owner) public view returns (uint balance) {
 return balances[_owner];
 }
 modifier onlyPayloadSize(uint256 size){
 assert(msg.data.length >= size + 4);
 _;
 }
 function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(_value > 0
 && frozenAccount[msg.sender] == false
 && frozenAccount[_to] == false
 && now > unlockUnixTime[msg.sender]
 && now > unlockUnixTime[_to]);
 if(isContract(_to)) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
 balances[_to] = SafeMath.add(balanceOf(_to), _value);
 assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
 Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 else {
 return transferToAddress(_to, _value, _data);
 }
 }
 function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
 require(_value > 0
 && frozenAccount[msg.sender] == false
 && frozenAccount[_to] == false
 && now > unlockUnixTime[msg.sender]
 && now > unlockUnixTime[_to]);
 if(isContract(_to)) {
 return transferToContract(_to, _value, _data);
 }
 else {
 return transferToAddress(_to, _value, _data);
 }
 }
 function transfer(address _to, uint _value) public returns (bool success) {
 require(_value > 0
 && frozenAccount[msg.sender] == false
 && frozenAccount[_to] == false
 && now > unlockUnixTime[msg.sender]
 && now > unlockUnixTime[_to]);
 bytes memory empty;
 if(isContract(_to)) {
 return transferToContract(_to, _value, empty);
 }
 else {
 return transferToAddress(_to, _value, empty);
 }
 }
 function isContract(address _addr) private view returns (bool is_contract) {
 uint length;
 assembly {
 length := extcodesize(_addr)
 }
 return (length>0);
 }
 function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
 balances[_to] = SafeMath.add(balanceOf(_to), _value);
 Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = SafeMath.sub(balanceOf(msg.sender), _value);
 balances[_to] = SafeMath.add(balanceOf(_to), _value);
 ContractReceiver receiver = ContractReceiver(_to);
 receiver.tokenFallback(msg.sender, _value, _data);
 Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 function freezeAccounts(address[] targets, bool isFrozen) onlyOwner public {
 require(targets.length > 0);
 for (uint i = 0; i < targets.length; i++) {
 require(targets[i] != 0x0);
 frozenAccount[targets[i]] = isFrozen;
 FrozenFunds(targets[i], isFrozen);
 }
 }
 function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
 require(targets.length > 0
 && targets.length == unixTimes.length);
 for(uint i = 0; i < targets.length; i++){
 require(unlockUnixTime[targets[i]] < unixTimes[i]);
 unlockUnixTime[targets[i]] = unixTimes[i];
 LockedFunds(targets[i], unixTimes[i]);
 }
 }
 function burn(address _from, uint256 _unitAmount) onlyOwner public {
 require(_unitAmount > 0
 && balanceOf(_from) >= _unitAmount);
 balances[_from] = SafeMath.sub(balances[_from], _unitAmount);
 totalSupply = SafeMath.sub(totalSupply, _unitAmount);
 Burn(_from, _unitAmount);
 }
 modifier canMint() {
 require(!mintingFinished);
 _;
 }
 function mint(address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
 require(_unitAmount > 0);
 totalSupply = SafeMath.add(totalSupply, _unitAmount);
 balances[_to] = SafeMath.add(balances[_to], _unitAmount);
 Mint(_to, _unitAmount);
 bytes memory empty;
 Transfer(address(0), _to, _unitAmount, empty);
 return true;
 }
 function finishMinting() onlyOwner canMint public returns (bool) {
 mintingFinished = true;
 MintFinished();
 return true;
 }
 function distributeTokens(address[] addresses, uint256 amount) public returns (bool) {
 require(amount > 0
 && addresses.length > 0
 && frozenAccount[msg.sender] == false
 && now > unlockUnixTime[msg.sender]);
 amount = SafeMath.mul(amount, 1e8);
 uint256 totalAmount = SafeMath.mul(amount, addresses.length);
 require(balances[msg.sender] >= totalAmount);
 bytes memory empty;
 for (uint i = 0; i < addresses.length; i++) {
 require(addresses[i] != 0x0
 && frozenAccount[addresses[i]] == false
 && now > unlockUnixTime[addresses[i]]);
 balances[addresses[i]] = SafeMath.add(balances[addresses[i]], amount);
 Transfer(msg.sender, addresses[i], amount, empty);
 }
 balances[msg.sender] = SafeMath.sub(balances[msg.sender], totalAmount);
 return true;
 }
 function collectTokens(address[] addresses, uint[] amounts) onlyOwner public returns (bool) {
 require(addresses.length > 0
 && addresses.length == amounts.length);
 uint256 totalAmount = 0;
 bytes memory empty;
 for (uint i = 0; i < addresses.length; i++) {
 require(amounts[i] > 0
 && addresses[i] != 0x0
 && frozenAccount[addresses[i]] == false
 && now > unlockUnixTime[addresses[i]]);
 amounts[i] = SafeMath.mul(amounts[i], 1e8);
 require(balances[addresses[i]] >= amounts[i]);
 balances[addresses[i]] = SafeMath.sub(balances[addresses[i]], amounts[i]);
 totalAmount = SafeMath.add(totalAmount, amounts[i]);
 Transfer(addresses[i], msg.sender, amounts[i], empty);
 }
 balances[msg.sender] = SafeMath.add(balances[msg.sender], totalAmount);
 return true;
 }
 function setDistributeAmount(uint256 _unitAmount) onlyOwner public {
 distributeAmount = _unitAmount;
 }
 function autoDistribute() payable public {
 require(distributeAmount > 0
 && balanceOf(owner) >= distributeAmount
 && frozenAccount[msg.sender] == false
 && now > unlockUnixTime[msg.sender]);
 if (msg.value > 0) owner.transfer(msg.value);
 bytes memory empty;
 balances[owner] = SafeMath.sub(balances[owner], distributeAmount);
 balances[msg.sender] = SafeMath.add(balances[msg.sender], distributeAmount);
 Transfer(owner, msg.sender, distributeAmount, empty);
 }
 function() payable public {
 autoDistribute();
 }
}