pragma solidity ^0.4.24;
contract AionClient {
 address private AionAddress;
 constructor(address addraion) public{
 AionAddress = addraion;
 }
 function execfunct(address to, uint256 value, uint256 gaslimit, bytes data) external returns(bool) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(msg.sender == AionAddress);
 return to.call.value(value).gas(gaslimit)(data);
 }
 function () payable public {}
}
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {return 0;}
 uint256 c = a * b;
 require(c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 require(c >= a);
 return c;
 }
}
contract Aion {
 using SafeMath for uint256;
 address public owner;
 uint256 public serviceFee;
 uint256 public AionID;
 uint256 public feeChangeInterval;
 mapping(address => address) public clientAccount;
 mapping(uint256 => bytes32) public scheduledCalls;
 event ExecutedCallEvent(address indexed from, uint256 indexed AionID, bool TxStatus, bool TxStatus_cancel, bool reimbStatus);
 event ScheduleCallEvent(uint256 indexed blocknumber, address indexed from, address to, uint256 value, uint256 gaslimit,
 uint256 gasprice, uint256 fee, bytes data, uint256 indexed AionID, bool schedType);
 event CancellScheduledTxEvent(address indexed from, uint256 Total, bool Status, uint256 indexed AionID);
 event feeChanged(uint256 newfee, uint256 oldfee);
 constructor () public {
 owner = msg.sender;
 serviceFee = 500000000000000;
 }
 function transferOwnership(address newOwner) public {
 require(msg.sender == owner);
 withdraw();
 owner = newOwner;
 }
 function createAccount() internal {
 if(clientAccount[msg.sender]==address(0x0)){
 AionClient newContract = new AionClient(address(this));
 clientAccount[msg.sender] = address(newContract);
 }
 }
 function ScheduleCall(uint256 blocknumber, address to, uint256 value, uint256 gaslimit, uint256 gasprice, bytes data, bool schedType) public payable returns (uint,address){
 require(msg.value == value.add(gaslimit.mul(gasprice)).add(serviceFee));
 AionID = AionID + 1;
 scheduledCalls[AionID] = keccak256(abi.encodePacked(blocknumber, msg.sender, to, value, gaslimit, gasprice, serviceFee, data, schedType));
 createAccount();
 clientAccount[msg.sender].transfer(msg.value);
 emit ScheduleCallEvent(blocknumber, msg.sender, to, value, gaslimit, gasprice, serviceFee, data, AionID, schedType);
 return (AionID,clientAccount[msg.sender]);
 }
 function executeCall(uint256 blocknumber, address from, address to, uint256 value, uint256 gaslimit, uint256 gasprice,
 uint256 fee, bytes data, uint256 aionId, bool schedType) external {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(msg.sender==owner);
 if(schedType) require(blocknumber <= block.timestamp);
 if(!schedType) require(blocknumber <= block.number);
 require(scheduledCalls[aionId]==keccak256(abi.encodePacked(blocknumber, from, to, value, gaslimit, gasprice, fee, data, schedType)));
 AionClient instance = AionClient(clientAccount[from]);
 require(instance.execfunct(address(this), gasprice*gaslimit+fee, 2100, hex"00"));
 bool TxStatus = instance.execfunct(to, value, gasleft().sub(50000), data);
 bool TxStatus_cancel;
 if(!TxStatus && value>0){TxStatus_cancel = instance.execfunct(from, value, 2100, hex"00");}
 delete scheduledCalls[aionId];
 bool reimbStatus = from.call.value((gasleft()).mul(gasprice)).gas(2100)();
 emit ExecutedCallEvent(from, aionId,TxStatus, TxStatus_cancel, reimbStatus);
 }
 function cancellScheduledTx(uint256 blocknumber, address from, address to, uint256 value, uint256 gaslimit, uint256 gasprice,
 uint256 fee, bytes data, uint256 aionId, bool schedType) external returns(bool) {
 if(schedType) require(blocknumber >= block.timestamp+(3 minutes) || blocknumber <= block.timestamp-(5 minutes));
 if(!schedType) require(blocknumber > block.number+10 || blocknumber <= block.number-20);
 require(scheduledCalls[aionId]==keccak256(abi.encodePacked(blocknumber, from, to, value, gaslimit, gasprice, fee, data, schedType)));
 require(msg.sender==from);
 AionClient instance = AionClient(clientAccount[msg.sender]);
 bool Status = instance.execfunct(from, value+gasprice*gaslimit+fee, 3000, hex"00");
 require(Status);
 emit CancellScheduledTxEvent(from, value+gasprice*gaslimit+fee, Status, aionId);
 delete scheduledCalls[aionId];
 return true;
 }
 function withdraw() public {
 require(msg.sender==owner);
 owner.transfer(address(this).balance);
 }
 function updatefee(uint256 fee) public{
 require(msg.sender==owner);
 require(feeChangeInterval<block.timestamp);
 uint256 oldfee = serviceFee;
 if(fee>serviceFee){
 require(((fee.sub(serviceFee)).mul(100)).div(serviceFee)<=10);
 serviceFee = fee;
 } else{
 serviceFee = fee;
 }
 feeChangeInterval = block.timestamp + (1 days);
 emit feeChanged(serviceFee, oldfee);
 }
 function () public payable {
 }
}