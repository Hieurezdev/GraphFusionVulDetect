pragma solidity ^0.4.24;
contract ERC20 {
 function balanceOf (address owner) public view returns (uint256);
 function allowance (address owner, address spender) public view returns (uint256);
 function transfer (address to, uint256 value) public returns (bool);
 function transferFrom (address from, address to, uint256 value) public returns (bool);
 function approve (address spender, uint256 value) public returns (bool);
}
contract MiddleSaleService {
 address public frontWindow;
 address public salesPipe;
 ERC20 public erc;
 address public owner;
 constructor(address _frontWindow, address _salesPipe, ERC20 _erc) public {
 frontWindow = _frontWindow;
 salesPipe = _salesPipe;
 erc = _erc;
 owner = msg.sender;
 }
 function setFrontWindow (address _frontWindow) external {
 require(msg.sender == owner);
 frontWindow = _frontWindow;
 }
 function setSalesPipe (address _salesPipe) external {
 require(msg.sender == owner);
 salesPipe = _salesPipe;
 }
 function setERC (ERC20 _erc) external {
 require(msg.sender == owner);
 erc = _erc;
 }
 function setOwner (address _owner) external {
 require(msg.sender == owner);
 owner = _owner;
 }
 function buyFST0(address receiver) internal {
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

 require(salesPipe.call.value(msg.value)());
 uint256 tmpERCBalance = erc.balanceOf(address(this));
 uint256 tmpEthBalance = address(this).balance;
 if (tmpERCBalance > 0) {
 require(erc.transfer(receiver, tmpERCBalance)); }
 if (tmpEthBalance > 0) {
 require(receiver.send(tmpEthBalance));
 }
 }
 function buyFST (address receiver) public payable {
 buyFST0(receiver);
 }
 function buyFST () public payable {
 buyFST0(msg.sender);
 }
 function () external payable {
 buyFST0(msg.sender);
 }
}