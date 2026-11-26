pragma solidity ^0.4.19;
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
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
contract Owned {
 address public owner;
 event TransferOwnership(address oldaddr, address newaddr);
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;}
 function Owned() public {
 owner = msg.sender;
 }
 function transferOwnership(address _new) onlyOwner public {
 address oldaddr = owner;
 owner = _new;
 TransferOwnership(oldaddr, owner);
 }
}
contract MontexToken is Owned{
 string public name;
 string public symbol;
 uint256 public decimals;
 uint256 public totalSupply;
 mapping (address => uint256) public balanceOf;
 event Transfer(address indexed from, address indexed to, uint256 value);
 function MontexToken() public{
 name = "Montex Token";
 symbol = "MON";
 decimals = 8;
 totalSupply = 2e9 * 10**uint256(decimals);
 balanceOf[msg.sender] = totalSupply;
 }
 function transfer(address _to, uint256 _value) public{
 if (balanceOf[msg.sender] < _value) revert();
 if (balanceOf[_to] + _value < balanceOf[_to]) revert();
 balanceOf[msg.sender] -= _value;
 balanceOf[_to] += _value;
 Transfer(msg.sender, _to, _value);
 }
}
contract Crowdsale is Owned {
 using SafeMath for uint256;
 uint256 public fundingGoal;
 uint256 public price;
 uint256 public transferableToken;
 uint256 public soldToken;
 uint256 public deadline;
 uint256 public token_price;
 MontexToken public tokenReward;
 bool public fundingGoalReached = false;
 bool public isOpened;
 mapping (address => Property) public fundersProperty;
 struct Property {
 uint256 paymentEther;
 uint256 reservedToken;
 }
 event CrowdsaleStart(uint fundingGoal, uint deadline, uint transferableToken, address beneficiary);
 event ReservedToken(address backer, uint amount, uint token, uint soldToken);
 event WithdrawalToken(address addr, uint amount, bool result);
 event WithdrawalEther(address addr, uint amount, bool result);
 event FinishCrowdSale(address beneficiary, uint fundingGoal, uint amountRaised, bool reached, uint raisedToken);
 modifier afterDeadline() { if (now >= deadline) _; }
 function Crowdsale (
 uint _fundingGoalInEthers,
 uint _transferableToken,
 uint _amountOfTokenPerEther,
 MontexToken _addressOfTokenUsedAsReward
 ) public {
 fundingGoal = _fundingGoalInEthers * 1 ether;
 price = 1 ether / _amountOfTokenPerEther;
 tokenReward = MontexToken(_addressOfTokenUsedAsReward);
 transferableToken = _transferableToken * 10 ** uint256(8);
 }
 function () payable external{
 if (!isOpened || now >= deadline) revert();
 uint amount = msg.value;
 uint amont_conv = amount * 1000;
 uint token = (amont_conv / price * token_price / 1000) * 10 ** uint256(8);
 if (token == 0 || soldToken + token > transferableToken) revert();
 fundersProperty[msg.sender].paymentEther += amount / 10 ** uint256(8);
 fundersProperty[msg.sender].reservedToken += token;
 soldToken += token;
 tokenReward.transfer(msg.sender, token);
 ReservedToken(msg.sender, amount, token,soldToken);
 }
 function start(uint startTime,uint _deadline,uint _token_price) onlyOwner public{
 deadline = _deadline;
 token_price = _token_price;
 if (fundingGoal == 0 || transferableToken == 0 ||
 tokenReward == address(0) || startTime >= now)
 {
 revert();
 }
 if (tokenReward.balanceOf(this) >= transferableToken) {
 if(startTime <= now && now <= deadline){
 isOpened = true;
 CrowdsaleStart(fundingGoal, deadline, transferableToken, owner);
 }
 }
 }
 function getBalance(address _addres) public
 constant returns(uint nowpaymentEther,uint nowbuyToken)
 {
 nowpaymentEther = fundersProperty[_addres].paymentEther * (1 ether) / 10 ** uint256(8);
 nowbuyToken = fundersProperty[_addres].reservedToken;
 }
 function valNowRate(uint _amount) public
 view returns(uint get_rate,uint get_token)
 {
 get_rate = token_price;
 get_token = _amount * get_rate;
 }
 function getRemainingTimeEthToken() public
 constant returns(
 uint now_time,
 uint now_deadline,
 uint remain_days,
 uint remain_hours,
 uint remain_minutes,
 uint remainEth,
 uint remainToken,
 uint remain_seconds,
 uint getEth,
 uint tokenReward_balance,
 uint transferable_token)
 {
 if(now < deadline) {
 remain_days = (deadline - now) / (1 days);
 remain_hours = (deadline - now) / (1 hours);
 remain_minutes = (deadline - now) / (1 minutes);
 remain_seconds = (deadline - now) / (1 seconds);
 now_time = now;
 now_deadline = deadline;
 }
 remainEth = (fundingGoal - this.balance) / (1 ether);
 remainToken = transferableToken - soldToken;
 getEth = this.balance / (1 ether);
 tokenReward_balance = tokenReward.balanceOf(this);
 transferable_token = transferableToken;
 }
 function finishCrowdSale() onlyOwner public {
 if (this.balance >= fundingGoal) {
 fundingGoalReached = true;
 }
 if(isOpened==true){
 isOpened = false;
 uint val = transferableToken - soldToken;
 if (val > 0) {
 tokenReward.transfer(msg.sender, transferableToken - soldToken);
 WithdrawalToken(msg.sender, val, true);
 }
 }
 FinishCrowdSale(owner, fundingGoal, this.balance, fundingGoalReached, soldToken);
 }
 function withdrawalOwner() onlyOwner public{
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 uint amount = this.balance;
 if (amount > 0) {
 bool ok = msg.sender.call.value(amount)();
 WithdrawalEther(msg.sender, amount, ok);
 }
 }
}