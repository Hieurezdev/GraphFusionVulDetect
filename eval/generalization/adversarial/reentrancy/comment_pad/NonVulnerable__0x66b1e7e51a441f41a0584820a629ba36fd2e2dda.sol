pragma solidity ^0.4.18;
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 assert(c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract TheRichestWins {
 using SafeMath for uint256;
 address contractOwner;
 uint tokenStartPrice = 0.001 ether;
 uint tokenStartPrice2 = 0.001483239697419133 ether;
 uint tokenPrice;
 uint tokenPrice2;
 address tokenOwner;
 address tokenOwner2;
 uint lastBuyBlock;
 uint newRoundDelay = 40;
 address public richestPlayer;
 uint public highestPrice;
 uint public round;
 uint public flips;
 uint payoutRound;
 uint public richestRoundId;
 event Transfer(address indexed from, address indexed to, uint256 price);
 event NewRound(uint paidPrice, uint win, address winner);
 event RichestBonus(uint win, address richestPlayer);
 function TheRichestWins() public {
 contractOwner = msg.sender;
 tokenOwner = address(0);
 lastBuyBlock = block.number;
 tokenPrice = tokenStartPrice;
 tokenPrice2 = tokenStartPrice2;
 }
 function getRoundId() public view returns(uint) {
 return round*1000000+flips;
 }
 function changeNewRoundDelay(uint delay) public {
 require(contractOwner == msg.sender);
 newRoundDelay = delay;
 }
 function changeContractOwner(address newOwner) public {
 require(contractOwner == msg.sender);
 contractOwner = newOwner;
 }
 function buyToken() public payable {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 address currentOwner;
 uint256 currentPrice;
 uint256 paidTooMuch;
 uint256 payment;
 if (tokenPrice < tokenPrice2) {
 currentOwner = tokenOwner;
 currentPrice = tokenPrice;
 require(tokenOwner2 != msg.sender);
 } else {
 currentOwner = tokenOwner2;
 currentPrice = tokenPrice2;
 require(tokenOwner != msg.sender);
 }
 require(msg.value >= currentPrice);
 paidTooMuch = msg.value.sub(currentPrice);
 payment = currentPrice.div(2);
 if (tokenPrice < tokenPrice2) {
 tokenPrice = currentPrice.mul(110).div(50);
 tokenOwner = msg.sender;
 } else {
 tokenPrice2 = currentPrice.mul(110).div(50);
 tokenOwner2 = msg.sender;
 }
 lastBuyBlock = block.number;
 flips++;
 Transfer(currentOwner, msg.sender, currentPrice);
 if (currentOwner != address(0)) {
 payoutRound = getRoundId()-3;
 currentOwner.call.value(payment).gas(24000)();
 }
 if (paidTooMuch > 0)
 msg.sender.transfer(paidTooMuch);
 }
 function getBlocksToNextRound() public view returns(uint) {
 if (lastBuyBlock + newRoundDelay < block.number) {
 return 0;
 }
 return lastBuyBlock + newRoundDelay + 1 - block.number;
 }
 function getPool() public view returns(uint balance) {
 balance = this.balance;
 }
 function finishRound() public {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(tokenPrice > tokenStartPrice);
 require(lastBuyBlock + newRoundDelay < block.number);
 lastBuyBlock = block.number;
 address owner = tokenOwner;
 uint price = tokenPrice;
 if (tokenPrice2>tokenPrice) {
 owner = tokenOwner2;
 price = tokenPrice2;
 }
 uint lastPaidPrice = price.mul(50).div(110);
 uint win = this.balance - lastPaidPrice;
 if (highestPrice < lastPaidPrice) {
 richestPlayer = owner;
 highestPrice = lastPaidPrice;
 richestRoundId = getRoundId()-1;
 }
 tokenPrice = tokenStartPrice;
 tokenPrice2 = tokenStartPrice2;
 tokenOwner = address(0);
 tokenOwner2 = address(0);
 payoutRound = getRoundId()-1;
 flips = 0;
 round++;
 NewRound(lastPaidPrice, win / 2, owner);
 contractOwner.transfer((this.balance - (lastPaidPrice + win / 2) - win / 10) * 19 / 20);
 owner.call.value(lastPaidPrice + win / 2).gas(24000)();
 if (richestPlayer!=address(0)) {
 payoutRound = richestRoundId;
 RichestBonus(win / 10, richestPlayer);
 richestPlayer.call.value(win / 10).gas(24000)();
 }
 }
 function getPayoutRoundId() public view returns(uint) {
 return payoutRound;
 }
 function getPrice() public view returns(uint) {
 if (tokenPrice2<tokenPrice)
 return tokenPrice2;
 return tokenPrice;
 }
 function getCurrentData() public view returns (uint price, uint nextPrice, uint pool, address winner, address looser, bool canFinish, uint nextPool, uint win, uint nextWin) {
 winner = tokenOwner;
 looser = tokenOwner2;
 price = tokenPrice2;
 nextPrice = tokenPrice;
 if (tokenPrice2>tokenPrice) {
 winner = tokenOwner2;
 looser = tokenOwner;
 price = tokenPrice;
 nextPrice = tokenPrice2;
 }
 canFinish = (tokenPrice > tokenStartPrice) && (lastBuyBlock + newRoundDelay < block.number);
 pool = getPool();
 if (price == tokenStartPrice) {
 nextPool = pool + price;
 win = 0;
 } else if (price == tokenStartPrice2) {
 nextPool = pool + price;
 win = (pool-nextPrice.mul(50).div(110))/2;
 } else {
 nextPool = pool + price / 2;
 win = (pool-nextPrice.mul(50).div(110))/2;
 }
 nextWin = (nextPool-price)/2;
 }
}