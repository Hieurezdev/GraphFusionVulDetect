pragma solidity ^0.4.24;
library SafeMath {
 function mul(uint256 a, uint256 b) internal constant returns(uint256) {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal constant returns(uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal constant returns(uint256) {
 assert(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal constant returns(uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract ERC20 {
 uint256 public totalSupply;
 function balanceOf(address who) constant returns(uint256);
 function transfer(address to, uint256 value) returns(bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
 function allowance(address owner, address spender) constant returns(uint256);
 function transferFrom(address from, address to, uint256 value) returns(bool);
 function approve(address spender, uint256 value) returns(bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20 {
 using SafeMath for uint256;
 mapping(address => uint256) balances;
 mapping (address => mapping (address => uint256)) allowed;
 function transfer(address _to, uint256 _value) returns (bool) {
 if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
 balances[msg.sender] = balances[msg.sender].sub(_value);
 balances[_to] = balances[_to].add(_value);
 Transfer(msg.sender, _to, _value);
 return true;
 }else {
 return false;
 }
 }
 function transferFrom(address _from, address _to, uint256 _value) returns(bool) {
 if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
 uint256 _allowance = allowed[_from][msg.sender];
 allowed[_from][msg.sender] = _allowance.sub(_value);
 balances[_to] = balances[_to].add(_value);
 balances[_from] = balances[_from].sub(_value);
 Transfer(_from, _to, _value);
 return true;
 } else {
 return false;
 }
 }
 function balanceOf(address _owner) constant returns(uint256 balance) {
 return balances[_owner];
 }
 function approve(address _spender, uint256 _value) returns(bool) {
 require((_value == 0) || (allowed[msg.sender][_spender] == 0));
 allowed[msg.sender][_spender] = _value;
 Approval(msg.sender, _spender, _value);
 return true;
 }
 function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
 return allowed[_owner][_spender];
 }
}
contract NOLLYCOIN is BasicToken {
 using SafeMath for uint256;
 string public name = "Nolly Coin";
 string public symbol = "NOLLY";
 uint8 public decimals = 18;
 uint256 public totalSupply = 500000000 * 10 ** 18;
 uint256 public reservedForFounders;
 uint256 public bountiesAllocation;
 uint256 public affiliatesAllocation;
 uint256 public totalAllocatedTokens;
 uint256 public tokensAllocatedToCrowdFund;
 address public founderMultiSigAddress = 0x59b645EB51B1e47e45F14A56F271030182393Efd;
 address public bountiesAllocAddress = 0x6C2625A8b19c7Bfa88d1420120DE45A60dCD6e28;
 address public affiliatesAllocAddress = 0x0f0345699Afa5EE03d2B089A5aF73C405885B592;
 address public crowdFundAddress;
 address public owner;
 event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);
 modifier onlyCrowdFundAddress() {
 require(msg.sender == crowdFundAddress);
 _;
 }
 modifier nonZeroAddress(address _to) {
 require(_to != 0x0);
 _;
 }
 modifier onlyFounders() {
 require(msg.sender == founderMultiSigAddress);
 _;
 }
 function NOLLYCOIN(address _crowdFundAddress) {
 owner = msg.sender;
 crowdFundAddress = _crowdFundAddress;
 reservedForFounders = 97500000 * 10 ** 18;
 tokensAllocatedToCrowdFund = 300000000 * 10 ** 18;
 affiliatesAllocation = 25000000 * 10 ** 18;
 bountiesAllocation = 27750000 * 10 ** 18;
 balances[founderMultiSigAddress] = reservedForFounders;
 balances[affiliatesAllocAddress] = affiliatesAllocation;
 balances[crowdFundAddress] = tokensAllocatedToCrowdFund;
 balances[bountiesAllocAddress] = bountiesAllocation;
 totalAllocatedTokens = balances[founderMultiSigAddress] + balances[affiliatesAllocAddress] + balances[bountiesAllocAddress];
 }
 function changeTotalSupply(uint256 _amount) onlyCrowdFundAddress {
 totalAllocatedTokens += _amount;
 }
 function changeFounderMultiSigAddress(address _newFounderMultiSigAddress) onlyFounders nonZeroAddress(_newFounderMultiSigAddress) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 founderMultiSigAddress = _newFounderMultiSigAddress;
 ChangeFoundersWalletAddress(now, founderMultiSigAddress);
 }
 function () {
 revert();
 }
}
contract NOLLYCOINCrowdFund {
 using SafeMath for uint256;
 NOLLYCOIN public token;
 uint256 public preSaleStartTime = 1514874072;
 uint256 public preSaleEndTime = 1522490430;
 uint256 public crowdfundStartDate = 1522576830;
 uint256 public crowdfundEndDate = 1525155672;
 uint256 public totalWeiRaised;
 uint256 public exchangeRateForETH = 32000;
 uint256 public exchangeRateForBTC = 60000;
 uint256 internal tokenSoldInPresale = 0;
 uint256 internal tokenSoldInCrowdsale = 0;
 uint256 internal minAmount = 1 * 10 ** 17;
 bool internal isTokenDeployed = false;
 address public founderMultiSigAddress = 0x59b645EB51B1e47e45F14A56F271030182393Efd;
 address public owner;
 enum State { PreSale, Crowdfund, Finish }
 event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);
 event CrowdFundClosed(uint256 _blockTimeStamp);
 event ChangeFoundersWalletAddress(uint256 _blockTimeStamp, address indexed _foundersWalletAddress);
 modifier tokenIsDeployed() {
 require(isTokenDeployed == true);
 _;
 }
 modifier nonZeroEth() {
 require(msg.value > 0);
 _;
 }
 modifier nonZeroAddress(address _to) {
 require(_to != 0x0);
 _;
 }
 modifier onlyFounders() {
 require(msg.sender == founderMultiSigAddress);
 _;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 modifier onlyPublic() {
 require(msg.sender != founderMultiSigAddress);
 _;
 }
 modifier inState(State state) {
 require(getState() == state);
 _;
 }
 function NOLLYCOINCrowdFund() {
 owner = msg.sender;
 }
 function setFounderMultiSigAddress(address _newFounderAddress) onlyFounders nonZeroAddress(_newFounderAddress) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 founderMultiSigAddress = _newFounderAddress;
 ChangeFoundersWalletAddress(now, founderMultiSigAddress);
 }
 function setTokenAddress(address _tokenAddress) external onlyOwner nonZeroAddress(_tokenAddress) {
 require(isTokenDeployed == false);
 token = NOLLYCOIN(_tokenAddress);
 isTokenDeployed = true;
 }
 function endCrowdfund() onlyFounders inState(State.Finish) returns(bool) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(now > crowdfundEndDate);
 uint256 remainingToken = token.balanceOf(this);
 if (remainingToken != 0)
 token.transfer(founderMultiSigAddress, remainingToken);
 CrowdFundClosed(now);
 return true;
 }
 function buyTokens(address beneficiary)
 nonZeroEth
 tokenIsDeployed
 onlyPublic
 nonZeroAddress(beneficiary)
 payable
 returns(bool)
 {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(msg.value >= minAmount);
 if (getState() == State.PreSale) {
 if (buyPreSaleTokens(beneficiary)) {
 return true;
 }
 return false;
 } else {
 require(now >= crowdfundStartDate && now <= crowdfundEndDate);
 fundTransfer(msg.value);
 uint256 amount = getNoOfTokens(exchangeRateForETH, msg.value);
 if (token.transfer(beneficiary, amount)) {
 tokenSoldInCrowdsale = tokenSoldInCrowdsale.add(amount);
 token.changeTotalSupply(amount);
 totalWeiRaised = totalWeiRaised.add(msg.value);
 TokenPurchase(beneficiary, msg.value, amount);
 return true;
 }
 return false;
 }
 }
 function buyPreSaleTokens(address beneficiary) internal returns(bool) {
 uint256 amount = getTokensForPreSale(exchangeRateForETH, msg.value);
 fundTransfer(msg.value);
 if (token.transfer(beneficiary, amount)) {
 tokenSoldInPresale = tokenSoldInPresale.add(amount);
 token.changeTotalSupply(amount);
 totalWeiRaised = totalWeiRaised.add(msg.value);
 TokenPurchase(beneficiary, msg.value, amount);
 return true;
 }
 return false;
 }
 function getNoOfTokens(uint256 _exchangeRate, uint256 _amount) internal constant returns(uint256) {
 uint256 noOfToken = _amount.mul(_exchangeRate);
 uint256 noOfTokenWithBonus = ((100 + getCurrentBonusRate()) * noOfToken).div(100);
 return noOfTokenWithBonus;
 }
 function getTokensForPreSale(uint256 _exchangeRate, uint256 _amount) internal constant returns(uint256) {
 uint256 noOfToken = _amount.mul(_exchangeRate);
 uint256 noOfTokenWithBonus = ((100 + getCurrentBonusRate()) * noOfToken).div(100);
 if (noOfTokenWithBonus + tokenSoldInPresale > (50000000 * 10 ** 18)) {
 revert();
 }
 return noOfTokenWithBonus;
 }
 function fundTransfer(uint256 weiAmount) internal {
 founderMultiSigAddress.transfer(weiAmount);
 }
 function getState() public constant returns(State) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (now >= preSaleStartTime && now <= preSaleEndTime) {
 return State.PreSale;
 }
 if (now >= crowdfundStartDate && now <= crowdfundEndDate) {
 return State.Crowdfund;
 }
 return State.Finish;
 }
 function getCurrentBonusRate() internal returns(uint8) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (getState() == State.PreSale) {
 return 30;
 }
 if (getState() == State.Crowdfund) {
 if (now > crowdfundStartDate && now <= 1523197901) {
 return 25;
 }
 if (now > 1523197901 && now <= 1523802701) {
 return 20;
 }
 if (now > 1523802701 && now <= 1524565102 ) {
 return 15;
 } else {
 return 10;
 }
 }
 }
 function currentBonus() public constant returns(uint8) {
 return getCurrentBonusRate();
 }
 function getContractTimestamp() public constant returns(
 uint256 _presaleStartDate,
 uint256 _presaleEndDate,
 uint256 _crowdsaleStartDate,
 uint256 _crowdsaleEndDate)
 {
 return (preSaleStartTime, preSaleEndTime, crowdfundStartDate, crowdfundEndDate);
 }
 function getExchangeRate() public constant returns(uint256 _exchangeRateForETH, uint256 _exchangeRateForBTC) {
 return (exchangeRateForETH, exchangeRateForBTC);
 }
 function getNoOfSoldToken() public constant returns(uint256 _tokenSoldInPresale, uint256 _tokenSoldInCrowdsale) {
 return (tokenSoldInPresale, tokenSoldInCrowdsale);
 }
 function getWeiRaised() public constant returns(uint256 _totalWeiRaised) {
 return totalWeiRaised;
 }
 function() public payable {
 buyTokens(msg.sender);
 }
}