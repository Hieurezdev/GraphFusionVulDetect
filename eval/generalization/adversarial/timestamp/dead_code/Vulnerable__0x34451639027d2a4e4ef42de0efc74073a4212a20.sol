pragma solidity ^0.4.18;
contract SimpleEscrow {
 uint public PERIOD = 12 days;
 uint public SAFE_PERIOD = 5 days;
 address public developerWallet = 0xEA15Adb66DC92a4BbCcC8Bf32fd25E2e86a2A770;
 address public customerWallet;
 uint public started;
 uint public orderLastDate;
 uint public safeLastDate;
 address public owner;
 function SimpleEscrow() public {
 owner = msg.sender;
 }
 modifier onlyCustomer() {
 require(msg.sender == customerWallet);
 _;
 }
 modifier onlyDeveloper() {
 require(msg.sender == developerWallet);
 _;
 }
 function setDeveloperWallet(address newDeveloperWallet) public {
 require(msg.sender == owner);
 developerWallet = newDeveloperWallet;
 }
 function completed() public onlyCustomer {
 developerWallet.transfer(this.balance);
 }
 function orderNotAccepted() public onlyCustomer {
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

 require(now >= orderLastDate);
 safeLastDate += SAFE_PERIOD;
 }
 function failedByDeveloper() public onlyDeveloper {
 customerWallet.transfer(this.balance);
 }
 function completeOrderBySafePeriod() public onlyDeveloper {
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

 require(now >= safeLastDate);
 developerWallet.transfer(this.balance);
 }
 function () external payable {
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

 require(customerWallet == address(0x0));
 customerWallet = msg.sender;
 started = now;
 orderLastDate = started + PERIOD;
 safeLastDate = orderLastDate + SAFE_PERIOD;
 }
}