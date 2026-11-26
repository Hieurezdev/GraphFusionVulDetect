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
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

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
 function forceReseed() onlyOwner{
 SeedComponents s;
 s.component1 = uint(msg.sender);
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