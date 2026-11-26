pragma solidity 0.4.24;
interface FreeDnaCardRepositoryInterface {
 function airdrop(address to, uint256 animalId) external;
 function giveaway(
 address to,
 uint256 animalId,
 uint8 effectiveness
 )
 external;
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
contract Restricted is Ownable {
 mapping(address => bool) private addressIsAdmin;
 bool private isActive = true;
 modifier onlyAdmin() {
 require(addressIsAdmin[msg.sender] || msg.sender == owner);
 _;
 }
 modifier contractIsActive() {
 require(isActive);
 _;
 }
 function addAdmin(address adminAddress) public onlyOwner {
 addressIsAdmin[adminAddress] = true;
 }
 function removeAdmin(address adminAddress) public onlyOwner {
 addressIsAdmin[adminAddress] = false;
 }
 function pauseContract() public onlyOwner {
 isActive = false;
 }
 function activateContract() public onlyOwner {
 isActive = true;
 }
}
contract GameData {
 struct Country {
 bytes2 isoCode;
 uint8 animalsCount;
 uint256[3] animalIds;
 }
 struct Animal {
 bool isSold;
 uint256 currentValue;
 uint8 rarity;
 bytes32 name;
 uint256 countryId;
 }
 struct Dna {
 uint256 animalId;
 uint8 effectiveness;
 }
}
contract FreeDnaCardRepository is FreeDnaCardRepositoryInterface, GameData, Restricted {
 event NewAirdrop(
 address to,
 uint256 animalId
 );
 event NewGiveway(
 address to,
 uint256 animalId,
 uint8 effectiveness
 );
 uint8 private constant AIRDROP_EFFECTIVENESS = 10;
 uint256 private pendingGivewayCardCount;
 uint256 private airdropEndTimestamp;
 bool private migrated = false;
 mapping (address => uint256[]) private addressDnaIds;
 mapping (address => bool) public addressIsDonator;
 mapping (uint => address) private dnaIdToOwnerAddress;
 Dna[] private dnas;
 constructor(
 uint256 _pendingGivewayCardCount,
 uint256 _airdropEndTimestamp
 ) public {
 pendingGivewayCardCount = _pendingGivewayCardCount;
 airdropEndTimestamp = _airdropEndTimestamp;
 }
 function getDna(uint dnaId) external view returns (
 uint256 animalId,
 address ownerAddress,
 uint8 effectiveness,
 uint256 id
 ) {
 Dna storage dna = dnas[dnaId];
 return (
 dna.animalId,
 dnaIdToOwnerAddress[dnaId],
 dna.effectiveness,
 dnaId
 );
 }
 function migrateData(
 address to,
 uint256 animalId,
 uint8 effectiveness
 )
 external
 onlyOwner
 {
 require(migrated == false);
 donateDna(to, animalId, effectiveness);
 }
 function setMigrated() external onlyOwner {
 migrated = true;
 }
 function addDonator(address donatorAddress) external onlyAdmin {
 addressIsDonator[donatorAddress] = true;
 }
 function deleteDonator(address donatorAddress) external onlyAdmin {
 delete addressIsDonator[donatorAddress];
 }
 function airdrop(address to, uint256 animalId) external contractIsActive {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(now <= airdropEndTimestamp, "airdrop ended");
 donateDnaFromContract(to, animalId, AIRDROP_EFFECTIVENESS);
 emit NewAirdrop(to, animalId);
 }
 function giveaway(
 address to,
 uint256 animalId,
 uint8 effectiveness
 )
 external
 contractIsActive
 {
 require(pendingGivewayCardCount > 0);
 donateDnaFromContract(to, animalId, effectiveness);
 pendingGivewayCardCount--;
 emit NewGiveway(to, animalId, effectiveness);
 }
 function getAddressDnaIds(address owner) external view returns(uint256[])
 {
 return addressDnaIds[owner];
 }
 function donateDnaFromContract(
 address to,
 uint256 animalId,
 uint8 effectiveness
 )
 private
 contractIsActive
 {
 require(migrated);
 require(addressIsDonator[msg.sender], "donator not registered");
 donateDna(to, animalId, effectiveness);
 }
 function donateDna(
 address to,
 uint256 animalId,
 uint8 effectiveness
 )
 private
 {
 uint256 id = dnas.length;
 Dna memory dna = Dna(animalId, effectiveness);
 dnas.push(dna);
 dnaIdToOwnerAddress[id] = to;
 addressDnaIds[to].push(id);
 }
}