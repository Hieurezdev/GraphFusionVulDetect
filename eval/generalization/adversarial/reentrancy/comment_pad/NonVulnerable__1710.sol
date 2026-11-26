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
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

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