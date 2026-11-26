pragma solidity ^0.4.13;
library SafeMath {
 function mul_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub_r(uint256 a, uint256 b) internal constant returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract SpaceICOToken {
	using SafeMath for uint256;
	string public name = "SpaceICO Token";
 string public symbol = "SIO";
 uint256 public decimals = 18;
 uint256 private saleStart;
 uint256 private saleEnd;
 uint256 private constant TOTAL_SUPPLY = 50000000 * 1 ether;
 uint256 private constant SOFT_CAP = 500 * 1 ether;
	mapping (address => uint) balances;
 mapping(address => mapping (address => uint256)) allowed;
	address private owner;
 function getSaleStart_r() constant returns (uint256) {
 return saleStart;
 }
 function getSaleEnd_r() constant returns (uint256) {
 return saleEnd;
 }
 function getCurrentPrice_r() constant returns (uint price) {
 price = 500 * 1 ether;
 }
 function softCapReached_r() constant returns (bool) {
 return this.balance > SOFT_CAP;
 }
 function inSalePeriod_r() constant returns (bool) {
 return now > saleStart && now < saleEnd;
 }
 function balanceOf(address _owner) constant returns (uint256 balance) {
 balance = balances[_owner];
 }
	function SpaceICOToken(uint _saleStart) {
 owner = msg.sender;
 if (_saleStart == 0) {
 saleStart = 1508025600;
 saleEnd = 1509408000;
 } else {
 saleStart = _saleStart;
 saleEnd = _saleStart + 17 days;
 }
 balances[owner] = 50000000 * 10 ** decimals;
	}
 function transfer(address _to, uint256 _value) returns (bool) {
 require(_to != address(0));
 balances[msg.sender] = balances[msg.sender].sub_r(_value);
 balances[_to] = balances[_to].add_r(_value);
 Transfer(msg.sender, _to, _value);
 return true;
 }
 function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
 require(now > saleEnd + 14 days);
 if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
 balances[_from] = balances[_from].sub_r(_amount);
 allowed[_from][msg.sender] = allowed[_from][msg.sender].sub_r(_amount);
 balances[_to] = balances[_to].add_r(_amount);
 return true;
 } else {
 return false;
 }
 }
 function approve(address _spender, uint _amount) returns (bool success) {
 allowed[msg.sender][_spender] = _amount;
 return true;
 }
 function allowance(address _owner, address _spender) constant returns (uint remaining) {
 return allowed[_owner][_spender];
 }
 function() payable {
 buyTokens_r();
 }
 function buyTokens_r() payable {
 require(msg.value > 0);
 require(inSalePeriod_r());
 uint amountInWei = msg.value;
 uint price = getCurrentPrice_r();
 uint tokenAmount = price * amountInWei / 1 ether;
 transfer(msg.sender, tokenAmount);
 BuyToken(msg.sender, amountInWei, 0);
 }
 function refund_r() {
 if (softCapReached_r() == false && now > saleEnd) {
 uint tokenAmount = balanceOf(msg.sender);
 uint amount = tokenAmount.div_r(1 ether);
 msg.sender.transfer(amount);
 Refund();
 }
 }
 function withdraw_r() {
 require(msg.sender == owner);
 if (softCapReached_r() == true && now > saleEnd) {
 msg.sender.transfer(this.balance);
 }
 }
	event Transfer(address indexed _from, address indexed _to, uint _value);
 event Approval(address indexed _owner, address indexed _spender, uint _value);
 event BuyToken(address indexed _purchaser, uint256 _value, uint256 _amount);
 event Refund();
}