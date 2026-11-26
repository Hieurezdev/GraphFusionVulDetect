pragma solidity ^0.4.11;
contract PonziUnlimited {
 modifier onlyBy(address _account)
 {
 require(msg.sender == _account);
 _;
 }
 event GainsCalculated(
 address receiver,
 uint payedAmount,
 uint gains,
 uint contractBalance,
 uint currentPayoutIndex
 );
 event FeesCalculated(
 uint gains,
 uint fees
 );
 event Payout(
 address receiver,
 uint value
 );
 event FeesPayout(
 uint value
 );
 event FundsDeposited(
 address depositor,
 uint amount
 );
 event ComputedGainsRate(
 address depositor,
 uint gainsRate
 );
 struct Deposit {
 address depositor;
 uint amount;
 }
 struct PayoutItem {
 address receiver;
 uint amount;
 }
 address public master;
 uint public feesRate;
 uint public numDeposits;
 uint public totalDeposited;
 uint public totalGains;
 uint public lastDeposit;
 uint public profitsRatePercent;
 uint public referedRateBonus;
 uint public refereesRateBonus;
 bool public active;
 uint private currentPayoutIndex;
 mapping (uint => Deposit) public depositsStack;
 mapping (address => uint) public refereesCount;
 mapping (address => uint) public pendingReferals;
 mapping (address => uint) public addressGains;
 mapping (address => uint[]) public addressPositions;
 mapping (address => address) public refereeInvitations;
 mapping (address => bool) public refereds;
 PayoutItem[] public lastPayouts;
 function PonziUnlimited() {
 master = msg.sender;
 feesRate = 10;
 numDeposits = 0;
 currentPayoutIndex = 0;
 profitsRatePercent = 15;
 referedRateBonus = 5;
 refereesRateBonus = 5;
 totalDeposited = 0;
 totalGains = 0;
 active = false;
 }
 function getPayout_r(uint index) constant returns (address receiver, uint amount) {
 PayoutItem memory payout_r;
 payout_r = lastPayouts[index];
 return (payout_r.receiver, payout_r.amount);
 }
 function getLastPayouts_r() constant returns (address[10] lastReceivers, uint[10] lastAmounts) {
 uint j = 0;
 PayoutItem memory currentPayout;
 uint length = lastPayouts.length;
 uint startIndex = 0;
 if (length > 10) {
 startIndex = length - 10;
 }
 for(uint i = startIndex; i < length; i++) {
 currentPayout = lastPayouts[i];
 lastReceivers[j] = currentPayout.receiver;
 lastAmounts[j] = currentPayout.amount;
 j++;
 }
 return (lastReceivers, lastAmounts);
 }
 function getMaster_r() constant returns (address masterAddress) {
 return master;
 }
 function getnumDeposits_r() constant returns (uint) {
 return numDeposits;
 }
 function getContractMetrics_r() constant returns (uint, uint, uint, uint, bool) {
 return (
 this.balance,
 totalDeposited,
 totalGains,
 numDeposits,
 active
 );
 }
 function setActive_r(bool activate) onlyBy(master) returns (bool) {
 active = activate;
 if (active) {
 dispatchGains_r();
 }
 return active;
 }
 function inviteReferee_r(address referer, address referee) returns (bool success) {
 success = true;
 refereeInvitations[referee] = referer;
 pendingReferals[referer] += 1;
 return success;
 }
 function createReferee_r(address referer, address referee) private {
 refereds[referee] = true;
 refereesCount[referer] += 1;
 pendingReferals[referer] -= 1;
 }
 function checkIfReferee_r(address referee) private {
 address referer = refereeInvitations[referee];
 if(referer != address(0)) {
 createReferee_r(referer, referee);
 delete refereeInvitations[referee];
 }
 }
 function getAddressGains_r(address addr) constant returns(uint) {
 return addressGains[addr];
 }
 function getCurrentPayoutIndex_r() constant returns(uint) {
 return currentPayoutIndex;
 }
 function getEarliestPosition_r(address addr) constant returns(uint[]) {
 return addressPositions[addr];
 }
 function deposit_r() payable {
 if(msg.value <= 0) throw;
 lastDeposit = block.timestamp;
 depositsStack[numDeposits] = Deposit(msg.sender, msg.value);
 totalDeposited += msg.value;
 checkIfReferee_r(msg.sender);
 FundsDeposited(msg.sender, msg.value);
 ++numDeposits;
 addressPositions[msg.sender].push(numDeposits);
 if(active) {
 dispatchGains_r();
 }
 }
 function resetBonuses_r(address depositor) private {
 resetReferee_r(depositor);
 resetReferedCount_r(depositor);
 }
 function setGainsRate_r(uint gainsRate) onlyBy(master) {
 profitsRatePercent = gainsRate;
 }
 function resetReferee_r(address depositor) private {
 refereds[depositor] = false;
 }
 function resetReferedCount_r(address depositor) private {
 refereesCount[depositor] = 0;
 }
 function getAccountReferalsStats_r(address addr) constant returns(uint, uint) {
 return (
 getPendingReferals_r(addr),
 getReferedCount_r(addr)
 );
 }
 function computeGainsRate_r(address depositor) constant returns(uint gainsPercentage) {
 gainsPercentage = profitsRatePercent;
 if(isReferee_r(depositor)) {
 gainsPercentage += referedRateBonus;
 }
 gainsPercentage += getReferedCount_r(depositor) * refereesRateBonus;
 ComputedGainsRate(depositor, gainsPercentage);
 return gainsPercentage;
 }
 function computeGains_r(Deposit deposit_r) private constant returns (uint gains, uint fees) {
 gains = 0;
 if(deposit_r.amount > 0) {
 gains = (deposit_r.amount * computeGainsRate_r(deposit_r.depositor)) / 100;
 fees = (gains * feesRate) / 100;
 GainsCalculated(deposit_r.depositor, deposit_r.amount, gains, this.balance, currentPayoutIndex);
 FeesCalculated(gains, fees);
 }
 return (
 gains - fees,
 fees
 );
 }
 function isReferee_r(address referee) private constant returns (bool) {
 return refereds[referee];
 }
 function getReferedCount_r(address referer) private constant returns (uint referedsCount) {
 referedsCount = refereesCount[referer];
 return referedsCount;
 }
 function getPendingReferals_r(address addr) private constant returns (uint) {
 return pendingReferals[addr];
 }
 function addNewPayout_r(PayoutItem payout_r) private {
 lastPayouts.length++;
 lastPayouts[lastPayouts.length-1] = payout_r;
 }
 function payout_r(Deposit deposit_r) private{
 var (gains, fees) = computeGains_r(deposit_r);
 bool success = false;
 bool feesSuccess = false;
 uint payableAmount = deposit_r.amount + gains;
 address currentDepositor = deposit_r.depositor;
 if(gains > 0 && this.balance > payableAmount) {
 success = currentDepositor.send( payableAmount );
 if (success) {
 Payout(currentDepositor, payableAmount);
 addNewPayout_r(PayoutItem(currentDepositor, payableAmount));
 feesSuccess = master.send(fees);
 if(feesSuccess) {
 FeesPayout(fees);
 }
 resetBonuses_r(currentDepositor);
 addressGains[currentDepositor] += gains;
 totalGains += gains;
 currentPayoutIndex ++;
 }
 }
 }
 function dispatchGains_r() {
 for (uint i = currentPayoutIndex; i<numDeposits; i++){
 payout_r(depositsStack[i]);
 }
 }
 function() payable {
 deposit_r();
 }
}