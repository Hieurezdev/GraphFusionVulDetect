pragma solidity ^0.4.11;
contract accessControlled {
 address public owner;
 mapping (address => bool) public registrator;
 function accessControlled() {
 registrator[msg.sender] = true;
 owner = msg.sender;
 }
 modifier onlyOwner {
 if ( msg.sender != owner ) throw;
 _;
 }
 modifier onlyRegistrator {
 if ( !registrator[msg.sender] ) throw;
 _;
 }
 function transferOwnership( address newOwner ) onlyOwner {
 owner = newOwner;
 }
 function updateRegistratorStatus( address registratorAddress, bool status ) onlyOwner {
 registrator[registratorAddress] = status;
 }
}
contract OriginalMyDocAuthenticity is accessControlled {
 mapping (string => uint) private authenticity;
 function storeAuthenticity(string sha256) onlyRegistrator {
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

 if (checkAuthenticity(sha256) == 0) {
 authenticity[sha256] = now;
 }
 }
 function checkAuthenticity(string sha256) constant returns (uint) {
 return authenticity[sha256];
 }
}