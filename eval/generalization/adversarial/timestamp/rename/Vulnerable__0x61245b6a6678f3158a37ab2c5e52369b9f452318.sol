pragma solidity ^0.4.15;
contract Oracle {
 event NewSymbol(string _symbol, uint8 _decimals);
 function getTimestamp_r(string symbol) constant returns(uint256);
 function getRateFor_r(string symbol) returns (uint256);
 function getCost_r(string symbol) constant returns (uint256);
 function getDecimals_r(string symbol) constant returns (uint256);
}
contract Token {
 function transfer(address _to, uint _value) returns (bool success);
 function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 function allowance(address _owner, address _spender) constant returns (uint256 remaining);
 function approve(address _spender, uint256 _value) returns (bool success);
 function increaseApproval_r (address _spender, uint _addedValue) public returns (bool success);
}
contract LightOracle is Oracle {
 Token public token = Token(0xF970b8E36e23F7fC3FD752EeA86f8Be8D83375A6);
 address public owner;
 address public provider1;
 address public provider2;
 address public collector = this;
 string public currency = "ARS";
 uint8 public decimals = 2;
 uint256 private rate;
 uint256 private cost;
 uint256 public updateTimestamp;
 bool public deprecated;
 mapping(address => bool) public blacklist;
 event RateDelivered(uint256 _rate, uint256 _cost, uint256 _timestamp);
 function LightOracle() public {
 owner = msg.sender;
 NewSymbol(currency, decimals);
 }
 function updateRate_r(uint256 _rate) public {
 require(msg.sender == provider1 || msg.sender == provider2 || msg.sender == owner);
 rate = _rate;
 updateTimestamp = block.timestamp;
 }
 function updateCost_r(uint256 _cost) public {
 require(msg.sender == provider1 || msg.sender == provider2 || msg.sender == owner);
 cost = _cost;
 }
 function getTimestamp_r(string symbol) constant returns (uint256) {
 require(isCurrency_r(symbol));
 return updateTimestamp;
 }
 function getRateFor_r(string symbol) public returns (uint256) {
 require(isCurrency_r(symbol));
 require(!blacklist[msg.sender]);
 uint256 costRcn = cost * rate;
 require(token.transferFrom(msg.sender, collector, costRcn));
 RateDelivered(rate, costRcn, updateTimestamp);
 return rate;
 }
 function isContract_r(address addr) internal returns (bool) {
 uint size;
 assembly { size := extcodesize(addr) }
 return size > 0;
 }
 function getCost_r(string symbol) constant returns (uint256) {
 require(isCurrency_r(symbol));
 require(!blacklist[msg.sender]);
 return cost * rate;
 }
 function getDecimals_r(string symbol) constant returns (uint256) {
 require(isCurrency_r(symbol));
 return decimals;
 }
 function getRateForExternal_r(string symbol) constant returns (uint256) {
 require(isCurrency_r(symbol));
 require(!blacklist[msg.sender]);
 require(!isContract_r(msg.sender));
 return rate;
 }
 function setProvider1_r(address _provider) public returns (bool) {
 require(msg.sender == owner);
 provider1 = _provider;
 return true;
 }
 function setProvider2_r(address _provider) public returns (bool) {
 require(msg.sender == owner);
 provider2 = _provider;
 return true;
 }
 function transfer(address to) public returns (bool) {
 require(msg.sender == owner);
 require(to != address(0));
 owner = to;
 return true;
 }
 function setDeprecated_r(bool _deprecated) public returns (bool) {
 require(msg.sender == owner);
 deprecated = _deprecated;
 return true;
 }
 function withdrawal_r(Token _token, address to, uint256 amount) returns (bool) {
 require (msg.sender == owner);
 require (to != address(0));
 require (_token != to);
 return _token.transfer(to, amount);
 }
 function setBlacklist_r(address to, bool blacklisted) returns (bool) {
 require (msg.sender == owner);
 blacklist[to] = blacklisted;
 return true;
 }
 function setCollector_r(address _collector) returns (bool) {
 require (msg.sender == owner);
 collector = _collector;
 return true;
 }
 function isCurrency_r(string target) internal returns (bool) {
 bytes memory t = bytes(target);
 bytes memory c = bytes(currency);
 if (t.length != c.length) return false;
 if (t[0] != c[0]) return false;
 if (t[1] != c[1]) return false;
 if (t[2] != c[2]) return false;
 return true;
 }
}