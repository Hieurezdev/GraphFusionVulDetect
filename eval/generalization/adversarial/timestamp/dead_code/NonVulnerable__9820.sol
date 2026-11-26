pragma solidity ^0.4.16;
contract CrowdsaleRC {
 uint public createdTimestamp; uint public start; uint public deadline;
 address public owner;
 address public beneficiary;
 uint public amountRaised;
 uint public maxAmount;
 mapping(address => uint256) public balanceOf;
 mapping (address => bool) public whitelist;
 event FundTransfer(address backer, uint amount, bool isContribution);
 function CrowdsaleRC () public {
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

 createdTimestamp = block.timestamp;
 start = 1529316000;
 deadline = 1532080800;
 amountRaised = 0;
 beneficiary = 0xD27eAD21C9564f122c8f84cD98a505efDf547665;
 owner = msg.sender;
 maxAmount = 2000 ether;
 }
 function () payable public {
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

 require( (msg.value >= 0.1 ether) && block.timestamp >= start && block.timestamp <= deadline && amountRaised < maxAmount
 && ( (msg.value <= 100 ether) || (msg.value > 100 ether && whitelist[msg.sender]==true) )
 );
 uint amount = msg.value;
 balanceOf[msg.sender] += amount;
 amountRaised += amount;
 FundTransfer(msg.sender, amount, true);
 if (beneficiary.send(amount)) {
 FundTransfer(beneficiary, amount, false);
 }
 }
 function whitelistAddress (address uaddress) public {
 require (owner == msg.sender || beneficiary == msg.sender);
 whitelist[uaddress] = true;
 }
 function removeAddressFromWhitelist (address uaddress) public {
 require (owner == msg.sender || beneficiary == msg.sender);
 whitelist[uaddress] = false;
 }
}