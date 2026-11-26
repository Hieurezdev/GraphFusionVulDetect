pragma solidity ^0.5.2;
library SafeMath {
 function mul_r(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 require(c / a == b);
 return c;
 }
 function div_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b > 0);
 uint256 c = a / b;
 return c;
 }
 function sub_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b <= a);
 uint256 c = a - b;
 return c;
 }
 function add_r(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 require(c >= a);
 return c;
 }
 function mod_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b != 0);
 return a % b;
 }
}
interface IERC20 {
 function transfer(address to, uint256 value) external returns (bool);
 function approve(address spender, uint256 value) external returns (bool);
 function transferFrom(address from, address to, uint256 value) external returns (bool);
 function totalSupply() external view returns (uint256);
 function balanceOf(address who) external view returns (uint256);
 function allowance(address owner, address spender) external view returns (uint256);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeERC20 {
 using SafeMath for uint256;
 function safeTransfer_r(IERC20 token_r, address to, uint256 value) internal {
 require(token_r.transfer(to, value));
 }
 function safeTransferFrom(IERC20 token_r, address from, address to, uint256 value) internal {
 require(token_r.transferFrom(from, to, value));
 }
 function safeApprove_r(IERC20 token_r, address spender, uint256 value) internal {
 require((value == 0) || (token_r.allowance(msg.sender, spender) == 0));
 require(token_r.approve(spender, value));
 }
 function safeIncreaseAllowance_r(IERC20 token_r, address spender, uint256 value) internal {
 uint256 newAllowance = token_r.allowance(address(this), spender).add_r(value);
 require(token_r.approve(spender, newAllowance));
 }
 function safeDecreaseAllowance_r(IERC20 token_r, address spender, uint256 value) internal {
 uint256 newAllowance = token_r.allowance(address(this), spender).sub_r(value);
 require(token_r.approve(spender, newAllowance));
 }
}
contract TokenTimelock {
 using SafeERC20 for IERC20;
 IERC20 private _token;
 address private _beneficiary;
 uint256 private _releaseTime;
 constructor (IERC20 token_r, address beneficiary_r, uint256 releaseTime_r) public {
 require(releaseTime_r > block.timestamp);
 _token = token_r;
 _beneficiary = beneficiary_r;
 _releaseTime = releaseTime_r;
 }
 function token_r() public view returns (IERC20) {
 return _token;
 }
 function beneficiary_r() public view returns (address) {
 return _beneficiary;
 }
 function releaseTime_r() public view returns (uint256) {
 return _releaseTime;
 }
 function release_r() public {
 require(block.timestamp >= _releaseTime);
 uint256 amount = _token.balanceOf(address(this));
 require(amount > 0);
 _token.safeTransfer_r(_beneficiary, amount);
 }
}