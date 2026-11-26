pragma solidity ^0.4.18;
library SafeMath {
 function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
 require((c = a - b) <= a);
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
 require((c = a + b) >= a);
 }
 function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
 require((b == 0 || (c = a * b) / b == a));
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
 c = a / b;
 }
}
interface Token {
 function mintTokens(address _recipient, uint _value) external returns(bool success);
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
 require(presaleOpen());
 require(msg.value >= minimumContribution);
 uint256 contribution = msg.value;
 uint256 refund;
 if(this.balance > hardcapInEther){
 refund = this.balance.sub(hardcapInEther);
 contribution = msg.value.sub(refund);
 msg.sender.transfer(refund);
 }
 fundsRaised = fundsRaised.add(contribution);
 contributionBy[msg.sender] = contributionBy[msg.sender].add(contribution);
 tokenContract.mintTokens(msg.sender, contribution.mul(tokensPerEther));
 ContributionReceived(msg.sender, contribution, contributionBy[msg.sender], this.balance);
 }
 function presaleOpen() public view returns(bool) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */
return(now >= startTime &&
 now <= endTime &&
 fundsRaised < hardcapInEther);}
 function withdrawFunds() public {
 require(this.balance > 0);
 beneficiaryAddress.transfer(this.balance);
 FundsWithdrawn(this.balance, beneficiaryAddress);
 }
}