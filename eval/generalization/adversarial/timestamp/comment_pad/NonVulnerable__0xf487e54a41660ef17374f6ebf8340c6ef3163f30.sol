pragma solidity 0.4.15;
contract ERC20 {
 function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}
contract REMMESale {
 uint public constant SALES_START = 1518552000;
 uint public constant FIRST_DAY_END = 1518638400;
 uint public constant SALES_DEADLINE = 1518724800;
 address public constant ASSET_MANAGER_WALLET = 0xbb12800E7446A51395B2d853D6Ce7F22210Bb5E5;
 address public constant TOKEN = 0x83984d6142934bb535793A82ADB0a46EF0F66B6d;
 address public constant WHITELIST_SUPPLIER = 0x1Ff21eCa1c3ba96ed53783aB9C92FfbF77862584;
 uint public constant TOKEN_CENTS = 10000;
 uint public constant BONUS = 10;
 uint public constant SALE_MAX_CAP = 500000000 * TOKEN_CENTS;
 uint public constant MINIMAL_PARTICIPATION = 0.1 ether;
 uint public constant MAXIMAL_PARTICIPATION = 15 ether;
 uint public saleContributions;
 uint public tokensPurchased;
 uint public allowedGasPrice = 20000000000 wei;
 uint public tokenPriceWei;
 mapping(address => uint) public participantContribution;
 mapping(address => bool) public whitelist;
 event Contributed(address receiver, uint contribution, uint reward);
 event WhitelistUpdated(address participant, bool isWhitelisted);
 event AllowedGasPriceUpdated(uint gasPrice);
 event TokenPriceUpdated(uint tokenPriceWei);
 event Error(string message);
 function REMMESale(uint _ethUsdPrice) {
 tokenPriceWei = 0.04 ether / _ethUsdPrice;
 }
 function contribute() payable returns(bool) {
 return contributeFor(msg.sender);
 }
 function contributeFor(address _participant) payable returns(bool) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(now >= SALES_START);
 require(now < SALES_DEADLINE);
 require((participantContribution[_participant] + msg.value) >= MINIMAL_PARTICIPATION);
 require(whitelist[_participant]);
 if (now <= FIRST_DAY_END) {
 require((participantContribution[_participant] + msg.value) <= MAXIMAL_PARTICIPATION);
 require(tx.gasprice <= allowedGasPrice);
 }
 uint tokensAmount = (msg.value * TOKEN_CENTS) / tokenPriceWei;
 require(tokensAmount > 0);
 uint bonusTokens = (tokensAmount * BONUS) / 100;
 uint totalTokens = tokensAmount + bonusTokens;
 tokensPurchased += totalTokens;
 require(tokensPurchased <= SALE_MAX_CAP);
 require(ERC20(TOKEN).transferFrom(ASSET_MANAGER_WALLET, _participant, totalTokens));
 saleContributions += msg.value;
 participantContribution[_participant] += msg.value;
 ASSET_MANAGER_WALLET.transfer(msg.value);
 Contributed(_participant, msg.value, totalTokens);
 return true;
 }
 modifier onlyWhitelistSupplier() {
 require(msg.sender == WHITELIST_SUPPLIER || msg.sender == ASSET_MANAGER_WALLET);
 _;
 }
 modifier onlyAdmin() {
 require(msg.sender == ASSET_MANAGER_WALLET);
 _;
 }
 function addToWhitelist(address _participant) onlyWhitelistSupplier() returns(bool) {
 if (whitelist[_participant]) {
 return true;
 }
 whitelist[_participant] = true;
 WhitelistUpdated(_participant, true);
 return true;
 }
 function removeFromWhitelist(address _participant) onlyWhitelistSupplier() returns(bool) {
 if (!whitelist[_participant]) {
 return true;
 }
 whitelist[_participant] = false;
 WhitelistUpdated(_participant, false);
 return true;
 }
 function setGasPrice(uint _allowedGasPrice) onlyAdmin() returns(bool) {
 allowedGasPrice = _allowedGasPrice;
 AllowedGasPriceUpdated(allowedGasPrice);
 return true;
 }
 function setEthPrice(uint _ethUsdPrice) onlyAdmin() returns(bool) {
 tokenPriceWei = 0.04 ether / _ethUsdPrice;
 TokenPriceUpdated(tokenPriceWei);
 return true;
 }
 function () payable {
 contribute();
 }
}