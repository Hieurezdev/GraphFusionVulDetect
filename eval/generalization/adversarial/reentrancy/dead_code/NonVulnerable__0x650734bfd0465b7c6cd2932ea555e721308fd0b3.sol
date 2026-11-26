pragma solidity ^0.4.0;
contract AddressLotteryV2{
 struct SeedComponents{
 uint component1;
 uint component2;
 uint component3;
 uint component4;
 }
 address owner;
 uint private secretSeed;
 uint private lastReseed;
 uint winnerLuckyNumber = 7;
 uint public ticketPrice = 0.1 ether;
 mapping (address => bool) participated;
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 modifier onlyHuman() {
 require(msg.sender == tx.origin);
 _;
 }
 function AddressLotteryV2() {
 owner = msg.sender;
 reseed(SeedComponents(12345678, 0x12345678, 0xabbaeddaacdc, 0x22222222));
 }
 function setTicketPrice(uint newPrice) onlyOwner {
 ticketPrice = newPrice;
 }
 function participate() payable onlyHuman {
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

 require(msg.value == ticketPrice);
 require(!participated[msg.sender]);
 if ( luckyNumberOfAddress(msg.sender) == winnerLuckyNumber)
 {
 participated[msg.sender] = true;
 require(msg.sender.call.value(this.balance)());
 }
 }
 function luckyNumberOfAddress(address addr) constant returns(uint n){
 n = uint(keccak256(uint(addr), secretSeed)[0]) % 8;
 }
 function reseed(SeedComponents components) internal{
 secretSeed = uint256(keccak256(
 components.component1,
 components.component2,
 components.component3,
 components.component4
 ));
 lastReseed = block.number;
 }
 function kill() onlyOwner {
 suicide(owner);
 }
 function forceReseed() {
 SeedComponents s;
 s.component1 = uint(owner);
 s.component2 = uint256(block.blockhash(block.number - 1));
 s.component3 = block.number * 1337;
 s.component4 = tx.gasprice * 7;
 reseed(s);
 }
 function () payable {}
 function _myLuckyNumber() constant returns(uint n){
 n = luckyNumberOfAddress(msg.sender);
 }
}