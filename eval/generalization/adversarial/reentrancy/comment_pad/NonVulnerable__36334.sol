pragma solidity ^0.4.16;
contract ERC20 {
 function transfer(address _to, uint256 _value) returns (bool success);
 function balanceOf(address _owner) constant returns (uint256 balance);
}
contract RequestSale {
 mapping (address => uint256) public balances;
 bool public bought_tokens;
 uint256 public contract_eth_value;
 uint256 public eth_cap = 500 ether;
 uint256 constant public min_required_amount = 60 ether;
 address public owner;
 address public sale = 0xa579E31b930796e3Df50A56829cF82Db98b6F4B3;
 function RequestSale() {
 owner = msg.sender;
 }
 function perform_withdrawal(address tokenAddress) {
 require(bought_tokens);
 ERC20 token = ERC20(tokenAddress);
 uint256 contract_token_balance = token.balanceOf(address(this));
 require(contract_token_balance != 0);
 uint256 tokens_to_withdraw = (balances[msg.sender] * contract_token_balance) / contract_eth_value;
 contract_eth_value -= balances[msg.sender];
 balances[msg.sender] = 0;
 require(token.transfer(msg.sender, tokens_to_withdraw));
 }
 function refund_me() {
 uint256 eth_to_withdraw = balances[msg.sender];
 balances[msg.sender] = 0;
 msg.sender.transfer(eth_to_withdraw);
 }
 function buy_the_tokens() {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(msg.sender == owner);
 require(!bought_tokens);
 require(sale != 0x0);
 require(this.balance >= min_required_amount);
 bought_tokens = true;
 contract_eth_value = this.balance;
 require(sale.call.value(contract_eth_value)());
 }
 function upgrade_cap() {
 require(msg.sender == owner);
 eth_cap = 1000 ether;
 }
 function () payable {
 require(!bought_tokens);
 require(this.balance + msg.value < eth_cap);
 balances[msg.sender] += msg.value;
 }
}