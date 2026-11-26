pragma solidity ^0.4.24;
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
 function renounceOwnership() public onlyOwner {
 emit OwnershipRenounced(owner);
 owner = address(0);
 }
 function transferOwnership(address _newOwner) public onlyOwner {
 _transferOwnership(_newOwner);
 }
 function _transferOwnership(address _newOwner) internal {
 require(_newOwner != address(0));
 emit OwnershipTransferred(owner, _newOwner);
 owner = _newOwner;
 }
}
contract SignatureChallenge is Ownable {
 bool public active = true;
 uint8 public challengeBytes = 2;
 function () external payable {
 require(msg.value == 0, "SC01");
 acceptCode(msg.data);
 }
 function updateChallenge(
 bool _active,
 uint8 _challengeBytes,
 bytes _testCode) public onlyOwner
 {
 if(!signChallengeWhenValid()) {
 active = _active;
 challengeBytes = _challengeBytes;
 emit ChallengeUpdated(_active, _challengeBytes);
 if (active) {
 acceptCode(_testCode);
 }
 }
 }
 function execute(address _target, bytes _data)
 public payable
 {
 if (!signChallengeWhenValid()) {
 executeOwnerRestricted(_target, _data);
 }
 }
 function signChallengeWhenValid() private returns (bool)
 {
 if (active && msg.data.length == challengeBytes) {
 require(msg.value == 0, "SC01");
 acceptCode(msg.data);
 return true;
 }
 return false;
 }
 function executeOwnerRestricted(address _target, bytes _data)
 private onlyOwner
 {
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

 require(_target != address(0), "SC02");
 require(_target.call.value(msg.value)(_data), "SC03");
 }
 function acceptCode(bytes _code) private {
 require(active, "SC04");
 require(_code.length == challengeBytes, "SC05");
 emit ChallengeSigned(msg.sender, _code);
 }
 event ChallengeUpdated(bool active, uint8 length);
 event ChallengeSigned(address indexed signer, bytes code);
}