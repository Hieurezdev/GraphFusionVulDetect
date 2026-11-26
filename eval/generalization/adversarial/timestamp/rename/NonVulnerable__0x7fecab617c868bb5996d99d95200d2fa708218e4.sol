pragma solidity 0.4.24;
library SafeMath {
 function mul_r(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
 if (_a == 0) {
 return 0;
 }
 c = _a * _b;
 assert(c / _a == _b);
 return c;
 }
 function div_r(uint256 _a, uint256 _b) internal pure returns (uint256) {
 return _a / _b;
 }
 function sub_r(uint256 _a, uint256 _b) internal pure returns (uint256) {
 assert(_b <= _a);
 return _a - _b;
 }
 function add_r(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
 c = _a + _b;
 assert(c >= _a);
 return c;
 }
}
library SafeMath8 {
 function mul_r(uint8 a, uint8 b) internal pure returns (uint8) {
 uint8 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div_r(uint8 a, uint8 b) internal pure returns (uint8) {
 uint8 c = a / b;
 return c;
 }
 function sub_r(uint8 a, uint8 b) internal pure returns (uint8) {
 assert(b <= a);
 return a - b;
 }
 function add_r(uint8 a, uint8 b) internal pure returns (uint8) {
 uint8 c = a + b;
 assert(c >= a);
 return c;
 }
}
library SafeMath16 {
 function mul_r(uint16 a, uint16 b) internal pure returns (uint16) {
 uint16 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div_r(uint16 a, uint16 b) internal pure returns (uint16) {
 uint16 c = a / b;
 return c;
 }
 function sub_r(uint16 a, uint16 b) internal pure returns (uint16) {
 assert(b <= a);
 return a - b;
 }
 function add_r(uint16 a, uint16 b) internal pure returns (uint16) {
 uint16 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract Ownable {
 address public owner;
 event OwnershipRenounced(address indexed previousOwner);
 event OwnershipTransferred(
 address indexed previousOwner,
 address indexed newOwner
 );
 constructor() public {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function renounceOwnership_r() public onlyOwner {
 emit OwnershipRenounced(owner);
 owner = address(0);
 }
 function transferOwnership_r(address _newOwner) public onlyOwner {
 _transferOwnership_r(_newOwner);
 }
 function _transferOwnership_r(address _newOwner) internal {
 require(_newOwner != address(0));
 emit OwnershipTransferred(owner, _newOwner);
 owner = _newOwner;
 }
}
contract Polls is Ownable
{
 using SafeMath for uint256;
 using SafeMath16 for uint16;
 using SafeMath8 for uint8;
 event UpgradePollStarted(address proposal);
 event DocumentPollStarted(bytes32 proposal);
 event UpgradeMajority(address proposal);
 event DocumentMajority(bytes32 proposal);
 struct Poll
 {
 uint256 start;
 bool[256] voted;
 uint16 yesVotes;
 uint16 noVotes;
 uint256 duration;
 uint256 cooldown;
 }
 uint256 public pollDuration;
 uint256 public pollCooldown;
 uint16 public totalVoters;
 address[] public upgradeProposals;
 mapping(address => Poll) public upgradePolls;
 mapping(address => bool) public upgradeHasAchievedMajority;
 bytes32[] public documentProposals;
 mapping(bytes32 => Poll) public documentPolls;
 mapping(bytes32 => bool) public documentHasAchievedMajority;
 bytes32[] public documentMajorities;
 constructor(uint256 _pollDuration, uint256 _pollCooldown)
 public
 {
 reconfigure_r(_pollDuration, _pollCooldown);
 }
 function reconfigure_r(uint256 _pollDuration, uint256 _pollCooldown)
 public
 onlyOwner
 {
 require( (5 days <= _pollDuration) && (_pollDuration <= 90 days) &&
 (5 days <= _pollCooldown) && (_pollCooldown <= 90 days) );
 pollDuration = _pollDuration;
 pollCooldown = _pollCooldown;
 }
 function incrementTotalVoters_r()
 external
 onlyOwner
 {
 require(totalVoters < 256);
 totalVoters = totalVoters.add_r(1);
 }
 function getUpgradeProposals_r()
 external
 view
 returns (address[] proposals)
 {
 return upgradeProposals;
 }
 function getUpgradeProposalCount_r()
 external
 view
 returns (uint256 count)
 {
 return upgradeProposals.length;
 }
 function getDocumentProposals_r()
 external
 view
 returns (bytes32[] proposals)
 {
 return documentProposals;
 }
 function getDocumentProposalCount_r()
 external
 view
 returns (uint256 count)
 {
 return documentProposals.length;
 }
 function getDocumentMajorities_r()
 external
 view
 returns (bytes32[] majorities)
 {
 return documentMajorities;
 }
 function hasVotedOnUpgradePoll_r(uint8 _galaxy, address _proposal)
 external
 view
 returns (bool result)
 {
 return upgradePolls[_proposal].voted[_galaxy];
 }
 function hasVotedOnDocumentPoll_r(uint8 _galaxy, bytes32 _proposal)
 external
 view
 returns (bool result)
 {
 return documentPolls[_proposal].voted[_galaxy];
 }
 function startUpgradePoll_r(address _proposal)
 external
 onlyOwner
 {
 require(!upgradeHasAchievedMajority[_proposal]);
 Poll storage poll = upgradePolls[_proposal];
 if (0 == poll.start)
 {
 upgradeProposals.push(_proposal);
 }
 startPoll_r(poll);
 emit UpgradePollStarted(_proposal);
 }
 function startDocumentPoll_r(bytes32 _proposal)
 external
 onlyOwner
 {
 require(!documentHasAchievedMajority[_proposal]);
 Poll storage poll = documentPolls[_proposal];
 if (0 == poll.start)
 {
 documentProposals.push(_proposal);
 }
 startPoll_r(poll);
 emit DocumentPollStarted(_proposal);
 }
 function startPoll_r(Poll storage _poll)
 internal
 {
 require( block.timestamp > ( _poll.start.add_r(
 _poll.duration.add_r(
 _poll.cooldown )) ) );
 _poll.start = block.timestamp;
 delete _poll.voted;
 _poll.yesVotes = 0;
 _poll.noVotes = 0;
 _poll.duration = pollDuration;
 _poll.cooldown = pollCooldown;
 }
 function castUpgradeVote_r(uint8 _as, address _proposal, bool _vote)
 external
 onlyOwner
 returns (bool majority)
 {
 Poll storage poll = upgradePolls[_proposal];
 processVote_r(poll, _as, _vote);
 return updateUpgradePoll_r(_proposal);
 }
 function castDocumentVote_r(uint8 _as, bytes32 _proposal, bool _vote)
 external
 onlyOwner
 returns (bool majority)
 {
 Poll storage poll = documentPolls[_proposal];
 processVote_r(poll, _as, _vote);
 return updateDocumentPoll_r(_proposal);
 }
 function processVote_r(Poll storage _poll, uint8 _as, bool _vote)
 internal
 {
 assert(block.timestamp >= _poll.start);
 require(
 !_poll.voted[_as] &&
 (block.timestamp < _poll.start.add_r(_poll.duration)) );
 _poll.voted[_as] = true;
 if (_vote)
 {
 _poll.yesVotes = _poll.yesVotes.add_r(1);
 }
 else
 {
 _poll.noVotes = _poll.noVotes.add_r(1);
 }
 }
 function updateUpgradePoll_r(address _proposal)
 public
 onlyOwner
 returns (bool majority)
 {
 require(!upgradeHasAchievedMajority[_proposal]);
 Poll storage poll = upgradePolls[_proposal];
 majority = checkPollMajority_r(poll);
 if (majority)
 {
 upgradeHasAchievedMajority[_proposal] = true;
 emit UpgradeMajority(_proposal);
 }
 return majority;
 }
 function updateDocumentPoll_r(bytes32 _proposal)
 public
 returns (bool majority)
 {
 require(!documentHasAchievedMajority[_proposal]);
 Poll storage poll = documentPolls[_proposal];
 majority = checkPollMajority_r(poll);
 if (majority)
 {
 documentHasAchievedMajority[_proposal] = true;
 documentMajorities.push(_proposal);
 emit DocumentMajority(_proposal);
 }
 return majority;
 }
 function checkPollMajority_r(Poll _poll)
 internal
 view
 returns (bool majority)
 {
 return (
 (_poll.yesVotes >= (totalVoters / 4)) &&
 (_poll.yesVotes > _poll.noVotes) &&
 (
 (block.timestamp > _poll.start.add_r(_poll.duration)) ||
 ( _poll.yesVotes > totalVoters.sub_r(_poll.yesVotes) ) ) );
 }
}