pragma solidity ^0.4.16;
contract token { function transfer(address receiver, uint amount) public ;
 function mintToken(address target, uint mintedAmount) public ;
 }
contract CrowdSale {
 enum State {
 Fundraising,
 Failed,
 Successful,
 Closed
 }
 State public state = State.Fundraising;
 struct Contribution {
 uint amount;
 address contributor;
 }
 Contribution[] contributions;
 uint public totalRaised;
 uint public currentBalance;
 uint public deadline;
 uint public completedAt;
 uint public priceInWei;
 uint public fundingMinimumTargetInWei;
 uint public fundingMaximumTargetInWei;
 token public tokenReward;
 address public creator;
 address public beneficiary;
 string campaignUrl;
 byte constant version = "1";
 event LogFundingReceived(address addr, uint amount, uint currentTotal);
 event LogWinnerPaid(address winnerAddress);
 event LogFundingSuccessful(uint totalRaised);
 event LogFunderInitialized(
 address creator,
 address beneficiary,
 string url,
 uint _fundingMaximumTargetInEther,
 uint256 deadline);
 modifier inState(State _state) {
 require(state == _state) ;
 _;
 }
 modifier isMinimum() {
 require(msg.value > priceInWei) ;
 _;
 }
 modifier inMultipleOfPrice() {
 require(msg.value%priceInWei == 0) ;
 _;
 }
 modifier isCreator() {
 require(msg.sender == creator) ;
 _;
 }
 modifier atEndOfLifecycle() {
 if(!((state == State.Failed || state == State.Successful) && completedAt + 1 hours < now)) {
 revert();
 }
 _;
 }
 function CrowdSale(
 uint _timeInMinutesForFundraising,
 string _campaignUrl,
 address _ifSuccessfulSendTo,
 uint _fundingMinimumTargetInEther,
 uint _fundingMaximumTargetInEther,
 token _addressOfTokenUsedAsReward,
 uint _etherCostOfEachToken) public
 {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 creator = msg.sender;
 beneficiary = _ifSuccessfulSendTo;
 campaignUrl = _campaignUrl;
 fundingMinimumTargetInWei = _fundingMinimumTargetInEther * 1 ether;
 fundingMaximumTargetInWei = _fundingMaximumTargetInEther * 1 ether;
 deadline = now + (_timeInMinutesForFundraising * 1 minutes);
 currentBalance = 0;
 tokenReward = token(_addressOfTokenUsedAsReward);
 priceInWei = _etherCostOfEachToken * 1 ether;
 LogFunderInitialized(
 creator,
 beneficiary,
 campaignUrl,
 fundingMaximumTargetInWei,
 deadline);
 }
 function contribute()
 public
 inState(State.Fundraising) isMinimum() inMultipleOfPrice() payable returns (uint256)
 {
 uint256 amountInWei = msg.value;
 contributions.push(
 Contribution({
 amount: msg.value,
 contributor: msg.sender
 })
 );
 totalRaised += msg.value;
 currentBalance = totalRaised;
 if(fundingMaximumTargetInWei != 0){
 tokenReward.transfer(msg.sender, amountInWei / priceInWei);
 }
 else{
 tokenReward.mintToken(msg.sender, amountInWei / priceInWei);
 }
 LogFundingReceived(msg.sender, msg.value, totalRaised);
 checkIfFundingCompleteOrExpired();
 return contributions.length - 1;
 }
 function checkIfFundingCompleteOrExpired() public {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (fundingMaximumTargetInWei != 0 && totalRaised > fundingMaximumTargetInWei) {
 state = State.Successful;
 LogFundingSuccessful(totalRaised);
 payOut();
 completedAt = now;
 } else if ( now > deadline ) {
 if(totalRaised >= fundingMinimumTargetInWei){
 state = State.Successful;
 LogFundingSuccessful(totalRaised);
 payOut();
 completedAt = now;
 }
 else{
 state = State.Failed;
 completedAt = now;
 }
 }
 }
 function payOut()
 public
 inState(State.Successful)
 {
 if(!beneficiary.send(this.balance)) {
 revert();
 }
 state = State.Closed;
 currentBalance = 0;
 LogWinnerPaid(beneficiary);
 }
 function getRefund()
 public
 inState(State.Failed)
 returns (bool)
 {
 for(uint i=0; i<=contributions.length; i++)
 {
 if(contributions[i].contributor == msg.sender){
 uint amountToRefund = contributions[i].amount;
 contributions[i].amount = 0;
 if(!contributions[i].contributor.send(amountToRefund)) {
 contributions[i].amount = amountToRefund;
 return false;
 }
 else{
 totalRaised -= amountToRefund;
 currentBalance = totalRaised;
 }
 return true;
 }
 }
 return false;
 }
 function removeContract()
 public
 isCreator()
 atEndOfLifecycle()
 {
 selfdestruct(msg.sender);
 }
 function () public { revert(); }
}