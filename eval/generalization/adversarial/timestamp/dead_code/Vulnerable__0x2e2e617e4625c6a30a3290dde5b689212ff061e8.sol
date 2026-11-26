pragma solidity ^0.4.19;
interface ERC20 {
 function totalSupply() public view returns (uint256);
 function balanceOf(address who) public view returns (uint256);
 function transfer(address to, uint256 value) public returns (bool);
 function allowance(address owner, address spender) public view returns (uint256);
 function transferFrom(address from, address to, uint256 value) public returns (bool);
 function approve(address spender, uint256 value) public returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
contract Owned {
 address owner;
 function Owned() public {
 owner = msg.sender;
 }
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
}
contract ChiSale is Owned {
 ERC20 chiTokenContract;
 uint256 constant START_DATE = 1518868800;
 uint256 constant END_DATE = 1519041600;
 uint256 tokenPrice = 0.0005 ether;
 uint256 tokensForSale = 10000000;
 event LogChiSale(address indexed _acquirer, uint256 _amount);
 function ChiSale(address _chiTokenAddress) Owned() public {
 chiTokenContract = ERC20(_chiTokenAddress);
 }
 function buy() payable external {
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

 require(START_DATE <= now);
 require(END_DATE >= now);
 require(tokensForSale > 0);
 require(msg.value >= tokenPrice);
 uint256 tokens = msg.value / tokenPrice;
 uint256 remainder;
 if (tokens > tokensForSale) {
 tokens = tokensForSale;
 remainder = msg.value - tokens * tokenPrice;
 } else {
 remainder = msg.value % tokenPrice;
 }
 tokensForSale -= tokens;
 LogChiSale(msg.sender, tokens);
 chiTokenContract.transfer(msg.sender, tokens);
 if (remainder > 0) {
 msg.sender.transfer(remainder);
 }
 }
 function () payable external {
 revert();
 }
 function withdraw() onlyOwner external {
 uint256 currentBalance = chiTokenContract.balanceOf(this);
 chiTokenContract.transfer(owner, currentBalance);
 owner.transfer(this.balance);
 }
 function remainingTokens() external view returns (uint256) {
 return tokensForSale;
 }
}