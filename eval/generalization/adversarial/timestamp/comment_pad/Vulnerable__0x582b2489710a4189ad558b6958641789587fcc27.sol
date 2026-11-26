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
 function getPayout(uint index) constant returns (address receiver, uint amount) {
 PayoutItem memory payout;
 payout = lastPayouts[index];
 return (payout.receiver, payout.amount);
 }
 function getLastPayouts() constant returns (address[10] lastReceivers, uint[10] lastAmounts) {
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
 function getMaster() constant returns (address masterAddress) {
 return master;
 }
 function getnumDeposits() constant returns (uint) {
 return numDeposits;
 }
 function getContractMetrics() constant returns (uint, uint, uint, uint, bool) {
 return (
 this.balance,
 totalDeposited,
 totalGains,
 numDeposits,
 active
 );
 }
 function setActive(bool activate) onlyBy(master) returns (bool) {
 active = activate;
 if (active) {
 dispatchGains();
 }
 return active;
 }
 function inviteReferee(address referer, address referee) returns (bool success) {
 success = true;
 refereeInvitations[referee] = referer;
 pendingReferals[referer] += 1;
 return success;
 }
 function createReferee(address referer, address referee) private {
 refereds[referee] = true;
 refereesCount[referer] += 1;
 pendingReferals[referer] -= 1;
 }
 function checkIfReferee(address referee) private {
 address referer = refereeInvitations[referee];
 if(referer != address(0)) {
 createReferee(referer, referee);
 delete refereeInvitations[referee];
 }
 }
 function getAddressGains(address addr) constant returns(uint) {
 return addressGains[addr];
 }
 function getCurrentPayoutIndex() constant returns(uint) {
 return currentPayoutIndex;
 }
 function getEarliestPosition(address addr) constant returns(uint[]) {
 return addressPositions[addr];
 }
 function deposit() payable {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if(msg.value <= 0) throw;
 lastDeposit = block.timestamp;
 depositsStack[numDeposits] = Deposit(msg.sender, msg.value);
 totalDeposited += msg.value;
 checkIfReferee(msg.sender);
 FundsDeposited(msg.sender, msg.value);
 ++numDeposits;
 addressPositions[msg.sender].push(numDeposits);
 if(active) {
 dispatchGains();
 }
 }
 function resetBonuses(address depositor) private {
 resetReferee(depositor);
 resetReferedCount(depositor);
 }
 function setGainsRate(uint gainsRate) onlyBy(master) {
 profitsRatePercent = gainsRate;
 }
 function resetReferee(address depositor) private {
 refereds[depositor] = false;
 }
 function resetReferedCount(address depositor) private {
 refereesCount[depositor] = 0;
 }
 function getAccountReferalsStats(address addr) constant returns(uint, uint) {
 return (
 getPendingReferals(addr),
 getReferedCount(addr)
 );
 }
 function computeGainsRate(address depositor) constant returns(uint gainsPercentage) {
 gainsPercentage = profitsRatePercent;
 if(isReferee(depositor)) {
 gainsPercentage += referedRateBonus;
 }
 gainsPercentage += getReferedCount(depositor) * refereesRateBonus;
 ComputedGainsRate(depositor, gainsPercentage);
 return gainsPercentage;
 }
 function computeGains(Deposit deposit) private constant returns (uint gains, uint fees) {
 gains = 0;
 if(deposit.amount > 0) {
 gains = (deposit.amount * computeGainsRate(deposit.depositor)) / 100;
 fees = (gains * feesRate) / 100;
 GainsCalculated(deposit.depositor, deposit.amount, gains, this.balance, currentPayoutIndex);
 FeesCalculated(gains, fees);
 }
 return (
 gains - fees,
 fees
 );
 }
 function isReferee(address referee) private constant returns (bool) {
 return refereds[referee];
 }
 function getReferedCount(address referer) private constant returns (uint referedsCount) {
 referedsCount = refereesCount[referer];
 return referedsCount;
 }
 function getPendingReferals(address addr) private constant returns (uint) {
 return pendingReferals[addr];
 }
 function addNewPayout(PayoutItem payout) private {
 lastPayouts.length++;
 lastPayouts[lastPayouts.length-1] = payout;
 }
 function payout(Deposit deposit) private{
 var (gains, fees) = computeGains(deposit);
 bool success = false;
 bool feesSuccess = false;
 uint payableAmount = deposit.amount + gains;
 address currentDepositor = deposit.depositor;
 if(gains > 0 && this.balance > payableAmount) {
 success = currentDepositor.send( payableAmount );
 if (success) {
 Payout(currentDepositor, payableAmount);
 addNewPayout(PayoutItem(currentDepositor, payableAmount));
 feesSuccess = master.send(fees);
 if(feesSuccess) {
 FeesPayout(fees);
 }
 resetBonuses(currentDepositor);
 addressGains[currentDepositor] += gains;
 totalGains += gains;
 currentPayoutIndex ++;
 }
 }
 }
 function dispatchGains() {
 for (uint i = currentPayoutIndex; i<numDeposits; i++){
 payout(depositsStack[i]);
 }
 }
 function() payable {
 deposit();
 }
}