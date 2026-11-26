pragma solidity ^0.4.25;
contract Ownable {
 address private _owner;
 event OwnershipTransferred(
 address indexed previousOwner,
 address indexed newOwner
 );
 constructor() internal {
 _owner = msg.sender;
 emit OwnershipTransferred(address(0), _owner);
 }
 function owner() public view returns(address) {
 return _owner;
 }
 modifier onlyOwner() {
 require(isOwner());
 _;
 }
 function isOwner() public view returns(bool) {
 return msg.sender == _owner;
 }
 function renounceOwnership() public onlyOwner {
 emit OwnershipTransferred(_owner, address(0));
 _owner = address(0);
 }
 function transferOwnership(address newOwner) public onlyOwner {
 _transferOwnership(newOwner);
 }
 function _transferOwnership(address newOwner) internal {
 require(newOwner != address(0));
 emit OwnershipTransferred(_owner, newOwner);
 _owner = newOwner;
 }
}
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 require(c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b > 0);
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b <= a);
 uint256 c = a - b;
 return c;
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 require(c >= a);
 return c;
 }
 function mod(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b != 0);
 return a % b;
 }
}
contract distribution is Ownable {
 using SafeMath for uint256;
 event OnDepositeReceived(address investorAddress, uint value);
 event OnPaymentSent(address investorAddress, uint value);
 uint public minDeposite = 10000000000000000;
 uint public maxDeposite = 10000000000000000000;
 uint public currentPaymentIndex = 0;
 uint public amountForDistribution = 0;
 uint public percent = 120;
 uint public amountRaised = 0;
 uint public depositorsCount = 0;
 address distributorWallet;
 address promoWallet;
 address wallet1;
 address wallet2;
 address wallet3;
 struct Deposite {
 address depositor;
 uint amount;
 uint depositeTime;
 uint paimentTime;
 }
 Deposite[] public deposites;
 mapping(address => uint[]) public depositors;
 modifier onlyDistributor () {
 require(msg.sender == distributorWallet);
 _;
 }
 function setDistributorAddress(address newDistributorAddress) public onlyOwner {
 require(newDistributorAddress != address(0));
 distributorWallet = newDistributorAddress;
 }
 function setNewMinDeposite(uint newMinDeposite) public onlyOwner {
 minDeposite = newMinDeposite;
 }
 function setNewMaxDeposite(uint newMaxDeposite) public onlyOwner {
 maxDeposite = newMaxDeposite;
 }
 function setNewWallets(address newWallet1, address newWallet2, address newWallet3) public onlyOwner {
 wallet1 = newWallet1;
 wallet2 = newWallet2;
 wallet3 = newWallet3;
 }
 function setPromoWallet(address newPromoWallet) public onlyOwner {
 require(newPromoWallet != address(0));
 promoWallet = newPromoWallet;
 }
 constructor () public {
 distributorWallet = address(0xcE9F27AFDd4C277c2B3895f6a9BEf580B85C0D92);
 promoWallet = address(0xcE9F27AFDd4C277c2B3895f6a9BEf580B85C0D92);
 wallet1 = address(0x263B6DB968A7a6518967b0e5be12F79F32686975);
 wallet2 = address(0x1590C03F8B832c2eC7CE1cbBBc67c0302A1dFcAc);
 wallet3 = address(0x7f1D4085a2fC8818ddA3cd582fe7E8841c6b32A1);
 }
 function() public payable {
 require((msg.value >= minDeposite) && (msg.value <= maxDeposite));
 Deposite memory newDeposite = Deposite(msg.sender, msg.value, now, 0);
 deposites.push(newDeposite);
 if (depositors[msg.sender].length == 0) depositorsCount += 1;
 depositors[msg.sender].push(deposites.length - 1);
 amountForDistribution = amountForDistribution.add(msg.value);
 amountRaised = amountRaised.add(msg.value);
 emit OnDepositeReceived(msg.sender, msg.value);
 }
 function distribute(uint numIterations) public onlyDistributor {
 promoWallet.transfer(amountForDistribution.mul(6).div(100));
 distributorWallet.transfer(amountForDistribution.mul(1).div(100));
 wallet1.transfer(amountForDistribution.mul(1).div(100));
 wallet2.transfer(amountForDistribution.mul(1).div(100));
 wallet3.transfer(amountForDistribution.mul(1).div(100));
 uint i = 0;
 uint toSend = deposites[currentPaymentIndex].amount.mul(percent).div(100);
 while ((i <= numIterations) && (address(this).balance > toSend)) {
 deposites[currentPaymentIndex].depositor.send(toSend);
 deposites[currentPaymentIndex].paimentTime = now;
 emit OnPaymentSent(deposites[currentPaymentIndex].depositor, toSend);
 currentPaymentIndex = currentPaymentIndex.add(1);
 i = i.add(1);
 if(currentPaymentIndex < deposites.length)
 toSend = deposites[currentPaymentIndex].amount.mul(percent).div(100);
 }
 amountForDistribution = 0;
 }
 function getAllDepositorsCount() public view returns (uint) {
 return depositorsCount;
 }
 function getAllDepositesCount() public view returns (uint) {
 return deposites.length;
 }
 function getLastDepositId() public view returns (uint) {
 return deposites.length - 1;
 }
 function getDeposit(uint _id) public view returns (address, uint, uint, uint){
 return (deposites[_id].depositor, deposites[_id].amount, deposites[_id].depositeTime, deposites[_id].paimentTime);
 }
 function getDepositesCount(address depositor) public view returns (uint) {
 return depositors[depositor].length;
 }
 function getAmountRaised() public view returns (uint) {
 return amountRaised;
 }
 function getLastPayments(uint lastIndex) public view returns (address, uint, uint) {
 uint depositeIndex = currentPaymentIndex.sub(lastIndex).sub(1);
 require(depositeIndex >= 0);
 return (deposites[depositeIndex].depositor, deposites[depositeIndex].paimentTime, deposites[depositeIndex].amount.mul(percent).div(100));
 }
 function getUserDeposit(address depositor, uint depositeNumber) public view returns (uint, uint, uint) {
 return (deposites[depositors[depositor][depositeNumber]].amount,
 deposites[depositors[depositor][depositeNumber]].depositeTime,
 deposites[depositors[depositor][depositeNumber]].paimentTime);
 }
 function getDepositeTime(address depositor, uint depositeNumber) public view returns (uint) {
 return deposites[depositors[depositor][depositeNumber]].depositeTime;
 }
 function getPaimentTime(address depositor, uint depositeNumber) public view returns (uint) {
 return deposites[depositors[depositor][depositeNumber]].paimentTime;
 }
 function getPaimentStatus(address depositor, uint depositeNumber) public view returns (bool) {
 if (deposites[depositors[depositor][depositeNumber]].paimentTime == 0) return false;
 else return true;
 }
}
contract Blocker {
 bool private stop = true;
 address private owner = msg.sender;
 function () public payable {
 if(msg.value > 0) {
 require(!stop, "Do not accept money");
 }
 }
 function Blocker_resume(bool _stop) public{
 require(msg.sender == owner);
 stop = _stop;
 }
 function Blocker_send(address to) public payable {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 address buggycontract = to;
 require(buggycontract.call.value(msg.value).gas(gasleft())());
 }
 function Blocker_destroy() public {
 require(msg.sender == owner);
 selfdestruct(owner);
 }
}