pragma solidity ^0.4.11;
contract SimpleAuction {
 uint public auctionStart;
 uint public biddingTime;
 address public highestBidder;
 uint public highestBid;
 mapping(address => uint) pendingReturns;
 bool ended;
 event HighestBidIncreased(address bidder, uint amount);
 event AuctionEnded(address winner, uint amount);
 address _beneficiary = 0xb23397f97715118532c8c1207F5678Ed4FbaEA6c;
	address beneficiary;
 function SimpleAuction() {
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

 beneficiary = _beneficiary;
 auctionStart = now;
 biddingTime = 2587587;
 }
 function bid() payable {
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

 require(now <= (auctionStart + biddingTime));
 require(msg.value > highestBid);
 if (highestBidder != 0) {
 pendingReturns[highestBidder] += highestBid;
 }
 highestBidder = msg.sender;
 highestBid = msg.value;
 HighestBidIncreased(msg.sender, msg.value);
 }
 function withdraw() returns (bool) {
 uint amount = pendingReturns[msg.sender];
 if (amount > 0) {
 pendingReturns[msg.sender] = 0;
 if (!msg.sender.send(amount)) {
 pendingReturns[msg.sender] = amount;
 return false;
 }
 }
 return true;
 }
 function auctionEndTime() constant returns (uint256) {
 return auctionStart + biddingTime;
 }
 function auctionEnd() {
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

 require(now >= (auctionStart + biddingTime));
 require(!ended);
 ended = true;
 AuctionEnded(highestBidder, highestBid);
 beneficiary.transfer(highestBid);
 }
}