pragma solidity 0.4.23;
contract AbstractToken {
	function balanceOf(address owner) public view returns (uint256 balance);
	function transfer(address to, uint256 value) public returns (bool success);
	function transferFrom(address from, address to, uint256 value) public returns (bool success);
	function approve(address spender, uint256 value) public returns (bool success);
	function allowance(address owner, address spender) public view returns (uint256 remaining);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Owned {
	address public owner = msg.sender;
	address public potentialOwner;
	modifier onlyOwner {
 require(msg.sender == owner);
 _;
	}
	modifier onlyPotentialOwner {
 require(msg.sender == potentialOwner);
 _;
	}
	event NewOwner(address old, address current);
	event NewPotentialOwner(address old, address potential);
	function setOwner(address _new)
 public
 onlyOwner
	{
 emit NewPotentialOwner(owner, _new);
 potentialOwner = _new;
	}
	function confirmOwnership()
 public
 onlyPotentialOwner
	{
 emit NewOwner(owner, potentialOwner);
 owner = potentialOwner;
 potentialOwner = address(0);
	}
}
contract SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 assert(c / a == b);
 return c;
	}
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
 return a / b;
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
	function pow(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a ** b;
 assert(c >= a);
 return c;
	}
}
contract StandardToken is AbstractToken, Owned, SafeMath {
	mapping (address => uint256) internal balances;
	mapping (address => mapping (address => uint256)) internal allowed;
	uint256 public totalSupply;
	function transfer(address _to, uint256 _value) public returns (bool success) {
 return _transfer(msg.sender, _to, _value);
	}
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
 require(allowed[_from][msg.sender] >= _value);
 allowed[_from][msg.sender] -= _value;
 return _transfer(_from, _to, _value);
	}
	function balanceOf(address _owner) public view returns (uint256 balance) {
 return balances[_owner];
	}
	function approve(address _spender, uint256 _value) public returns (bool success) {
 allowed[msg.sender][_spender] = _value;
 emit Approval(msg.sender, _spender, _value);
 return true;
	}
	function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
 return allowed[_owner][_spender];
	}
	function _transfer(address _from, address _to, uint256 _value) private returns (bool success) {
 require(_to != address(0));
 require(balances[_from] >= _value);
 balances[_from] -= _value;
 balances[_to] = add(balances[_to], _value);
 emit Transfer(_from, _to, _value);
 return true;
	}
}
contract Token is StandardToken {
	uint256 public creationTime;
	function Token() public {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 creationTime = now;
	}
	function transferERC20Token(AbstractToken _token, address _to, uint256 _value)
 public
 onlyOwner
 returns (bool success)
	{
 require(_token.balanceOf(address(this)) >= _value);
 uint256 receiverBalance = _token.balanceOf(_to);
 require(_token.transfer(_to, _value));
 uint256 receiverNewBalance = _token.balanceOf(_to);
 assert(receiverNewBalance == add(receiverBalance, _value));
 return true;
	}
	function increaseApproval(address _spender, uint256 _value) public returns (bool success) {
 allowed[msg.sender][_spender] = add(allowed[msg.sender][_spender], _value);
 emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
	}
	function decreaseApproval(address _spender, uint256 _value) public returns (bool success) {
 uint256 oldValue = allowed[msg.sender][_spender];
 if (_value > oldValue) {
 allowed[msg.sender][_spender] = 0;
 } else {
 allowed[msg.sender][_spender] = sub(oldValue, _value);
 }
 emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
	}
}
contract NexoToken is Token {
	string constant public name = 'Nexo';
	string constant public symbol = 'NEXO';
	uint8 constant public decimals = 18;
	address public investorsAllocation = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
	uint256 public investorsTotal = 525000000e18;
	address public overdraftAllocation = address(0x1111111111111111111111111111111111111111);
	uint256 public overdraftTotal = 250000000e18;
	uint256 public overdraftPeriodAmount = 41666666e18;
	uint256 public overdraftUnvested = 4e18;
	uint256 public overdraftCliff = 5 * 30 days;
	uint256 public overdraftPeriodLength = 30 days;
	uint8 public overdraftPeriodsNumber = 6;
	address public teamAllocation = address(0x2222222222222222222222222222222222222222);
	uint256 public teamTotal = 112500000e18;
	uint256 public teamPeriodAmount = 7031250e18;
	uint256 public teamUnvested = 0;
	uint256 public teamCliff = 0;
	uint256 public teamPeriodLength = 3 * 30 days;
	uint8 public teamPeriodsNumber = 16;
	address public communityAllocation = address(0x3333333333333333333333333333333333333333);
	uint256 public communityTotal = 60000000e18;
	uint256 public communityPeriodAmount = 8333333e18;
	uint256 public communityUnvested = 10000002e18;
	uint256 public communityCliff = 0;
	uint256 public communityPeriodLength = 3 * 30 days;
	uint8 public communityPeriodsNumber = 6;
	address public advisersAllocation = address(0x4444444444444444444444444444444444444444);
	uint256 public advisersTotal = 52500000e18;
	uint256 public advisersPeriodAmount = 2291666e18;
	uint256 public advisersUnvested = 25000008e18;
	uint256 public advisersCliff = 0;
	uint256 public advisersPeriodLength = 30 days;
	uint8 public advisersPeriodsNumber = 12;
	function NexoToken() public {
 totalSupply = 1000000000e18;
 balances[investorsAllocation] = investorsTotal;
 balances[overdraftAllocation] = overdraftTotal;
 balances[teamAllocation] = teamTotal;
 balances[communityAllocation] = communityTotal;
 balances[advisersAllocation] = advisersTotal;
 allowed[investorsAllocation][msg.sender] = investorsTotal;
 allowed[overdraftAllocation][msg.sender] = overdraftUnvested;
 allowed[communityAllocation][msg.sender] = communityUnvested;
 allowed[advisersAllocation][msg.sender] = advisersUnvested;
	}
	function distributeInvestorsTokens(address _to, uint256 _amountWithDecimals)
 public
 onlyOwner
	{
 require(transferFrom(investorsAllocation, _to, _amountWithDecimals));
	}
	function withdrawOverdraftTokens(address _to, uint256 _amountWithDecimals)
 public
 onlyOwner
	{
 allowed[overdraftAllocation][msg.sender] = allowance(overdraftAllocation, msg.sender);
 require(transferFrom(overdraftAllocation, _to, _amountWithDecimals));
	}
	function withdrawTeamTokens(address _to, uint256 _amountWithDecimals)
 public
 onlyOwner
	{
 allowed[teamAllocation][msg.sender] = allowance(teamAllocation, msg.sender);
 require(transferFrom(teamAllocation, _to, _amountWithDecimals));
	}
	function withdrawCommunityTokens(address _to, uint256 _amountWithDecimals)
 public
 onlyOwner
	{
 allowed[communityAllocation][msg.sender] = allowance(communityAllocation, msg.sender);
 require(transferFrom(communityAllocation, _to, _amountWithDecimals));
	}
	function withdrawAdvisersTokens(address _to, uint256 _amountWithDecimals)
 public
 onlyOwner
	{
 allowed[advisersAllocation][msg.sender] = allowance(advisersAllocation, msg.sender);
 require(transferFrom(advisersAllocation, _to, _amountWithDecimals));
	}
	function allowance(address _owner, address _spender)
 public
 view
 returns (uint256 remaining)
	{
 if (_spender != owner) {
 return allowed[_owner][_spender];
 }
 uint256 unlockedTokens;
 uint256 spentTokens;
 if (_owner == overdraftAllocation) {
 unlockedTokens = _calculateUnlockedTokens(
 overdraftCliff,
 overdraftPeriodLength,
 overdraftPeriodAmount,
 overdraftPeriodsNumber,
 overdraftUnvested
 );
 spentTokens = sub(overdraftTotal, balanceOf(overdraftAllocation));
 } else if (_owner == teamAllocation) {
 unlockedTokens = _calculateUnlockedTokens(
 teamCliff,
 teamPeriodLength,
 teamPeriodAmount,
 teamPeriodsNumber,
 teamUnvested
 );
 spentTokens = sub(teamTotal, balanceOf(teamAllocation));
 } else if (_owner == communityAllocation) {
 unlockedTokens = _calculateUnlockedTokens(
 communityCliff,
 communityPeriodLength,
 communityPeriodAmount,
 communityPeriodsNumber,
 communityUnvested
 );
 spentTokens = sub(communityTotal, balanceOf(communityAllocation));
 } else if (_owner == advisersAllocation) {
 unlockedTokens = _calculateUnlockedTokens(
 advisersCliff,
 advisersPeriodLength,
 advisersPeriodAmount,
 advisersPeriodsNumber,
 advisersUnvested
 );
 spentTokens = sub(advisersTotal, balanceOf(advisersAllocation));
 } else {
 return allowed[_owner][_spender];
 }
 return sub(unlockedTokens, spentTokens);
	}
	function confirmOwnership()
 public
 onlyPotentialOwner
	{
 allowed[investorsAllocation][owner] = 0;
 allowed[investorsAllocation][msg.sender] = balanceOf(investorsAllocation);
 allowed[overdraftAllocation][owner] = 0;
 allowed[teamAllocation][owner] = 0;
 allowed[communityAllocation][owner] = 0;
 allowed[advisersAllocation][owner] = 0;
 super.confirmOwnership();
	}
	function _calculateUnlockedTokens(
 uint256 _cliff,
 uint256 _periodLength,
 uint256 _periodAmount,
 uint8 _periodsNumber,
 uint256 _unvestedAmount
	)
 private
 view
 returns (uint256)
	{
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (now < add(creationTime, _cliff)) {
 return _unvestedAmount;
 }
 uint256 periods = div(sub(now, add(creationTime, _cliff)), _periodLength);
 periods = periods > _periodsNumber ? _periodsNumber : periods;
 return add(_unvestedAmount, mul(periods, _periodAmount));
	}
}