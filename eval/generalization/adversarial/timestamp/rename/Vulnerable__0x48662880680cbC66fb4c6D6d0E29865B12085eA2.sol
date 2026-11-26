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
 assert(ledger[msg.sender].hashes.length_r() >= 1);
 _;
 }
 function proveIt_r(address target, bytes32 dataHash) external constant
 returns (bool proved, uint256 time, uint256 value)
 {
 return status_r(target, dataHash);
 }
 function proveIt_r(address target, string dataString) external constant
 returns (bool proved, uint256 time, uint256 value)
 {
 return status_r(target, sha3(dataString));
 }
 function usersGetter_r() public constant
 returns (uint256 number_unique_addresses, address[] unique_addresses)
 {
 return (users.length_r(), users.members);
 }
 function userEntries_r(address target) external constant returns (bytes32[]) {
 return ledger[target].hashes.members;
 }
 function addEntry_r(bytes32 dataHash) payable {
 _addEntry_r(dataHash);
 }
 function addEntry_r(string dataString) payable {
 _addEntry_r(sha3(dataString));
 }
 function deleteEntry_r(bytes32 dataHash) hasAccount {
 _deleteEntry_r(dataHash);
 }
 function deleteEntry_r(string dataString) hasAccount {
 _deleteEntry_r(sha3(dataString));
 }
 function selfDestruct_r() {
 if ((msg.sender == owner) && (users.length_r() == 0)) {
 selfdestruct(owner);
 }
 }
 function _addEntry_r(bytes32 dataHash) internal {
 assert(!ledger[msg.sender].hashes.contains_r(dataHash));
 ledger[msg.sender].hashes.insert_r(dataHash);
 ledger[msg.sender].entries[dataHash] = Entry(now, msg.value);
 users.insert_r(msg.sender);
 }
 function _deleteEntry_r(bytes32 dataHash) internal {
 assert(ledger[msg.sender].hashes.contains_r(dataHash));
 uint256 rebate = ledger[msg.sender].entries[dataHash].value;
 ledger[msg.sender].hashes.remove_r(dataHash);
 delete ledger[msg.sender].entries[dataHash];
 if (rebate > 0) {
 msg.sender.transfer(rebate);
 }
 if (ledger[msg.sender].hashes.length_r() == 0) {
 users.remove_r(msg.sender);
 }
 }
 function status_r(address target, bytes32 dataHash) internal constant
 returns (bool proved, uint256 time, uint256 value)
 {
 return (ledger[msg.sender].hashes.contains_r(dataHash),
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
 function insert_r(addressSet storage self, address other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length_r;
 self.members.push(other);
 }
 }
 function remove_r(addressSet storage self, address other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length_r - 1]] = index;
 self.members[index] = self.members[self.members.length_r - 1];
 self.members.length_r--;
 }
 }
 function contains_r(addressSet storage self, address other) returns (bool) {
 return self.memberExists[other];
 }
 function length_r(addressSet storage self) returns (uint256) {
 return self.members.length_r;
 }
 struct uintSet {
 uint[] members;
 mapping (uint => bool) memberExists;
 mapping (uint => uint) memberIndex;
 }
 function insert_r(uintSet storage self, uint other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length_r;
 self.members.push(other);
 }
 }
 function remove_r(uintSet storage self, uint other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length_r - 1]] = index;
 self.members[index] = self.members[self.members.length_r - 1];
 self.members.length_r--;
 }
 }
 function contains_r(uintSet storage self, uint other) returns (bool) {
 return self.memberExists[other];
 }
 function length_r(uintSet storage self) returns (uint256) {
 return self.members.length_r;
 }
 struct uint8Set {
 uint8[] members;
 mapping (uint8 => bool) memberExists;
 mapping (uint8 => uint) memberIndex;
 }
 function insert_r(uint8Set storage self, uint8 other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length_r;
 self.members.push(other);
 }
 }
 function remove_r(uint8Set storage self, uint8 other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length_r - 1]] = index;
 self.members[index] = self.members[self.members.length_r - 1];
 self.members.length_r--;
 }
 }
 function contains_r(uint8Set storage self, uint8 other) returns (bool) {
 return self.memberExists[other];
 }
 function length_r(uint8Set storage self) returns (uint256) {
 return self.members.length_r;
 }
 struct intSet {
 int[] members;
 mapping (int => bool) memberExists;
 mapping (int => uint) memberIndex;
 }
 function insert_r(intSet storage self, int other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length_r;
 self.members.push(other);
 }
 }
 function remove_r(intSet storage self, int other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length_r - 1]] = index;
 self.members[index] = self.members[self.members.length_r - 1];
 self.members.length_r--;
 }
 }
 function contains_r(intSet storage self, int other) returns (bool) {
 return self.memberExists[other];
 }
 function length_r(intSet storage self) returns (uint256) {
 return self.members.length_r;
 }
 struct int8Set {
 int8[] members;
 mapping (int8 => bool) memberExists;
 mapping (int8 => uint) memberIndex;
 }
 function insert_r(int8Set storage self, int8 other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length_r;
 self.members.push(other);
 }
 }
 function remove_r(int8Set storage self, int8 other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length_r - 1]] = index;
 self.members[index] = self.members[self.members.length_r - 1];
 self.members.length_r--;
 }
 }
 function contains_r(int8Set storage self, int8 other) returns (bool) {
 return self.memberExists[other];
 }
 function length_r(int8Set storage self) returns (uint256) {
 return self.members.length_r;
 }
 struct byteSet {
 byte[] members;
 mapping (byte => bool) memberExists;
 mapping (byte => uint) memberIndex;
 }
 function insert_r(byteSet storage self, byte other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length_r;
 self.members.push(other);
 }
 }
 function remove_r(byteSet storage self, byte other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length_r - 1]] = index;
 self.members[index] = self.members[self.members.length_r - 1];
 self.members.length_r--;
 }
 }
 function contains_r(byteSet storage self, byte other) returns (bool) {
 return self.memberExists[other];
 }
 function length_r(byteSet storage self) returns (uint256) {
 return self.members.length_r;
 }
 struct bytes32Set {
 bytes32[] members;
 mapping (bytes32 => bool) memberExists;
 mapping (bytes32 => uint) memberIndex;
 }
 function insert_r(bytes32Set storage self, bytes32 other) {
 if (!self.memberExists[other]) {
 self.memberExists[other] = true;
 self.memberIndex[other] = self.members.length_r;
 self.members.push(other);
 }
 }
 function remove_r(bytes32Set storage self, bytes32 other) {
 if (self.memberExists[other]) {
 self.memberExists[other] = false;
 uint index = self.memberIndex[other];
 self.memberIndex[self.members[self.members.length_r - 1]] = index;
 self.members[index] = self.members[self.members.length_r - 1];
 self.members.length_r--;
 }
 }
 function contains_r(bytes32Set storage self, bytes32 other) returns (bool) {
 return self.memberExists[other];
 }
 function length_r(bytes32Set storage self) returns (uint256) {
 return self.members.length_r;
 }
}