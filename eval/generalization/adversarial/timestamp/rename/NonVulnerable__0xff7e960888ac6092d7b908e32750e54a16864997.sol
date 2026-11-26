pragma solidity ^0.4.24;
contract ERC20 {
 uint public totalSupply;
 function balanceOf(address who) constant returns (uint);
 function allowance(address owner, address spender) constant returns (uint);
 function transfer(address to, uint value) returns (bool ok);
 function transferFrom(address from, address to, uint value) returns (bool ok);
 function approve(address spender, uint value) returns (bool ok);
 event Transfer(address indexed from, address indexed to, uint value);
 event Approval(address indexed owner, address indexed spender, uint value);
}
contract SafeMath {
 function safeMul_r(uint a, uint b) internal returns (uint) {
 uint c = a * b;
 assert_r(a == 0 || c / a == b);
 return c;
 }
 function safeDiv_r(uint a, uint b) internal returns (uint) {
 assert_r(b > 0);
 uint c = a / b;
 assert_r(a == b * c + a % b);
 return c;
 }
 function safeSub_r(uint a, uint b) internal returns (uint) {
 assert_r(b <= a);
 return a - b;
 }
 function safeAdd_r(uint a, uint b) internal returns (uint) {
 uint c = a + b;
 assert_r(c>=a && c>=b);
 return c;
 }
 function max64_r(uint64 a, uint64 b) internal constant returns (uint64) {
 return a >= b ? a : b;
 }
 function min64_r(uint64 a, uint64 b) internal constant returns (uint64) {
 return a < b ? a : b;
 }
 function max256_r(uint256 a, uint256 b) internal constant returns (uint256) {
 return a >= b ? a : b;
 }
 function min256_r(uint256 a, uint256 b) internal constant returns (uint256) {
 return a < b ? a : b;
 }
 function assert_r(bool assertion) internal {
 if (!assertion) {
 throw;
 }
 }
}
contract StandardToken is ERC20, SafeMath {
 event Minted(address receiver, uint amount);
 mapping(address => uint) balances;
 mapping (address => mapping (address => uint)) allowed;
 modifier onlyPayloadSize(uint size) {
 if(msg.data.length != size + 4) {
 throw;
 }
 _;
 }
 function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool success) {
 balances[msg.sender] = safeSub_r(balances[msg.sender], _value);
 balances[_to] = safeAdd_r(balances[_to], _value);
 Transfer(msg.sender, _to, _value);
 return true;
 }
 function transferFrom(address _from, address _to, uint _value) returns (bool success) {
 uint _allowance = allowed[_from][msg.sender];
 balances[_to] = safeAdd_r(balances[_to], _value);
 balances[_from] = safeSub_r(balances[_from], _value);
 allowed[_from][msg.sender] = safeSub_r(_allowance, _value);
 Transfer(_from, _to, _value);
 return true;
 }
 function balanceOf(address _owner) constant returns (uint balance) {
 return balances[_owner];
 }
 function approve(address _spender, uint _value) returns (bool success) {
 if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;
 allowed[msg.sender][_spender] = _value;
 Approval(msg.sender, _spender, _value);
 return true;
 }
 function allowance(address _owner, address _spender) constant returns (uint remaining) {
 return allowed[_owner][_spender];
 }
 function addApproval_r(address _spender, uint _addedValue)
 onlyPayloadSize(2 * 32)
 returns (bool success) {
 uint oldValue = allowed[msg.sender][_spender];
 allowed[msg.sender][_spender] = safeAdd_r(oldValue, _addedValue);
 Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
 function subApproval_r(address _spender, uint _subtractedValue)
 onlyPayloadSize(2 * 32)
 returns (bool success) {
 uint oldVal = allowed[msg.sender][_spender];
 if (_subtractedValue > oldVal) {
 allowed[msg.sender][_spender] = 0;
 } else {
 allowed[msg.sender][_spender] = safeSub_r(oldVal, _subtractedValue);
 }
 Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
}
contract BurnableToken is StandardToken {
 address public constant BURN_ADDRESS = 0;
 event Burned(address burner, uint burnedAmount);
 function burn(uint burnAmount) {
 address burner = msg.sender;
 balances[burner] = safeSub_r(balances[burner], burnAmount);
 totalSupply = safeSub_r(totalSupply, burnAmount);
 Burned(burner, burnAmount);
 }
}
contract UpgradeAgent {
 uint public originalSupply;
 function isUpgradeAgent_r() public constant returns (bool) {
 return true;
 }
 function upgradeFrom_r(address _from, uint256 _value) public;
}
contract UpgradeableToken is StandardToken {
 address public upgradeMaster;
 UpgradeAgent public upgradeAgent;
 uint256 public totalUpgraded;
 enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}
 event Upgrade(address indexed _from, address indexed _to, uint256 _value);
 event UpgradeAgentSet(address agent);
 function UpgradeableToken(address _upgradeMaster) {
 upgradeMaster = _upgradeMaster;
 }
 function upgrade_r(uint256 value) public {
 UpgradeState state = getUpgradeState_r();
 if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
 throw;
 }
 if (value == 0) throw;
 balances[msg.sender] = safeSub_r(balances[msg.sender], value);
 totalSupply = safeSub_r(totalSupply, value);
 totalUpgraded = safeAdd_r(totalUpgraded, value);
 upgradeAgent.upgradeFrom_r(msg.sender, value);
 Upgrade(msg.sender, upgradeAgent, value);
 }
 function setUpgradeAgent_r(address agent) external {
 if(!canUpgrade_r()) {
 throw;
 }
 if (agent == 0x0) throw;
 if (msg.sender != upgradeMaster) throw;
 if (getUpgradeState_r() == UpgradeState.Upgrading) throw;
 upgradeAgent = UpgradeAgent(agent);
 if(!upgradeAgent.isUpgradeAgent_r()) throw;
 if (upgradeAgent.originalSupply() != totalSupply) throw;
 UpgradeAgentSet(upgradeAgent);
 }
 function getUpgradeState_r() public constant returns(UpgradeState) {
 if(!canUpgrade_r()) return UpgradeState.NotAllowed;
 else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
 else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
 else return UpgradeState.Upgrading;
 }
 function setUpgradeMaster_r(address master) public {
 if (master == 0x0) throw;
 if (msg.sender != upgradeMaster) throw;
 upgradeMaster = master;
 }
 function canUpgrade_r() public constant returns(bool) {
 return true;
 }
}
contract Ownable {
 address public owner;
 function Ownable() {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 if (msg.sender != owner) {
 throw;
 }
 _;
 }
 function transferOwnership_r(address newOwner) onlyOwner {
 if (newOwner != address(0)) {
 owner = newOwner;
 }
 }
}
contract ReleasableToken is ERC20, Ownable {
 address public releaseAgent;
 bool public released = false;
 mapping (address => bool) public transferAgents;
 modifier canTransfer(address _sender) {
 if(!released) {
 if(!transferAgents[_sender]) {
 throw;
 }
 }
 _;
 }
 function setReleaseAgent_r(address addr) onlyOwner inReleaseState(false) public {
 releaseAgent = addr;
 }
 function setTransferAgent_r(address addr, bool state) onlyOwner inReleaseState(false) public {
 transferAgents[addr] = state;
 }
 function releaseTokenTransfer_r() public onlyReleaseAgent {
 released = true;
 }
 modifier inReleaseState(bool releaseState) {
 if(releaseState != released) {
 throw;
 }
 _;
 }
 modifier onlyReleaseAgent() {
 if(msg.sender != releaseAgent) {
 throw;
 }
 _;
 }
 function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
 return super.transfer(_to, _value);
 }
 function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
 return super.transferFrom(_from, _to, _value);
 }
}
library SafeMathLib {
 function times_r(uint a, uint b) returns (uint) {
 uint c = a * b;
 assert_r(a == 0 || c / a == b);
 return c;
 }
 function minus_r(uint a, uint b) returns (uint) {
 assert_r(b <= a);
 return a - b;
 }
 function plus_r(uint a, uint b) returns (uint) {
 uint c = a + b;
 assert_r(c>=a);
 return c;
 }
 function assert_r(bool assertion) private {
 if (!assertion) throw;
 }
}
contract MintableToken is StandardToken, Ownable {
 using SafeMathLib for uint;
 bool public mintingFinished = false;
 mapping (address => bool) public mintAgents;
 event MintingAgentChanged(address addr, bool state );
 function mint(address receiver, uint amount) onlyMintAgent canMint public {
 totalSupply = totalSupply.plus_r(amount);
 balances[receiver] = balances[receiver].plus_r(amount);
 Transfer(0, receiver, amount);
 }
 function setMintAgent_r(address addr, bool state) onlyOwner canMint public {
 mintAgents[addr] = state;
 MintingAgentChanged(addr, state);
 }
 modifier onlyMintAgent() {
 if(!mintAgents[msg.sender]) {
 throw;
 }
 _;
 }
 modifier canMint() {
 if(mintingFinished) throw;
 _;
 }
}
contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken {
 string public name;
 string public symbol;
 uint public decimals;
 function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable)
 UpgradeableToken(msg.sender) {
 owner = msg.sender;
 name = _name;
 symbol = _symbol;
 totalSupply = _initialSupply;
 decimals = _decimals;
 balances[owner] = totalSupply;
 if(totalSupply > 0) {
 Minted(owner, totalSupply);
 }
 if(!_mintable) {
 mintingFinished = true;
 if(totalSupply == 0) {
 throw;
 }
 }
 }
 function releaseTokenTransfer_r() public onlyReleaseAgent {
 mintingFinished = true;
 super.releaseTokenTransfer_r();
 }
 function canUpgrade_r() public constant returns(bool) {
 return released && super.canUpgrade_r();
 }
}
contract BurnableCrowdsaleToken is BurnableToken, CrowdsaleToken {
 function BurnableCrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint _decimals, bool _mintable)
 CrowdsaleToken(_name, _symbol, _initialSupply, _decimals, _mintable) {
 }
}