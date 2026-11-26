pragma solidity ^0.4.21;
contract Ownable {
 address public owner;
 event OwnershipRenounced(address indexed previousOwner);
 event OwnershipTransferred(
 address indexed previousOwner,
 address indexed newOwner
 );
 function Ownable() public {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
}
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
 if (a == 0) {
 return 0;
 }
 c = a * b;
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
 function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract ERC20Basic {
 function totalSupply() public view returns (uint256);
 function balanceOf(address who) public view returns (uint256);
 function transfer(address to, uint256 value) public returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
contract BVesting is Ownable {
 using SafeMath for uint256;
 address public teamWallet;
 address public earlyWallet;
 address public institutionWallet;
 uint256 public teamTimeLock = 1000 minutes;
 uint256 public earlyTimeLock = 5 * 30 minutes;
 uint256 public institutionTimeLock = 50 * 30 minutes;
 uint256 public teamAllocation = 15 * (10 ** 7) * (10 ** 18);
 uint256 public earlyAllocation = 5 * (10 ** 7) * (10 ** 18);
 uint256 public institutionAllocation = 15 * (10 ** 7) * (10 ** 18);
 uint256 public totalAllocation = 35 * (10 ** 7) * (10 ** 18);
 uint256 public teamStageSetting = 34;
 uint256 public earlyStageSetting = 5;
 uint256 public institutionStageSetting = 50;
 ERC20Basic public token;
 uint256 public start;
 uint256 public lockStartTime;
 mapping(address => uint256) public allocations;
 mapping(address => uint256) public stageSettings;
 mapping(address => uint256) public timeLockDurations;
 mapping(address => uint256) public releasedAmounts;
 modifier onlyReserveWallets {
 require(allocations[msg.sender] > 0);
 _;
 }
 function BVesting(ERC20Basic _token,
 address _teamWallet,
 address _earlyWallet,
 address _institutionWallet,
 uint256 _start,
 uint256 _lockTime)public{
 require(_start > 0);
 require(_lockTime > 0);
 require(_start.add(_lockTime) > 0);
 require(_teamWallet != address(0));
 require(_earlyWallet != address(0));
 require(_institutionWallet != address(0));
 token = _token;
 teamWallet = _teamWallet;
 earlyWallet = _earlyWallet;
 institutionWallet = _institutionWallet;
 start = _start;
 lockStartTime = start.add(_lockTime);
 }
 function allocateToken() onlyOwner public{
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(block.timestamp > lockStartTime);
 require(allocations[teamWallet] == 0);
 require(token.balanceOf(address(this)) == totalAllocation);
 allocations[teamWallet] = teamAllocation;
 allocations[earlyWallet] = earlyAllocation;
 allocations[institutionWallet] = institutionAllocation;
 stageSettings[teamWallet] = teamStageSetting;
 stageSettings[earlyWallet] = earlyStageSetting;
 stageSettings[institutionWallet] = institutionStageSetting;
 timeLockDurations[teamWallet] = teamTimeLock;
 timeLockDurations[earlyWallet] = earlyTimeLock;
 timeLockDurations[institutionWallet] = institutionTimeLock;
 }
 function releaseToken() onlyReserveWallets public{
 uint256 stage = vestStage();
 uint256 totalUnlocked = stage.mul(allocations[msg.sender]).div(stageSettings[msg.sender]);
 require(totalUnlocked < allocations[msg.sender]);
 require(releasedAmounts[msg.sender] < totalUnlocked);
 uint256 payment = totalUnlocked - releasedAmounts[msg.sender];
 releasedAmounts[msg.sender] = totalUnlocked;
 require(token.transfer(teamWallet, payment));
 }
 function vestStage() public view onlyReserveWallets returns(uint256){
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 uint256 vestingMonths = timeLockDurations[msg.sender].div(stageSettings[msg.sender]);
 uint256 stage = (block.timestamp.sub(lockStartTime)).div(vestingMonths);
 if(stage > stageSettings[msg.sender]){
 stage = stageSettings[msg.sender];
 }
 return stage;
 }
}