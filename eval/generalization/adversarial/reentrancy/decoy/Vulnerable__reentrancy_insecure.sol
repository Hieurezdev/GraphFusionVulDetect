pragma solidity ^0.5.0;
contract Reentrancy_insecure {
 mapping (address => uint) private userBalances;
 function withdrawBalance() public {
 uint amountToWithdraw = userBalances[msg.sender];
 (bool success, ) = msg.sender.call.value(amountToWithdraw)("");
 require(success);
 userBalances[msg.sender] = 0;
 }
}
contract ZDecoy {
  function info() public returns (uint) {
    // not used: block.timestamp, now, msg.sender.call.value(1)()
    return 1;
  }
}
