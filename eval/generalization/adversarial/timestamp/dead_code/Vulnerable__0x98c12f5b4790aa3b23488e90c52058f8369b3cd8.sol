pragma solidity ^0.4.15;
contract PaperTrading {
rebalance[] public record;
struct rebalance{
 address creator;
 bytes32 shasum;
 uint256 time;
 uint256 blocknum;
 string remarks;
}
function addRecord(bytes32 shasum,string remarks) public returns (uint256 recordID) {
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

 recordID = record.length++;
 rebalance storage Reb = record[recordID];
 Reb.creator=msg.sender;
 Reb.shasum=shasum;
 Reb.time = block.timestamp;
 Reb.blocknum = block.number;
 Reb.remarks = remarks;
 LogRebalance(Reb.creator,Reb.shasum,Reb.remarks,Reb.time,Reb.blocknum,recordID);
}
event LogRebalance(address Creator, bytes32 sha256sum, string Remarks, uint256 time, uint256 blocknum, uint256 indexed RecordID );
}