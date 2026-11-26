pragma solidity ^0.4.2;
contract DSSafeAddSub {
 function safeToAdd(uint a, uint b) internal returns (bool) {
 return (a + b >= a);
 }
 function safeAdd(uint a, uint b) internal returns (uint) {
 require(safeToAdd(a, b));
 return a + b;
 }
 function safeToSubtract(uint a, uint b) internal returns (bool) {
 return (b <= a);
 }
 function safeSub(uint a, uint b) internal returns (uint) {
 require(safeToSubtract(a, b));
 return a - b;
 }
}
contract MyDice is DSSafeAddSub {
 modifier betIsValid(uint _betSize, uint _playerNumber) {
 require(((((_betSize * (10000-(safeSub(_playerNumber,1)))) / (safeSub(_playerNumber,1))+_betSize))*houseEdge/houseEdgeDivisor)-_betSize <= maxProfit);
 require(_playerNumber < maxNumber);
 require(_betSize >= minBet);
 _;
 }
 modifier gameIsActive {
 require(gamePaused == false);
 _;
 }
 modifier payoutsAreActive {
 require(payoutsPaused == false);
 _;
 }
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 uint constant public maxBetDivisor = 1000000;
 uint constant public houseEdgeDivisor = 1000;
 bool public gamePaused;
 address public owner;
 bool public payoutsPaused;
 uint public contractBalance;
 uint public houseEdge;
 uint public maxProfit;
 uint public maxProfitAsPercentOfHouse;
 uint public minBet;
 uint public totalBets;
 uint public totalUserProfit;
 uint private randomNumber;
 uint private maxNumber = 10000;
 uint private underNumber = 5000;
 struct Bet
 {
 address bettorAddress;
 uint betSize;
 uint betID;
 }
 uint public numElements = 0;
 Bet[] pendingBets;
 mapping (address => uint) playerPendingWithdrawals;
 event LogBetStart(uint indexed betID);
 event LogResult(uint indexed BetID, address indexed PlayerAddress, uint indexed PlayerNumber, uint DiceResult, uint Value, int Status,uint BetValue,uint targetNumber);
 event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);
 function MyDice() {
 owner = msg.sender;
 ownerSetHouseEdge(935);
 ownerSetMaxProfitAsPercentOfHouse(20000);
 ownerSetMinBet(20000000000000000);
 }
 function GetRandomNumber(uint32 seed) internal
 returns(uint randomNum)
 {
 randomNumber = randomNumber % block.timestamp + uint256(block.blockhash(block.number - 1));
 randomNumber = randomNumber + block.timestamp * block.difficulty * block.number + 1;
 randomNumber = uint(sha3(randomNumber,seed));
 return (maxNumber - randomNumber % maxNumber);
 }
 function StartRollDice(uint32 seed) public
 gameIsActive
 onlyOwner
 {
 if(numElements == 0)
 return;
 uint i = numElements - 1;
 uint randResult = GetRandomNumber(seed);
 if(randResult < underNumber){
 uint playerProfit = ((((pendingBets[i].betSize * (maxNumber-(safeSub(underNumber,1)))) / (safeSub(underNumber,1))+pendingBets[i].betSize))*houseEdge/houseEdgeDivisor)-pendingBets[i].betSize;
 contractBalance = safeSub(contractBalance, playerProfit);
 uint reward = safeAdd(playerProfit, pendingBets[i].betSize);
 totalUserProfit = totalUserProfit + playerProfit;
 LogResult(pendingBets[i].betID, pendingBets[i].bettorAddress, underNumber, randResult, reward, 1, pendingBets[i].betSize,underNumber);
 setMaxProfit();
 if(!pendingBets[i].bettorAddress.send(reward)){
 LogResult(pendingBets[i].betID, pendingBets[i].bettorAddress, underNumber, randResult, reward, 2, pendingBets[i].betSize,underNumber);
 playerPendingWithdrawals[pendingBets[i].bettorAddress] = safeAdd(playerPendingWithdrawals[pendingBets[i].bettorAddress], reward);
 }
 numElements -= 1;
 return;
 }
 if(randResult >= underNumber){
 LogResult(pendingBets[i].betID, pendingBets[i].bettorAddress, underNumber, randResult, pendingBets[i].betSize, 0, pendingBets[i].betSize,underNumber);
 contractBalance = safeAdd(contractBalance, pendingBets[i].betSize-1);
 setMaxProfit();
 if(!pendingBets[i].bettorAddress.send(1)){
 playerPendingWithdrawals[pendingBets[i].bettorAddress] = safeAdd(playerPendingWithdrawals[pendingBets[i].bettorAddress], 1);
 }
 numElements -= 1;
 return;
 }
 }
 function playerRollDice() public
 payable
 gameIsActive
 betIsValid(msg.value, underNumber)
 {
 totalBets++;
 Bet memory b = Bet(msg.sender,msg.value,totalBets);
 if(numElements == pendingBets.length) {
 pendingBets.length += 1;
 }
 pendingBets[numElements++] = b;
 LogBetStart(totalBets);
 }
 function playerWithdrawPendingTransactions() public payoutsAreActive returns (bool) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 uint withdrawAmount = playerPendingWithdrawals[msg.sender];
 playerPendingWithdrawals[msg.sender] = 0;
 if (msg.sender.call.value(withdrawAmount)()) {
 return true;
 } else {
 playerPendingWithdrawals[msg.sender] = withdrawAmount;
 return false;
 }
 }
 function playerGetPendingTxByAddress(address addressToCheck) public constant returns (uint) {
 return playerPendingWithdrawals[addressToCheck];
 }
 function setMaxProfit() internal {
 maxProfit = (contractBalance*maxProfitAsPercentOfHouse)/maxBetDivisor;
 }
 function ()
 payable
 {
 playerRollDice();
 }
 function ownerAddBankroll()
 payable
 onlyOwner
 {
 contractBalance = safeAdd(contractBalance, msg.value);
 setMaxProfit();
 }
 function getcontractBalance() public
 onlyOwner
 returns(uint)
 {
 return contractBalance;
 }
 function ownerSetHouseEdge(uint newHouseEdge) public
 onlyOwner
 {
 houseEdge = newHouseEdge;
 }
 function getHouseEdge() public
 onlyOwner
 returns(uint)
 {
 return houseEdge;
 }
 function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
 onlyOwner
 {
 require(newMaxProfitAsPercent <= 50000);
 maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
 setMaxProfit();
 }
 function getMaxProfitAsPercentOfHouse() public
 onlyOwner
 returns(uint)
 {
 return maxProfitAsPercentOfHouse;
 }
 function ownerSetMinBet(uint newMinimumBet) public
 onlyOwner
 {
 minBet = newMinimumBet;
 }
 function getMinBet() public
 onlyOwner
 returns(uint)
 {
 return minBet;
 }
 function ownerTransferEther(address sendTo, uint amount) public
 onlyOwner
 {
 contractBalance = safeSub(contractBalance, amount);
 setMaxProfit();
 require(sendTo.send(amount));
 LogOwnerTransfer(sendTo, amount);
 }
 function ownerPauseGame(bool newStatus) public
 onlyOwner
 {
 gamePaused = newStatus;
 }
 function ownerPausePayouts(bool newPayoutStatus) public
 onlyOwner
 {
 payoutsPaused = newPayoutStatus;
 }
 function ownerChangeOwner(address newOwner) public
 onlyOwner
 {
 owner = newOwner;
 }
 function ownerkill() public
 onlyOwner
 {
 suicide(owner);
 }
}