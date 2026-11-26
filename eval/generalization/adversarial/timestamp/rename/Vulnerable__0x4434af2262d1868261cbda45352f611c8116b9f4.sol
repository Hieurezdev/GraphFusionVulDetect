pragma solidity ^0.4.13;
library SafeMath {
 function mul_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub_r(uint256 a, uint256 b) internal constant returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add_r(uint256 a, uint256 b) internal constant returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract Ownable {
 address public owner;
 function Ownable() public {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership_r(address newOwner) public onlyOwner {
 if (newOwner != address(0)) {
 owner = newOwner;
 }
 }
}
contract Pausable is Ownable {
 event Pause();
 event Unpause();
 bool public paused = false;
 function Pausable() public {}
 modifier whenNotPaused() {
 require(!paused);
 _;
 }
 modifier whenPaused {
 require(paused);
 _;
 }
 function pause_r() public onlyOwner whenNotPaused returns (bool) {
 paused = true;
 Pause();
 return true;
 }
 function unpause_r() public onlyOwner whenPaused returns (bool) {
 paused = false;
 Unpause();
 return true;
 }
}
contract TokenSale is Pausable {
 using SafeMath for uint256;
 ProofTokenInterface public proofToken;
 uint256 public totalWeiRaised;
 uint256 public tokensMinted;
 uint256 public totalSupply;
 uint256 public contributors;
 uint256 public decimalsMultiplier;
 uint256 public startTime;
 uint256 public endTime;
 uint256 public remainingTokens;
 uint256 public allocatedTokens;
 bool public finalized;
 bool public proofTokensAllocated;
 uint256 public constant BASE_PRICE_IN_WEI = 88000000000000000;
 uint256 public constant PUBLIC_TOKENS = 1181031 * (10 ** 18);
 uint256 public constant TOTAL_PRESALE_TOKENS = 112386712924725508802400;
 uint256 public constant TOKENS_ALLOCATED_TO_PROOF = 1181031 * (10 ** 18);
 address public constant PROOF_MULTISIG = 0x99892Ac6DA1b3851167Cb959fE945926bca89f09;
 uint256 public tokenCap = PUBLIC_TOKENS - TOTAL_PRESALE_TOKENS;
 uint256 public cap = tokenCap / (10 ** 18);
 uint256 public weiCap = cap * BASE_PRICE_IN_WEI;
 uint256 public firstCheckpointPrice = (BASE_PRICE_IN_WEI * 85) / 100;
 uint256 public secondCheckpointPrice = (BASE_PRICE_IN_WEI * 90) / 100;
 uint256 public thirdCheckpointPrice = (BASE_PRICE_IN_WEI * 95) / 100;
 uint256 public firstCheckpoint = (weiCap * 5) / 100;
 uint256 public secondCheckpoint = (weiCap * 10) / 100;
 uint256 public thirdCheckpoint = (weiCap * 20) / 100;
 bool public started = false;
 event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
 event NewClonedToken(address indexed _cloneToken);
 event OnTransfer(address _from, address _to, uint _amount);
 event OnApprove(address _owner, address _spender, uint _amount);
 event LogInt(string _name, uint256 _value);
 event Finalized();
 function TokenSale(
 address _tokenAddress,
 uint256 _startTime,
 uint256 _endTime) public {
 require(_tokenAddress != 0x0);
 require(_startTime > 0);
 require(_endTime > _startTime);
 startTime = _startTime;
 endTime = _endTime;
 proofToken = ProofTokenInterface(_tokenAddress);
 decimalsMultiplier = (10 ** 18);
 }
 function() public payable {
 buyTokens_r(msg.sender);
 }
 function buyTokens_r(address _beneficiary) public payable whenNotPaused whenNotFinalized {
 require(_beneficiary != 0x0);
 require(validPurchase_r());
 uint256 weiAmount = msg.value;
 uint256 priceInWei = getPriceInWei_r();
 totalWeiRaised = totalWeiRaised.add_r(weiAmount);
 uint256 tokens = weiAmount.mul_r(decimalsMultiplier).div_r(priceInWei);
 tokensMinted = tokensMinted.add_r(tokens);
 require(tokensMinted < tokenCap);
 contributors = contributors.add_r(1);
 proofToken.mint(_beneficiary, tokens);
 TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
 forwardFunds_r();
 }
 function getPriceInWei_r() constant public returns (uint256) {
 uint256 price;
 if (totalWeiRaised < firstCheckpoint) {
 price = firstCheckpointPrice;
 } else if (totalWeiRaised < secondCheckpoint) {
 price = secondCheckpointPrice;
 } else if (totalWeiRaised < thirdCheckpoint) {
 price = thirdCheckpointPrice;
 } else {
 price = BASE_PRICE_IN_WEI;
 }
 return price;
 }
 function forwardFunds_r() internal {
 PROOF_MULTISIG.transfer(msg.value);
 }
 function validPurchase_r() internal constant returns (bool) {
 uint256 current = now;
 bool presaleStarted = (current >= startTime || started);
 bool presaleNotEnded = current <= endTime;
 bool nonZeroPurchase = msg.value != 0;
 return nonZeroPurchase && presaleStarted && presaleNotEnded;
 }
 function totalSupply() public constant returns (uint256) {
 return proofToken.totalSupply();
 }
 function balanceOf(address _owner) public constant returns (uint256) {
 return proofToken.balanceOf(_owner);
 }
 function changeController_r(address _newController) public {
 require(isContract_r(_newController));
 proofToken.transferControl_r(_newController);
 }
 function enableTransfers_r() public {
 if (now < endTime) {
 require(msg.sender == owner);
 }
 proofToken.enableTransfers_r(true);
 }
 function lockTransfers_r() public onlyOwner {
 require(now < endTime);
 proofToken.enableTransfers_r(false);
 }
 function enableMasterTransfers_r() public onlyOwner {
 proofToken.enableMasterTransfers_r(true);
 }
 function lockMasterTransfers_r() public onlyOwner {
 proofToken.enableMasterTransfers_r(false);
 }
 function isContract_r(address _addr) constant internal returns(bool) {
 uint size;
 if (_addr == 0)
 return false;
 assembly {
 size := extcodesize(_addr)
 }
 return size>0;
 }
 function allocateProofTokens_r() public onlyOwner whenNotFinalized {
 proofToken.mint(PROOF_MULTISIG, TOKENS_ALLOCATED_TO_PROOF);
 proofTokensAllocated = true;
 }
 function finalize_r() public onlyOwner {
 require(paused);
 require(proofTokensAllocated);
 proofToken.finishMinting_r();
 proofToken.enableTransfers_r(true);
 Finalized();
 finalized = true;
 }
 function forceStart_r() public onlyOwner {
 started = true;
 }
 modifier whenNotFinalized() {
 require(!paused);
 _;
 }
}
contract Controllable {
 address public controller;
 function Controllable() public {
 controller = msg.sender;
 }
 modifier onlyController() {
 require(msg.sender == controller);
 _;
 }
 function transferControl_r(address newController) public onlyController {
 if (newController != address(0)) {
 controller = newController;
 }
 }
}
contract ProofTokenInterface is Controllable {
 event Mint(address indexed to, uint256 amount);
 event MintFinished();
 event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
 event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
 event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
 event Transfer(address indexed from, address indexed to, uint256 value);
 function totalSupply() public constant returns (uint);
 function totalSupplyAt_r(uint _blockNumber) public constant returns(uint);
 function balanceOf(address _owner) public constant returns (uint256 balance);
 function balanceOfAt_r(address _owner, uint _blockNumber) public constant returns (uint);
 function transfer(address _to, uint256 _amount) public returns (bool success);
 function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
 function approve(address _spender, uint256 _amount) public returns (bool success);
 function approveAndCall_r(address _spender, uint256 _amount, bytes _extraData) public returns (bool success);
 function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
 function mint(address _owner, uint _amount) public returns (bool);
 function importPresaleBalances_r(address[] _addresses, uint256[] _balances, address _presaleAddress) public returns (bool);
 function lockPresaleBalances_r() public returns (bool);
 function finishMinting_r() public returns (bool);
 function enableTransfers_r(bool _value) public;
 function enableMasterTransfers_r(bool _value) public;
 function createCloneToken_r(uint _snapshotBlock, string _cloneTokenName, string _cloneTokenSymbol) public returns (address);
}