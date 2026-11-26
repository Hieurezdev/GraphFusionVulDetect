pragma solidity ^0.5.2;
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
 function safeTransfer(IERC20 token, address to, uint256 value) internal {
 require(token.transfer(to, value));
 }
 function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
 require(token.transferFrom(from, to, value));
 }
 function safeApprove(IERC20 token, address spender, uint256 value) internal {
 require((value == 0) || (token.allowance(msg.sender, spender) == 0));
 require(token.approve(spender, value));
 }
 function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
 uint256 newAllowance = token.allowance(address(this), spender).add(value);
 require(token.approve(spender, newAllowance));
 }
 function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
 uint256 newAllowance = token.allowance(address(this), spender).sub(value);
 require(token.approve(spender, newAllowance));
 }
}
contract TokenTimelock {
 using SafeERC20 for IERC20;
 IERC20 private _token;
 address private _beneficiary;
 uint256 private _releaseTime;
 constructor (IERC20 token, address beneficiary, uint256 releaseTime) public {
 require(releaseTime > block.timestamp);
 _token = token;
 _beneficiary = beneficiary;
 _releaseTime = releaseTime;
 }
 function token() public view returns (IERC20) {
 return _token;
 }
 function beneficiary() public view returns (address) {
 return _beneficiary;
 }
 function releaseTime() public view returns (uint256) {
 return _releaseTime;
 }
 function release() public {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(block.timestamp >= _releaseTime);
 uint256 amount = _token.balanceOf(address(this));
 require(amount > 0);
 _token.safeTransfer(_beneficiary, amount);
 }
}