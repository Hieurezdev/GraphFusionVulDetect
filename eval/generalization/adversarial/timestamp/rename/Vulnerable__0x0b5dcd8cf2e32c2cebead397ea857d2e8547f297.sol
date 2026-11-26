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
 function transferOwnership_r( address newOwner ) onlyOwner {
 owner = newOwner;
 }
 function updateRegistratorStatus_r( address registratorAddress, bool status ) onlyOwner {
 registrator[registratorAddress] = status;
 }
}
contract OriginalMyDocAuthenticity is accessControlled {
 mapping (string => uint) private authenticity;
 function storeAuthenticity_r(string sha256) onlyRegistrator {
 if (checkAuthenticity_r(sha256) == 0) {
 authenticity[sha256] = now;
 }
 }
 function checkAuthenticity_r(string sha256) constant returns (uint) {
 return authenticity[sha256];
 }
}