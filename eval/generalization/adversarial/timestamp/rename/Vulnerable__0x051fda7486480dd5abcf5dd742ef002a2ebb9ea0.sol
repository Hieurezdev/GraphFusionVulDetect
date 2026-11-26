pragma solidity ^0.4.11;
contract Owned {
 modifier onlyOwner() {
 if(msg.sender != owner) throw;
 _;
 }
 address public owner;
 function Owned() {
 owner = msg.sender;
 }
 address public newOwner;
 function changeOwner_r(address _newOwner) onlyOwner {
 newOwner = _newOwner;
 }
 function acceptOwnership_r() {
 if (msg.sender == newOwner) {
 owner = newOwner;
 }
 }
}
contract ERC20Token {
 uint256 public totalSupply;
 function balanceOf(address _owner) constant returns (uint256 balance);
 function transfer(address _to, uint256 _value) returns (bool success);
 function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
 function approve(address _spender, uint256 _value) returns (bool success);
 function allowance(address _owner, address _spender) constant returns (uint256 remaining);
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract TokenController {
 function proxyPayment_r(address _owner) payable returns(bool);
 function onTransfer_r(address _from, address _to, uint _amount) returns(bool);
 function onApprove_r(address _owner, address _spender, uint _amount)
 returns(bool);
}
contract Controlled {
 modifier onlyController { if (msg.sender != controller) throw; _; }
 address public controller;
 function Controlled() { controller = msg.sender;}
 function changeController_r(address _newController) onlyController {
 controller = _newController;
 }
}
contract ApproveAndCallFallBack {
 function receiveApproval(address from, uint256 _amount, address _token, bytes _data);
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
 creationBlock = getBlockNumber_r();
 }
 function transfer(address _to, uint256 _amount) returns (bool success) {
 if (!transfersEnabled) throw;
 return doTransfer_r(msg.sender, _to, _amount);
 }
 function transferFrom(address _from, address _to, uint256 _amount
 ) returns (bool success) {
 if (msg.sender != controller) {
 if (!transfersEnabled) throw;
 if (allowed[_from][msg.sender] < _amount) return false;
 allowed[_from][msg.sender] -= _amount;
 }
 return doTransfer_r(_from, _to, _amount);
 }
 function doTransfer_r(address _from, address _to, uint _amount
 ) internal returns(bool) {
 if (_amount == 0) {
 return true;
 }
 if (parentSnapShotBlock >= getBlockNumber_r()) throw;
 if ((_to == 0) || (_to == address(this))) throw;
 var previousBalanceFrom = balanceOfAt_r(_from, getBlockNumber_r());
 if (previousBalanceFrom < _amount) {
 return false;
 }
 if (isContract_r(controller)) {
 if (!TokenController(controller).onTransfer_r(_from, _to, _amount))
 throw;
 }
 updateValueAtNow_r(balances[_from], previousBalanceFrom - _amount);
 var previousBalanceTo = balanceOfAt_r(_to, getBlockNumber_r());
 if (previousBalanceTo + _amount < previousBalanceTo) throw;
 updateValueAtNow_r(balances[_to], previousBalanceTo + _amount);
 Transfer(_from, _to, _amount);
 return true;
 }
 function balanceOf(address _owner) constant returns (uint256 balance) {
 return balanceOfAt_r(_owner, getBlockNumber_r());
 }
 function approve(address _spender, uint256 _amount) returns (bool success) {
 if (!transfersEnabled) throw;
 if ((_amount!=0) && (allowed[msg.sender][_spender] !=0)) throw;
 if (isContract_r(controller)) {
 if (!TokenController(controller).onApprove_r(msg.sender, _spender, _amount))
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
 function approveAndCall_r(address _spender, uint256 _amount, bytes _extraData
 ) returns (bool success) {
 if (!approve(_spender, _amount)) throw;
 ApproveAndCallFallBack(_spender).receiveApproval(
 msg.sender,
 _amount,
 this,
 _extraData
 );
 return true;
 }
 function totalSupply() constant returns (uint) {
 return totalSupplyAt_r(getBlockNumber_r());
 }
 function balanceOfAt_r(address _owner, uint _blockNumber) constant
 returns (uint) {
 if ((balances[_owner].length == 0)
 || (balances[_owner][0].fromBlock > _blockNumber)) {
 if (address(parentToken) != 0) {
 return parentToken.balanceOfAt_r(_owner, min_r(_blockNumber, parentSnapShotBlock));
 } else {
 return 0;
 }
 } else {
 return getValueAt_r(balances[_owner], _blockNumber);
 }
 }
 function totalSupplyAt_r(uint _blockNumber) constant returns(uint) {
 if ((totalSupplyHistory.length == 0)
 || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
 if (address(parentToken) != 0) {
 return parentToken.totalSupplyAt_r(min_r(_blockNumber, parentSnapShotBlock));
 } else {
 return 0;
 }
 } else {
 return getValueAt_r(totalSupplyHistory, _blockNumber);
 }
 }
 function createCloneToken_r(
 string _cloneTokenName,
 uint8 _cloneDecimalUnits,
 string _cloneTokenSymbol,
 uint _snapshotBlock,
 bool _transfersEnabled
 ) returns(address) {
 if (_snapshotBlock == 0) _snapshotBlock = getBlockNumber_r();
 MiniMeToken cloneToken = tokenFactory.createCloneToken_r(
 this,
 _snapshotBlock,
 _cloneTokenName,
 _cloneDecimalUnits,
 _cloneTokenSymbol,
 _transfersEnabled
 );
 cloneToken.changeController_r(msg.sender);
 NewCloneToken(address(cloneToken), _snapshotBlock);
 return address(cloneToken);
 }
 function generateTokens_r(address _owner, uint _amount
 ) onlyController returns (bool) {
 uint curTotalSupply = getValueAt_r(totalSupplyHistory, getBlockNumber_r());
 if (curTotalSupply + _amount < curTotalSupply) throw;
 updateValueAtNow_r(totalSupplyHistory, curTotalSupply + _amount);
 var previousBalanceTo = balanceOf(_owner);
 if (previousBalanceTo + _amount < previousBalanceTo) throw;
 updateValueAtNow_r(balances[_owner], previousBalanceTo + _amount);
 Transfer(0, _owner, _amount);
 return true;
 }
 function destroyTokens_r(address _owner, uint _amount
 ) onlyController returns (bool) {
 uint curTotalSupply = getValueAt_r(totalSupplyHistory, getBlockNumber_r());
 if (curTotalSupply < _amount) throw;
 updateValueAtNow_r(totalSupplyHistory, curTotalSupply - _amount);
 var previousBalanceFrom = balanceOf(_owner);
 if (previousBalanceFrom < _amount) throw;
 updateValueAtNow_r(balances[_owner], previousBalanceFrom - _amount);
 Transfer(_owner, 0, _amount);
 return true;
 }
 function enableTransfers_r(bool _transfersEnabled) onlyController {
 transfersEnabled = _transfersEnabled;
 }
 function getValueAt_r(Checkpoint[] storage checkpoints, uint _block
 ) constant internal returns (uint) {
 if (checkpoints.length == 0) return 0;
 if (_block >= checkpoints[checkpoints.length-1].fromBlock)
 return checkpoints[checkpoints.length-1].value;
 if (_block < checkpoints[0].fromBlock) return 0;
 uint min_r = 0;
 uint max = checkpoints.length-1;
 while (max > min_r) {
 uint mid = (max + min_r + 1)/ 2;
 if (checkpoints[mid].fromBlock<=_block) {
 min_r = mid;
 } else {
 max = mid-1;
 }
 }
 return checkpoints[min_r].value;
 }
 function updateValueAtNow_r(Checkpoint[] storage checkpoints, uint _value
 ) internal {
 if ((checkpoints.length == 0)
 || (checkpoints[checkpoints.length -1].fromBlock < getBlockNumber_r())) {
 Checkpoint newCheckPoint = checkpoints[ checkpoints.length++ ];
 newCheckPoint.fromBlock = uint128(getBlockNumber_r());
 newCheckPoint.value = uint128(_value);
 } else {
 Checkpoint oldCheckPoint = checkpoints[checkpoints.length-1];
 oldCheckPoint.value = uint128(_value);
 }
 }
 function isContract_r(address _addr) constant internal returns(bool) {
 uint size;
 if (_addr == 0) return false;
 assembly {
 size := extcodesize(_addr)
 }
 return size>0;
 }
 function min_r(uint a, uint b) internal returns (uint) {
 return a < b ? a : b;
 }
 function () payable {
 if (isContract_r(controller)) {
 if (! TokenController(controller).proxyPayment_r.value(msg.value)(msg.sender))
 throw;
 } else {
 throw;
 }
 }
 function getBlockNumber_r() internal constant returns (uint256) {
 return block.number;
 }
 function claimTokens_r(address _token) onlyController {
 if (_token == 0x0) {
 controller.transfer(this.balance);
 return;
 }
 ERC20Token token = ERC20Token(_token);
 uint balance = token.balanceOf(this);
 token.transfer(controller, balance);
 ClaimedTokens(_token, controller, balance);
 }
 event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
 event Transfer(address indexed _from, address indexed _to, uint256 _amount);
 event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
 event Approval(
 address indexed _owner,
 address indexed _spender,
 uint256 _amount
 );
}
contract MiniMeTokenFactory {
 function createCloneToken_r(
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
 newToken.changeController_r(msg.sender);
 return newToken;
 }
}
library SafeMath {
 function mul_r(uint a, uint b) internal returns (uint) {
 uint c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div_r(uint a, uint b) internal returns (uint) {
 uint c = a / b;
 return c;
 }
 function sub_r(uint a, uint b) internal returns (uint) {
 assert(b <= a);
 return a - b;
 }
 function add_r(uint a, uint b) internal returns (uint) {
 uint c = a + b;
 assert(c >= a);
 return c;
 }
 function max64_r(uint64 a, uint64 b) internal constant returns (uint64) {
 return a >= b ? a : b;
 }
 function min64_r(uint64 a, uint64 b) internal constant returns (uint64) {
 return a < b ? a : b;
 }
 function max256_r(uint256 a, uint256 b) internal constant returns (uint256) {
 return a >= b ? a : b;
 }
 function min256_r(uint256 a, uint256 b) internal constant returns (uint256) {
 return a < b ? a : b;
 }
}
contract ATTContribution is Owned, TokenController {
 using SafeMath for uint256;
 uint256 constant public exchangeRate = 600;
 uint256 constant public maxGasPrice = 50000000000;
 uint256 public maxFirstRoundTokenLimit = 20000000 ether;
 uint256 public maxIssueTokenLimit = 70000000 ether;
 MiniMeToken public ATT;
 address public attController;
 address public destEthFoundation;
 address public destTokensAngel;
 uint256 public startTime;
 uint256 public endTime;
 uint256 public totalNormalTokenGenerated;
 uint256 public totalNormalEtherCollected;
 uint256 public totalIssueTokenGenerated;
 uint256 public finalizedBlock;
 uint256 public finalizedTime;
 bool public paused;
 modifier initialized() {
 require(address(ATT) != 0x0);
 _;
 }
 modifier contributionOpen() {
 require(time_r() >= startTime &&
 time_r() <= endTime &&
 finalizedBlock == 0 &&
 address(ATT) != 0x0);
 _;
 }
 modifier notPaused() {
 require(!paused);
 _;
 }
 function ATTContribution() {
 paused = false;
 }
 function initialize_r(
 address _att,
 address _attController,
 uint _startTime,
 uint _endTime,
 address _destEthFoundation,
 address _destTokensAngel
 ) public onlyOwner {
 require(address(ATT) == 0x0);
 ATT = MiniMeToken(_att);
 require(ATT.totalSupply() == 0);
 require(ATT.controller() == address(this));
 require(ATT.decimals() == 18);
 startTime = _startTime;
 endTime = _endTime;
 assert(startTime < endTime);
 require(_attController != 0x0);
 attController = _attController;
 require(_destEthFoundation != 0x0);
 destEthFoundation = _destEthFoundation;
 require(_destTokensAngel != 0x0);
 destTokensAngel = _destTokensAngel;
 }
 function () public payable notPaused {
 proxyPayment_r(msg.sender);
 }
 function proxyPayment_r(address _th) public payable notPaused initialized contributionOpen returns (bool) {
 require(_th != 0x0);
 buyNormal_r(_th);
 return true;
 }
 function onTransfer_r(address, address, uint256) public returns (bool) {
 return false;
 }
 function onApprove_r(address, address, uint256) public returns (bool) {
 return false;
 }
 function buyNormal_r(address _th) internal {
 require(tx.gasprice <= maxGasPrice);
 address caller;
 if (msg.sender == address(ATT)) {
 caller = _th;
 } else {
 caller = msg.sender;
 }
 require(!isContract_r(caller));
 doBuy_r(_th, msg.value);
 }
 function doBuy_r(address _th, uint256 _toFund) internal {
 require(tx.gasprice <= maxGasPrice);
 assert(msg.value >= _toFund);
 assert(totalNormalTokenGenerated < maxFirstRoundTokenLimit);
 uint256 endOfFirstWeek = startTime.add_r(1 weeks);
 uint256 endOfSecondWeek = startTime.add_r(2 weeks);
 uint256 finalExchangeRate = exchangeRate;
 if (now < endOfFirstWeek)
 {
 finalExchangeRate = exchangeRate.mul_r(110).div_r(100);
 } else if (now < endOfSecondWeek)
 {
 finalExchangeRate = exchangeRate.mul_r(105).div_r(100);
 }
 if (_toFund > 0) {
 uint256 tokensGenerating = _toFund.mul_r(finalExchangeRate);
 uint256 tokensToBeGenerated = totalNormalTokenGenerated.add_r(tokensGenerating);
 if (tokensToBeGenerated > maxFirstRoundTokenLimit)
 {
 tokensGenerating = maxFirstRoundTokenLimit - totalNormalTokenGenerated;
 _toFund = tokensGenerating.div_r(finalExchangeRate);
 }
 assert(ATT.generateTokens_r(_th, tokensGenerating));
 destEthFoundation.transfer(_toFund);
 totalNormalTokenGenerated = totalNormalTokenGenerated.add_r(tokensGenerating);
 totalNormalEtherCollected = totalNormalEtherCollected.add_r(_toFund);
 NewSale(_th, _toFund, tokensGenerating);
 }
 uint256 toReturn = msg.value.sub_r(_toFund);
 if (toReturn > 0) {
 if (msg.sender == address(ATT)) {
 _th.transfer(toReturn);
 } else {
 msg.sender.transfer(toReturn);
 }
 }
 }
 function issueTokenToGuaranteedAddress_r(address _th, uint256 _amount, bytes data) onlyOwner initialized notPaused contributionOpen {
 require(totalIssueTokenGenerated.add_r(_amount) <= maxIssueTokenLimit);
 assert(ATT.generateTokens_r(_th, _amount));
 totalIssueTokenGenerated = totalIssueTokenGenerated.add_r(_amount);
 NewIssue(_th, _amount, data);
 }
 function adjustLimitBetweenIssueAndNormal_r(uint256 _amount, bool _isAddToNormal) onlyOwner initialized contributionOpen {
 if(_isAddToNormal)
 {
 require(totalIssueTokenGenerated.add_r(_amount) <= maxIssueTokenLimit);
 maxIssueTokenLimit = maxIssueTokenLimit.sub_r(_amount);
 maxFirstRoundTokenLimit = maxFirstRoundTokenLimit.add_r(_amount);
 } else {
 require(totalNormalTokenGenerated.add_r(_amount) <= maxFirstRoundTokenLimit);
 maxFirstRoundTokenLimit = maxFirstRoundTokenLimit.sub_r(_amount);
 maxIssueTokenLimit = maxIssueTokenLimit.add_r(_amount);
 }
 }
 function finalize_r() public onlyOwner initialized {
 require(time_r() >= startTime);
 require(finalizedBlock == 0);
 finalizedBlock = getBlockNumber_r();
 finalizedTime = now;
 uint256 tokensToSecondRound = 90000000 ether;
 uint256 tokensToReserve = 90000000 ether;
 uint256 tokensToAngelAndOther = 30000000 ether;
 tokensToSecondRound = tokensToSecondRound.add_r(maxFirstRoundTokenLimit).sub_r(totalNormalTokenGenerated);
 tokensToSecondRound = tokensToSecondRound.add_r(maxIssueTokenLimit).sub_r(totalIssueTokenGenerated);
 uint256 totalTokens = 300000000 ether;
 require(totalTokens == ATT.totalSupply().add_r(tokensToSecondRound).add_r(tokensToReserve).add_r(tokensToAngelAndOther));
 assert(ATT.generateTokens_r(0xb1, tokensToSecondRound));
 assert(ATT.generateTokens_r(0xb2, tokensToReserve));
 assert(ATT.generateTokens_r(destTokensAngel, tokensToAngelAndOther));
 ATT.changeController_r(attController);
 Finalized();
 }
 function percent_r(uint256 p) internal returns (uint256) {
 return p.mul_r(10**16);
 }
 function isContract_r(address _addr) constant internal returns (bool) {
 if (_addr == 0) return false;
 uint256 size;
 assembly {
 size := extcodesize(_addr)
 }
 return (size > 0);
 }
 function time_r() constant returns (uint) {
 return block.timestamp;
 }
 function tokensIssued_r() public constant returns (uint256) {
 return ATT.totalSupply();
 }
 function getBlockNumber_r() internal constant returns (uint256) {
 return block.number;
 }
 function claimTokens_r(address _token) public onlyOwner {
 if (ATT.controller() == address(this)) {
 ATT.claimTokens_r(_token);
 }
 if (_token == 0x0) {
 owner.transfer(this.balance);
 return;
 }
 ERC20Token token = ERC20Token(_token);
 uint256 balance = token.balanceOf(this);
 token.transfer(owner, balance);
 ClaimedTokens(_token, owner, balance);
 }
 function pauseContribution_r() onlyOwner {
 paused = true;
 }
 function resumeContribution_r() onlyOwner {
 paused = false;
 }
 event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
 event NewSale(address indexed _th, uint256 _amount, uint256 _tokens);
 event NewIssue(address indexed _th, uint256 _amount, bytes data);
 event Finalized();
}