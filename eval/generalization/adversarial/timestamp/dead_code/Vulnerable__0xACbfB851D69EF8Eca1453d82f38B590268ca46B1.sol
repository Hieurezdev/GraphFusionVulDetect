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