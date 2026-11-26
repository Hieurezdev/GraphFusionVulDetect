pragma solidity ^0.4.25;
contract Prosperity {
 function transfer(address _toAddress, uint256 _amountOfTokens) public returns(bool);
	function myTokens() public view returns(uint256);
 function myDividends(bool _includeReferralBonus) public view returns(uint256);
 function buy(address _referredBy) public payable returns(uint256);
 function withdraw() public;
	function reinvest() public;
	function() payable external;
}
contract Lending {
	using SafeMath for *;
 event Transfer (
 address indexed from,
 address indexed to,
 uint256 tokens
 );
	event onDeposit (
 address indexed customer,
 uint256 tokens
	);
	event onReinvestProfit (
 address indexed customer,
 uint256 tokens
	);
	event onWithdrawProfit (
 address indexed customer,
 uint256 tokens
	);
	event onWithdrawCapital (
 address indexed customer,
 uint256 tokens
	);
	modifier onlyTokenContract {
 require(msg.sender == address(tokenContract_));
 _;
 }
 modifier onlyBagholders() {
 require(myDeposit() > 0);
 _;
 }
 modifier onlyStronghands() {
 require(myProfit(msg.sender) > 0);
 _;
 }
 modifier onlyAdministrator(){
 address _customerAddress = msg.sender;
 require(administrator_ == _customerAddress);
 _;
 }
 mapping(address => Dealer) internal dealers_;
 uint256 internal totalDeposit_ = 0;
	Prosperity public tokenContract_;
 address internal administrator_;
	struct Dealer {
 uint256 deposit;
 uint256 profit;
 uint256 time;
	}
 constructor() public {
 administrator_ = 0x28436C7453EbA01c6EcbC8a9cAa975f0ADE6Fff1;
 }
	function() payable external {
	}
 function tokenFallback(address _from, uint256 _value, bytes _data)
 onlyTokenContract()
 external
 returns (bool)
	{
 Dealer storage _dealer = dealers_[_from];
 _dealer.profit = myProfit(_from);
 _dealer.time = now;
 _dealer.deposit = _dealer.deposit.add(_value);
 totalDeposit_ = totalDeposit_.add(_value);
 emit onDeposit(_from, _value);
 return true;
 _data;
	}
	function reinvestProfit()
 onlyStronghands()
 public
	{
 address _customerAddress = msg.sender;
 Dealer storage _dealer = dealers_[_customerAddress];
 uint256 _profits = myProfit(_customerAddress);
 _dealer.deposit = _dealer.deposit.add(_profits);
 _dealer.profit = 0;
 _dealer.time = now;
 totalDeposit_ = totalDeposit_.add(_profits);
 emit onReinvestProfit(_customerAddress, _profits);
	}
	function withdrawProfit()
 onlyStronghands()
 public
	{
 address _customerAddress = msg.sender;
 Dealer storage _dealer = dealers_[_customerAddress];
 uint256 _profits = myProfit(_customerAddress);
 _dealer.profit = 0;
 _dealer.time = now;
 tokenContract_.transfer(_customerAddress, _profits);
 emit onWithdrawProfit(_customerAddress, _profits);
	}
	function withdrawCapital()
 onlyBagholders()
 public
	{
 address _customerAddress = msg.sender;
 Dealer storage _dealer = dealers_[_customerAddress];
 uint256 _deposit = _dealer.deposit;
 uint256 _taxedDeposit = _deposit.mul(75).div(100);
 uint256 _profits = myProfit(_customerAddress);
 _dealer.deposit = 0;
 _dealer.profit = _profits;
 totalDeposit_ = totalDeposit_.sub(_deposit);
 tokenContract_.transfer(_customerAddress, _taxedDeposit);
 emit onWithdrawCapital(_customerAddress, _taxedDeposit);
	}
	function reinvestEther()
 public
	{
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 uint256 _balance = address(this).balance;
 if (_balance > 0) {
 if(!address(tokenContract_).call.value(_balance)()) {
 revert();
 }
 }
	}
	function reinvestDividends()
 public
	{
 uint256 _dividends = myDividends(true);
 if (_dividends > 0) {
 tokenContract_.reinvest();
 }
	}
 function totalDeposit()
 public
 view
 returns(uint256)
 {
 return totalDeposit_;
 }
 function totalSupply()
 public
 view
 returns(uint256)
 {
 return tokenContract_.myTokens();
 }
	function surplus()
 public
 view
 returns(int256)
	{
 uint256 _tokens = totalSupply();
 if (totalDeposit_ > 0) {
 return int256((1000).mul(_tokens).div(totalDeposit_) - 1000);
 } else {
 return 1000;
 }
	}
 function myDeposit()
 public
 view
 returns(uint256)
 {
 address _customerAddress = msg.sender;
 Dealer storage _dealer = dealers_[_customerAddress];
 return _dealer.deposit;
 }
	function myProfit(address _customerAddress)
 public
 view
 returns(uint256)
	{
 Dealer storage _dealer = dealers_[_customerAddress];
 uint256 _oldProfits = _dealer.profit;
 uint256 _newProfits = 0;
 if (
 _dealer.time == 0 ||
 _dealer.deposit == 0
 )
 {
 _newProfits = 0;
 } else {
 uint256 _timeLending = now - _dealer.time;
 _newProfits = _timeLending
 .mul(_dealer.deposit)
 .mul(1337)
 .div(100000)
 .div(86400);
 }
 return _newProfits.add(_oldProfits);
	}
	function myDividends(bool _includeReferralBonus)
 public
 view
 returns(uint256)
	{
 return tokenContract_.myDividends(_includeReferralBonus);
	}
	function setTokenContract(address _tokenContract)
 onlyAdministrator()
 public
	{
 tokenContract_ = Prosperity(_tokenContract);
	}
}
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 assert(c / a == b);
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