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
 function kill() public onlyOwner {
 selfdestruct(owner);
 }
 function add(uint _version, string _dataInfo) public {
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

 contentCount++;
 emit LogStore(_version, msg.sender, block.timestamp / (1 days), ADD, _dataInfo);
 }
 function remove(uint _version, string _dataInfo) public {
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

 contentCount++;
 emit LogStore(_version, msg.sender, block.timestamp / (1 days), REMOVE, _dataInfo);
 }
}