pragma solidity ^0.4.13;
contract Owned {
 function Owned() {
 owner = msg.sender;
 }
 address public owner;
 modifier onlyOwner { if (msg.sender == owner) _; }
 function changeOwner(address _newOwner) onlyOwner {
 owner = _newOwner;
 }
 function execute(address _dst, uint _value, bytes _data) onlyOwner {
 _dst.call.value(_value)(_data);
 }
}
contract ChooseWHGReturnAddress is Owned {
 mapping (address => address) returnAddresses;
 uint public endDate;
 function ChooseWHGReturnAddress(uint _endDate) {
 endDate = _endDate;
 }
 function requestReturn(address _returnAddr) {
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

 require(now <= endDate);
 require(returnAddresses[msg.sender] == 0x0);
 returnAddresses[msg.sender] = _returnAddr;
 ReturnRequested(msg.sender, _returnAddr);
 }
 function getReturnAddress(address _addr) constant returns (address) {
 if (returnAddresses[_addr] == 0x0) {
 return _addr;
 } else {
 return returnAddresses[_addr];
 }
 }
 function isReturnRequested(address _addr) constant returns (bool) {
 return returnAddresses[_addr] != 0x0;
 }
 event ReturnRequested(address indexed origin, address indexed returnAddress);
}