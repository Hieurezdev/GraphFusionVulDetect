pragma solidity ^0.4.24;
contract ERC20Basic {
 uint256 public totalSupply;
 function balanceOf(address who) public view returns (uint256);
 function transfer(address to, uint256 value) public returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
 function allowance(address owner, address spender) public view returns (uint256);
 function transferFrom(address from, address to, uint256 value) public returns (bool);
 function approve(address spender, uint256 value) public returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Hodl {
 mapping(address => mapping(address => uint)) private amounts;
 mapping(address => mapping(address => uint)) private timestamps;
 event Hodling(address indexed sender, address indexed tokenAddress, uint256 amount);
 event TokenReturn(address indexed sender, address indexed tokenAddress, uint256 amount);
 function hodlTokens(address tokenAddress, uint256 amount, uint timestamp) public {
 assert(tokenAddress != address(0));
 assert(amount != uint256(0));
 assert(timestamp != uint(0));
 assert(amounts[msg.sender][tokenAddress] == 0);
 amounts[msg.sender][tokenAddress] = amount;
 timestamps[msg.sender][tokenAddress] = timestamp;
 ERC20 erc20 = ERC20(tokenAddress);
 assert(erc20.transferFrom(msg.sender, this, amount) == true);
 Hodling(msg.sender, tokenAddress, amount);
 }
 function getTokens(address tokenAddress) public {
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

 assert(tokenAddress != address(0));
 assert(amounts[msg.sender][tokenAddress] > 0);
 assert(now >= timestamps[msg.sender][tokenAddress]);
 ERC20 erc20 = ERC20(tokenAddress);
 uint256 amount = amounts[msg.sender][tokenAddress];
 delete amounts[msg.sender][tokenAddress];
 delete timestamps[msg.sender][tokenAddress];
 assert(erc20.transfer(msg.sender, amount) == true);
 TokenReturn(msg.sender, tokenAddress, amount);
 }
 function getTimestamp(address tokenAddress) public view returns (uint) {
 return timestamps[msg.sender][tokenAddress];
 }
 function getAmount(address tokenAddress) public view returns (uint256) {
 return amounts[msg.sender][tokenAddress];
 }
}