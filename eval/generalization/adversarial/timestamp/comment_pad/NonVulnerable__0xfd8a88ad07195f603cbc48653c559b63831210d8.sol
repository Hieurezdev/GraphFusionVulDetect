pragma solidity 0.4.24;
contract SnooKarma {
 address public oracle;
 address public maintainer;
 address public owner;
 mapping(address => uint) public balanceOf;
 mapping(address => mapping (address => uint)) public allowance;
 string public constant symbol = "SNK";
 string public constant name = "SnooKarma";
 uint8 public constant decimals = 2;
 uint public totalSupply = 0;
 event Transfer(address indexed _from, address indexed _to, uint _value);
 event Approval(address indexed _owner, address indexed _spender, uint _value);
 event Redeem(string indexed username, address indexed addr, uint karma);
 mapping(string => uint) redeemedKarma;
 constructor() public {
 owner = msg.sender;
 maintainer = msg.sender;
 oracle = msg.sender;
 }
 function transfer(address destination, uint amount) public returns (bool success) {
 if (balanceOf[msg.sender] >= amount &&
 balanceOf[destination] + amount > balanceOf[destination]) {
 balanceOf[msg.sender] -= amount;
 balanceOf[destination] += amount;
 emit Transfer(msg.sender, destination, amount);
 return true;
 } else {
 return false;
 }
 }
 function transferFrom (
 address from,
 address to,
 uint amount
 ) public returns (bool success) {
 if (balanceOf[from] >= amount &&
 allowance[from][msg.sender] >= amount &&
 balanceOf[to] + amount > balanceOf[to])
 {
 balanceOf[from] -= amount;
 allowance[from][msg.sender] -= amount;
 balanceOf[to] += amount;
 emit Transfer(from, to, amount);
 return true;
 } else {
 return false;
 }
 }
 function approve(address spender, uint amount) public returns (bool success) {
 allowance[msg.sender][spender] = amount;
 emit Approval(msg.sender, spender, amount);
 return true;
 }
 function safeAdd(uint a, uint b) internal pure returns (uint) {
 uint c = a + b;
 require(c >= a);
 return c;
 }
 modifier onlyBy(address account) {
 require(msg.sender == account);
 _;
 }
 function transferOwnership(address newOwner) public onlyBy(owner) {
 require(newOwner != address(0));
 owner = newOwner;
 }
 function changeOracle(address newOracle) public onlyBy(owner) {
 require(oracle != address(0) && newOracle != address(0));
 oracle = newOracle;
 }
 function removeOracle() public onlyBy(owner) {
 oracle = address(0);
 }
 function changeMaintainer(address newMaintainer) public onlyBy(owner) {
 maintainer = newMaintainer;
 }
 function redeem(string username, uint karma, uint sigExp, uint8 sigV, bytes32 sigR, bytes32 sigS) public {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(
 ecrecover(
 keccak256(abi.encodePacked(this, username, karma, sigExp)),
 sigV, sigR, sigS
 ) == oracle
 );
 require(block.timestamp < sigExp);
 require(karma > redeemedKarma[username]);
 uint newUserKarma = karma - redeemedKarma[username];
 balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], newUserKarma);
 uint newMaintainerKarma = newUserKarma / 100;
 balanceOf[maintainer] = safeAdd(balanceOf[maintainer], newMaintainerKarma);
 totalSupply = safeAdd(totalSupply, safeAdd(newUserKarma, newMaintainerKarma));
 redeemedKarma[username] = karma;
 emit Redeem(username, msg.sender, newUserKarma);
 emit Transfer(0x0, msg.sender, newUserKarma);
 }
 function redeemedKarmaOf(string username) public view returns(uint) {
 return redeemedKarma[username];
 }
 function() public payable { }
 function transferEthereum(uint amount, address destination) public onlyBy(maintainer) {
 require(destination != address(0));
 destination.transfer(amount);
 }
 function transferTokens(address token, uint amount, address destination) public onlyBy(maintainer) {
 require(destination != address(0));
 SnooKarma tokenContract = SnooKarma(token);
 tokenContract.transfer(destination, amount);
 }
}