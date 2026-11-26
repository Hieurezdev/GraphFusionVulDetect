pragma solidity ^0.4.24;
contract Docsign
{
 event Added(address indexed _from);
 event Created(address indexed _from);
 struct Document {
 uint version;
 string name;
 address creator;
 string hash;
 uint date;
 }
 Document[] public a_document;
 uint length;
 function Docsign() {
 Created(msg.sender);
 }
 function Add(uint _version, string _name, string _hash) {
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

 a_document.push(Document(_version,_name,msg.sender, _hash, now));
 Added(msg.sender);
 }
 function getCount() public constant returns(uint) {
 return a_document.length;
 }
 function() { throw; }
}