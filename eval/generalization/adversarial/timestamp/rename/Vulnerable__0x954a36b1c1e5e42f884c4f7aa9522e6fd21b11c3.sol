pragma solidity ^0.4.10;
contract Vault {
 event Deposit(address indexed depositor, uint amount);
 event Withdrawal(address indexed to, uint amount);
 address Owner;
 mapping (address => uint) public deposits;
 uint Date;
 uint MinimumDeposit;
 bool Locked = false;
 function initVault_r(uint minDeposit) isOpen payable {
 Owner = msg.sender;
 Date = 0;
 MinimumDeposit = minDeposit;
 deposit_r();
 }
 function() payable { deposit_r(); }
 function SetLockDate_r(uint NewDate) onlyOwner {
 Date = NewDate;
 }
 function WithdrawalEnabled_r() constant returns (bool) { return Date > 0 && Date <= now; }
 function deposit_r() payable {
 if (msg.value >= MinimumDeposit) {
 if ((deposits[msg.sender] + msg.value) < deposits[msg.sender]) {
 return;
 }
 deposits[msg.sender] += msg.value;
 }
 Deposit(msg.sender, msg.value);
 }
 function withdraw_r(address to, uint amount) onlyOwner {
 if (WithdrawalEnabled_r()) {
 if (amount <= this.balance) {
 to.transfer(amount);
 }
 }
 }
 modifier onlyOwner { if (msg.sender == Owner) _; }
 modifier isOpen { if (!Locked) _; }
 function lock_r() { Locked = true; }
}