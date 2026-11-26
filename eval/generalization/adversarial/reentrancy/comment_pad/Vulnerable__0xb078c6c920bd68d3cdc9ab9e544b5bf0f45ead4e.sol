pragma solidity ^0.4.15;
contract SafeMath {
 function safeMul(uint a, uint b) internal returns (uint) {
 uint c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function safeSub(uint a, uint b) internal returns (uint) {
 assert(b <= a);
 return a - b;
 }
 function safeAdd(uint a, uint b) internal returns (uint) {
 uint c = a + b;
 assert(c>=a && c>=b);
 return c;
 }
}
contract Token {
 function totalSupply() constant returns (uint256 supply) {}
 function balanceOf(address _owner) constant returns (uint256 balance) {}
 function transfer(address _to, uint256 _value) returns (bool success) {}
 function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
 function approve(address _spender, uint256 _value) returns (bool success) {}
 function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 uint public decimals;
 string public name;
}
contract TokenLab is SafeMath {
 address public admin;
 address public feeAccount;
 uint public feeMake;
 uint public feeTake;
 mapping (address => mapping (address => uint)) public tokens;
 mapping (address => mapping (bytes32 => bool)) public orders;
 mapping (address => mapping (bytes32 => uint)) public orderFills;
 event Order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
 event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
 event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
 event Deposit(address token, address user, uint amount, uint balance);
 event Withdraw(address token, address user, uint amount, uint balance);
 function TokenLab(address feeAccount_, uint feeMake_, uint feeTake_) {
 admin = msg.sender;
 feeAccount = feeAccount_;
 feeMake = feeMake_;
 feeTake = feeTake_;
 }
 modifier onlyAdmin () {
 require(msg.sender == admin);
 _;
 }
 function changeAdmin(address admin_) onlyAdmin {
 admin = admin_;
 }
 function changeFeeAccount(address feeAccount_) onlyAdmin {
 feeAccount = feeAccount_;
 }
 function changeFeeMake(uint feeMake_) onlyAdmin {
 require (feeMake_ <= feeMake);
 feeMake = feeMake_;
 }
 function changeFeeTake(uint feeTake_) onlyAdmin {
 require (feeTake_ <= feeTake);
 feeTake = feeTake_;
 }
 function deposit() payable {
 tokens[0][msg.sender] = safeAdd(tokens[0][msg.sender], msg.value);
 Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
 }
 function withdraw(uint amount) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(tokens[0][msg.sender] >= amount);
 tokens[0][msg.sender] = safeSub(tokens[0][msg.sender], amount);
 require(msg.sender.call.value(amount)());
 Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
 }
 function depositToken(address token, uint amount) {
 require (token!=0);
 require (Token(token).transferFrom(msg.sender, this, amount));
 tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
 Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
 }
 function withdrawToken(address token, uint amount) {
 require (token!=0);
 require (tokens[token][msg.sender] >= amount);
 tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
 require (Token(token).transfer(msg.sender, amount));
 Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
 }
 function balanceOf(address token, address user) constant returns (uint) {
 return tokens[token][user];
 }
 function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) {
 bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
 orders[msg.sender][hash] = true;
 Order(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
 }
 function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {
 bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
 require ((
 (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user) &&
 block.number <= expires &&
 safeAdd(orderFills[user][hash], amount) <= amountGet
 ));
 tradeBalances(tokenGet, amountGet, tokenGive, amountGive, user, amount);
 orderFills[user][hash] = safeAdd(orderFills[user][hash], amount);
 Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
 }
 function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
 uint feeMakeXfer = safeMul(amount, feeMake) / (1 ether);
 uint feeTakeXfer = safeMul(amount, feeTake) / (1 ether);
 tokens[tokenGet][msg.sender] = safeSub(tokens[tokenGet][msg.sender], safeAdd(amount, feeTakeXfer));
 tokens[tokenGet][user] = safeAdd(tokens[tokenGet][user], safeSub(amount, feeMakeXfer));
 tokens[tokenGet][feeAccount] = safeAdd(tokens[tokenGet][feeAccount], safeAdd(feeMakeXfer, feeTakeXfer));
 tokens[tokenGive][user] = safeSub(tokens[tokenGive][user], safeMul(amountGive, amount) / amountGet);
 tokens[tokenGive][msg.sender] = safeAdd(tokens[tokenGive][msg.sender], safeMul(amountGive, amount) / amountGet);
 }
 function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant returns(bool) {
 if (!(
 tokens[tokenGet][sender] >= amount &&
 availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
 )) return false;
 return true;
 }
 function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {
 bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
 if (!(
 (orders[user][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == user) &&
 block.number <= expires
 )) return 0;
 uint available1 = safeSub(amountGet, orderFills[user][hash]);
 uint available2 = safeMul(tokens[tokenGive][user], amountGet) / amountGive;
 if (available1<available2) return available1;
 return available2;
 }
 function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user) constant returns(uint) {
 bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
 return orderFills[user][hash];
 }
 function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) {
 bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
 require ((orders[msg.sender][hash] || ecrecover(sha3("\x19Ethereum Signed Message:\n32", hash),v,r,s) == msg.sender));
 orderFills[msg.sender][hash] = amountGet;
 Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
 }
}