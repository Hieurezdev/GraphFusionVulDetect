pragma solidity ^0.4.11;
contract ERC20Basic {
 uint256 public totalSupply;
 function balanceOf(address who) public constant returns (uint256);
 function transfer(address to, uint256 value) public returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
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
library SafeMathLibExt {
 function times_r(uint a, uint b) returns (uint) {
 uint c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function divides_r(uint a, uint b) returns (uint) {
 assert(b > 0);
 uint c = a / b;
 assert(a == b * c + a % b);
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
contract PricingStrategy {
 address public tier;
 function isPricingStrategy_r() public constant returns (bool) {
 return true;
 }
 function isSane_r(address crowdsale) public constant returns (bool) {
 return true;
 }
 function isPresalePurchase_r(address purchaser) public constant returns (bool) {
 return false;
 }
 function updateRate_r(uint newOneTokenInWei) public;
 function calculatePrice_r(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}
contract FinalizeAgent {
 bool public reservedTokensAreDistributed = false;
 function isFinalizeAgent_r() public constant returns(bool) {
 return true;
 }
 function isSane_r() public constant returns (bool);
 function distributeReservedTokens_r(uint reservedTokensDistributionBatch);
 function finalizeCrowdsale_r();
}
contract ERC20 is ERC20Basic {
 function allowance(address owner, address spender) public constant returns (uint256);
 function transferFrom(address from, address to, uint256 value) public returns (bool);
 function approve(address spender, uint256 value) public returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract FractionalERC20Ext is ERC20 {
 uint public decimals;
 uint public minCap;
}
contract CrowdsaleExt is Haltable {
 uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;
 using SafeMathLibExt for uint;
 FractionalERC20Ext public token;
 PricingStrategy public pricingStrategy;
 FinalizeAgent public finalizeAgent;
 string public name;
 address public multisigWallet;
 uint public minimumFundingGoal;
 uint public startsAt;
 uint public endsAt;
 uint public tokensSold = 0;
 uint public weiRaised = 0;
 uint public investorCount = 0;
 bool public finalized;
 bool public isWhiteListed;
 address[] public joinedCrowdsales;
 uint8 public joinedCrowdsalesLen = 0;
 uint8 public joinedCrowdsalesLenMax = 50;
 struct JoinedCrowdsaleStatus {
 bool isJoined;
 uint8 position;
 }
 mapping (address => JoinedCrowdsaleStatus) joinedCrowdsaleState;
 mapping (address => uint256) public investedAmountOf;
 mapping (address => uint256) public tokenAmountOf;
 struct WhiteListData {
 bool status;
 uint minCap;
 uint maxCap;
 }
 bool public isUpdatable;
 mapping (address => WhiteListData) public earlyParticipantWhitelist;
 address[] public whitelistedParticipants;
 uint public ownerTestValue;
 enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized}
 event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);
 event Whitelisted(address addr, bool status, uint minCap, uint maxCap);
 event WhitelistItemChanged(address addr, bool status, uint minCap, uint maxCap);
 event StartsAtChanged(uint newStartsAt);
 event EndsAtChanged(uint newEndsAt);
 function CrowdsaleExt(string _name, address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, bool _isUpdatable, bool _isWhiteListed) {
 owner = msg.sender;
 name = _name;
 token = FractionalERC20Ext(_token);
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
 isUpdatable = _isUpdatable;
 isWhiteListed = _isWhiteListed;
 }
 function() payable {
 throw;
 }
 function investInternal_r(address receiver, uint128 customerId) stopInEmergency private {
 if(getState_r() == State.PreFunding) {
 throw;
 } else if(getState_r() == State.Funding) {
 if(isWhiteListed) {
 if(!earlyParticipantWhitelist[receiver].status) {
 throw;
 }
 }
 } else {
 throw;
 }
 uint weiAmount = msg.value;
 uint tokenAmount = pricingStrategy.calculatePrice_r(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());
 if(tokenAmount == 0) {
 throw;
 }
 if(isWhiteListed) {
 if(tokenAmount < earlyParticipantWhitelist[receiver].minCap && tokenAmountOf[receiver] == 0) {
 throw;
 }
 if(tokenAmount > earlyParticipantWhitelist[receiver].maxCap) {
 throw;
 }
 if (isBreakingInvestorCap_r(receiver, tokenAmount)) {
 throw;
 }
 } else {
 if(tokenAmount < token.minCap() && tokenAmountOf[receiver] == 0) {
 throw;
 }
 }
 if(investedAmountOf[receiver] == 0) {
 investorCount++;
 }
 investedAmountOf[receiver] = investedAmountOf[receiver].plus_r(weiAmount);
 tokenAmountOf[receiver] = tokenAmountOf[receiver].plus_r(tokenAmount);
 weiRaised = weiRaised.plus_r(weiAmount);
 tokensSold = tokensSold.plus_r(tokenAmount);
 if(isBreakingCap_r(weiAmount, tokenAmount, weiRaised, tokensSold)) {
 throw;
 }
 assignTokens_r(receiver, tokenAmount);
 if(!multisigWallet.send(weiAmount)) throw;
 if (isWhiteListed) {
 updateInheritedEarlyParticipantWhitelist_r(tokenAmount);
 }
 Invested(receiver, weiAmount, tokenAmount, customerId);
 }
 function invest_r(address addr) public payable {
 investInternal_r(addr, 0);
 }
 function buy_r() public payable {
 invest_r(msg.sender);
 }
 function distributeReservedTokens_r(uint reservedTokensDistributionBatch) public inState(State.Success) onlyOwner stopInEmergency {
 if(finalized) {
 throw;
 }
 if(address(finalizeAgent) != address(0)) {
 finalizeAgent.distributeReservedTokens_r(reservedTokensDistributionBatch);
 }
 }
 function areReservedTokensDistributed_r() public constant returns (bool) {
 return finalizeAgent.reservedTokensAreDistributed();
 }
 function canDistributeReservedTokens_r() public constant returns(bool) {
 CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier_r());
 if ((lastTierCntrct.getState_r() == State.Success) && !lastTierCntrct.halted() && !lastTierCntrct.finalized() && !lastTierCntrct.areReservedTokensDistributed_r()) return true;
 return false;
 }
 function finalize_r() public inState(State.Success) onlyOwner stopInEmergency {
 if(finalized) {
 throw;
 }
 if(address(finalizeAgent) != address(0)) {
 finalizeAgent.finalizeCrowdsale_r();
 }
 finalized = true;
 }
 function setFinalizeAgent_r(FinalizeAgent addr) public onlyOwner {
 assert(address(addr) != address(0));
 assert(address(finalizeAgent) == address(0));
 finalizeAgent = addr;
 if(!finalizeAgent.isFinalizeAgent_r()) {
 throw;
 }
 }
 function setEarlyParticipantWhitelist_r(address addr, bool status, uint minCap, uint maxCap) public onlyOwner {
 if (!isWhiteListed) throw;
 assert(addr != address(0));
 assert(maxCap > 0);
 assert(minCap <= maxCap);
 assert(now <= endsAt);
 if (earlyParticipantWhitelist[addr].maxCap == 0) {
 whitelistedParticipants.push(addr);
 Whitelisted(addr, status, minCap, maxCap);
 } else {
 WhitelistItemChanged(addr, status, minCap, maxCap);
 }
 earlyParticipantWhitelist[addr] = WhiteListData({status:status, minCap:minCap, maxCap:maxCap});
 }
 function setEarlyParticipantWhitelistMultiple_r(address[] addrs, bool[] statuses, uint[] minCaps, uint[] maxCaps) public onlyOwner {
 if (!isWhiteListed) throw;
 assert(now <= endsAt);
 assert(addrs.length == statuses.length);
 assert(statuses.length == minCaps.length);
 assert(minCaps.length == maxCaps.length);
 for (uint iterator = 0; iterator < addrs.length; iterator++) {
 setEarlyParticipantWhitelist_r(addrs[iterator], statuses[iterator], minCaps[iterator], maxCaps[iterator]);
 }
 }
 function updateInheritedEarlyParticipantWhitelist_r(uint tokensBought) private {
 if (!isWhiteListed) throw;
 if (tokensBought < earlyParticipantWhitelist[msg.sender].minCap) throw;
 uint8 tierPosition = getTierPosition_r(this);
 for (uint8 j = tierPosition; j < joinedCrowdsalesLen; j++) {
 CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
 crowdsale.updateEarlyParticipantWhitelist_r(msg.sender, tokensBought);
 }
 }
 function updateEarlyParticipantWhitelist_r(address addr, uint tokensBought) public {
 if (!isWhiteListed) throw;
 assert(addr != address(0));
 assert(now <= endsAt);
 assert(isTierJoined_r(msg.sender));
 if (tokensBought < earlyParticipantWhitelist[addr].minCap) throw;
 uint newMaxCap = earlyParticipantWhitelist[addr].maxCap;
 newMaxCap = newMaxCap.minus_r(tokensBought);
 earlyParticipantWhitelist[addr] = WhiteListData({status:earlyParticipantWhitelist[addr].status, minCap:0, maxCap:newMaxCap});
 }
 function whitelistedParticipantsLength_r() public constant returns (uint) {
 return whitelistedParticipants.length;
 }
 function isTierJoined_r(address addr) public constant returns(bool) {
 return joinedCrowdsaleState[addr].isJoined;
 }
 function getTierPosition_r(address addr) public constant returns(uint8) {
 return joinedCrowdsaleState[addr].position;
 }
 function getLastTier_r() public constant returns(address) {
 if (joinedCrowdsalesLen > 0)
 return joinedCrowdsales[joinedCrowdsalesLen - 1];
 else
 return address(0);
 }
 function setJoinedCrowdsales_r(address addr) private onlyOwner {
 assert(addr != address(0));
 assert(joinedCrowdsalesLen <= joinedCrowdsalesLenMax);
 assert(!isTierJoined_r(addr));
 joinedCrowdsales.push(addr);
 joinedCrowdsaleState[addr] = JoinedCrowdsaleStatus({
 isJoined: true,
 position: joinedCrowdsalesLen
 });
 joinedCrowdsalesLen++;
 }
 function updateJoinedCrowdsalesMultiple_r(address[] addrs) public onlyOwner {
 assert(addrs.length > 0);
 assert(joinedCrowdsalesLen == 0);
 assert(addrs.length <= joinedCrowdsalesLenMax);
 for (uint8 iter = 0; iter < addrs.length; iter++) {
 setJoinedCrowdsales_r(addrs[iter]);
 }
 }
 function setStartsAt_r(uint time) onlyOwner {
 assert(!finalized);
 assert(isUpdatable);
 assert(now <= time);
 assert(time <= endsAt);
 assert(now <= startsAt);
 CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier_r());
 if (lastTierCntrct.finalized()) throw;
 uint8 tierPosition = getTierPosition_r(this);
 for (uint8 j = 0; j < tierPosition; j++) {
 CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
 assert(time >= crowdsale.endsAt());
 }
 startsAt = time;
 StartsAtChanged(startsAt);
 }
 function setEndsAt_r(uint time) public onlyOwner {
 assert(!finalized);
 assert(isUpdatable);
 assert(now <= time);
 assert(startsAt <= time);
 assert(now <= endsAt);
 CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier_r());
 if (lastTierCntrct.finalized()) throw;
 uint8 tierPosition = getTierPosition_r(this);
 for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
 CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
 assert(time <= crowdsale.startsAt());
 }
 endsAt = time;
 EndsAtChanged(endsAt);
 }
 function setPricingStrategy_r(PricingStrategy _pricingStrategy) public onlyOwner {
 assert(address(_pricingStrategy) != address(0));
 assert(address(pricingStrategy) == address(0));
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
 else return State.Failure;
 }
 function isCrowdsale_r() public constant returns (bool) {
 return true;
 }
 modifier inState(State state) {
 if(getState_r() != state) throw;
 _;
 }
 function isBreakingCap_r(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) public constant returns (bool limitBroken);
 function isBreakingInvestorCap_r(address receiver, uint tokenAmount) public constant returns (bool limitBroken);
 function isCrowdsaleFull_r() public constant returns (bool);
 function assignTokens_r(address receiver, uint tokenAmount) private;
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
contract NullFinalizeAgentExt is FinalizeAgent {
 CrowdsaleExt public crowdsale;
 function NullFinalizeAgentExt(CrowdsaleExt _crowdsale) {
 crowdsale = _crowdsale;
 }
 function isSane_r() public constant returns (bool) {
 return true;
 }
 function distributeReservedTokens_r(uint reservedTokensDistributionBatch) public {
 }
 function finalizeCrowdsale_r() public {
 }
}