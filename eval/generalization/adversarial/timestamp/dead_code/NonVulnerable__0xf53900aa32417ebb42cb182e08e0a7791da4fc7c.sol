pragma solidity ^0.4.18;
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
contract ERC20 {
 function totalSupply() public view returns (uint256);
 function balanceOf(address who) public view returns (uint256);
 function transfer(address to, uint256 value) public returns (bool);
 function allowance(address owner, address spender) public view returns (uint256);
 function transferFrom(address from, address to, uint256 value) public returns (bool);
 function approve(address spender, uint256 value) public returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ZpoCrowdsaleA {
 using SafeMath for uint256;
 uint256 public constant HARD_CAP = 2000000000 * (10 ** 18);
 uint256 public constant ICO_CAP = 7000;
 uint256 public constant NUM_STAGES = 4;
 uint256 public constant ICO_START1 = 1518689400;
 uint256 public constant ICO_START2 = ICO_START1 + 300 seconds;
 uint256 public constant ICO_START3 = ICO_START2 + 300 seconds;
 uint256 public constant ICO_START4 = ICO_START3 + 300 seconds;
 uint256 public constant ICO_END = ICO_START4 + 300 seconds;
 uint256 public constant ICO_RATE1 = 20000 * (10 ** 18);
 uint256 public constant ICO_RATE2 = 18000 * (10 ** 18);
 uint256 public constant ICO_RATE3 = 17000 * (10 ** 18);
 uint256 public constant ICO_RATE4 = 16000 * (10 ** 18);
 uint256 public constant ICO_CAP1 = 14000;
 uint256 public constant ICO_CAP2 = 21000;
 uint256 public constant ICO_CAP3 = 28000;
 uint256 public constant ICO_CAP4 = 35000;
 address public owner;
 ERC20 public tokenReward;
 address public tokenOwner;
 address public wallet;
 uint256 public stage = 0;
 uint256 public tokensSold = 0;
 uint256 public weiRaised = 0;
 event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
 event IcoStageStarted(uint256 stage);
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function ZpoCrowdsaleA(address _tokenAddress, address _wallet) public {
 require(_tokenAddress != address(0));
 require(_wallet != address(0));
 owner = msg.sender;
 tokenOwner = msg.sender;
 wallet = _wallet;
 tokenReward = ERC20(_tokenAddress);
 stage = 0;
 }
 function () external payable {
 buyTokens(msg.sender);
 }
 function buyTokens(address _beneficiary) public payable {
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

 require(_beneficiary != address(0));
 require(stage <= NUM_STAGES);
 require(validPurchase());
 require(now <= ICO_END);
 require(weiRaised < ICO_CAP4);
 require(msg.value >= (10 ** 17));
 require(msg.value <= (1000 ** 18));
 determineCurrentStage();
 require(stage >= 1 && stage <= NUM_STAGES);
 uint256 weiAmount = msg.value;
 uint256 tokens = getTokenAmount(weiAmount);
 require(tokens > 0);
 weiRaised = weiRaised.add(weiAmount);
 tokensSold = tokensSold.add(tokens);
 assert(tokenReward.transferFrom(tokenOwner, _beneficiary, tokens));
 TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
 forwardFunds();
 }
 function forwardFunds() internal {
 wallet.transfer(msg.value);
 }
 function determineCurrentStage() internal {
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

 uint256 prevStage = stage;
 checkCap();
 if (stage < 4 && now >= ICO_START4) {
 stage = 4;
 checkNewPeriod(prevStage);
 return;
 }
 if (stage < 3 && now >= ICO_START3) {
 stage = 3;
 checkNewPeriod(prevStage);
 return;
 }
 if (stage < 2 && now >= ICO_START2) {
 stage = 2;
 checkNewPeriod(prevStage);
 return;
 }
 if (stage < 1 && now >= ICO_START1) {
 stage = 1;
 checkNewPeriod(prevStage);
 return;
 }
 }
 function checkCap() internal {
 if (weiRaised >= ICO_CAP3) {
 stage = 4;
 }
 else if (weiRaised >= ICO_CAP2) {
 stage = 3;
 }
 else if (weiRaised >= ICO_CAP1) {
 stage = 2;
 }
 }
 function checkNewPeriod(uint256 _prevStage) internal {
 if (stage != _prevStage) {
 IcoStageStarted(stage);
 }
 }
 function getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
 uint256 rate = 0;
 if (stage == 1) {
 rate = ICO_RATE1;
 } else if (stage == 2) {
 rate = ICO_RATE2;
 } else if (stage == 3) {
 rate = ICO_RATE3;
 } else if (stage == 4) {
 rate = ICO_RATE4;
 }
 return rate.mul(_weiAmount);
 }
 function validPurchase() internal view returns (bool) {
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

 bool withinPeriod = now >= ICO_START1 && now <= ICO_END;
 bool nonZeroPurchase = msg.value != 0;
 return withinPeriod && nonZeroPurchase;
 }
}