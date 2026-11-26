pragma solidity ^0.4.24;
interface ERC223I {
 function balanceOf(address _owner) external view returns (uint balance);
 function name() external view returns (string _name);
 function symbol() external view returns (string _symbol);
 function decimals() external view returns (uint8 _decimals);
 function totalSupply() external view returns (uint256 supply);
 function transfer(address to, uint value) external returns (bool ok);
 function transfer(address to, uint value, bytes data) external returns (bool ok);
 function transfer(address to, uint value, bytes data, string custom_fallback) external returns (bool ok);
 function releaseTokenTransfer() external;
 event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}
contract SafeMath {
 function safeSub(uint256 x, uint256 y) internal pure returns (uint256) {
 assert(y <= x);
 uint256 z = x - y;
 return z;
 }
 function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
 uint256 z = x + y;
 assert(z >= x);
 return z;
 }
 function safeDiv(uint256 x, uint256 y) internal pure returns (uint256) {
 uint256 z = x / y;
 return z;
 }
 function safeMul(uint256 x, uint256 y) internal pure returns (uint256) {
 if (x == 0) {
 return 0;
 }
 uint256 z = x * y;
 assert(z / x == y);
 return z;
 }
 function safePerc(uint256 x, uint256 y) internal pure returns (uint256) {
 if (x == 0) {
 return 0;
 }
 uint256 z = x * y;
 assert(z / x == y);
 z = z / 10000;
 return z;
 }
 function min(uint256 x, uint256 y) internal pure returns (uint256) {
 uint256 z = x <= y ? x : y;
 return z;
 }
 function max(uint256 x, uint256 y) internal pure returns (uint256) {
 uint256 z = x >= y ? x : y;
 return z;
 }
}
contract Ownable {
 address public owner;
 address public newOwner;
 event OwnershipTransferred(address indexed _from, address indexed _to);
 constructor() public {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 assert(msg.sender == owner);
 _;
 }
 function transferOwnership(address _newOwner) public onlyOwner {
 assert(_newOwner != address(0));
 newOwner = _newOwner;
 }
 function acceptOwnership() public {
 if (msg.sender == newOwner) {
 emit OwnershipTransferred(owner, newOwner);
 owner = newOwner;
 }
 }
}
contract Agent is Ownable {
 address public defAgent;
 mapping(address => bool) public Agents;
 event UpdatedAgent(address _agent, bool _status);
 constructor() public {
 defAgent = msg.sender;
 Agents[msg.sender] = true;
 }
 modifier onlyAgent() {
 assert(Agents[msg.sender]);
 _;
 }
 function updateAgent(address _agent, bool _status) public onlyOwner {
 assert(_agent != address(0));
 Agents[_agent] = _status;
 emit UpdatedAgent(_agent, _status);
 }
}
contract ERC223 is ERC223I, Agent, SafeMath {
 mapping(address => uint) balances;
 string public name;
 string public symbol;
 uint8 public decimals;
 uint256 public totalSupply;
 address public crowdsale = address(0);
 bool public released = false;
 modifier canTransfer() {
 assert(released || msg.sender == crowdsale);
 _;
 }
 modifier onlyCrowdsaleContract() {
 assert(msg.sender == crowdsale);
 _;
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
 function isContract(address _addr) private view returns (bool is_contract) {
 uint length;
 assembly {
 length := extcodesize(_addr)
 }
 return (length>0);
 }
 function transfer(address _to, uint _value, bytes _data) external canTransfer() returns (bool success) {
 if(isContract(_to)) {
 return transferToContract(_to, _value, _data);
 } else {
 return transferToAddress(_to, _value, _data);
 }
 }
 function transfer(address _to, uint _value) external canTransfer() returns (bool success) {
 bytes memory empty;
 if(isContract(_to)) {
 return transferToContract(_to, _value, empty);
 } else {
 return transferToAddress(_to, _value, empty);
 }
 }
 function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = safeSub(balances[msg.sender], _value);
 balances[_to] = safeAdd(balances[_to], _value);
 emit Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = safeSub(balances[msg.sender], _value);
 balances[_to] = safeAdd(balances[_to], _value);
 assert(_to.call.value(0)(abi.encodeWithSignature("tokenFallback(address,uint256,bytes)", msg.sender, _value, _data)));
 emit Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 function transfer(address _to, uint _value, bytes _data, string _custom_fallback) external canTransfer() returns (bool success) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if(isContract(_to)) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
 balances[_to] = safeAdd(balanceOf(_to), _value);
 assert(_to.call.value(0)(abi.encodeWithSignature(_custom_fallback), msg.sender, _value, _data));
 emit Transfer(msg.sender, _to, _value, _data);
 return true;
 } else {
 return transferToAddress(_to, _value, _data);
 }
 }
 function setCrowdsaleContract(address _contract) external onlyOwner {
 crowdsale = _contract;
 }
 function releaseTokenTransfer() external onlyCrowdsaleContract {
 released = true;
 }
}
contract SABIToken is ERC223 {
 uint public initialSupply = 1400 * 10**6;
 event UpdatedTokenInformation(string _name, string _symbol);
 constructor(string _name, string _symbol, address _crowdsale, address _team, address _bounty, address _adviser, address _developer) public {
 name = _name;
 symbol = _symbol;
 decimals = 8;
 crowdsale = _crowdsale;
 bytes memory empty;
 totalSupply = initialSupply*uint(10)**decimals;
 balances[_crowdsale] = totalSupply;
 emit Transfer(0x0, _crowdsale, balances[_crowdsale], empty);
 uint value = safePerc(totalSupply, 1500);
 balances[_crowdsale] = safeSub(balances[_crowdsale], value);
 balances[_team] = value;
 emit Transfer(_crowdsale, _team, balances[_team], empty);
 value = safePerc(totalSupply, 500);
 balances[_crowdsale] = safeSub(balances[_crowdsale], value);
 balances[_bounty] = value;
 emit Transfer(_crowdsale, _bounty, balances[_bounty], empty);
 value = safePerc(totalSupply, 150);
 balances[_crowdsale] = safeSub(balances[_crowdsale], value);
 balances[_adviser] = value;
 emit Transfer(_crowdsale, _adviser, balances[_adviser], empty);
 value = safePerc(totalSupply, 100);
 balances[_crowdsale] = safeSub(balances[_crowdsale], value);
 balances[_developer] = value;
 emit Transfer(_crowdsale, _developer, balances[_developer], empty);
 }
 function mint(address _receiver, uint _amount) public onlyOwner {
 balances[_receiver] = safeAdd(balances[_receiver], _amount);
 totalSupply = safeAdd(totalSupply, _amount);
 bytes memory empty;
 emit Transfer(0x0, _receiver, _amount, empty);
 }
 function updateTokenInformation(string _name, string _symbol) public onlyOwner {
 name = _name;
 symbol = _symbol;
 emit UpdatedTokenInformation(_name, _symbol);
 }
}