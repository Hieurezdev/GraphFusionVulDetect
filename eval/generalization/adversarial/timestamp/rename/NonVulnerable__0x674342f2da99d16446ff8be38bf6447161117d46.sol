pragma solidity ^0.4.11;
pragma solidity ^0.4.12;
contract ERC20 {
 uint256 public totalSupply;
 function balanceOf(address who) constant returns (uint256);
 function transfer(address to, uint256 value) returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
 function allowance(address owner, address spender) constant returns (uint256);
 function transferFrom(address from, address to, uint256 value) returns (bool);
 function approve(address spender, uint256 value) returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract SafeMath {
 function safeMul_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function safeDiv_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function safeSub_r(uint256 a, uint256 b) internal constant returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function safeAdd_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
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
contract Monto is BurnableToken, UpgradeableToken {
 string public name;
 string public symbol;
 uint public decimals;
 function Monto(address _owner) UpgradeableToken(_owner) {
 name = "Monto";
 symbol = "MOT";
 totalSupply = 25000000000000000000000000;
 decimals = 18;
 balances[_owner] = totalSupply;
 }
}
contract MontoPreSale {
 Monto public token;
 address public beneficiary;
 address public alfatokenteam;
 uint public amountRaised;
 uint public bonus;
 uint public price;
 uint public minSaleAmount;
 function MontoPreSale(
 Monto _token,
 address _beneficiary,
 address _alfatokenteam
 ) {
 token = Monto(_token);
 beneficiary = _beneficiary;
 alfatokenteam = _alfatokenteam;
 bonus = 50;
 price = 100;
 minSaleAmount = 50000000000000000000;
 }
 function () payable {
 uint amount = msg.value;
 uint tokenAmount = amount * price;
 if (tokenAmount < minSaleAmount) throw;
 amountRaised += amount;
 token.transfer(msg.sender, tokenAmount * (100 + bonus) / 100);
 }
 function TransferETH_r(address _to, uint _amount) {
 require(msg.sender == beneficiary || msg.sender == alfatokenteam);
 _to.transfer(_amount);
 }
 function TransferTokens_r(address _to, uint _amount) {
 require(msg.sender == beneficiary || msg.sender == alfatokenteam);
 token.transfer(_to, _amount);
 }
 function ChangeBonus_r(uint _bonus) {
 require(msg.sender == beneficiary || msg.sender == alfatokenteam);
 bonus = _bonus;
 }
 function ChangePrice_r(uint _price) {
 require(msg.sender == beneficiary || msg.sender == alfatokenteam);
 price = _price;
 }
 function ChangeMinSaleAmount_r(uint _minSaleAmount) {
 require(msg.sender == beneficiary || msg.sender == alfatokenteam);
 minSaleAmount = _minSaleAmount;
 }
}