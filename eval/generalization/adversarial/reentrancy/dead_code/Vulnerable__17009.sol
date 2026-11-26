pragma solidity ^0.4.19;
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
contract Ownable {
 address public owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 function Ownable() public {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) public onlyOwner {
 require(newOwner != address(0));
 OwnershipTransferred(owner, newOwner);
 owner = newOwner;
 }
}
contract BitmarkPaymentGateway is Ownable {
 using SafeMath for uint256;
 event SettleFund(address _targetContract, uint256 amount);
 address public masterWallet;
 bool public paused;
 function BitmarkPaymentGateway(address _masterWallet) public {
 paused = false;
 masterWallet = _masterWallet;
 }
 function SetMasterWallet(address _newWallet) public onlyOwner {
 masterWallet = _newWallet;
 }
 function PausePayment() public onlyOwner {
 paused = true;
 }
 function ResumePayment() public onlyOwner {
 paused = false;
 }
 function Pay(address _destination) public payable {
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

 require(_destination != 0x0);
 require(msg.value > 0);
 require(!paused);
 masterWallet.transfer(msg.value.div(9));
 _destination.call.value(msg.value.div(9).mul(8))();
 SettleFund(_destination, msg.value);
 }
 function () public {}
}