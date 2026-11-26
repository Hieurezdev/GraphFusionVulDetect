pragma solidity ^0.4.24;
library SafeMathLib {
 function times(uint a, uint b) returns (uint) {
 uint c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function minus(uint a, uint b) returns (uint) {
 assert(b <= a);
 return a - b;
 }
 function plus(uint a, uint b) returns (uint) {
 uint c = a + b;
 assert(c>=a);
 return c;
 }
}
contract PricingStrategy {
 function isPricingStrategy() public constant returns (bool) {
 return true;
 }
 function isSane(address crowdsale) public constant returns (bool) {
 return true;
 }
 function isPresalePurchase(address purchaser) public constant returns (bool) {
 return false;
 }
 function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}
contract FinalizeAgent {
 function isFinalizeAgent() public constant returns(bool) {
 return true;
 }
 function isSane() public constant returns (bool);
 function finalizeCrowdsale();
}
contract ERC20Basic {
 uint256 public totalSupply;
 function balanceOf(address who) constant returns (uint256);
 function transfer(address to, uint256 value) returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
 function allowance(address owner, address spender) constant returns (uint256);
 function transferFrom(address from, address to, uint256 value) returns (bool);
 function approve(address spender, uint256 value) returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract FractionalERC20 is ERC20 {
 uint public decimals;
}
contract Ownable {
 address public owner;
 function Ownable() {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) onlyOwner {
 require(newOwner != address(0));
 owner = newOwner;
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
 function halt() external onlyOwner {
 halted = true;
 }
 function unhalt() external onlyOwner onlyInEmergency {
 halted = false;
 }
}
contract CrowdsaleBase is Haltable {
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
 State public testState;
 function CrowdsaleBase(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) {
 owner = msg.sender;
 token = FractionalERC20(_token);
 setPricingStrategy(_pricingStrategy);
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
 function() payable {
 throw;
 }
 function investInternal(address receiver, uint128 customerId) stopInEmergency internal returns(uint tokensBought) {
 if(getState() == State.PreFunding) {
 if(!earlyParticipantWhitelist[receiver]) {
 throw;
 }
 } else if(getState() == State.Funding) {
 } else {
 throw;
 }
 uint weiAmount = msg.value;
 uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());
 require(tokenAmount != 0);
 if(investedAmountOf[receiver] == 0) {
 investorCount++;
 }
 investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
 tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);
 weiRaised = weiRaised.plus(weiAmount);
 tokensSold = tokensSold.plus(tokenAmount);
 if(pricingStrategy.isPresalePurchase(receiver)) {
 presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
 }
 require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));
 assignTokens(receiver, tokenAmount);
 if(!multisigWallet.send(weiAmount)) throw;
 Invested(receiver, weiAmount, tokenAmount, customerId);
 return tokenAmount;
 }
 function finalize() public inState(State.Success) onlyOwner stopInEmergency {
 if(finalized) {
 throw;
 }
 if(address(finalizeAgent) != 0) {
 finalizeAgent.finalizeCrowdsale();
 }
 finalized = true;
 }
 function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
 finalizeAgent = addr;
 if(!finalizeAgent.isFinalizeAgent()) {
 throw;
 }
 }
 function setEndsAt(uint time) onlyOwner {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if(now > time) {
 throw;
 }
 if(startsAt > time) {
 throw;
 }
 endsAt = time;
 EndsAtChanged(endsAt);
 }
 function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
 pricingStrategy = _pricingStrategy;
 if(!pricingStrategy.isPricingStrategy()) {
 throw;
 }
 }
 function setMultisig(address addr) public onlyOwner {
 if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
 throw;
 }
 multisigWallet = addr;
 }
 function loadRefund() public payable inState(State.Failure) {
 if(msg.value == 0) throw;
 loadedRefund = loadedRefund.plus(msg.value);
 }
 function refund() public inState(State.Refunding) {
 uint256 weiValue = investedAmountOf[msg.sender];
 if (weiValue == 0) throw;
 investedAmountOf[msg.sender] = 0;
 weiRefunded = weiRefunded.plus(weiValue);
 Refund(msg.sender, weiValue);
 if (!msg.sender.send(weiValue)) throw;
 }
 function isMinimumGoalReached() public constant returns (bool reached) {
 return weiRaised >= minimumFundingGoal;
 }
 function isFinalizerSane() public constant returns (bool sane) {
 return finalizeAgent.isSane();
 }
 function isPricingSane() public constant returns (bool sane) {
 return pricingStrategy.isSane(address(this));
 }
 function getState() public constant returns (State) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if(finalized) return State.Finalized;
 else if (address(finalizeAgent) == 0) return State.Preparing;
 else if (!finalizeAgent.isSane()) return State.Preparing;
 else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
 else if (block.timestamp < startsAt) return State.PreFunding;
 else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
 else if (isMinimumGoalReached()) return State.Success;
 else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
 else return State.Failure;
 }
 function setOwnerTestValue(uint val) onlyOwner {
 ownerTestValue = val;
 }
 function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
 earlyParticipantWhitelist[addr] = status;
 Whitelisted(addr, status);
 }
 function isCrowdsale() public constant returns (bool) {
 return true;
 }
 modifier inState(State state) {
 if(getState() != state) throw;
 _;
 }
 function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);
 function isCrowdsaleFull() public constant returns (bool);
 function assignTokens(address receiver, uint tokenAmount) internal;
}
contract Crowdsale is CrowdsaleBase {
 bool public requireCustomerId;
 bool public requiredSignedAddress;
 address public signerAddress;
 function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) CrowdsaleBase(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal) {
 }
 function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {
 uint tokenAmount = fullTokens * 10**token.decimals();
 uint weiAmount = weiPrice * fullTokens;
 weiRaised = weiRaised.plus(weiAmount);
 tokensSold = tokensSold.plus(tokenAmount);
 investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
 tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);
 assignTokens(receiver, tokenAmount);
 Invested(receiver, weiAmount, tokenAmount, 0);
 }
 function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
 bytes32 hash = sha256(addr);
 if (ecrecover(hash, v, r, s) != signerAddress) throw;
 if(customerId == 0) throw;
 investInternal(addr, customerId);
 }
 function investWithCustomerId(address addr, uint128 customerId) public payable {
 if(requiredSignedAddress) throw;
 if(customerId == 0) throw;
 investInternal(addr, customerId);
 }
 function invest(address addr) public payable {
 if(requireCustomerId) throw;
 if(requiredSignedAddress) throw;
 investInternal(addr, 0);
 }
 function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
 investWithSignedAddress(msg.sender, customerId, v, r, s);
 }
 function buyWithCustomerId(uint128 customerId) public payable {
 investWithCustomerId(msg.sender, customerId);
 }
 function buy() public payable {
 invest(msg.sender);
 }
 function() payable {
 invest(msg.sender);
 }
 function setRequireCustomerId(bool value) onlyOwner {
 requireCustomerId = value;
 InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
 }
 function setRequireSignedAddress(bool value, address _signerAddress) onlyOwner {
 requiredSignedAddress = value;
 signerAddress = _signerAddress;
 InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
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
 function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
 releaseAgent = addr;
 }
 function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
 transferAgents[addr] = state;
 }
 function releaseTokenTransfer() public onlyReleaseAgent {
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
contract DefaultFinalizeAgent is FinalizeAgent {
 ReleasableToken public token;
 Crowdsale public crowdsale;
 function DefaultFinalizeAgent(ReleasableToken _token, Crowdsale _crowdsale) {
 token = _token;
 crowdsale = _crowdsale;
 }
 function isSane() public constant returns (bool) {
 return (token.releaseAgent() == address(this));
 }
 function finalizeCrowdsale() public {
 if(msg.sender != address(crowdsale)) {
 throw;
 }
 token.releaseTokenTransfer();
 }
}