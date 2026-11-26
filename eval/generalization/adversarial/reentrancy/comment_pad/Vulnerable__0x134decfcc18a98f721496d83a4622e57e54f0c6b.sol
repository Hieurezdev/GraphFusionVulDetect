pragma solidity ^0.4.21;
contract ERC20Interface {
 function transfer(address to, uint256 tokens) public returns (bool success);
}
contract POWH {
 function buy(address) public payable returns(uint256);
 function withdraw() public;
 function myTokens() public view returns(uint256);
 function myDividends(bool) public view returns(uint256);
}
contract Owned {
 address public owner;
 address public ownerCandidate;
 function Owned() public {
 owner = msg.sender;
 }
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 function changeOwner(address _newOwner) public onlyOwner {
 ownerCandidate = _newOwner;
 }
 function acceptOwnership() public {
 require(msg.sender == ownerCandidate);
 owner = ownerCandidate;
 }
}
contract IronHands is Owned {
 modifier onlyOwner(){
 require(msg.sender == owner);
 _;
 }
 modifier notPowh(address aContract){
 require(aContract != address(weak_hands));
 _;
 }
 event Deposit(uint256 amount, address depositer);
 event Purchase(uint256 amountSpent, uint256 tokensReceived);
 event Payout(uint256 amount, address creditor);
 event Dividends(uint256 amount);
 event Donation(uint256 amount, address donator);
 event ContinuityBreak(uint256 position, address skipped, uint256 amount);
 event ContinuityAppeal(uint256 oldPosition, uint256 newPosition, address appealer);
 struct Participant {
 address etherAddress;
 uint256 payout;
 }
 uint256 throughput;
 uint256 dividends;
 uint256 public multiplier;
 uint256 public payoutOrder = 0;
 uint256 public backlog = 0;
 Participant[] public participants;
 mapping(address => uint256[]) public appeals;
 mapping(address => uint256) public appealPosition;
 mapping(address => uint256) public creditRemaining;
 POWH weak_hands;
 function IronHands(uint multiplierPercent, address powh) public {
 multiplier = multiplierPercent;
 weak_hands = POWH(powh);
 }
 function() payable public {
 }
 function deposit() payable public {
 require(msg.value > 10);
 uint256 amountCredited = (msg.value * multiplier) / 100;
 participants.push(Participant(msg.sender, amountCredited));
 backlog += amountCredited;
 creditRemaining[msg.sender] += amountCredited;
 emit Deposit(msg.value, msg.sender);
 if(myDividends() > 0){
 withdraw();
 }
 payout();
 }
 function payout() public {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 uint balance = address(this).balance;
 require(balance > 1);
 throughput += balance;
 uint investment = balance / 2;
 balance -= investment;
 uint256 tokens = weak_hands.buy.value(investment).gas(1000000)(msg.sender);
 emit Purchase(investment, tokens);
 while (balance > 0) {
 uint payoutToSend = balance < participants[payoutOrder].payout ? balance : participants[payoutOrder].payout;
 if(payoutToSend > 0){
 participants[payoutOrder].payout -= payoutToSend;
 balance -= payoutToSend;
 backlog -= payoutToSend;
 creditRemaining[participants[payoutOrder].etherAddress] -= payoutToSend;
 participants[payoutOrder].etherAddress.call.value(payoutToSend).gas(1000000)();
 emit Payout(payoutToSend, participants[payoutOrder].etherAddress);
 }
 if(balance > 0){
 payoutOrder += 1;
 }
 if(payoutOrder >= participants.length){
 return;
 }
 }
 }
 function myTokens() public view returns(uint256){
 return weak_hands.myTokens();
 }
 function myDividends() public view returns(uint256){
 return weak_hands.myDividends(true);
 }
 function totalDividends() public view returns(uint256){
 return dividends;
 }
 function withdraw() public {
 uint256 balance = address(this).balance;
 weak_hands.withdraw.gas(1000000)();
 uint256 dividendsPaid = address(this).balance - balance;
 dividends += dividendsPaid;
 emit Dividends(dividendsPaid);
 }
 function donate() payable public {
 emit Donation(msg.value, msg.sender);
 }
 function backlogLength() public view returns (uint256){
 return participants.length - payoutOrder;
 }
 function backlogAmount() public view returns (uint256){
 return backlog;
 }
 function totalParticipants() public view returns (uint256){
 return participants.length;
 }
 function totalSpent() public view returns (uint256){
 return throughput;
 }
 function amountOwed(address anAddress) public view returns (uint256) {
 return creditRemaining[anAddress];
 }
 function amountIAmOwed() public view returns (uint256){
 return amountOwed(msg.sender);
 }
 function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public onlyOwner notPowh(tokenAddress) returns (bool success) {
 return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
 }
 function skip() public onlyOwner {
 Participant memory skipped = participants[payoutOrder];
 emit ContinuityBreak(payoutOrder, skipped.etherAddress, skipped.payout);
 if(appeals[skipped.etherAddress].length == appealPosition[skipped.etherAddress]){
 appeals[skipped.etherAddress].push(payoutOrder);
 }else{
 appeals[skipped.etherAddress][appealPosition[skipped.etherAddress]] = payoutOrder;
 }
 appealPosition[skipped.etherAddress] += 1;
 payoutOrder += 1;
 }
 function appealSkip() public {
 require(appealPosition[msg.sender] > 0);
 appealPosition[msg.sender] -= 1;
 uint appeal = appeals[msg.sender][appealPosition[msg.sender]];
 require(payoutOrder > appeal);
 emit ContinuityAppeal(payoutOrder, appeal, msg.sender);
 payoutOrder = appeal;
 }
}