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