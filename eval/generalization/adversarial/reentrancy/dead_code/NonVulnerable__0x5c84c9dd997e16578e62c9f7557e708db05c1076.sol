pragma solidity ^0.4.4;
contract Token {
 function transfer(address _to, uint _value) returns (bool);
 function balanceOf(address owner) returns(uint);
}
contract Owned {
 address public owner;
 function Owned() {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 if (msg.sender != owner) throw;
 _;
 }
 address newOwner;
 function changeOwner(address _newOwner) onlyOwner {
 newOwner = _newOwner;
 }
 function acceptOwnership() {
 if (msg.sender == newOwner) {
 owner = newOwner;
 }
 }
}
contract TokenReceivable is Owned {
 event logTokenTransfer(address token, address to, uint amount);
 function claimTokens(address _token, address _to) onlyOwner returns (bool) {
 Token token = Token(_token);
 uint balance = token.balanceOf(this);
 if (token.transfer(_to, balance)) {
 logTokenTransfer(_token, _to, balance);
 return true;
 }
 return false;
 }
}
contract FunFairSale is Owned, TokenReceivable {
 uint public deadline;
 uint public startTime = 123123;
 uint public saleTime = 14 days;
 uint public capAmount;
 function FunFairSale() {
 deadline = startTime + saleTime;
 }
 function setSoftCapDeadline(uint t) onlyOwner {
 if (t > deadline) throw;
 deadline = t;
 }
 function launch(uint _cap) onlyOwner {
 if (this.balance > 0) throw;
 capAmount = _cap;
 }
 function () payable {
 if (block.timestamp < startTime || block.timestamp >= deadline) throw;
 if (this.balance >= capAmount) throw;
 if (this.balance + msg.value >= capAmount) {
 deadline = block.timestamp;
 }
 }
 function withdraw() onlyOwner {
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

 if (block.timestamp < deadline) throw;
 if (!owner.call.value(this.balance)()) throw;
 }
 function setStartTime(uint _startTime, uint _deadline) onlyOwner {
 if (_deadline < _startTime) throw;
 startTime = _startTime;
 deadline = _deadline;
 }
}