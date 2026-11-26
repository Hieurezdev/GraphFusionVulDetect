pragma solidity ^0.4.10;
contract Vault {
 event Deposit(address indexed depositor, uint amount);
 event Withdrawal(address indexed to, uint amount);
 address Owner;
 mapping (address => uint) public deposits;
 uint Date;
 uint MinimumDeposit;
 bool Locked = false;
 function initVault(uint minDeposit) isOpen payable {
 Owner = msg.sender;
 Date = 0;
 MinimumDeposit = minDeposit;
 deposit();
 }
 function() payable { deposit(); }
 function SetLockDate(uint NewDate) onlyOwner {
 Date = NewDate;
 }
 function WithdrawalEnabled() constant returns (bool) {
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
 return Date > 0 && Date <= now; }
 function deposit() payable {
 if (msg.value >= MinimumDeposit) {
 if ((deposits[msg.sender] + msg.value) < deposits[msg.sender]) {
 return;
 }
 deposits[msg.sender] += msg.value;
 }
 Deposit(msg.sender, msg.value);
 }
 function withdraw(address to, uint amount) onlyOwner {
 if (WithdrawalEnabled()) {
 if (amount <= this.balance) {
 to.transfer(amount);
 }
 }
 }
 modifier onlyOwner { if (msg.sender == Owner) _; }
 modifier isOpen { if (!Locked) _; }
 function lock() { Locked = true; }
}