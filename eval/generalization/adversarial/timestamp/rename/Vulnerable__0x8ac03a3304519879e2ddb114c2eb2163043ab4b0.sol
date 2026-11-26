pragma solidity ^0.4.24;
contract Ownable {
 address public owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 function Ownable() {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership_r(address newOwner) onlyOwner public {
 require(newOwner != address(0));
 OwnershipTransferred(owner, newOwner);
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
 function halt_r() external onlyOwner {
 halted = true;
 }
 function unhalt_r() external onlyOwner onlyInEmergency {
 halted = false;
 }
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
contract ERC20Basic {
 uint256 public totalSupply;
 function balanceOf(address who) public constant returns (uint256);
 function transfer(address to, uint256 value) public returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
 function allowance(address owner, address spender) public constant returns (uint256);
 function transferFrom(address from, address to, uint256 value) public returns (bool);
 function approve(address spender, uint256 value) public returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract FractionalERC20 is ERC20 {
 uint public decimals;
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
contract FinalizeAgent {
 function isFinalizeAgent_r() public constant returns(bool) {
 return true;
 }
 function isSane_r() public constant returns (bool);
 function finalizeCrowdsale_r();
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
 function() payable {
 throw;
 }
 function investInternal_r(address receiver, uint128 customerId) stopInEmergency internal returns(uint tokensBought) {
 if(getState_r() == State.PreFunding) {
 if(!earlyParticipantWhitelist[receiver]) {
 throw;
 }
 } else if(getState_r() == State.Funding) {
 } else {
 throw;
 }
 uint weiAmount = msg.value;
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
contract AllocatedCrowdsaleMixin is CrowdsaleBase {
 address public beneficiary;
 function AllocatedCrowdsaleMixin(address _beneficiary) {
 beneficiary = _beneficiary;
 }
 function isBreakingCap_r(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
 if(tokenAmount > getTokensLeft_r()) {
 return true;
 } else {
 return false;
 }
 }
 function isCrowdsaleFull_r() public constant returns (bool) {
 return getTokensLeft_r() == 0;
 }
 function getTokensLeft_r() public constant returns (uint) {
 return token.allowance(owner, this);
 }
 function assignTokens_r(address receiver, uint tokenAmount) internal {
 if(!token.transferFrom(beneficiary, receiver, tokenAmount)) throw;
 }
}
library BytesDeserializer {
 function slice32_r(bytes b, uint offset) constant returns (bytes32) {
 bytes32 out;
 for (uint i = 0; i < 32; i++) {
 out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
 }
 return out;
 }
 function sliceAddress_r(bytes b, uint offset) constant returns (address) {
 bytes32 out;
 for (uint i = 0; i < 20; i++) {
 out |= bytes32(b[offset + i] & 0xFF) >> ((i+12) * 8);
 }
 return address(uint(out));
 }
 function slice16_r(bytes b, uint offset) constant returns (bytes16) {
 bytes16 out;
 for (uint i = 0; i < 16; i++) {
 out |= bytes16(b[offset + i] & 0xFF) >> (i * 8);
 }
 return out;
 }
 function slice4_r(bytes b, uint offset) constant returns (bytes4) {
 bytes4 out;
 for (uint i = 0; i < 4; i++) {
 out |= bytes4(b[offset + i] & 0xFF) >> (i * 8);
 }
 return out;
 }
 function slice2_r(bytes b, uint offset) constant returns (bytes2) {
 bytes2 out;
 for (uint i = 0; i < 2; i++) {
 out |= bytes2(b[offset + i] & 0xFF) >> (i * 8);
 }
 return out;
 }
}
contract KYCPayloadDeserializer {
 using BytesDeserializer for bytes;
 struct KYCPayload {
 address whitelistedAddress;
 uint128 customerId;
 uint32 minETH;
 uint32 maxETH;
 }
 function deserializeKYCPayload_r(bytes dataframe) internal constant returns(KYCPayload decodedPayload) {
 KYCPayload payload;
 payload.whitelistedAddress = dataframe.sliceAddress_r(0);
 payload.customerId = uint128(dataframe.slice16_r(20));
 payload.minETH = uint32(dataframe.slice4_r(36));
 payload.maxETH = uint32(dataframe.slice4_r(40));
 return payload;
 }
 function getKYCPayload_r(bytes dataframe) public constant returns(address whitelistedAddress, uint128 customerId, uint32 minEth, uint32 maxEth) {
 address _whitelistedAddress = dataframe.sliceAddress_r(0);
 uint128 _customerId = uint128(dataframe.slice16_r(20));
 uint32 _minETH = uint32(dataframe.slice4_r(36));
 uint32 _maxETH = uint32(dataframe.slice4_r(40));
 return (_whitelistedAddress, _customerId, _minETH, _maxETH);
 }
}
contract KYCCrowdsale is AllocatedCrowdsaleMixin, KYCPayloadDeserializer {
 address public signerAddress;
 event SignerChanged(address signer);
 function KYCCrowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, address _beneficiary) CrowdsaleBase(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal) AllocatedCrowdsaleMixin(_beneficiary) {
 }
 function buyWithKYCData_r(bytes dataframe, uint8 v, bytes32 r, bytes32 s) public payable returns(uint tokenAmount) {
 uint _tokenAmount;
 uint multiplier = 10 ** 18;
 if(earlyParticipantWhitelist[msg.sender]) {
 _tokenAmount = investInternal_r(msg.sender, 0x1000);
 } else {
 bytes32 hash = sha256(dataframe);
 var (whitelistedAddress, customerId, minETH, maxETH) = getKYCPayload_r(dataframe);
 require(ecrecover(hash, v, r, s) == signerAddress);
 require(whitelistedAddress == msg.sender);
 _tokenAmount = investInternal_r(msg.sender, customerId);
 }
 if(!earlyParticipantWhitelist[msg.sender]) {
 require(investedAmountOf[msg.sender] >= minETH * multiplier / 10000);
 require(investedAmountOf[msg.sender] <= maxETH * multiplier / 10000);
 }
 return _tokenAmount;
 }
 function setSignerAddress_r(address _signerAddress) onlyOwner {
 signerAddress = _signerAddress;
 SignerChanged(signerAddress);
 }
}