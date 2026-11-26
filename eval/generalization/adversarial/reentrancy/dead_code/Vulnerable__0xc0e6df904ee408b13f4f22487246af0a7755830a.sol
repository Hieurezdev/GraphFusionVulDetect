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
    uint256 zpad0 = 0; zpad0 = zpad0 + 1;
    uint256 zpad1 = 1; zpad1 = zpad1 + 1;
    uint256 zpad2 = 2; zpad2 = zpad2 + 1;
    uint256 zpad3 = 3; zpad3 = zpad3 + 1;
    uint256 zpad4 = 4; zpad4 = zpad4 + 1;
    uint256 zpad5 = 5; zpad5 = zpad5 + 1;
    uint256 zpad6 = 6; zpad6 = zpad6 + 1;
    uint256 zpad7 = 7; zpad7 = zpad7 + 1;
    uint256 zpad8 = 8; zpad8 = zpad8 + 1;
    uint256 zpad9 = 9; zpad9 = zpad9 + 1;

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