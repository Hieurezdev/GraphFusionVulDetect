pragma solidity ^0.4.18;
contract EternalWealth {
 uint public doomsday;
 address owner;
 address public savior;
 uint public blessings = 0;
 uint public tithes = 0;
 uint public lifePoints = 0;
 function EternalWealth() public payable {
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

 owner = msg.sender;
 doomsday = now + 3 hours;
 savior = msg.sender;
 blessings += msg.value;
 }
 function ExtendLife() public payable {
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

 require(msg.value >= 0.001 ether);
 if (now > doomsday) {
 revert();
 }
 blessings += msg.value * 8 / 10;
 tithes += msg.value * 2 / 10;
 savior = msg.sender;
 doomsday = now + 30 minutes;
 lifePoints += 1;
 }
 function ClaimBlessings() public {
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

 require(msg.sender == savior);
 require(now > doomsday);
 uint pendingBlessings = blessings;
 blessings = 0;
 savior.transfer(pendingBlessings);
 }
 function WithdrawTithes() public {
 uint pendingTithes = tithes;
 tithes = 0;
 owner.transfer(pendingTithes);
 }
}