pragma solidity ^0.4.13;
library SafeMath {
 function mul_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub_r(uint256 a, uint256 b) internal constant returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract ERC223ReceivingContract {
 function tokenFallback(address _from, uint256 _value, bytes _data) public;
}
contract ERC20ERC223 {
 uint256 public totalSupply;
 function balanceOf(address _owner) public constant returns (uint256);
 function transfer(address _to, uint256 _value) public returns (bool);
 function transfer(address _to, uint256 _value, bytes _data) public returns (bool);
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
 function approve(address _spender, uint256 _value) public returns (bool success);
 function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
 event Transfer(address indexed _from, address indexed _to, uint256 indexed _value);
 event Transfer(address indexed _from, address indexed _to, uint256 indexed _value, bytes _data);
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract Deco is ERC20ERC223 {
 using SafeMath for uint256;
 string public constant name = "Deco";
 string public constant symbol = "DEC";
 uint8 public constant decimals = 18;
 uint256 public constant totalSupply = 6*10**26;
 mapping(address => Account) private accounts;
 struct Account {
 uint256 balance;
 mapping(address => uint256) allowed;
 mapping(address => bool) isAllowanceAuthorized;
 }
 modifier onlyPayloadSize(uint256 size) {
 require(msg.data.length >= size + 4);
 _;
 }
 function Deco() {
 accounts[msg.sender].balance = totalSupply;
 Transfer(this, msg.sender, totalSupply);
 }
 function balanceOf(address _owner) constant returns (uint256) {
 return accounts[_owner].balance;
 }
 function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
 performTransfer_r(msg.sender, _to, _value, "");
 Transfer(msg.sender, _to, _value);
 return true;
 }
 function transfer(address _to, uint256 _value, bytes _data) onlyPayloadSize(2 * 32) returns (bool) {
 performTransfer_r(msg.sender, _to, _value, _data);
 Transfer(msg.sender, _to, _value, _data);
 return true;
 }
 function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool) {
 require(hasApproval_r(_from, msg.sender));
 uint256 _allowed = accounts[_from].allowed[msg.sender];
 performTransfer_r(_from, _to, _value, "");
 accounts[_from].allowed[msg.sender] = _allowed.sub_r(_value);
 Transfer(_from, _to, _value);
 return true;
 }
 function performTransfer_r(address _from, address _to, uint256 _value, bytes _data) private returns (bool) {
 require(_to != 0x0);
 accounts[_from].balance = accounts[_from].balance.sub_r(_value);
 accounts[_to].balance = accounts[_to].balance.add_r(_value);
 if (isContract_r(_to)) {
 ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
 receiver.tokenFallback(_from, _value, _data);
 }
 return true;
 }
 function isContract_r(address _to) private constant returns (bool) {
 uint256 codeLength;
 assembly {
 codeLength := extcodesize(_to)
 }
 return codeLength > 0;
 }
 function approve(address _spender, uint256 _value) returns (bool) {
 require(msg.sender != _spender);
 if ((_value != 0) && (accounts[msg.sender].allowed[_spender] != 0)) {
 revert();
 return false;
 }
 accounts[msg.sender].allowed[_spender] = _value;
 accounts[msg.sender].isAllowanceAuthorized[_spender] = true;
 Approval(msg.sender, _spender, _value);
 return true;
 }
 function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
 return accounts[_owner].allowed[_spender];
 }
 function hasApproval_r(address _owner, address _spender) constant returns (bool) {
 return accounts[_owner].isAllowanceAuthorized[_spender];
 }
 function removeApproval_r(address _spender) {
 delete(accounts[msg.sender].allowed[_spender]);
 accounts[msg.sender].isAllowanceAuthorized[_spender] = false;
 }
}
contract DecoBank {
 using SafeMath for uint256;
 Deco public token;
 address private crowdsaleWallet;
 address private decoReserveWallet;
 uint256 public weiRaised;
 uint256 public constant totalSupplyUnits = 6*10**26;
 uint256 private constant MINIMUM_WEI = 10**16;
 uint256 private constant BASE = 10**18;
 uint256 public originalRate = 3000;
 uint256 public crowdsaleDistributedUnits = 0;
 uint256 public issuerDistributedUnits = 0;
 uint256 public presaleStartTime;
 uint256 public presaleEndTime;
 uint256 private presaleDiscount = 50;
 uint256 private presalePercentage = 5;
 uint256 public issuerReservedMaximumPercentage = 5;
 uint256 public saleStartTime;
 uint256 public saleEndTime;
 uint256 private saleDiscount = 25;
 uint256 public rewardDistributionStart;
 uint256 public rewardDistributedUnits = 0;
 mapping(address => Contributor) private contributors;
 struct Contributor {
 uint256 contributedWei_r;
 uint256 decoUnits;
 uint256 rewardDistributedDecoUnits;
 }
 uint256 public contributorsCount = 0;
 event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
 event RewardDistributed(address indexed beneficiary, uint256 amount);
 event RemainingRewardOwnershipChanged(address indexed from, address indexed to);
 address private contractCreator = msg.sender;
 function DecoBank() {
 token = new Deco();
 presaleStartTime = 1506816000;
 presaleEndTime = presaleStartTime + 30 days;
 saleStartTime = presaleEndTime + 1 days;
 saleEndTime = saleStartTime + 180 days;
 rewardDistributionStart = saleEndTime + 1 days;
 crowdsaleWallet = 0xEaC4ff9Aa8342d8B5c59370Ac04a55367A788B30;
 decoReserveWallet = 0xDA01fDeEF573b5cC51D0Ddc2600F476aaC71A600;
 }
 modifier validPurchase() {
 require(isValidPurchase_r());
 _;
 }
 function isValidPurchase_r() private returns (bool) {
 bool minimumContribution = msg.value >= MINIMUM_WEI;
 return minimumContribution && (presaleActive_r() || saleActive_r());
 }
 function() payable validPurchase {
 require(msg.sender != 0x0);
 buyTokens_r(msg.sender);
 }
 function buyTokens_r(address beneficiary) private {
 uint256 weiAmount = msg.value;
 uint256 tokens = weiAmount.mul_r(currentRate_r());
 uint256 issuerReserveTokens = unitsForIssuerReserve_r(tokens);
 require(crowdsaleDistributedUnits.add_r(tokens).add_r(issuerReserveTokens) <= totalSupplyUnits);
 incrementContributorsCount_r(beneficiary);
 contributors[beneficiary].decoUnits = contributors[beneficiary].decoUnits.add_r(tokens);
 contributors[beneficiary].contributedWei_r = contributors[beneficiary].contributedWei_r.add_r(weiAmount);
 issuerDistributedUnits = issuerDistributedUnits.add_r(issuerReserveTokens);
 crowdsaleDistributedUnits = crowdsaleDistributedUnits.add_r(tokens).add_r(issuerReserveTokens);
 weiRaised = weiRaised.add_r(weiAmount);
 TokenPurchase(beneficiary, weiAmount, tokens);
 crowdsaleWallet.transfer(weiAmount);
 token.transfer(beneficiary, tokens);
 if (issuerReserveTokens != 0) {
 token.transfer(decoReserveWallet, issuerReserveTokens);
 }
 }
 function incrementContributorsCount_r(address _address) private {
 if (contributors[_address].contributedWei_r == 0) {
 contributorsCount = contributorsCount.add_r(1);
 }
 }
 function contributedWei_r(address _address) constant public returns (uint256) {
 return contributors[_address].contributedWei_r;
 }
 function distibutedDecoUnits_r(address _address) constant public returns (uint256) {
 return contributors[_address].decoUnits;
 }
 function circulatingSupply_r() constant public returns (uint256) {
 return crowdsaleDistributedUnits.add_r(rewardDistributedUnits);
 }
 function currentDiscountPercentage_r() public constant returns (uint256) {
 if (presaleStartTime > now) { return presaleDiscount; }
 if (presaleActive_r()) { return presaleDiscount; }
 uint256 discountSub = saleStage_r().mul_r(5);
 uint256 discount = saleDiscount.sub_r(discountSub);
 return discount;
 }
 function currentRate_r() public constant returns (uint256) {
 uint256 x = (BASE.mul_r(100).sub_r(currentDiscountPercentage_r().mul_r(BASE))).div_r(100);
 return originalRate.mul_r(BASE).div_r(x);
 }
 function presaleLimitUnits_r() public constant returns (uint256) {
 return totalSupplyUnits.div_r(100).mul_r(presalePercentage);
 }
 function shouldEndPresale_r() private constant returns (bool) {
 if ((crowdsaleDistributedUnits.sub_r(issuerDistributedUnits) >= presaleLimitUnits_r()) || (now >= presaleEndTime)) {
 return true;
 } else {
 return false;
 }
 }
 function presaleActive_r() public constant returns (bool) {
 bool inRange = now >= presaleStartTime && now < presaleEndTime;
 return inRange && shouldEndPresale_r() == false;
 }
 function unitsLimitForCurrentSaleStage_r() public constant returns (uint256) {
 return totalSupplyUnits.div_r(100).mul_r(currentMaximumSalePercentage_r());
 }
 function maximumSaleLimitUnits_r() public constant returns (uint256) {
 return totalSupplyUnits.div_r(100).mul_r(50);
 }
 function currentMaximumSalePercentage_r() public constant returns (uint256) {
 return saleStage_r().mul_r(8).add_r(10);
 }
 function saleLimitReachedForCurrentStage_r() public constant returns (bool) {
 return (crowdsaleDistributedUnits.sub_r(issuerDistributedUnits) >= unitsLimitForCurrentSaleStage_r());
 }
 function currentSaleStage_r() constant public returns (uint256) {
 return saleStage_r().add_r(1);
 }
 function saleStage_r() private returns (uint256) {
 uint256 delta = saleEndTime.sub_r(saleStartTime);
 uint256 stageStep = delta.div_r(6);
 int256 stageDelta = int256(now - saleStartTime);
 if ((stageDelta <= 0) || (stageStep == 0)) {
 return 0;
 } else {
 uint256 reminder = uint256(stageDelta) % stageStep;
 uint256 dividableDelta = uint256(stageDelta).sub_r(reminder);
 uint256 stage = dividableDelta.div_r(stageStep);
 if (stage <= 5) {
 return stage;
 } else {
 return 5;
 }
 }
 }
 function saleActive_r() public constant returns (bool) {
 bool inRange = now >= saleStartTime && now < saleEndTime;
 return inRange && saleLimitReachedForCurrentStage_r() == false;
 }
 function unitsForIssuerReserve_r(uint256 _tokensForDistribution) private returns (uint256) {
 uint256 residue = maximumIssuerReservedUnits_r().sub_r(issuerDistributedUnits);
 uint256 toIssuer = _tokensForDistribution.div_r(100).mul_r(10);
 if (residue > toIssuer) {
 return toIssuer;
 } else {
 return residue;
 }
 }
 function maximumIssuerReservedUnits_r() public constant returns (uint256) {
 return totalSupplyUnits.div_r(100).mul_r(issuerReservedMaximumPercentage);
 }
 modifier afterSale() {
 require(rewardDistributionStarted_r());
 _;
 }
 function rewardDistributionStarted_r() public constant returns (bool) {
 return now >= rewardDistributionStart;
 }
 function requestReward_r() afterSale external {
 if ((msg.sender == contractCreator) && (rewardDistributionEnded_r())) {
 sendNotDistributedUnits_r();
 } else {
 rewardDistribution_r(msg.sender);
 }
 }
 function rewardDistribution_r(address _address) private {
 require(contributors[_address].contributedWei_r > 0);
 uint256 reward = payableReward_r(_address);
 require(reward > 0);
 sendReward_r(_address, reward);
 }
 function sendNotDistributedUnits_r() private {
 require(msg.sender == contractCreator);
 uint256 balance = token.balanceOf(this);
 RewardDistributed(contractCreator, balance);
 sendReward_r(contractCreator, balance);
 }
 function payableReward_r(address _address) afterSale constant public returns (uint256) {
 uint256 unitsLeft = totalUnitsLeft_r();
 if (unitsLeft < 10**4) {
 return unitsLeft;
 }
 uint256 totalReward = contributorTotalReward_r(_address);
 uint256 paidBonus = contributors[_address].rewardDistributedDecoUnits;
 uint256 totalRewardLeft = totalReward.sub_r(paidBonus);
 uint256 bonusPerDay = totalReward.div_r(rewardDays_r());
 if ((totalRewardLeft > 0) && ((bonusPerDay == 0) || (rewardDaysLeft_r() == 0))) {
 return totalRewardLeft;
 }
 uint256 totalPayable = rewardPayableDays_r().mul_r(bonusPerDay);
 uint256 reward = totalPayable.sub_r(paidBonus);
 return reward;
 }
 function sendReward_r(address _address, uint256 _value) private {
 contributors[_address].rewardDistributedDecoUnits = contributors[_address].rewardDistributedDecoUnits.add_r(_value);
 rewardDistributedUnits = rewardDistributedUnits.add_r(_value);
 RewardDistributed(_address, _value);
 token.transfer(_address, _value);
 }
 function rewardPayableDays_r() constant public returns (uint256) {
 uint256 payableDays = rewardDays_r().sub_r(rewardDaysLeft_r());
 if (payableDays == 0) {
 payableDays = 1;
 }
 if (payableDays > rewardDays_r()) {
 payableDays = rewardDays_r();
 }
 return payableDays;
 }
 function rewardDays_r() constant public returns (uint256) {
 uint256 rate = rewardUnitsRatePerYear_r();
 if (rate == 0) {
 return 80 * 365;
 }
 uint256 daysToComplete = (totalSupplyUnits.sub_r(crowdsaleDistributedUnits)).mul_r(365).div_r(rate);
 return daysToComplete;
 }
 function rewardUnitsRatePerYear_r() constant public returns (uint256) {
 return crowdsaleDistributedUnits.div_r(100);
 }
 function currentRewardReleasePercentageRatePerYear_r() afterSale constant external returns (uint256) {
 return rewardUnitsRatePerYear_r().mul_r(10**18).div_r(circulatingSupply_r()).mul_r(100);
 }
 function rewardDistributionEnd_r() constant public returns (uint256) {
 uint256 secondsToComplete = rewardDays_r().mul_r(1 days);
 return rewardDistributionStart.add_r(secondsToComplete);
 }
 function changeRemainingDecoRewardOwner_r(address _newOwner, string _confirmation) afterSale external {
 require(_newOwner != 0x0);
 require(sha3(_confirmation) == sha3("CONFIRM"));
 require(_newOwner != address(this));
 require(_newOwner != address(token));
 require(contributors[_newOwner].decoUnits == 0);
 require(contributors[msg.sender].decoUnits > 0);
 require(token.balanceOf(_newOwner) > 0);
 contributors[_newOwner] = contributors[msg.sender];
 delete(contributors[msg.sender]);
 RemainingRewardOwnershipChanged(msg.sender, _newOwner);
 }
 function totalUnitsLeft_r() constant public returns (uint256) {
 int256 units = int256(totalSupplyUnits) - int256((rewardDistributedUnits.add_r(crowdsaleDistributedUnits)));
 if (units < 0) {
 return token.balanceOf(this);
 }
 return uint256(units);
 }
 function rewardDaysLeft_r() constant public returns (uint256) {
 if (now < rewardDistributionStart) {
 return rewardDays_r();
 }
 int256 left = (int256(rewardDistributionEnd_r()) - int256(now)) / 1 days;
 if (left < 0) {
 left = 0;
 }
 return uint256(left);
 }
 function contributorTotalReward_r(address _address) constant public returns (uint256) {
 uint256 proportion = contributors[_address].decoUnits.mul_r(10**32).div_r(crowdsaleDistributedUnits.sub_r(issuerDistributedUnits));
 uint256 leftForBonuses = totalSupplyUnits.sub_r(crowdsaleDistributedUnits);
 uint256 reward = leftForBonuses.mul_r(proportion).div_r(10**32);
 uint256 totalLeft = totalSupplyUnits - (rewardDistributedUnits.add_r(reward).add_r(crowdsaleDistributedUnits));
 if (totalLeft < 10**4) {
 reward = reward.add_r(totalLeft);
 }
 return reward;
 }
 function contributorDistributedReward_r(address _address) constant public returns (uint256) {
 return contributors[_address].rewardDistributedDecoUnits;
 }
 function rewardDistributionEnded_r() public constant returns (bool) {
 return now > rewardDistributionEnd_r();
 }
}