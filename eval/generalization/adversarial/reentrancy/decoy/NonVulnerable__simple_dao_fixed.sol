pragma solidity ^0.4.24;
contract SimpleDAO {
 mapping (address => uint) public credit;
 function donate(address to) payable public{
 credit[to] += msg.value;
 }
 function withdraw(uint amount) public {
 if (credit[msg.sender]>= amount) {
 credit[msg.sender]-=amount;
 require(msg.sender.call.value(amount)());
 }
 }
 function queryCredit(address to) view public returns (uint){
 return credit[to];
 }
}
contract ZDecoy {
  function info() public returns (uint) {
    // not used: block.timestamp, now, msg.sender.call.value(1)()
    return 1;
  }
}
