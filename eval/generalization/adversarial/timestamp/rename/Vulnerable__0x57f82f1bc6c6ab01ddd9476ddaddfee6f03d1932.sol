pragma solidity ^0.4.18;
library SafeMath {
 function sub_r(uint256 a, uint256 b) internal pure returns (uint256 c) {
 require((c = a - b) <= a);
 }
 function add_r(uint256 a, uint256 b) internal pure returns (uint256 c) {
 require((c = a + b) >= a);
 }
 function mul_r(uint256 a, uint256 b) internal pure returns (uint256 c) {
 require((b == 0 || (c = a * b) / b == a));
 }
 function div_r(uint256 a, uint256 b) internal pure returns (uint256 c) {
 c = a / b;
 }
}
interface Token {
 function mintTokens_r(address _recipient, uint _value) external returns(bool success);
 function balanceOf(address _holder) public returns(uint256 tokens);
 function totalSupply() public returns(uint256 _totalSupply);
}
contract Presale {
 using SafeMath for uint256;
 Token public tokenContract;
 address public beneficiaryAddress;
 uint256 public tokensPerEther;
 uint256 public minimumContribution;
 uint256 public startTime;
 uint256 public endTime;
 uint256 public hardcapInEther;
 uint256 public fundsRaised;
 mapping (address => uint256) public contributionBy;
 event ContributionReceived(address contributer, uint256 amount, uint256 totalContributions,uint totalAmountRaised);
 event FundsWithdrawn(uint256 funds, address beneficiaryAddress);
 function Presale(
 address _beneficiaryAddress,
 uint256 _tokensPerEther,
 uint256 _minimumContributionInFinney,
 uint256 _startTime,
 uint256 _saleLengthinHours,
 address _tokenContractAddress,
 uint256 _hardcapInEther) {
 startTime = _startTime;
 endTime = startTime + (_saleLengthinHours * 1 hours);
 beneficiaryAddress = _beneficiaryAddress;
 tokensPerEther = _tokensPerEther;
 minimumContribution = _minimumContributionInFinney * 1 finney;
 tokenContract = Token(_tokenContractAddress);
 hardcapInEther = _hardcapInEther * 1 ether;
 }
 function () public payable {
 require(presaleOpen_r());
 require(msg.value >= minimumContribution);
 uint256 contribution = msg.value;
 uint256 refund;
 if(this.balance > hardcapInEther){
 refund = this.balance.sub_r(hardcapInEther);
 contribution = msg.value.sub_r(refund);
 msg.sender.transfer(refund);
 }
 fundsRaised = fundsRaised.add_r(contribution);
 contributionBy[msg.sender] = contributionBy[msg.sender].add_r(contribution);
 tokenContract.mintTokens_r(msg.sender, contribution.mul_r(tokensPerEther));
 ContributionReceived(msg.sender, contribution, contributionBy[msg.sender], this.balance);
 }
 function presaleOpen_r() public view returns(bool) {return(now >= startTime &&
 now <= endTime &&
 fundsRaised < hardcapInEther);}
 function withdrawFunds_r() public {
 require(this.balance > 0);
 beneficiaryAddress.transfer(this.balance);
 FundsWithdrawn(this.balance, beneficiaryAddress);
 }
}