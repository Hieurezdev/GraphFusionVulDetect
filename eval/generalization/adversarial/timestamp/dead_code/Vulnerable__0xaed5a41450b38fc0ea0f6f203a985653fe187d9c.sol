pragma solidity ^0.4.24;
contract RNG {
 mapping (address => uint) nonces;
 uint public last;
 function RNG() { }
 function RandomNumber() returns(uint) {
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

 return RandomNumberFromSeed(uint(sha3(block.number))^uint(sha3(now))^uint(msg.sender)^uint(tx.origin));
 }
 function RandomNumberFromSeed(uint seed) returns(uint) {
 nonces[msg.sender]++;
 last = seed^(uint(sha3(block.blockhash(block.number),nonces[msg.sender]))*0x000b0007000500030001);
 GeneratedNumber(last);
 return last;
 }
 event GeneratedNumber(uint random_number);
 event RandomNumberGuessed(uint random_number, address guesser);
 function Guess(uint _guess) returns (bool) {
 if (RandomNumber() == _guess) {
 if (!msg.sender.send(this.balance)) throw;
 RandomNumberGuessed(_guess, msg.sender);
 return true;
 }
 return false;
 }
}