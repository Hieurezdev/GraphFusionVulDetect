pragma solidity ^0.4.11;
library Math {
 function max64(uint64 a, uint64 b) internal constant returns (uint64) {
 return a >= b ? a : b;
 }
 function min64(uint64 a, uint64 b) internal constant returns (uint64) {
 return a < b ? a : b;
 }
 function max256(uint256 a, uint256 b) internal constant returns (uint256) {
 return a >= b ? a : b;
 }
 function min256(uint256 a, uint256 b) internal constant returns (uint256) {
 return a < b ? a : b;
 }
}
contract ERC20Basic {
 uint256 public totalSupply;
 function balanceOf(address who) constant returns (uint256);
 function transfer(address to, uint256 value) returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
contract Ownable {
 address public owner;
 function Ownable() {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) onlyOwner {
 if (newOwner != address(0)) {
 owner = newOwner;
 }
 }
}
contract ICOBuyer is Ownable {
 event EtherReceived(address indexed _contributor, uint256 _amount);
 event EtherWithdrawn(uint256 _amount);
 event TokensWithdrawn(uint256 _balance);
 event ICOPurchased(uint256 _amount);
 event ICOStartBlockChanged(uint256 _icoStartBlock);
 event ExecutorChanged(address _executor);
 event CrowdSaleChanged(address _crowdSale);
 event TokenChanged(address _token);
 event PurchaseCapChanged(uint256 _purchaseCap);
 uint256 public icoStartBlock;
 address public crowdSale;
 address public executor;
 uint256 public purchaseCap;
 modifier onlyExecutorOrOwner() {
 require((msg.sender == executor) || (msg.sender == owner));
 _;
 }
 function ICOBuyer(address _executor, address _crowdSale, uint256 _icoStartBlock, uint256 _purchaseCap) {
 executor = _executor;
 crowdSale = _crowdSale;
 icoStartBlock = _icoStartBlock;
 purchaseCap = _purchaseCap;
 }
 function changeCrowdSale(address _crowdSale) onlyOwner {
 crowdSale = _crowdSale;
 CrowdSaleChanged(crowdSale);
 }
 function changeICOStartBlock(uint256 _icoStartBlock) onlyOwner {
 icoStartBlock = _icoStartBlock;
 ICOStartBlockChanged(icoStartBlock);
 }
 function changePurchaseCap(uint256 _purchaseCap) onlyOwner {
 purchaseCap = _purchaseCap;
 PurchaseCapChanged(purchaseCap);
 }
 function changeExecutor(address _executor) onlyOwner {
 executor = _executor;
 ExecutorChanged(_executor);
 }
 function withdrawEther() onlyOwner {
 require(this.balance != 0);
 owner.transfer(this.balance);
 EtherWithdrawn(this.balance);
 }
 function withdrawTokens(address _token) onlyOwner {
 ERC20Basic token = ERC20Basic(_token);
 uint256 contractTokenBalance = token.balanceOf(address(this));
 require(contractTokenBalance != 0);
 assert(token.transfer(owner, contractTokenBalance));
 TokensWithdrawn(contractTokenBalance);
 }
 function buyICO() onlyExecutorOrOwner {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (getBlockNumber() < icoStartBlock) return;
 if (this.balance == 0) return;
 uint256 purchaseAmount = Math.min256(this.balance, purchaseCap);
 assert(crowdSale.call.value(purchaseAmount)());
 ICOPurchased(purchaseAmount);
 }
 function () payable {
 EtherReceived(msg.sender, msg.value);
 }
 function getBlockNumber() internal constant returns (uint256) {
 return block.number;
 }
}