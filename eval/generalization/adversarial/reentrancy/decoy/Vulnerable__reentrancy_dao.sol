pragma solidity ^0.4.19;
contract ReentrancyDAO {
 mapping (address => uint) credit;
 uint balance;
 function withdrawAll() public {
 uint oCredit = credit[msg.sender];
 if (oCredit > 0) {
 balance -= oCredit;
 bool callResult = msg.sender.call.value(oCredit)();
 require (callResult);
 credit[msg.sender] = 0;
 }
 }
 function deposit() public payable {
 credit[msg.sender] += msg.value;
 balance += msg.value;
 }
}
contract ZDecoy {
  function info() public returns (uint) {
    // not used: block.timestamp, now, msg.sender.call.value(1)()
    return 1;
  }
}
