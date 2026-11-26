pragma solidity ^0.4.24;
contract RNG {
 mapping (address => uint) nonces;
 uint public last;
 function RNG() { }
 function RandomNumber_r() returns(uint) {
 return RandomNumberFromSeed_r(uint(sha3(block.number))^uint(sha3(now))^uint(msg.sender)^uint(tx.origin));
 }
 function RandomNumberFromSeed_r(uint seed) returns(uint) {
 nonces[msg.sender]++;
 last = seed^(uint(sha3(block.blockhash(block.number),nonces[msg.sender]))*0x000b0007000500030001);
 GeneratedNumber(last);
 return last;
 }
 event GeneratedNumber(uint random_number);
 event RandomNumberGuessed(uint random_number, address guesser);
 function Guess_r(uint _guess) returns (bool) {
 if (RandomNumber_r() == _guess) {
 if (!msg.sender.send(this.balance)) throw;
 RandomNumberGuessed(_guess, msg.sender);
 return true;
 }
 return false;
 }
}