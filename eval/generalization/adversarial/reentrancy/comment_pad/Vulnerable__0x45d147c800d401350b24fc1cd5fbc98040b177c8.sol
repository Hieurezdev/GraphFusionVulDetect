pragma solidity ^0.4.2;
contract Token{
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
 event Approval(address indexed _onwer,address indexed _spender, uint256 _value);
 function totalSupply() constant returns(uint256 totalSupply){}
 function balanceOf(address _owner) constant returns (uint256 balance){}
 function transfer(address _to, uint256 _value) constant returns(bool success){}
 function transferFrom(address _from, address _to, uint256 _value) constant returns (bool success){}
 function approve(address _spender, uint256 _value) constant returns(bool success){}
 function allowance(address _owner, uint _spender) constant returns(uint256 remaining){}
}
contract StandardToken is Token{
 uint256 public totalSupply;
 mapping(address => uint256)balances;
 mapping(address =>mapping(address=>uint256))allowed;
 function transfer(address _to, uint256 _value)constant returns(bool success){
 if(balances[msg.sender]>_value && balances[_to]+_value>balances[_to]) {
 balances[msg.sender] -= _value;
 balances[_to] +=_value;
 Transfer(msg.sender,_to,_value);
 return true;
 } else {
 return false;
 }
 }
 function transferFrom(address _from, address _to, uint256 _value)constant returns(bool success){
 if(balances[_from]>_value && allowed[_from][msg.sender]>_value && balances[_to]+_value>balances[_to]){
 balances[_from]-=_value;
 allowed[_from][msg.sender]-=_value;
 balances[_to]-=_value;
 Transfer(_from,_to,_value);
 return true;
 } else {
 return false;
 }
 }
 function approve(address _spender, uint256 _value)constant returns (bool success){
 allowed[msg.sender][_spender]=_value;
 Approval(msg.sender,_spender,_value);
 return true;
 }
 function balanceOf(address _owner) constant returns (uint256 balance){
 return balances[_owner];
 }
 function allowance(address _onwer,address _spender) constant returns(uint256 allowance){
 return allowed[_onwer][_spender];
 }
}
contract NinjaToken is StandardToken{
 string public name ="NinjaToken";
 string public version="0.0.1";
 uint public decimals = 18;
 mapping(address=>string) public commit;
 address public founder;
 address public admin;
 bool public fundingLock=true;
 address public fundingAccount;
 uint public startBlock;
 uint public blockDuration;
 uint public fundingExchangeRate;
 uint public price=10;
 bool public transferLock=false;
 event Funding(address sender, uint256 eth);
 event Buy(address buyer, uint256 eth);
 function NinjaToken(address _founder,address _admin){
 founder=_founder;
 admin=_admin;
 }
 function changeFunder(address _founder,address _admin){
 if(msg.sender!=admin) throw;
 founder=_founder;
 admin=_admin;
 }
 function setFundingLock(bool _fundinglock,address _fundingAccount){
 if(msg.sender!=founder) throw;
 fundingLock=_fundinglock;
 fundingAccount=_fundingAccount;
 }
 function setFundingEnv(uint _startBlock, uint _blockDuration,uint _fundingExchangeRate){
 if(msg.sender!=founder) throw;
 startBlock=_startBlock;
 blockDuration=_blockDuration;
 fundingExchangeRate=_fundingExchangeRate;
 }
 function funding() payable {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if(fundingLock||block.number<startBlock||block.number>startBlock+blockDuration) throw;
 if(balances[msg.sender]>balances[msg.sender]+msg.value*fundingExchangeRate || msg.value>msg.value*fundingExchangeRate) throw;
 if(!fundingAccount.call.value(msg.value)()) throw;
 balances[msg.sender]+=msg.value*fundingExchangeRate;
 Funding(msg.sender,msg.value);
 }
 function setPrice(uint _price,bool _transferLock){
 if(msg.sender!=founder) throw;
 price=_price;
 transferLock=_transferLock;
 }
 function buy(string _commit) payable{
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if(balances[msg.sender]>balances[msg.sender]+msg.value*price || msg.value>msg.value*price) throw;
 if(!fundingAccount.call.value(msg.value)()) throw;
 balances[msg.sender]+=msg.value*price;
 commit[msg.sender]=_commit;
 Buy(msg.sender,msg.value);
 }
 function transfer(address _to, uint256 _value)constant returns(bool success){
 if(transferLock) throw;
 return super.transfer(_to, _value);
 }
 function transferFrom(address _from, address _to, uint256 _value)constant returns(bool success){
 if(transferLock) throw;
 return super.transferFrom(_from, _to, _value);
 }
}