pragma solidity ^0.4.13;
contract FinalizeAgent {
 function isFinalizeAgent_r() public constant returns(bool) {
 return true;
 }
 function isSane_r() public constant returns (bool);
 function finalizeCrowdsale_r();
}
contract PricingStrategy {
 function isPricingStrategy_r() public constant returns (bool) {
 return true;
 }
 function isSane_r(address crowdsale) public constant returns (bool) {
 return true;
 }
 function isPresalePurchase_r(address purchaser) public constant returns (bool) {
 return false;
 }
 function calculatePrice_r(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}
library SafeMathLib {
 function times_r(uint a, uint b) returns (uint) {
 uint c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function minus_r(uint a, uint b) returns (uint) {
 assert(b <= a);
 return a - b;
 }
 function plus_r(uint a, uint b) returns (uint) {
 uint c = a + b;
 assert(c>=a);
 return c;
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
 function transferOwnership_r(address newOwner) public onlyOwner {
 require(newOwner != address(0));
 OwnershipTransferred(owner, newOwner);
 owner = newOwner;
 }
}
contract Recoverable is Ownable {
 function Recoverable() {
 }
 function recoverTokens_r(ERC20Basic token) onlyOwner public {
 token.transfer(owner, tokensToBeReturned_r(token));
 }
 function tokensToBeReturned_r(ERC20Basic token) public returns (uint) {
 return token.balanceOf(this);
 }
}
contract Haltable is Ownable {
 bool public halted;
 modifier stopInEmergency {
 if (halted) throw;
 _;
 }
 modifier stopNonOwnersInEmergency {
 if (halted && msg.sender != owner) throw;
 _;
 }
 modifier onlyInEmergency {
 if (!halted) throw;
 _;
 }
 function halt_r() external onlyOwner {
 halted = true;
 }
 function unhalt_r() external onlyOwner onlyInEmergency {
 halted = false;
 }
}
contract Whitelist is Ownable {
 mapping(address => bool) public whitelist;
 event WhitelistedAddressAdded(address addr);
 event WhitelistedAddressRemoved(address addr);
 modifier onlyWhitelisted() {
 require(whitelist[msg.sender]);
 _;
 }
 function addAddressToWhitelist_r(address addr) onlyOwner public returns(bool success) {
 if (!whitelist[addr]) {
 whitelist[addr] = true;
 WhitelistedAddressAdded(addr);
 success = true;
 }
 }
 function addAddressesToWhitelist_r(address[] addrs) onlyOwner public returns(bool success) {
 for (uint256 i = 0; i < addrs.length; i++) {
 if (addAddressToWhitelist_r(addrs[i])) {
 success = true;
 }
 }
 }
 function removeAddressFromWhitelist_r(address addr) onlyOwner public returns(bool success) {
 if (whitelist[addr]) {
 whitelist[addr] = false;
 WhitelistedAddressRemoved(addr);
 success = true;
 }
 }
 function removeAddressesFromWhitelist_r(address[] addrs) onlyOwner public returns(bool success) {
 for (uint256 i = 0; i < addrs.length; i++) {
 if (removeAddressFromWhitelist_r(addrs[i])) {
 success = true;
 }
 }
 }
}
contract ERC20Basic {
 function totalSupply() public view returns (uint256);
 function balanceOf(address who) public view returns (uint256);
 function transfer(address to, uint256 value) public returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
 function allowance(address owner, address spender) public view returns (uint256);
 function transferFrom(address from, address to, uint256 value) public returns (bool);
 function approve(address spender, uint256 value) public returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract FractionalERC20 is ERC20 {
 uint public decimals;
}
library SafeMath {
 function mul_r(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 assert(c / a == b);
 return c;
 }
 function div_r(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub_r(uint256 a, uint256 b) internal pure returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add_r(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract BasicToken is ERC20Basic {
 using SafeMath for uint256;
 mapping(address => uint256) balances;
 uint256 totalSupply_;
 function totalSupply() public view returns (uint256) {
 return totalSupply_;
 }
 function transfer(address _to, uint256 _value) public returns (bool) {
 require(_to != address(0));
 require(_value <= balances[msg.sender]);
 balances[msg.sender] = balances[msg.sender].sub_r(_value);
 balances[_to] = balances[_to].add_r(_value);
 Transfer(msg.sender, _to, _value);
 return true;
 }
 function balanceOf(address _owner) public view returns (uint256 balance) {
 return balances[_owner];
 }
}
contract StandardToken is ERC20, BasicToken {
 mapping (address => mapping (address => uint256)) internal allowed;
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
 require(_to != address(0));
 require(_value <= balances[_from]);
 require(_value <= allowed[_from][msg.sender]);
 balances[_from] = balances[_from].sub_r(_value);
 balances[_to] = balances[_to].add_r(_value);
 allowed[_from][msg.sender] = allowed[_from][msg.sender].sub_r(_value);
 Transfer(_from, _to, _value);
 return true;
 }
 function approve(address _spender, uint256 _value) public returns (bool) {
 allowed[msg.sender][_spender] = _value;
 Approval(msg.sender, _spender, _value);
 return true;
 }
 function allowance(address _owner, address _spender) public view returns (uint256) {
 return allowed[_owner][_spender];
 }
 function increaseApproval_r(address _spender, uint _addedValue) public returns (bool) {
 allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add_r(_addedValue);
 Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
 function decreaseApproval_r(address _spender, uint _subtractedValue) public returns (bool) {
 uint oldValue = allowed[msg.sender][_spender];
 if (_subtractedValue > oldValue) {
 allowed[msg.sender][_spender] = 0;
 } else {
 allowed[msg.sender][_spender] = oldValue.sub_r(_subtractedValue);
 }
 Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
}
contract CrowdsaleBase is Haltable, Whitelist {
 uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;
 using SafeMathLib for uint;
 FractionalERC20 public token;
 PricingStrategy public pricingStrategy;
 FinalizeAgent public finalizeAgent;
 address public multisigWallet;
 uint public minimumFundingGoal;
 uint public startsAt;
 uint public endsAt;
 uint public tokensSold = 0;
 uint public weiRaised = 0;
 uint public presaleWeiRaised = 0;
 uint public investorCount = 0;
 uint public loadedRefund = 0;
 uint public weiRefunded = 0;
 bool public finalized;
 mapping (address => uint256) public investedAmountOf;
 mapping (address => uint256) public tokenAmountOf;
 mapping (address => bool) public earlyParticipantWhitelist;
 uint public ownerTestValue;
 enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}
 event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);
 event Refund(address investor, uint weiAmount);
 event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);
 event Whitelisted(address addr, bool status);
 event EndsAtChanged(uint newEndsAt);
 function CrowdsaleBase(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) {
 owner = msg.sender;
 token = FractionalERC20(_token);
 setPricingStrategy_r(_pricingStrategy);
 multisigWallet = _multisigWallet;
 if(multisigWallet == 0) {
 throw;
 }
 if(_start == 0) {
 throw;
 }
 startsAt = _start;
 if(_end == 0) {
 throw;
 }
 endsAt = _end;
 if(startsAt >= endsAt) {
 throw;
 }
 minimumFundingGoal = _minimumFundingGoal;
 }
 function investInternal_r(address receiver, uint128 customerId) stopInEmergency internal returns(uint tokensBought) {
 Whitelist dc;
 address contract_addr = 0x062e41d1037745dc203e8c1AAcA651B8d157Da96;
 dc = Whitelist(contract_addr);
 require (dc.whitelist(msg.sender));
 require (dc.whitelist(receiver));
 if(getState_r() == State.PreFunding) {
 if(!earlyParticipantWhitelist[receiver]) {
 throw;
 }
 } else if(getState_r() == State.Funding) {
 } else {
 throw;
 }
 uint weiAmount = msg.value;
 require(weiAmount >= minimumFundingGoal);
 uint tokenAmount = pricingStrategy.calculatePrice_r(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());
 require(tokenAmount != 0);
 if(investedAmountOf[receiver] == 0) {
 investorCount++;
 }
 investedAmountOf[receiver] = investedAmountOf[receiver].plus_r(weiAmount);
 tokenAmountOf[receiver] = tokenAmountOf[receiver].plus_r(tokenAmount);
 weiRaised = weiRaised.plus_r(weiAmount);
 tokensSold = tokensSold.plus_r(tokenAmount);
 if(pricingStrategy.isPresalePurchase_r(receiver)) {
 presaleWeiRaised = presaleWeiRaised.plus_r(weiAmount);
 }
 require(!isBreakingCap_r(weiAmount, tokenAmount, weiRaised, tokensSold));
 assignTokens_r(receiver, tokenAmount);
 if(!multisigWallet.send(weiAmount)) throw;
 Invested(receiver, weiAmount, tokenAmount, customerId);
 return tokenAmount;
 }
 function finalize_r() public inState(State.Success) onlyOwner stopInEmergency {
 if(finalized) {
 throw;
 }
 if(address(finalizeAgent) != 0) {
 finalizeAgent.finalizeCrowdsale_r();
 }
 finalized = true;
 }
 function setFinalizeAgent_r(FinalizeAgent addr) onlyOwner {
 finalizeAgent = addr;
 if(!finalizeAgent.isFinalizeAgent_r()) {
 throw;
 }
 }
 function setEndsAt_r(uint time) onlyOwner {
 if(now > time) {
 throw;
 }
 if(startsAt > time) {
 throw;
 }
 endsAt = time;
 EndsAtChanged(endsAt);
 }
 function setPricingStrategy_r(PricingStrategy _pricingStrategy) onlyOwner {
 pricingStrategy = _pricingStrategy;
 if(!pricingStrategy.isPricingStrategy_r()) {
 throw;
 }
 }
 function setMultisig_r(address addr) public onlyOwner {
 if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
 throw;
 }
 multisigWallet = addr;
 }
 function loadRefund_r() public payable inState(State.Failure) {
 if(msg.value == 0) throw;
 loadedRefund = loadedRefund.plus_r(msg.value);
 }
 function refund_r() public inState(State.Refunding) {
 uint256 weiValue = investedAmountOf[msg.sender];
 if (weiValue == 0) throw;
 investedAmountOf[msg.sender] = 0;
 weiRefunded = weiRefunded.plus_r(weiValue);
 Refund(msg.sender, weiValue);
 if (!msg.sender.send(weiValue)) throw;
 }
 function isMinimumGoalReached_r() public constant returns (bool reached) {
 return weiRaised >= minimumFundingGoal;
 }
 function isFinalizerSane_r() public constant returns (bool sane) {
 return finalizeAgent.isSane_r();
 }
 function isPricingSane_r() public constant returns (bool sane) {
 return pricingStrategy.isSane_r(address(this));
 }
 function getState_r() public constant returns (State) {
 if(finalized) return State.Finalized;
 else if (address(finalizeAgent) == 0) return State.Preparing;
 else if (!finalizeAgent.isSane_r()) return State.Preparing;
 else if (!pricingStrategy.isSane_r(address(this))) return State.Preparing;
 else if (block.timestamp < startsAt) return State.PreFunding;
 else if (block.timestamp <= endsAt && !isCrowdsaleFull_r()) return State.Funding;
 else if (isMinimumGoalReached_r()) return State.Success;
 else if (!isMinimumGoalReached_r() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
 else return State.Failure;
 }
 function setOwnerTestValue_r(uint val) onlyOwner {
 ownerTestValue = val;
 }
 function setEarlyParicipantWhitelist_r(address addr, bool status) onlyOwner {
 earlyParticipantWhitelist[addr] = status;
 Whitelisted(addr, status);
 }
 function isCrowdsale_r() public constant returns (bool) {
 return true;
 }
 modifier inState(State state) {
 if(getState_r() != state) throw;
 _;
 }
 function isBreakingCap_r(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);
 function isCrowdsaleFull_r() public constant returns (bool);
 function assignTokens_r(address receiver, uint tokenAmount) internal;
}
contract Crowdsale is CrowdsaleBase {
 bool public requireCustomerId;
 bool public requiredSignedAddress;
 address public signerAddress;
 function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) CrowdsaleBase(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal) {
 }
 function preallocate_r(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {
 uint tokenAmount = fullTokens * 10**token.decimals();
 uint weiAmount = weiPrice * fullTokens;
 weiRaised = weiRaised.plus_r(weiAmount);
 tokensSold = tokensSold.plus_r(tokenAmount);
 investedAmountOf[receiver] = investedAmountOf[receiver].plus_r(weiAmount);
 tokenAmountOf[receiver] = tokenAmountOf[receiver].plus_r(tokenAmount);
 assignTokens_r(receiver, tokenAmount);
 Invested(receiver, weiAmount, tokenAmount, 0);
 }
 function investWithSignedAddress_r(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
 bytes32 hash = sha256(addr);
 if (ecrecover(hash, v, r, s) != signerAddress) throw;
 if(customerId == 0) throw;
 investInternal_r(addr, customerId);
 }
 function investWithCustomerId_r(address addr, uint128 customerId) public payable {
 if(requiredSignedAddress) throw;
 if(customerId == 0) throw;
 investInternal_r(addr, customerId);
 }
 function invest_r(address addr) public payable {
 if(requireCustomerId) throw;
 if(requiredSignedAddress) throw;
 investInternal_r(addr, 0);
 }
 function buyWithSignedAddress_r(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
 investWithSignedAddress_r(msg.sender, customerId, v, r, s);
 }
 function buyWithCustomerIdWithChecksum_r(uint128 customerId, bytes1 checksum) public payable {
 if (bytes1(sha3(customerId)) != checksum) throw;
 investWithCustomerId_r(msg.sender, customerId);
 }
 function buyWithCustomerId_r(uint128 customerId) public payable {
 investWithCustomerId_r(msg.sender, customerId);
 }
 function buy_r() public payable {
 invest_r(msg.sender);
 }
 function setRequireCustomerId_r(bool value) onlyOwner {
 requireCustomerId = value;
 InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
 }
 function setRequireSignedAddress_r(bool value, address _signerAddress) onlyOwner {
 requiredSignedAddress = value;
 signerAddress = _signerAddress;
 InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
 }
 function () public payable {
 invest_r(msg.sender);
 }
}
contract MintedTokenCappedCrowdsale is Crowdsale {
 uint public maximumSellableTokens;
 function MintedTokenCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, uint _maximumSellableTokens) Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal) {
 maximumSellableTokens = _maximumSellableTokens;
 }
 function isBreakingCap_r(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
 return tokensSoldTotal > maximumSellableTokens;
 }
 function isCrowdsaleFull_r() public constant returns (bool) {
 return tokensSold >= maximumSellableTokens;
 }
 function assignTokens_r(address receiver, uint tokenAmount) internal {
 MintableToken mintableToken = MintableToken(token);
 mintableToken.mint(receiver, tokenAmount);
 }
}
contract ERC827 is ERC20 {
 function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
 function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
 function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);
}
contract ERC827Token is ERC827, StandardToken {
 function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
 require(_spender != address(this));
 super.approve(_spender, _value);
 require(_spender.call(_data));
 return true;
 }
 function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
 require(_to != address(this));
 super.transfer(_to, _value);
 require(_to.call(_data));
 return true;
 }
 function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
 require(_to != address(this));
 super.transferFrom(_from, _to, _value);
 require(_to.call(_data));
 return true;
 }
 function increaseApproval_r(address _spender, uint _addedValue, bytes _data) public returns (bool) {
 require(_spender != address(this));
 super.increaseApproval_r(_spender, _addedValue);
 require(_spender.call(_data));
 return true;
 }
 function decreaseApproval_r(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
 require(_spender != address(this));
 super.decreaseApproval_r(_spender, _subtractedValue);
 require(_spender.call(_data));
 return true;
 }
}
contract StandardTokenExt is StandardToken, ERC827Token, Recoverable {
 function isToken_r() public constant returns (bool weAre) {
 return true;
 }
}
contract MintableToken is StandardTokenExt {
 using SafeMathLib for uint;
 bool public mintingFinished = false;
 mapping (address => bool) public mintAgents;
 event MintingAgentChanged(address addr, bool state);
 event Minted(address receiver, uint amount);
 function mint(address receiver, uint amount) onlyMintAgent canMint public {
 totalSupply_ = totalSupply_.plus_r(amount);
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