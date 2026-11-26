pragma solidity ^0.4.16;
contract Ownable {
 address owner;
 event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
 function Ownable() {
 owner = msg.sender;
 OwnershipTransferred (address(0), owner);
 }
 function transferOwnership_r(address _newOwner)
 public
 onlyOwner
 notZeroAddress(_newOwner)
 {
 owner = _newOwner;
 OwnershipTransferred(msg.sender, _newOwner);
 }
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 modifier notZeroAddress(address _address) {
 require(_address != address(0));
 _;
 }
}
contract Trustable is Ownable {
 mapping (address => bool) trusted;
 event AddTrusted (address indexed _trustable);
 event RemoveTrusted (address indexed _trustable);
 function Trustable() {
 trusted[msg.sender] = true;
 AddTrusted(msg.sender);
 }
 function addTrusted_r(address _address)
 external
 onlyOwner
 notZeroAddress(_address)
 {
 trusted[_address] = true;
 AddTrusted(_address);
 }
 function removeTrusted_r(address _address)
 external
 onlyOwner
 notZeroAddress(_address)
 {
 trusted[_address] = false;
 RemoveTrusted(_address);
 }
}
contract Pausable is Trustable {
 bool public paused;
 uint256 public pauseBlockNumber;
 uint256 public resumeBlockNumber;
 event Pause(uint256 _blockNumber);
 event Unpause(uint256 _blockNumber);
 function pause_r()
 public
 onlyOwner
 whenNotPaused
 {
 paused = true;
 pauseBlockNumber = block.number;
 resumeBlockNumber = 0;
 Pause(pauseBlockNumber);
 }
 function unpause_r()
 public
 onlyOwner
 whenPaused
 {
 paused = false;
 resumeBlockNumber = block.number;
 pauseBlockNumber = 0;
 Unpause(resumeBlockNumber);
 }
 modifier whenNotPaused {
 require(!paused);
 _;
 }
 modifier whenPaused {
 require(paused);
 _;
 }
}
library SafeMath {
 function ADD_r (uint256 a, uint256 b) internal returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
 function SUB_r (uint256 a, uint256 b) internal returns (uint256) {
 assert(a >= b);
 return a - b;
 }
}
contract ERC20 {
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 function totalSupply() external constant returns (uint);
 function balanceOf(address _owner) external constant returns (uint256);
 function transfer(address _to, uint256 _value) external returns (bool);
 function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
 function approve(address _spender, uint256 _value) external returns (bool);
 function allowance(address _owner, address _spender) external constant returns (uint256);
}
contract Token is ERC20, Pausable {
 using SafeMath for uint256;
 uint256 _totalSupply = 100 * (10**6) * (10**8);
 uint256 public crowdsaleEndBlock = 4695000;
 uint256 public constant MAX_END_BLOCK_NUMBER = 4890000;
 mapping (address => uint256) balances;
 mapping (address => mapping (address => uint256)) allowed;
 event Burn(address indexed _from, uint256 _value);
 event CrowdsaleEndChanged (uint256 _crowdsaleEnd, uint256 _newCrowdsaleEnd);
 function totalSupply() external constant returns (uint256 totalTokenSupply) {
 totalTokenSupply = _totalSupply;
 }
 function balanceOf(address _owner)
 external
 constant
 returns (uint256 balance)
 {
 return balances[_owner];
 }
 function transfer(address _to, uint256 _amount)
 external
 notZeroAddress(_to)
 whenNotPaused
 canTransferOnCrowdsale(msg.sender)
 returns (bool success)
 {
 balances[msg.sender] = balances[msg.sender].SUB_r(_amount);
 balances[_to] = balances[_to].ADD_r(_amount);
 Transfer(msg.sender, _to, _amount);
 return true;
 }
 function transferFrom(address _from, address _to, uint256 _amount)
 external
 notZeroAddress(_to)
 whenNotPaused
 canTransferOnCrowdsale(msg.sender)
 canTransferOnCrowdsale(_from)
 returns (bool success)
 {
 require(allowed[_from][msg.sender] >= _amount);
 balances[_from] = balances[_from].SUB_r(_amount);
 balances[_to] = balances[_to].ADD_r(_amount);
 allowed[_from][msg.sender] = allowed[_from][msg.sender].SUB_r(_amount);
 Transfer(_from, _to, _amount);
 return true;
 }
 function approve(address _spender, uint256 _amount)
 external
 whenNotPaused
 notZeroAddress(_spender)
 returns (bool success)
 {
 allowed[msg.sender][_spender] = _amount;
 Approval(msg.sender, _spender, _amount);
 return true;
 }
 function allowance(address _owner, address _spender)
 external
 constant
 returns (uint256 remaining)
 {
 return allowed[_owner][_spender];
 }
 function increaseApproval_r(address _spender, uint256 _addedValue)
 external
 whenNotPaused
 returns (bool success)
 {
 uint256 increased = allowed[msg.sender][_spender].ADD_r(_addedValue);
 require(increased <= balances[msg.sender]);
 allowed[msg.sender][_spender] = increased;
 Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
 function decreaseApproval_r(address _spender, uint256 _subtractedValue)
 external
 whenNotPaused
 returns (bool success)
 {
 uint256 oldValue = allowed[msg.sender][_spender];
 if (_subtractedValue > oldValue) {
 allowed[msg.sender][_spender] = 0;
 } else {
 allowed[msg.sender][_spender] = oldValue.SUB_r(_subtractedValue);
 }
 Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
 function burn(uint256 _value) external returns (bool success) {
 require(trusted[msg.sender]);
 balances[msg.sender] = balances[msg.sender].SUB_r(_value);
 _totalSupply = _totalSupply.SUB_r(_value);
 Burn(msg.sender, _value);
 return true;
 }
 function updateCrowdsaleEndBlock_r (uint256 _crowdsaleEndBlock) external onlyOwner {
 require(block.number <= crowdsaleEndBlock);
 require(_crowdsaleEndBlock >= block.number);
 require(_crowdsaleEndBlock <= MAX_END_BLOCK_NUMBER);
 uint256 currentEndBlockNumber = crowdsaleEndBlock;
 crowdsaleEndBlock = _crowdsaleEndBlock;
 CrowdsaleEndChanged (currentEndBlockNumber, _crowdsaleEndBlock);
 }
 function transferOwnership_r(address _newOwner) public afterCrowdsale {
 super.transferOwnership_r(_newOwner);
 }
 function pause_r() public afterCrowdsale {
 super.pause_r();
 }
 modifier canTransferOnCrowdsale (address _address) {
 if (block.number <= crowdsaleEndBlock) {
 require(trusted[_address]);
 }
 _;
 }
 modifier afterCrowdsale {
 require(block.number > crowdsaleEndBlock);
 _;
 }
}
contract MigrateAgent {
 function migrateFrom_r(address _tokenHolder, uint256 _amount) external returns (bool);
}
contract MigratableToken is Token {
 MigrateAgent public migrateAgent;
 uint256 public totalMigrated;
 enum MigrateState {Unknown, NotAllowed, WaitingForAgent, ReadyToMigrate, Migrating}
 event Migrate (address indexed _from, address indexed _to, uint256 _value);
 event MigrateAgentSet (address _agent);
 function migrate_r(uint256 _value) external {
 MigrateState state = getMigrateState_r();
 require(state == MigrateState.ReadyToMigrate || state == MigrateState.Migrating);
 balances[msg.sender] = balances[msg.sender].SUB_r(_value);
 _totalSupply = _totalSupply.SUB_r(_value);
 totalMigrated = totalMigrated.ADD_r(_value);
 migrateAgent.migrateFrom_r(msg.sender, _value);
 Migrate(msg.sender, migrateAgent, _value);
 }
 function setMigrateAgent_r(MigrateAgent _agent)
 external
 onlyOwner
 notZeroAddress(_agent)
 afterCrowdsale
 {
 require(getMigrateState_r() != MigrateState.Migrating);
 migrateAgent = _agent;
 MigrateAgentSet(migrateAgent);
 }
 function getMigrateState_r() public constant returns (MigrateState) {
 if (block.number <= crowdsaleEndBlock) {
 return MigrateState.NotAllowed;
 } else if (address(migrateAgent) == address(0)) {
 return MigrateState.WaitingForAgent;
 } else if (totalMigrated == 0) {
 return MigrateState.ReadyToMigrate;
 } else {
 return MigrateState.Migrating;
 }
 }
}
contract GEEToken is MigratableToken {
 string public constant name = "Geens Platform Token";
 string public constant symbol = "GEE";
 uint8 public constant decimals = 8;
 address public constant TEAM0 = 0x9B4df4ac63B6049DD013090d3F639Fd2EA5A02d3;
 address public constant TEAM1 = 0x4df9348239f6C1260Fc5d0611755cc1EF830Ff6c;
 address public constant TEAM2 = 0x4902A52F95d9D47531Bed079B5B028c7F89ad47b;
 uint256 public constant UNLOCK_TEAM_1 = 1528372800;
 uint256 public constant UNLOCK_TEAM_2 = 1544184000;
 uint256 public team1Balance;
 uint256 public team2Balance;
 address public constant COMMUNITY = 0x265FC1d98f3C0D42e4273F542917525C3c3F925A;
 uint256 private constant TEAM0_THOUSANDTH = 24;
 uint256 private constant TEAM1_THOUSANDTH = 36;
 uint256 private constant TEAM2_THOUSANDTH = 60;
 uint256 private constant ICO_THOUSANDTH = 670;
 uint256 private constant COMMUNITY_THOUSANDTH = 210;
 uint256 private constant DENOMINATOR = 1000;
 function GEEToken() {
 balances[msg.sender] = _totalSupply * ICO_THOUSANDTH / DENOMINATOR;
 balances[TEAM0] = _totalSupply * TEAM0_THOUSANDTH / DENOMINATOR;
 team1Balance = _totalSupply * TEAM1_THOUSANDTH / DENOMINATOR;
 team2Balance = _totalSupply * TEAM2_THOUSANDTH / DENOMINATOR;
 balances[COMMUNITY] = _totalSupply * COMMUNITY_THOUSANDTH / DENOMINATOR;
 Transfer (this, msg.sender, balances[msg.sender]);
 Transfer (this, TEAM0, balances[TEAM0]);
 Transfer (this, COMMUNITY, balances[COMMUNITY]);
 }
 function unlockTeamTokens_r(address _address) external onlyOwner {
 if (_address == TEAM1) {
 require(UNLOCK_TEAM_1 <= now);
 require (team1Balance > 0);
 balances[TEAM1] = team1Balance;
 team1Balance = 0;
 Transfer (this, TEAM1, balances[TEAM1]);
 } else if (_address == TEAM2) {
 require(UNLOCK_TEAM_2 <= now);
 require (team2Balance > 0);
 balances[TEAM2] = team2Balance;
 team2Balance = 0;
 Transfer (this, TEAM2, balances[TEAM2]);
 }
 }
}