pragma solidity ^0.4.13;
contract Prover {
 using Sets for *;
 address owner;
 Sets.addressSet internal users;
 mapping (address => UserAccount) internal ledger;
 struct UserAccount {
 Sets.bytes32Set hashes;
 mapping (bytes32 => Entry) entries;
 }
 struct Entry {
 uint256 time;
 uint256 value;
 }
 function Prover() {
 owner = msg.sender;
 }
 function () {
 revert();
 }
 modifier hasAccount() {
 assert(ledger[msg.sender].hashes.length() >= 1);
 _;
 }
 function proveIt(address target, bytes32 dataHash) external constant
 returns (bool proved, uint256 time, uint256 value)
 {
 return status(target, dataHash);
 }
 function proveIt(address target, string dataString) external constant
 returns (bool proved, uint256 time, uint256 value)
 {
 return status(target, sha3(dataString));
 }
 function usersGetter() public constant
 returns (uint256 number_unique_addresses, address[] unique_addresses)
 {
 return (users.length(), users.members);
 }
 function userEntries(address target) external constant returns (bytes32[]) {
 return ledger[target].hashes.members;
 }
 function addEntry(bytes32 dataHash) payable {
 _addEntry(dataHash);
 }
 function addEntry(string dataString) payable {
 _addEntry(sha3(dataString));
 }
 function deleteEntry(bytes32 dataHash) hasAccount {
 _deleteEntry(dataHash);
 }
 function deleteEntry(string dataString) hasAccount {
 _deleteEntry(sha3(dataString));
 }
 function selfDestruct() {
 if ((msg.sender == owner) && (users.length() == 0)) {
 selfdestruct(owner);
 }
 }
 function _addEntry(bytes32 dataHash) internal {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 assert(!ledger[msg.sender].hashes.contains(dataHash));
 ledger[msg.sender].hashes.insert(dataHash);
 ledger[msg.sender].entries[dataHash] = Entry(now, msg.value);
 users.insert(msg.sender);
 }
 function _deleteEntry(bytes32 dataHash) internal {
 assert(ledger[msg.sender].hashes.contains(dataHash));
 uint256 rebate = ledger[msg.sender].entries[dataHash].value;
 ledger[msg.sender].hashes.remove(dataHash);
 delete ledger[msg.sender].entries[dataHash];
 if (rebate > 0) {
 msg.sender.transfer(rebate);
 }
 if (ledger[msg.sender].hashes.length() == 0) {
 users.remove(msg.sender);
 }
 }
 function status(address target, bytes32 dataHash) internal constant
 returns (bool proved, uint256 time, uint256 value)
 {
 return (ledger[msg.sender].hashes.contains(dataHash),
 ledger[target].entries[dataHash].time,
 ledger[target].entries[dataHash].value);
 }
}
library Sets {
 struct addressSet {
 address[] members;
 mapping (address => bool) memberExists;
 mapping (address => uint) memberIndex;
 }
 function insert(addressSet storage self, address other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length;
 self.members.push(other);
 }
 }
 function remove(addressSet storage self, address other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length - 1]] = index;
 self.members[index] = self.members[self.members.length - 1];
 self.members.length--;
 }
 }
 function contains(addressSet storage self, address other) returns (bool) {
 return self.memberExists[other];
 }
 function length(addressSet storage self) returns (uint256) {
 return self.members.length;
 }
 struct uintSet {
 uint[] members;
 mapping (uint => bool) memberExists;
 mapping (uint => uint) memberIndex;
 }
 function insert(uintSet storage self, uint other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length;
 self.members.push(other);
 }
 }
 function remove(uintSet storage self, uint other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length - 1]] = index;
 self.members[index] = self.members[self.members.length - 1];
 self.members.length--;
 }
 }
 function contains(uintSet storage self, uint other) returns (bool) {
 return self.memberExists[other];
 }
 function length(uintSet storage self) returns (uint256) {
 return self.members.length;
 }
 struct uint8Set {
 uint8[] members;
 mapping (uint8 => bool) memberExists;
 mapping (uint8 => uint) memberIndex;
 }
 function insert(uint8Set storage self, uint8 other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length;
 self.members.push(other);
 }
 }
 function remove(uint8Set storage self, uint8 other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length - 1]] = index;
 self.members[index] = self.members[self.members.length - 1];
 self.members.length--;
 }
 }
 function contains(uint8Set storage self, uint8 other) returns (bool) {
 return self.memberExists[other];
 }
 function length(uint8Set storage self) returns (uint256) {
 return self.members.length;
 }
 struct intSet {
 int[] members;
 mapping (int => bool) memberExists;
 mapping (int => uint) memberIndex;
 }
 function insert(intSet storage self, int other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length;
 self.members.push(other);
 }
 }
 function remove(intSet storage self, int other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length - 1]] = index;
 self.members[index] = self.members[self.members.length - 1];
 self.members.length--;
 }
 }
 function contains(intSet storage self, int other) returns (bool) {
 return self.memberExists[other];
 }
 function length(intSet storage self) returns (uint256) {
 return self.members.length;
 }
 struct int8Set {
 int8[] members;
 mapping (int8 => bool) memberExists;
 mapping (int8 => uint) memberIndex;
 }
 function insert(int8Set storage self, int8 other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length;
 self.members.push(other);
 }
 }
 function remove(int8Set storage self, int8 other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length - 1]] = index;
 self.members[index] = self.members[self.members.length - 1];
 self.members.length--;
 }
 }
 function contains(int8Set storage self, int8 other) returns (bool) {
 return self.memberExists[other];
 }
 function length(int8Set storage self) returns (uint256) {
 return self.members.length;
 }
 struct byteSet {
 byte[] members;
 mapping (byte => bool) memberExists;
 mapping (byte => uint) memberIndex;
 }
 function insert(byteSet storage self, byte other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length;
 self.members.push(other);
 }
 }
 function remove(byteSet storage self, byte other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length - 1]] = index;
 self.members[index] = self.members[self.members.length - 1];
 self.members.length--;
 }
 }
 function contains(byteSet storage self, byte other) returns (bool) {
 return self.memberExists[other];
 }
 function length(byteSet storage self) returns (uint256) {
 return self.members.length;
 }
 struct bytes32Set {
 bytes32[] members;
 mapping (bytes32 => bool) memberExists;
 mapping (bytes32 => uint) memberIndex;
 }
 function insert(bytes32Set storage self, bytes32 other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length;
 self.members.push(other);
 }
 }
 function remove(bytes32Set storage self, bytes32 other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length - 1]] = index;
 self.members[index] = self.members[self.members.length - 1];
 self.members.length--;
 }
 }
 function contains(bytes32Set storage self, bytes32 other) returns (bool) {
 return self.memberExists[other];
 }
 function length(bytes32Set storage self) returns (uint256) {
 return self.members.length;
 }
}