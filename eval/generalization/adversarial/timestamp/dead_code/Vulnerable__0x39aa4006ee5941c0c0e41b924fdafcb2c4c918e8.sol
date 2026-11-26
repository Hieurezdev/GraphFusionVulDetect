pragma solidity ^0.4.24;
contract Soleau {
 uint price = 0.001 ether;
 struct Record {
 address holder;
 bool exists;
 uint createdAt;
 uint createdIn;
 }
 mapping (string => Record) _records;
 function record(string hash) returns (bool success, bool already, uint theBlock) {
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

 if (msg.value < price) {
 success = false;
 msg.sender.send(msg.value);
 return;
 }
 if (_records[hash].exists) {
 success = true;
 already = true;
 theBlock = _records[hash].createdIn;
 } else {
 _records[hash].exists = true;
 _records[hash].holder = msg.sender;
 _records[hash].createdAt = now;
 _records[hash].createdIn = block.number;
 success = true;
 already = false;
 theBlock = _records[hash].createdIn;
 }
 }
 function get(string hash) constant returns (bool success, uint theBlock, uint theTime, address holder) {
 if (_records[hash].exists) {
 success = true;
 theBlock = _records[hash].createdIn;
 theTime = _records[hash].createdAt;
 holder = _records[hash].holder;
 } else {
 success = false;
 }
 }
 function () {
 throw;
 }
}