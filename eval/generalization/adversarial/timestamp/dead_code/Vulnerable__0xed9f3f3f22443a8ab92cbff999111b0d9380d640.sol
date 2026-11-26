pragma solidity ^0.4.11;
library SafeMath {
 function mul(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal constant returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract PricingStrategy {
 using SafeMath for uint;
 uint public newRateTime;
 uint public rate1;
 uint public rate2;
 uint public minimumWeiAmount;
 function PricingStrategy(
 uint _newRateTime,
 uint _rate1,
 uint _rate2,
 uint _minimumWeiAmount
 ) {
 require(_newRateTime > 0);
 require(_rate1 > 0);
 require(_rate2 > 0);
 require(_minimumWeiAmount > 0);
 newRateTime = _newRateTime;
 rate1 = _rate1;
 rate2 = _rate2;
 minimumWeiAmount = _minimumWeiAmount;
 }
 function isPricingStrategy() public constant returns (bool) {
 return true;
 }
 function calculateTokenAmount(uint weiAmount) public constant returns (uint tokenAmount) {
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

 uint bonusRate = 0;
 if (weiAmount >= minimumWeiAmount) {
 if (now < newRateTime) {
 bonusRate = rate1;
 } else {
 bonusRate = rate2;
 }
 }
 return weiAmount.mul(bonusRate);
 }
}