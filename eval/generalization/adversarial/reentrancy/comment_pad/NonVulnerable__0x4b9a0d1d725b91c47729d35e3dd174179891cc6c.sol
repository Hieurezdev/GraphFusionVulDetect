pragma solidity ^0.4.13;
contract DSExec {
 function tryExec( address target, bytes calldata, uint value)
 internal
 returns (bool call_ret)
 {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 return target.call.value(value)(calldata);
 }
 function exec( address target, bytes calldata, uint value)
 internal
 {
 if(!tryExec(target, calldata, value)) {
 revert();
 }
 }
 function exec( address t, bytes c )
 internal
 {
 exec(t, c, 0);
 }
 function exec( address t, uint256 v )
 internal
 {
 bytes memory c; exec(t, c, v);
 }
 function tryExec( address t, bytes c )
 internal
 returns (bool)
 {
 return tryExec(t, c, 0);
 }
 function tryExec( address t, uint256 v )
 internal
 returns (bool)
 {
 bytes memory c; return tryExec(t, c, v);
 }
}
contract DSNote {
 event LogNote(
 bytes4 indexed sig,
 address indexed guy,
 bytes32 indexed foo,
 bytes32 indexed bar,
 uint wad,
 bytes fax
 ) anonymous;
 modifier note {
 bytes32 foo;
 bytes32 bar;
 assembly {
 foo := calldataload(4)
 bar := calldataload(36)
 }
 LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);
 _;
 }
}
contract DSGroup is DSExec, DSNote {
 address[] public members;
 uint public quorum;
 uint public window;
 uint public actionCount;
 mapping (uint => Action) public actions;
 mapping (uint => mapping (address => bool)) public confirmedBy;
 mapping (address => bool) public isMember;
 event Proposed (uint id, bytes calldata);
 event Confirmed (uint id, address member);
 event Triggered (uint id);
 struct Action {
 address target;
 bytes calldata;
 uint value;
 uint confirmations;
 uint deadline;
 bool triggered;
 }
 function DSGroup(
 address[] members_,
 uint quorum_,
 uint window_
 ) {
 members = members_;
 quorum = quorum_;
 window = window_;
 for (uint i = 0; i < members.length; i++) {
 isMember[members[i]] = true;
 }
 }
 function memberCount() constant returns (uint) {
 return members.length;
 }
 function target(uint id) constant returns (address) {
 return actions[id].target;
 }
 function calldata(uint id) constant returns (bytes) {
 return actions[id].calldata;
 }
 function value(uint id) constant returns (uint) {
 return actions[id].value;
 }
 function confirmations(uint id) constant returns (uint) {
 return actions[id].confirmations;
 }
 function deadline(uint id) constant returns (uint) {
 return actions[id].deadline;
 }
 function triggered(uint id) constant returns (bool) {
 return actions[id].triggered;
 }
 function confirmed(uint id) constant returns (bool) {
 return confirmations(id) >= quorum;
 }
 function expired(uint id) constant returns (bool) {
 return now > deadline(id);
 }
 function deposit() note payable {
 }
 function propose(
 address target,
 bytes calldata,
 uint value
 ) onlyMembers note returns (uint id) {
 id = ++actionCount;
 actions[id].target = target;
 actions[id].calldata = calldata;
 actions[id].value = value;
 actions[id].deadline = now + window;
 Proposed(id, calldata);
 }
 function confirm(uint id) onlyMembers onlyActive(id) note {
 assert(!confirmedBy[id][msg.sender]);
 confirmedBy[id][msg.sender] = true;
 actions[id].confirmations++;
 Confirmed(id, msg.sender);
 }
 function trigger(uint id) onlyMembers onlyActive(id) note {
 assert(confirmed(id));
 actions[id].triggered = true;
 exec(actions[id].target, actions[id].calldata, actions[id].value);
 Triggered(id);
 }
 modifier onlyMembers {
 assert(isMember[msg.sender]);
 _;
 }
 modifier onlyActive(uint id) {
 assert(!expired(id));
 assert(!triggered(id));
 _;
 }
 function getInfo() constant returns (
 uint quorum_,
 uint memberCount,
 uint window_,
 uint actionCount_
 ) {
 return (quorum, members.length, window, actionCount);
 }
 function getActionStatus(uint id) constant returns (
 uint confirmations,
 uint deadline,
 bool triggered,
 address target,
 uint value
 ) {
 return (
 actions[id].confirmations,
 actions[id].deadline,
 actions[id].triggered,
 actions[id].target,
 actions[id].value
 );
 }
}
contract DSGroupFactory is DSNote {
 mapping (address => bool) public isGroup;
 function newGroup(
 address[] members,
 uint quorum,
 uint window
 ) note returns (DSGroup group) {
 group = new DSGroup(members, quorum, window);
 isGroup[group] = true;
 }
}
contract DBC {
 modifier pre_cond(bool condition) {
 require(condition);
 _;
 }
 modifier post_cond(bool condition) {
 _;
 assert(condition);
 }
 modifier invariant(bool condition) {
 require(condition);
 _;
 assert(condition);
 }
}
contract Owned is DBC {
 address public owner;
 function Owned() { owner = msg.sender; }
 function changeOwner(address ofNewOwner) pre_cond(isOwner()) { owner = ofNewOwner; }
 function isOwner() internal returns (bool) { return msg.sender == owner; }
}
contract Governance is DBC, Owned, DSGroup {
 struct Version {
 address version;
 bool active;
 uint timestamp;
 }
 address public MELON_ASSET;
 address[] public authorities;
 Version[] public versions;
 mapping (address => uint) public versionToProposalIds;
 mapping (uint => uint) public versionIdToShutdownIds;
 event VersionUpdated(uint id);
 function Governance(
 address[] ofAuthorities,
 uint ofQuorum,
 uint ofWindow
 )
 DSGroup(ofAuthorities, ofQuorum, ofWindow)
 {}
 function getVersionById(uint id) view returns (address ofVersion, bool active, uint timestamp) {
 return (
 versions[id].version,
 versions[id].active,
 versions[id].timestamp
 );
 }
 function addVersion(
 address ofVersion
 )
 pre_cond(msg.sender == address(this))
 returns (uint id)
 {
 require(msg.sender == address(this));
 Version memory info;
 info.version = ofVersion;
 info.active = true;
 info.timestamp = now;
 versions.push(info);
 emit VersionUpdated(versions.length - 1);
 }
 function shutDownVersion(uint id)
 pre_cond(msg.sender == address(this))
 pre_cond(isActive(id))
 {
 require(msg.sender == address(this));
 VersionInterface Version = VersionInterface(versions[id].version);
 Version.shutDown();
 delete versions[id];
 emit VersionUpdated(id);
 }
 function getVersionsLength() public view returns (uint) {
 return versions.length;
 }
 function isActive(uint id) public view returns (bool active) {
 (, active, ) = getVersionById(id);
 }
}
interface VersionInterface {
 event FundUpdated(uint id);
 function shutDown() external;
 function setupFund(
 bytes32 ofFundName,
 address ofQuoteAsset,
 uint ofManagementFee,
 uint ofPerformanceFee,
 address ofCompliance,
 address ofRiskMgmt,
 address[] ofExchanges,
 address[] ofDefaultAssets,
 uint8 v,
 bytes32 r,
 bytes32 s
 );
 function shutDownFund(address ofFund);
 function getNativeAsset() view returns (address);
 function getFundById(uint withId) view returns (address);
 function getLastFundId() view returns (uint);
 function getFundByManager(address ofManager) view returns (address);
 function termsAndConditionsAreSigned(uint8 v, bytes32 r, bytes32 s) view returns (bool signed);
}