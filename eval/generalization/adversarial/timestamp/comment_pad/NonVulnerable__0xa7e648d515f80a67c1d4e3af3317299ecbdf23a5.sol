pragma solidity 0.4.24;
interface Token {
 function mint(address to, uint256 value) external returns (bool);
}
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 require(c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b > 0);
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b <= a);
 uint256 c = a - b;
 return c;
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 require(c >= a);
 return c;
 }
 function mod(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b != 0);
 return a % b;
 }
}
contract Ownable {
 address public owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 constructor() public {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) public onlyOwner {
 require(newOwner != address(0));
 emit OwnershipTransferred(owner, newOwner);
 owner = newOwner;
 }
}
contract Investing is Ownable {
 using SafeMath for uint;
 Token public token;
 address public trust;
 address[] public investors;
 struct Investor {
 address investor;
 string currency;
 uint rate;
 uint amount;
 bool redeemed;
 uint timestamp;
 uint tokens;
 }
 mapping(address => Investor[]) public investments;
 mapping(address => uint) public investmentsCount;
 constructor () public {
 owner = msg.sender;
 }
 modifier onlyTrust() {
 require(msg.sender == trust);
 _;
 }
 function makeInvestment(address _investor, string _currency, uint _rate, uint _amount) onlyTrust public returns (bool){
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 uint numberOfTokens;
 numberOfTokens = _amount.div(_rate);
 uint _counter = investments[_investor].push(Investor(_investor, _currency, _rate, _amount, false, now, numberOfTokens));
 investmentsCount[_investor] = _counter;
 require(token.mint(_investor, numberOfTokens));
 investors.push(_investor);
 return true;
 }
 function redeem(address _investor, uint _index) public onlyTrust returns (bool) {
 require(investments[_investor][_index].redeemed == false);
 investments[_investor][_index].redeemed = true;
 return true;
 }
 function setTokenContractsAddress(address _tokenContract) public onlyOwner {
 require(_tokenContract != address(0));
 token = Token(_tokenContract);
 }
 function setTrustAddress(address _trust) public onlyOwner {
 require(_trust != address(0));
 trust = _trust;
 }
 function returnInvestors() public view returns (address[]) {
 return investors;
 }
 function getInvestmentsCounter(address _investor) public view returns(uint) {
 return investmentsCount[_investor];
 }
 function getInvestor(address _investor, uint _index) public view returns(string, uint, uint, bool, uint, uint) {
 return (
 investments[_investor][_index].currency,
 investments[_investor][_index].rate,
 investments[_investor][_index].amount,
 investments[_investor][_index].redeemed,
 investments[_investor][_index].timestamp,
 investments[_investor][_index].tokens
 );
 }
 function isRedeemed(address _investor, uint _index) public view returns(bool) {
 return investments[_investor][_index].redeemed;
 }
}