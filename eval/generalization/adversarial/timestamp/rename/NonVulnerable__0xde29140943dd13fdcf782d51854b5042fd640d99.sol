pragma solidity 0.4.24;
contract Store2 {
 uint16 constant internal NONE = 0;
 uint16 constant internal ADD = 1;
 uint16 constant internal REMOVE = 2;
 address public owner;
 uint public contentCount = 0;
 event LogStore(uint indexed version, address indexed sender, uint indexed timePage,
 uint16 eventType, string dataInfo);
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 constructor() public {
 owner = msg.sender;
 }
 function () public {
 revert();
 }
 function kill_r() public onlyOwner {
 selfdestruct(owner);
 }
 function add_r(uint _version, string _dataInfo) public {
 contentCount++;
 emit LogStore(_version, msg.sender, block.timestamp / (1 days), ADD, _dataInfo);
 }
 function remove_r(uint _version, string _dataInfo) public {
 contentCount++;
 emit LogStore(_version, msg.sender, block.timestamp / (1 days), REMOVE, _dataInfo);
 }
}