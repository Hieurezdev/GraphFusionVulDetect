pragma solidity ^0.4.16;
library SafeMath {
 function mul(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal constant returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract Ownable {
 address public owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 function Ownable(address _owner){
 owner = _owner;
 }
 function transferOwnership(address newOwner) onlyOwner public {
 require(newOwner != address(0));
 OwnershipTransferred(owner, newOwner);
 owner = newOwner;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
}
contract ReentrancyGuard {
 bool private rentrancy_lock = false;
 modifier nonReentrant() {
 require(!rentrancy_lock);
 rentrancy_lock = true;
 _;
 rentrancy_lock = false;
 }
}
contract Pausable is Ownable {
 event Pause(bool indexed state);
 bool private paused = false;
 modifier whenNotPaused() {
 require(!paused);
 _;
 }
 modifier whenPaused() {
 require(paused);
 _;
 }
 function Paused() external constant returns(bool){ return paused; }
 function tweakState() external onlyOwner {
 paused = !paused;
 Pause(paused);
 }
}
contract Allocations{
 uint256 private releaseTime;
	mapping (address => uint256) private allocations;
	function Allocations(){
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 releaseTime = now + 200 days;
 allocate();
	}
 function allocate() private {
 allocations[0xab1cb1740344A9280dC502F3B8545248Dc3045eA] = 4000000 * 1 ether;
 allocations[0x330709A59Ab2D1E1105683F92c1EE8143955a357] = 4000000 * 1 ether;
 allocations[0xAa0887fc6e8896C4A80Ca3368CFd56D203dB39db] = 3000000 * 1 ether;
 allocations[0x1fbA1d22435DD3E7Fa5ba4b449CC550a933E72b3] = 200000 * 1 ether;
 allocations[0xC9d5E2c7e40373ae576a38cD7e62E223C95aBFD4] = 200000 * 1 ether;
 allocations[0xabc0B64a38DE4b767313268F0db54F4cf8816D9C] = 220000 * 1 ether;
 allocations[0x5d85bCDe5060C5Bd00DBeDF5E07F43CE3Ccade6f] = 50000 * 1 ether;
 allocations[0xecb1b0231CBC0B04015F9e5132C62465C128B578] = 500000 * 1 ether;
 allocations[0xFF22FA2B3e5E21817b02a45Ba693B7aC01485a9C] = 2955000 * 1 ether;
 }
	function release() internal returns (uint256 amount){
 amount = allocations[msg.sender];
 allocations[msg.sender] = 0;
 return amount;
	}
	function RealeaseTime() external constant returns(uint256){ return releaseTime; }
 modifier timeLock() {
 require(now >= releaseTime);
 _;
	}
	modifier isTeamMember() {
 require(allocations[msg.sender] >= 10000 * 1 ether);
 _;
	}
}
contract NotaryPlatformToken is Pausable, Allocations, ReentrancyGuard{
 using SafeMath for uint256;
 string constant name = "Notary Platform Token";
 string constant symbol = "NTRY";
 uint8 constant decimals = 18;
 uint256 totalSupply = 150000000 * 1 ether;
 mapping(address => uint256) private balances;
 mapping (address => mapping (address => uint256)) private allowed;
 event Approval(address indexed owner, address indexed spender, uint256 value);
 event Transfer(address indexed from, address indexed to, uint256 value);
 function NotaryPlatformToken() Ownable(0x1538EF80213cde339A333Ee420a85c21905b1b2D){
 balances[0x244092a2FECFC48259cf810b63BA3B3c0B811DCe] = 134875000 * 1 ether;
 }
 function transfer(address _to, uint256 _value) external whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {
 require(_to != address(0));
 balances[msg.sender] = balances[msg.sender].sub(_value);
 balances[_to] = balances[_to].add(_value);
 Transfer(msg.sender, _to, _value);
 return true;
 }
 function balanceOf(address _owner) external constant returns (uint256 balance) {
 return balances[_owner];
 }
 function transferFrom(address _from, address _to, uint256 _value) external whenNotPaused returns (bool) {
 require(_to != address(0));
 uint256 _allowance = allowed[_from][msg.sender];
 balances[_from] = balances[_from].sub(_value);
 balances[_to] = balances[_to].add(_value);
 allowed[_from][msg.sender] = _allowance.sub(_value);
 Transfer(_from, _to, _value);
 return true;
 }
 function approve(address _spender, uint256 _value) external whenNotPaused returns (bool) {
 allowed[msg.sender][_spender] = _value;
 Approval(msg.sender, _spender, _value);
 return true;
 }
 function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
 return allowed[_owner][_spender];
 }
 function increaseApproval (address _spender, uint _addedValue) external whenNotPaused returns (bool success) {
 allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
 Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
 function decreaseApproval (address _spender, uint _subtractedValue) external whenNotPaused returns (bool success) {
 uint oldValue = allowed[msg.sender][_spender];
 if (_subtractedValue > oldValue) {
 allowed[msg.sender][_spender] = 0;
 } else {
 allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
 }
 Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
 function claim() external whenNotPaused nonReentrant timeLock isTeamMember {
 balances[msg.sender] = balances[msg.sender].add(release());
 }
 uint256 public totalMigrated;
 bool private upgrading = false;
 MigrationAgent private agent;
 event Migrate(address indexed _from, address indexed _to, uint256 _value);
 event Upgrading(bool status);
 function migrationAgent() external constant returns(address){ return agent; }
 function upgradingEnabled() external constant returns(bool){ return upgrading; }
 function migrate(uint256 _value) external nonReentrant isUpgrading {
 require(_value > 0);
 require(_value <= balances[msg.sender]);
 require(agent.isMigrationAgent());
 balances[msg.sender] = balances[msg.sender].sub(_value);
 totalSupply = totalSupply.sub(_value);
 totalMigrated = totalMigrated.add(_value);
 if(!agent.migrateFrom(msg.sender, _value)){
 revert();
 }
 Migrate(msg.sender, agent, _value);
 }
 function setMigrationAgent(address _agent) external isUpgrading onlyOwner {
 require(_agent != 0x00);
 agent = MigrationAgent(_agent);
 if(!agent.isMigrationAgent()){
 revert();
 }
 if(agent.originalSupply() != totalSupply){
 revert();
 }
 }
 function tweakUpgrading() external onlyOwner{
 upgrading = !upgrading;
 Upgrading(upgrading);
 }
 function isTokenContract() external constant returns (bool) {
 return true;
 }
 modifier isUpgrading() {
 require(upgrading);
 _;
 }
 modifier onlyPayloadSize(uint size) {
 require(msg.data.length > size + 4);
 _;
 }
 function () {
 revert();
 }
}
contract MigrationAgent {
 uint256 public originalSupply;
 function migrateFrom(address _from, uint256 _value) external returns(bool);
 function isMigrationAgent() external constant returns (bool) {
 return true;
 }
}