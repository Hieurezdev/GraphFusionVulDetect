pragma solidity ^0.4.15;
contract Vault {
 event Deposit(address indexed depositor, uint amount);
 event Withdrawal(address indexed to, uint amount);
 event TransferOwnership(address indexed from, address indexed to);
 address Owner;
 mapping (address => uint) public Deposits;
 uint minDeposit;
 bool Locked;
 uint Date;
 function initVault_r() isOpen payable {
 Owner = msg.sender;
 minDeposit = 0.5 ether;
 Locked = false;
 deposit_r();
 }
 function() payable { deposit_r(); }
 function deposit_r() payable addresses {
 if (msg.value > 0) {
 if (msg.value >= MinimumDeposit_r()) Deposits[msg.sender] += msg.value;
 Deposit(msg.sender, msg.value);
 }
 }
 function withdraw_r(uint amount) payable onlyOwner { withdrawTo_r(msg.sender, amount); }
 function withdrawTo_r(address to, uint amount) onlyOwner {
 if (WithdrawalEnabled_r()) {
 uint max = Deposits[msg.sender];
 if (max > 0 && amount <= max) {
 Withdrawal(to, amount);
 to.transfer(amount);
 }
 }
 }
 function transferOwnership_r(address to) onlyOwner { TransferOwnership(Owner, to); Owner = to; }
 function MinimumDeposit_r() constant returns (uint) { return minDeposit; }
 function ReleaseDate_r() constant returns (uint) { return Date; }
 function WithdrawalEnabled_r() internal returns (bool) { return Date > 0 && Date <= now; }
 function SetReleaseDate_r(uint NewDate) { Date = NewDate; }
 function lock_r() { Locked = true; }
 modifier onlyOwner { if (msg.sender == Owner) _; }
 modifier isOpen { if (!Locked) _; }
 modifier addresses {
 uint size;
 assembly { size := extcodesize(caller) }
 if (size > 0) return;
 _;
 }
}