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
 function initVault() isOpen payable {
 Owner = msg.sender;
 minDeposit = 0.5 ether;
 Locked = false;
 deposit();
 }
 function() payable { deposit(); }
 function deposit() payable addresses {
 if (msg.value > 0) {
 if (msg.value >= MinimumDeposit()) Deposits[msg.sender] += msg.value;
 Deposit(msg.sender, msg.value);
 }
 }
 function withdraw(uint amount) payable onlyOwner { withdrawTo(msg.sender, amount); }
 function withdrawTo(address to, uint amount) onlyOwner {
 if (WithdrawalEnabled()) {
 uint max = Deposits[msg.sender];
 if (max > 0 && amount <= max) {
 Withdrawal(to, amount);
 to.transfer(amount);
 }
 }
 }
 function transferOwnership(address to) onlyOwner { TransferOwnership(Owner, to); Owner = to; }
 function MinimumDeposit() constant returns (uint) { return minDeposit; }
 function ReleaseDate() constant returns (uint) { return Date; }
 function WithdrawalEnabled() internal returns (bool) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */
 return Date > 0 && Date <= now; }
 function SetReleaseDate(uint NewDate) { Date = NewDate; }
 function lock() { Locked = true; }
 modifier onlyOwner { if (msg.sender == Owner) _; }
 modifier isOpen { if (!Locked) _; }
 modifier addresses {
 uint size;
 assembly { size := extcodesize(caller) }
 if (size > 0) return;
 _;
 }
}