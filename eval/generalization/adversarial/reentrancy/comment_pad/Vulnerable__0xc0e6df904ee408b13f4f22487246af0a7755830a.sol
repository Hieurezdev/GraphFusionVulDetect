pragma solidity ^0.4.25;
contract Multiplier2 {
 address constant private FATHER = 0x7CDfA222f37f5C4CCe49b3bBFC415E8C911D1cD8;
 address constant private TECH_AND_PROMO = 0xdA149b17C154e964456553C749B7B4998c152c9E;
 uint constant public FATHER_PERCENT = 6;
 uint constant public TECH_AND_PROMO_PERCENT = 1;
 uint constant public MAX_INVESTMENT = 3 ether;
 uint constant public MULTIPLIER = 111;
 struct Deposit {
 address depositor;
 uint128 deposit;
 uint128 expect;
 }
 Deposit[] private queue;
 uint public currentReceiverIndex = 0;
 mapping(address => uint) public numInQueue;
 function () public payable {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if(msg.value > 0 && msg.sender != FATHER){
 require(gasleft() >= 250000, "We require more gas!");
 require(msg.value <= MAX_INVESTMENT);
 uint donation = msg.value*FATHER_PERCENT/100;
 require(FATHER.call.value(donation).gas(gasleft())());
 require(numInQueue[msg.sender] == 0, "Only one deposit at a time!");
 queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/100)));
 numInQueue[msg.sender] = queue.length;
 uint support = msg.value*TECH_AND_PROMO_PERCENT/100;
 TECH_AND_PROMO.send(support);
 pay();
 }
 }
 function pay() private {
 uint128 money = uint128(address(this).balance);
 for(uint i=currentReceiverIndex; i<queue.length; i++){
 Deposit storage dep = queue[i];
 if(money >= dep.expect){
 dep.depositor.send(dep.expect);
 money -= dep.expect;
 delete numInQueue[dep.depositor];
 delete queue[i];
 }else{
 dep.depositor.send(money);
 dep.expect -= money;
 break;
 }
 if(gasleft() <= 50000)
 break;
 }
 currentReceiverIndex = i;
 }
 function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect){
 Deposit storage dep = queue[idx];
 return (dep.depositor, dep.deposit, dep.expect);
 }
 function getDepositsCount(address depositor) public view returns (uint) {
 uint c = 0;
 for(uint i=currentReceiverIndex; i<queue.length; ++i){
 if(queue[i].depositor == depositor)
 c++;
 }
 return c;
 }
 function getDeposits(address depositor) public view returns (uint[] idxs, uint128[] deposits, uint128[] expects) {
 uint c = getDepositsCount(depositor);
 idxs = new uint[](c);
 deposits = new uint128[](c);
 expects = new uint128[](c);
 if(c > 0) {
 uint j = 0;
 for(uint i=currentReceiverIndex; i<queue.length; ++i){
 Deposit storage dep = queue[i];
 if(dep.depositor == depositor){
 idxs[j] = i;
 deposits[j] = dep.deposit;
 expects[j] = dep.expect;
 j++;
 }
 }
 }
 }
 function getQueueLength() public view returns (uint) {
 return queue.length - currentReceiverIndex;
 }
}