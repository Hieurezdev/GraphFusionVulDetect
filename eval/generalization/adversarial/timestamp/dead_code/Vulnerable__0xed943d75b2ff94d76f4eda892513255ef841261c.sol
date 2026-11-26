pragma solidity ^0.4.11;
contract Ownable {
 address public owner;
 function Ownable() {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) onlyOwner {
 if (newOwner != address(0)) {
 owner = newOwner;
 }
 }
}
contract KyberContirbutorWhitelist is Ownable {
 mapping(address=>uint) addressCap;
 function KyberContirbutorWhitelist() {}
 event ListAddress( address _user, uint _cap, uint _time );
 function listAddress( address _user, uint _cap ) onlyOwner {
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

 addressCap[_user] = _cap;
 ListAddress( _user, _cap, now );
 }
 function getCap( address _user ) constant returns(uint) {
 return addressCap[_user];
 }
}