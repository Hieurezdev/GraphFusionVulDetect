pragma solidity ^0.4.6;
contract TokenController {
 function proxyPayment(address _owner) payable returns(bool);
 function onTransfer(address _from, address _to, uint _amount) returns(bool);
 function onApprove(address _owner, address _spender, uint _amount)
 returns(bool);
}
contract Controlled {
 modifier onlyController { if (msg.sender != controller) throw; _; }
 address public controller;
 function Controlled() { controller = msg.sender;}
 function changeController(address _newController) onlyController {
 controller = _newController;
 }
}
contract MiniMeToken is Controlled {
 string public name;
 uint8 public decimals;
 string public symbol;
 string public version = 'MMT_0.1';
 struct Checkpoint {
 uint128 fromBlock;
 uint128 value;
 }
 MiniMeToken public parentToken;
 uint public parentSnapShotBlock;
 uint public creationBlock;
 mapping (address => Checkpoint[]) balances;
 mapping (address => mapping (address => uint256)) allowed;
 Checkpoint[] totalSupplyHistory;
 bool public transfersEnabled;
 MiniMeTokenFactory public tokenFactory;
 function MiniMeToken(
 address _tokenFactory,
 address _parentToken,
 uint _parentSnapShotBlock,
 string _tokenName,
 uint8 _decimalUnits,
 string _tokenSymbol,
 bool _transfersEnabled
 ) {
 tokenFactory = MiniMeTokenFactory(_tokenFactory);
 name = _tokenName;
 decimals = _decimalUnits;
 symbol = _tokenSymbol;
 parentToken = MiniMeToken(_parentToken);
 parentSnapShotBlock = _parentSnapShotBlock;
 transfersEnabled = _transfersEnabled;
 creationBlock = block.number;
 }
 function transfer(address _to, uint256 _amount) returns (bool success) {
 if (!transfersEnabled) throw;
 return doTransfer(msg.sender, _to, _amount);
 }
 function transferFrom(address _from, address _to, uint256 _amount
 ) returns (bool success) {
 if (msg.sender != controller) {
 if (!transfersEnabled) throw;
 if (allowed[_from][msg.sender] < _amount) return false;
 allowed[_from][msg.sender] -= _amount;
 }
 return doTransfer(_from, _to, _amount);
 }
 function doTransfer(address _from, address _to, uint _amount
 ) internal returns(bool) {
 if (_amount == 0) {
 return true;
 }
 if ((_to == 0) || (_to == address(this))) throw;
 var previousBalanceFrom = balanceOfAt(_from, block.number);
 if (previousBalanceFrom < _amount) {
 return false;
 }
 if (isContract(controller)) {
 if (!TokenController(controller).onTransfer(_from, _to, _amount))
 throw;
 }
 updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
 var previousBalanceTo = balanceOfAt(_to, block.number);
 updateValueAtNow(balances[_to], previousBalanceTo + _amount);
 Transfer(_from, _to, _amount);
 return true;
 }
 function balanceOf(address _owner) constant returns (uint256 balance) {
 return balanceOfAt(_owner, block.number);
 }
 function approve(address _spender, uint256 _amount) returns (bool success) {
 if (!transfersEnabled) throw;
 if ((_amount!=0) && (allowed[msg.sender][_spender] !=0)) throw;
 if (isContract(controller)) {
 if (!TokenController(controller).onApprove(msg.sender, _spender, _amount))
 throw;
 }
 allowed[msg.sender][_spender] = _amount;
 Approval(msg.sender, _spender, _amount);
 return true;
 }
 function allowance(address _owner, address _spender
 ) constant returns (uint256 remaining) {
 return allowed[_owner][_spender];
 }
 function approveAndCall(address _spender, uint256 _amount, bytes _extraData
 ) returns (bool success) {
 allowed[msg.sender][_spender] = _amount;
 Approval(msg.sender, _spender, _amount);
 if(!_spender.call(
 bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))),
 msg.sender,
 _amount,
 this,
 _extraData
 )) { throw;
 }
 return true;
 }
 function totalSupply() constant returns (uint) {
 return totalSupplyAt(block.number);
 }
 function balanceOfAt(address _owner, uint _blockNumber) constant
 returns (uint) {
 if (_blockNumber < creationBlock) {
 return 0;
 } else if ((balances[_owner].length == 0)
 || (balances[_owner][0].fromBlock > _blockNumber)) {
 if (address(parentToken) != 0) {
 return parentToken.balanceOfAt(_owner, parentSnapShotBlock);
 } else {
 return 0;
 }
 } else {
 return getValueAt(balances[_owner], _blockNumber);
 }
 }
 function totalSupplyAt(uint _blockNumber) constant returns(uint) {
 if (_blockNumber < creationBlock) {
 return 0;
 } else if ((totalSupplyHistory.length == 0)
 || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
 if (address(parentToken) != 0) {
 return parentToken.totalSupplyAt(parentSnapShotBlock);
 } else {
 return 0;
 }
 } else {
 return getValueAt(totalSupplyHistory, _blockNumber);
 }
 }
 function createCloneToken(
 string _cloneTokenName,
 uint8 _cloneDecimalUnits,
 string _cloneTokenSymbol,
 uint _snapshotBlock,
 bool _transfersEnabled
 ) returns(address) {
 if (_snapshotBlock > block.number) _snapshotBlock = block.number;
 MiniMeToken cloneToken = tokenFactory.createCloneToken(
 this,
 _snapshotBlock,
 _cloneTokenName,
 _cloneDecimalUnits,
 _cloneTokenSymbol,
 _transfersEnabled
 );
 cloneToken.changeController(msg.sender);
 NewCloneToken(address(cloneToken), _snapshotBlock);
 return address(cloneToken);
 }
 function generateTokens(address _owner, uint _amount
 ) onlyController returns (bool) {
 uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
 updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
 var previousBalanceTo = balanceOf(_owner);
 updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
 Transfer(0, _owner, _amount);
 return true;
 }
 function destroyTokens(address _owner, uint _amount
 ) onlyController returns (bool) {
 uint curTotalSupply = getValueAt(totalSupplyHistory, block.number);
 if (curTotalSupply < _amount) throw;
 updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
 var previousBalanceFrom = balanceOf(_owner);
 if (previousBalanceFrom < _amount) throw;
 updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
 Transfer(_owner, 0, _amount);
 return true;
 }
 function enableTransfers(bool _transfersEnabled) onlyController {
 transfersEnabled = _transfersEnabled;
 }
 function getValueAt(Checkpoint[] storage checkpoints, uint _block
 ) constant internal returns (uint) {
 if (checkpoints.length == 0) return 0;
 if (_block >= checkpoints[checkpoints.length-1].fromBlock)
 return checkpoints[checkpoints.length-1].value;
 if (_block < checkpoints[0].fromBlock) return 0;
 uint min = 0;
 uint max = checkpoints.length-1;
 while (max > min) {
 uint mid = (max + min + 1)/ 2;
 if (checkpoints[mid].fromBlock<=_block) {
 min = mid;
 } else {
 max = mid-1;
 }
 }
 return checkpoints[min].value;
 }
 function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value
 ) internal {
 if ((checkpoints.length == 0)
 || (checkpoints[checkpoints.length -1].fromBlock < block.number)) {
 Checkpoint newCheckPoint = checkpoints[ checkpoints.length++ ];
 newCheckPoint.fromBlock = uint128(block.number);
 newCheckPoint.value = uint128(_value);
 } else {
 Checkpoint oldCheckPoint = checkpoints[checkpoints.length-1];
 oldCheckPoint.value = uint128(_value);
 }
 }
 function isContract(address _addr) constant internal returns(bool) {
 uint size;
 if (_addr == 0) return false;
 assembly {
 size := extcodesize(_addr)
 }
 return size>0;
 }
 function () payable {
 if (isContract(controller)) {
 if (! TokenController(controller).proxyPayment.value(msg.value)(msg.sender))
 throw;
 } else {
 throw;
 }
 }
 event Transfer(address indexed _from, address indexed _to, uint256 _amount);
 event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
 event Approval(
 address indexed _owner,
 address indexed _spender,
 uint256 _amount
 );
}
contract MiniMeTokenFactory {
 function createCloneToken(
 address _parentToken,
 uint _snapshotBlock,
 string _tokenName,
 uint8 _decimalUnits,
 string _tokenSymbol,
 bool _transfersEnabled
 ) returns (MiniMeToken) {
 MiniMeToken newToken = new MiniMeToken(
 this,
 _parentToken,
 _snapshotBlock,
 _tokenName,
 _decimalUnits,
 _tokenSymbol,
 _transfersEnabled
 );
 newToken.changeController(msg.sender);
 return newToken;
 }
}
contract Owned {
 modifier onlyOwner { if (msg.sender != owner) throw; _; }
 address public owner;
 function Owned() { owner = msg.sender;}
 function changeOwner(address _newOwner) onlyOwner {
 owner = _newOwner;
 }
}
contract Campaign is TokenController, Owned {
 uint public startFundingTime;
 uint public endFundingTime;
 uint public maximumFunding;
 uint public totalCollected;
 MiniMeToken public tokenContract;
 address public vaultAddress;
 function Campaign(
 uint _startFundingTime,
 uint _endFundingTime,
 uint _maximumFunding,
 address _vaultAddress,
 address _tokenAddress
 ) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if ((_endFundingTime < now) ||
 (_endFundingTime <= _startFundingTime) ||
 (_maximumFunding > 10000 ether) ||
 (_vaultAddress == 0))
 {
 throw;
 }
 startFundingTime = _startFundingTime;
 endFundingTime = _endFundingTime;
 maximumFunding = _maximumFunding;
 tokenContract = MiniMeToken(_tokenAddress);
 vaultAddress = _vaultAddress;
 }
 function () payable {
 doPayment(msg.sender);
 }
 function proxyPayment(address _owner) payable returns(bool) {
 doPayment(_owner);
 return true;
 }
 function onTransfer(address _from, address _to, uint _amount) returns(bool) {
 return true;
 }
 function onApprove(address _owner, address _spender, uint _amount)
 returns(bool)
 {
 return true;
 }
 function doPayment(address _owner) internal {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if ((now<startFundingTime) ||
 (now>endFundingTime) ||
 (tokenContract.controller() == 0) ||
 (msg.value == 0) ||
 (totalCollected + msg.value > maximumFunding))
 {
 throw;
 }
 totalCollected += msg.value;
 if (!vaultAddress.send(msg.value)) {
 throw;
 }
 if (!tokenContract.generateTokens(_owner, msg.value)) {
 throw;
 }
 return;
 }
 function finalizeFunding() {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (now < endFundingTime) throw;
 tokenContract.changeController(0);
 }
 function setVault(address _newVaultAddress) onlyOwner {
 vaultAddress = _newVaultAddress;
 }
}