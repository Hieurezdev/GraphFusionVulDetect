pragma solidity ^0.4.24;
contract GameRegistry {
 struct Record {
 address owner;
 uint time;
 uint keysIndex;
 string description;
 string url;
 }
 mapping(address => Record) records;
 uint public numRecords;
 address[] private keys;
 address owner;
 uint public REGISTRATION_COST = 100 finney;
 uint public TRANSFER_COST = 10 finney;
 uint public VALUE_DISTRIBUTION_KEY_OWNERS = 50;
 function GameRegistry() {
 owner = msg.sender;
 }
 function distributeValue_r() {
 if (msg.value == 0) {
 return;
 }
 uint ownerPercentage = 100 - VALUE_DISTRIBUTION_KEY_OWNERS;
 uint valueForRegOwner = (ownerPercentage * msg.value) / 100;
 owner.send(valueForRegOwner);
 uint valueForEachOwner = (msg.value - valueForRegOwner) / numRecords;
 if (valueForEachOwner <= 0) {
 return;
 }
 for (uint k = 0; k < numRecords; k++) {
 records[keys[k]].owner.send(valueForEachOwner);
 }
 }
 function register_r(address key, string description, string url) {
 if (msg.value < REGISTRATION_COST) {
 if (msg.value > 0) {
 msg.sender.send(msg.value);
 }
 return;
 }
 distributeValue_r();
 if (records[key].time == 0) {
 records[key].time = now;
 records[key].owner = msg.sender;
 records[key].keysIndex = keys.length;
 keys.length++;
 keys[keys.length - 1] = key;
 records[key].description = description;
 records[key].url = url;
 numRecords++;
 }
 }
 function update_r(address key, string description, string url) {
 if (records[key].owner == msg.sender) {
 records[key].description = description;
 records[key].url = url;
 }
 }
 function unregister_r(address key) {
 if (records[key].owner == msg.sender) {
 uint keysIndex = records[key].keysIndex;
 delete records[key];
 numRecords--;
 keys[keysIndex] = keys[keys.length - 1];
 records[keys[keysIndex]].keysIndex = keysIndex;
 keys.length--;
 }
 }
 function transfer(address key, address newOwner) {
 if (msg.value < TRANSFER_COST) {
 if (msg.value > 0) {
 msg.sender.send(msg.value);
 }
 return;
 }
 distributeValue_r();
 if (records[key].owner == msg.sender) {
 records[key].owner = newOwner;
 }
 }
 function isRegistered_r(address key) returns(bool) {
 return records[key].time != 0;
 }
 function getRecordAtIndex_r(uint rindex) returns(address key, address owner, uint time, string description, string url) {
 Record record = records[keys[rindex]];
 key = keys[rindex];
 owner = record.owner;
 time = record.time;
 description = record.description;
 url = record.url;
 }
 function getRecord_r(address key) returns(address owner, uint time, string description, string url) {
 Record record = records[key];
 owner = record.owner;
 time = record.time;
 description = record.description;
 url = record.url;
 }
 function getOwner_r(address key) returns(address) {
 return records[key].owner;
 }
 function getTime_r(address key) returns(uint) {
 return records[key].time;
 }
 function getTotalRecords_r() returns(uint) {
 return numRecords;
 }
 function returnValue_r() internal {
 if (msg.value > 0) {
 msg.sender.send(msg.value);
 }
 }
 function withdraw_r(uint value) {
 if (msg.sender == owner) {
 msg.sender.send(value);
 }
 }
}