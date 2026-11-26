pragma solidity ^0.4.16;
contract owned {
 address public owner;
 function owned() public {
 owner = msg.sender;
 }
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) onlyOwner public {
 owner = newOwner;
 }
}
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }
contract TokenERC20 {
 string public name;
 string public symbol;
 uint8 public decimals = 18;
 uint256 public totalSupply;
 mapping (address => uint256) public balanceOf;
 mapping (address => mapping (address => uint256)) public allowance;
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Burn(address indexed from, uint256 value);
 function TokenERC20(
 uint256 initialSupply,
 string tokenName,
 string tokenSymbol,
 uint8 tokenDecimals
 ) public {
 name = tokenName;
 symbol = tokenSymbol;
 decimals = tokenDecimals;
 totalSupply = initialSupply * 10 ** uint256(decimals);
 balanceOf[msg.sender] = totalSupply;
 }
 function _transfer(address _from, address _to, uint _value) internal {
 require(_to != 0x0);
 require(balanceOf[_from] >= _value);
 require(balanceOf[_to] + _value > balanceOf[_to]);
 uint previousBalances = balanceOf[_from] + balanceOf[_to];
 balanceOf[_from] -= _value;
 balanceOf[_to] += _value;
 Transfer(_from, _to, _value);
 assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
 }
 function transfer(address _to, uint256 _value) public {
 _transfer(msg.sender, _to, _value);
 }
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
 require(_value <= allowance[_from][msg.sender]);
 allowance[_from][msg.sender] -= _value;
 _transfer(_from, _to, _value);
 return true;
 }
 function approve(address _spender, uint256 _value) public
 returns (bool success) {
 allowance[msg.sender][_spender] = _value;
 return true;
 }
 function approveAndCall(address _spender, uint256 _value, bytes _extraData)
 public
 returns (bool success) {
 tokenRecipient spender = tokenRecipient(_spender);
 if (approve(_spender, _value)) {
 spender.receiveApproval(msg.sender, _value, this, _extraData);
 return true;
 }
 }
 function burn(uint256 _value) public returns (bool success) {
 require(balanceOf[msg.sender] >= _value);
 balanceOf[msg.sender] -= _value;
 totalSupply -= _value;
 Burn(msg.sender, _value);
 return true;
 }
 function burnFrom(address _from, uint256 _value) public returns (bool success) {
 require(balanceOf[_from] >= _value);
 require(_value <= allowance[_from][msg.sender]);
 balanceOf[_from] -= _value;
 allowance[_from][msg.sender] -= _value;
 totalSupply -= _value;
 Burn(_from, _value);
 return true;
 }
}
contract TESTAhihi is owned, TokenERC20 {
 uint256 public constant initialSupply = 44950000;
 string public constant tokenName = "TESTAhihi";
 string public constant tokenSymbol = "TAS";
 uint8 public constant tokenDecimals = 6;
 uint256 public sellPrice;
 uint256 public buyPrice;
 bool isAllowMining;
 function setAllowMining(bool allowMining) onlyOwner {
 isAllowMining = allowMining;
 }
 mapping (address => bool) public frozenAccount;
 event FrozenFunds(address target, bool frozen);
 function TESTAhihi() TokenERC20(initialSupply, tokenName, tokenSymbol, tokenDecimals) public {}
 bytes32 public currentChallenge;
 uint public timeOfLastProof;
 uint public difficulty = 10**32;
 function proofOfWork(uint nonce){
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (isAllowMining){
 bytes8 n = bytes8(sha3(nonce, currentChallenge));
 require(n >= bytes8(difficulty));
 uint timeSinceLastProof = (now - timeOfLastProof);
 require(timeSinceLastProof >= 5 seconds);
 balanceOf[msg.sender] += timeSinceLastProof / 60 seconds;
 difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;
 timeOfLastProof = now;
 currentChallenge = sha3(nonce, currentChallenge, block.blockhash(block.number - 1));
 }
 }
 uint256 minBalanceForAccounts;
 function setMinBalance(uint minimumBalanceInFinney) onlyOwner {
 minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
 }
 function _transfer(address _from, address _to, uint _value) internal {
 require (_to != 0x0);
 require (balanceOf[_from] > _value);
 require (balanceOf[_to] + _value > balanceOf[_to]);
 require(!frozenAccount[_from]);
 require(!frozenAccount[_to]);
 balanceOf[_from] -= _value;
 balanceOf[_to] += _value;
 Transfer(_from, _to, _value);
 }
 function mintToken(address target, uint256 mintedAmount) onlyOwner public {
 balanceOf[target] += mintedAmount;
 totalSupply += mintedAmount;
 Transfer(0, this, mintedAmount);
 Transfer(this, target, mintedAmount);
 }
 function freezeAccount(address target, bool freeze) onlyOwner public {
 frozenAccount[target] = freeze;
 FrozenFunds(target, freeze);
 }
 function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
 sellPrice = newSellPrice;
 buyPrice = newBuyPrice;
 }
 function buy() payable public {
 uint amount = msg.value / buyPrice;
 _transfer(this, msg.sender, amount);
 }
 function sell(uint256 amount) public {
 require(this.balance >= amount * sellPrice);
 _transfer(msg.sender, this, amount);
 msg.sender.transfer(amount * sellPrice);
 }
 function transfer(address _to, uint256 _value) public {
 if(msg.sender.balance < minBalanceForAccounts)
 sell((minBalanceForAccounts - msg.sender.balance) / sellPrice);
 _transfer(msg.sender, _to, _value);
 if(_to.balance<minBalanceForAccounts){
 require(this.balance >= ((minBalanceForAccounts - _to.balance) / sellPrice) * sellPrice);
 _transfer(_to, this, ((minBalanceForAccounts - _to.balance) / sellPrice));
 _to.transfer(((minBalanceForAccounts - _to.balance) / sellPrice) * sellPrice);
 }
 }
}