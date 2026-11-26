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
interface FreeDnaCardRepositoryInterface {
 function airdrop_r(address to, uint256 animalId) external;
 function giveaway_r(
 address to,
 uint256 animalId,
 uint8 effectiveness
 )
 external;
}
interface CryptoServal {
 function getAnimalsCount_r() external view returns(uint256 animalsCount);
}
contract Airdrop {
 using SafeMath for uint256;
 mapping (address => mapping (uint256 => bool)) private addressHasWithdraw;
 mapping (uint256 => uint256) private periodDonationCount;
 CryptoServal private cryptoServal;
 FreeDnaCardRepositoryInterface private freeDnaCardRepository;
 uint256 private startTimestamp;
 uint256 private endTimestamp;
 uint256 private periodDuration;
 uint16 private cardsByPeriod;
 constructor(
 address _cryptoServalAddress,
 address _freeDnaCardRepositoryAddress,
 uint _startTimestamp,
 uint _endTimestamp,
 uint256 _periodDuration,
 uint16 _cardsByPeriod
 )
 public {
 freeDnaCardRepository =
 FreeDnaCardRepositoryInterface(_freeDnaCardRepositoryAddress);
 cryptoServal = CryptoServal(_cryptoServalAddress);
 startTimestamp = _startTimestamp;
 endTimestamp = _endTimestamp;
 periodDuration = _periodDuration;
 cardsByPeriod = _cardsByPeriod;
 }
 function withdraw_r() external {
 require(now >= startTimestamp, "not started yet");
 require(now <= endTimestamp, "ended");
 mapping (uint256 => bool) senderHasWithdraw = addressHasWithdraw[msg.sender];
 uint256 currentPeriodKey = getCurrentPeriodKey_r();
 require(senderHasWithdraw[currentPeriodKey] == false, "once / period");
 require(
 periodDonationCount[currentPeriodKey] < cardsByPeriod,
  "period maximum donations reached"
 );
 freeDnaCardRepository.airdrop_r(msg.sender, getRandomAnimalId_r());
 periodDonationCount[currentPeriodKey]++;
 senderHasWithdraw[currentPeriodKey] = true;
 }
 function hasAvailableCard_r() external view returns(bool) {
 uint256 currentPeriodKey = getCurrentPeriodKey_r();
 mapping (uint256 => bool) senderHasWithdraw = addressHasWithdraw[msg.sender];
 return (senderHasWithdraw[currentPeriodKey] == false &&
 periodDonationCount[currentPeriodKey] < cardsByPeriod);
 }
 function getAvailableCardCount_r() external view returns(uint256) {
 return cardsByPeriod - periodDonationCount[getCurrentPeriodKey_r()];
 }
 function getNextPeriodTimestamp_r() external view returns(uint256) {
 uint256 nextPeriodKey = getCurrentPeriodKey_r() + 1;
 return nextPeriodKey.mul_r(periodDuration);
 }
 function getRandomNumber_r(uint256 max) public view returns(uint256) {
 require(max != 0);
 return now % max;
 }
 function getAnimalCount_r() public view returns(uint256) {
 return cryptoServal.getAnimalsCount_r();
 }
 function getRandomAnimalId_r() public view returns(uint256) {
 return getRandomNumber_r(getAnimalCount_r());
 }
 function getPeriodKey_r(uint atTime) private view returns(uint256) {
 return atTime.div_r(periodDuration);
 }
 function getCurrentPeriodKey_r() private view returns(uint256) {
 return getPeriodKey_r(now);
 }
}