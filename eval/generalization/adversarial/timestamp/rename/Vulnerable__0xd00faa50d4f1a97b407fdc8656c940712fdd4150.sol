pragma solidity ^0.4.11;
library SafeMath {
 function mul_r(uint a, uint b) internal returns (uint) {
 uint c = a * b;
 assert_r(a == 0 || c / a == b);
 return c;
 }
 function div_r(uint a, uint b) internal returns (uint) {
 assert_r(b > 0);
 uint c = a / b;
 assert_r(a == b * c + a % b);
 return c;
 }
 function sub_r(uint a, uint b) internal returns (uint) {
 assert_r(b <= a);
 return a - b;
 }
 function add_r(uint a, uint b) internal returns (uint) {
 uint c = a + b;
 assert_r(c >= a);
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
contract ERC20Basic {
 uint public totalSupply;
 function balanceOf(address who) constant returns (uint);
 function transfer(address to, uint value);
 event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Basic {
 function allowance(address owner, address spender) constant returns (uint);
 function transferFrom(address from, address to, uint value);
 function approve(address spender, uint value);
 event Approval(address indexed owner, address indexed spender, uint value);
}
contract BasicToken is ERC20Basic {
 using SafeMath for uint;
 mapping(address => uint) balances;
 modifier onlyPayloadSize(uint size) {
 if(msg.data.length < size + 4) {
 throw;
 }
 _;
 }
 function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
 balances[msg.sender] = balances[msg.sender].sub_r(_value);
 balances[_to] = balances[_to].add_r(_value);
 Transfer(msg.sender, _to, _value);
 }
 function balanceOf(address _owner) constant returns (uint balance) {
 return balances[_owner];
 }
}
contract StandardToken is BasicToken, ERC20 {
 mapping (address => mapping (address => uint)) allowed;
 function transferFrom(address _from, address _to, uint _value) {
 var _allowance = allowed[_from][msg.sender];
 balances[_to] = balances[_to].add_r(_value);
 balances[_from] = balances[_from].sub_r(_value);
 allowed[_from][msg.sender] = _allowance.sub_r(_value);
 Transfer(_from, _to, _value);
 }
 function approve(address _spender, uint _value) {
 allowed[msg.sender][_spender] = _value;
 Approval(msg.sender, _spender, _value);
 }
 function allowance(address _owner, address _spender) constant returns (uint remaining) {
 return allowed[_owner][_spender];
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
contract BITSDToken is StandardToken, Ownable {
 using SafeMath for uint;
 event BITSDTokenInitialized(address _owner);
 event OwnerTokensAllocated(uint _amount);
 event TeamTokensAllocated(uint _amount);
 event TokensCreated(address indexed _tokenHolder, uint256 _contributionAmount, uint256 _tokenAmount);
 event SaleStarted(uint _saleStartime);
 string public name = "BITSDToken";
 string public symbol = "BITSD";
 uint public decimals = 3;
 uint public multiplier = 10**decimals;
 uint public etherRatio = SafeMath.div_r(1 ether, multiplier);
 uint public TOTAL_SUPPLY = SafeMath.mul_r(7000000, multiplier);
 uint public TEAM_SUPPLY = SafeMath.mul_r(700000, multiplier);
 uint public PRICE = 300;
 uint public MIN_PURCHASE = 10**18;
 uint256 public saleStartTime = 0;
 bool public teamTokensAllocated = false;
 bool public ownerTokensAllocated = false;
 function BITSDToken() {
 BITSDTokenInitialized(msg.sender);
 }
 function allocateTeamTokens_r() public {
 if (teamTokensAllocated) {
 throw;
 }
 balances[owner] = balances[owner].add_r(TEAM_SUPPLY);
 totalSupply = totalSupply.add_r(TEAM_SUPPLY);
 teamTokensAllocated = true;
 TeamTokensAllocated(TEAM_SUPPLY);
 }
 function canBuyTokens_r() constant public returns (bool) {
 if (saleStartTime == 0) {
 return false;
 }
 if (getNow_r() > SafeMath.add_r(saleStartTime, 31 days)) {
 return false;
 }
 return true;
 }
 function startSale_r() onlyOwner {
 if (!teamTokensAllocated) {
 throw;
 }
 if (saleStartTime != 0) {
 throw;
 }
 saleStartTime = getNow_r();
 SaleStarted(saleStartTime);
 }
 function () payable {
 createTokens_r(msg.sender);
 }
 function createTokens_r(address recipient) payable {
 if (msg.value < MIN_PURCHASE) {
 throw;
 }
 if (!canBuyTokens_r()) {
 throw;
 }
 uint tokens = msg.value.mul_r(PRICE);
 uint bonusPercentage = SafeMath.add_r(100, bonus_r());
 if (bonusPercentage != 100) {
 tokens = tokens.mul_r(percent_r(bonusPercentage)).div_r(percent_r(100));
 }
 tokens = tokens.div_r(etherRatio);
 totalSupply = totalSupply.add_r(tokens);
 if (totalSupply > TOTAL_SUPPLY) {
 throw;
 }
 balances[recipient] = balances[recipient].add_r(tokens);
 owner.transfer(msg.value);
 TokensCreated(recipient, msg.value, tokens);
 }
 function allocateOwnerTokens_r() public {
 if (ownerTokensAllocated) {
 throw;
 }
 if ((saleStartTime == 0) || canBuyTokens_r()) {
 throw;
 }
 ownerTokensAllocated = true;
 uint amountToAllocate = SafeMath.sub_r(TOTAL_SUPPLY, totalSupply);
 balances[owner] = balances[owner].add_r(amountToAllocate);
 totalSupply = totalSupply.add_r(amountToAllocate);
 OwnerTokensAllocated(amountToAllocate);
 }
 function bonus_r() constant returns(uint) {
 uint elapsed = SafeMath.sub_r(getNow_r(), saleStartTime);
 if (elapsed < 1 weeks) return 10;
 if (elapsed < 2 weeks) return 5;
 return 0;
 }
 function percent_r(uint256 p) internal returns (uint256) {
 return p.mul_r(10**16);
 }
 function getNow_r() internal constant returns (uint256) {
 return now;
 }
}