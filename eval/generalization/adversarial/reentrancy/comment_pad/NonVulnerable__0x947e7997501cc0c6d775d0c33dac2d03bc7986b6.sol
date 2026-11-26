pragma solidity 0.5.5;
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 assert(c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract owned {
 address payable public owner;
 constructor () public {
 owner = msg.sender;
 }
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address payable newOwner) onlyOwner public {
 owner = newOwner;
 }
}
contract EnvoyChain_v1 is owned {
 using SafeMath for uint256;
 string public name;
 string public symbol;
 uint256 public decimals;
 uint256 public totalSupply;
 bool public safeguard = false;
 mapping (address => uint256) public balanceOf;
 mapping (address => mapping (address => uint256)) public allowance;
 mapping (address => bool) public frozenAccount;
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Burn(address indexed from, uint256 value);
 event FrozenFunds(address target, bool frozen);
 function _transfer(address _from, address _to, uint _value) internal {
 require(!safeguard);
 require (_to != address(0));
 require(!frozenAccount[_from]);
 require(!frozenAccount[_to]);
 balanceOf[_from] = balanceOf[_from].sub(_value);
 balanceOf[_to] = balanceOf[_to].add(_value);
 emit Transfer(_from, _to, _value);
 }
 function transfer(address _to, uint256 _value) public returns (bool success) {
 _transfer(msg.sender, _to, _value);
 return true;
 }
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
 require(_value <= allowance[_from][msg.sender]);
 allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
 _transfer(_from, _to, _value);
 return true;
 }
 function approve(address _spender, uint256 _value) public returns (bool success) {
 require(!safeguard);
 allowance[msg.sender][_spender] = _value;
 return true;
 }
 constructor() public{
 balanceOf[owner] = totalSupply;
 emit Transfer(address(0), owner, totalSupply);
 }
 function () external payable {
 buyTokens();
 }
 function burn(uint256 _value) public returns (bool success) {
 require(!safeguard);
 balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
 totalSupply = totalSupply.sub(_value);
 emit Burn(msg.sender, _value);
 return true;
 }
 function burnFrom(address _from, uint256 _value) public returns (bool success) {
 require(!safeguard);
 balanceOf[_from] = balanceOf[_from].sub(_value);
 allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
 totalSupply = totalSupply.sub(_value);
 emit Burn(_from, _value);
 return true;
 }
 function freezeAccount(address target, bool freeze) onlyOwner public {
 frozenAccount[target] = freeze;
 emit FrozenFunds(target, freeze);
 }
 function mintToken(address target, uint256 mintedAmount) onlyOwner public {
 balanceOf[target] = balanceOf[target].add(mintedAmount);
 totalSupply = totalSupply.add(mintedAmount);
 emit Transfer(address(0), target, mintedAmount);
 }
 function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
 _transfer(address(this), owner, tokenAmount);
 }
 function manualWithdrawEther()onlyOwner public{
 address(owner).transfer(address(this).balance);
 }
 function changeSafeguardStatus() onlyOwner public{
 if (safeguard == false){
 safeguard = true;
 }
 else{
 safeguard = false;
 }
 }
 bool public passiveAirdropStatus;
 uint256 public passiveAirdropTokensAllocation;
 uint256 public airdropAmount;
 uint256 public passiveAirdropTokensSold;
 mapping(uint256 => mapping(address => bool)) public airdropClaimed;
 uint256 internal airdropClaimedIndex;
 uint256 public airdropFee = 0.05 ether;
 function startNewPassiveAirDrop(uint256 passiveAirdropTokensAllocation_, uint256 airdropAmount_ ) public onlyOwner {
 passiveAirdropTokensAllocation = passiveAirdropTokensAllocation_;
 airdropAmount = airdropAmount_;
 passiveAirdropStatus = true;
 }
 function stopPassiveAirDropCompletely() public onlyOwner{
 passiveAirdropTokensAllocation = 0;
 airdropAmount = 0;
 airdropClaimedIndex++;
 passiveAirdropStatus = false;
 }
 function claimPassiveAirdrop() public payable returns(bool) {
 require(airdropAmount > 0, 'Token amount must not be zero');
 require(passiveAirdropStatus, 'Air drop is not active');
 require(passiveAirdropTokensSold <= passiveAirdropTokensAllocation, 'Air drop sold out');
 require(!airdropClaimed[airdropClaimedIndex][msg.sender], 'user claimed air drop already');
 require(!isContract(msg.sender), 'No contract address allowed to claim air drop');
 require(msg.value >= airdropFee, 'Not enough ether to claim this airdrop');
 _transfer(address(this), msg.sender, airdropAmount);
 passiveAirdropTokensSold += airdropAmount;
 airdropClaimed[airdropClaimedIndex][msg.sender] = true;
 return true;
 }
 function changePassiveAirdropAmount(uint256 newAmount) public onlyOwner{
 airdropAmount = newAmount;
 }
 function isContract(address _address) public view returns (bool){
 uint32 size;
 assembly {
 size := extcodesize(_address)
 }
 return (size > 0);
 }
 function updateAirdropFee(uint256 newFee) public onlyOwner{
 airdropFee = newFee;
 }
 function airdropACTIVE(address[] memory recipients,uint256 tokenAmount) public onlyOwner {
 require(recipients.length <= 150);
 uint256 totalAddresses = recipients.length;
 for(uint i = 0; i < totalAddresses; i++)
 {
 _transfer(address(this), recipients[i], tokenAmount);
 }
 }
 bool public whitelistingStatus;
 mapping (address => bool) public whitelisted;
 function changeWhitelistingStatus() onlyOwner public{
 if (whitelistingStatus == false){
 whitelistingStatus = true;
 }
 else{
 whitelistingStatus = false;
 }
 }
 function whitelistUser(address userAddress) onlyOwner public{
 require(whitelistingStatus == true);
 require(userAddress != address(0));
 whitelisted[userAddress] = true;
 }
 function whitelistManyUsers(address[] memory userAddresses) onlyOwner public{
 require(whitelistingStatus == true);
 uint256 addressCount = userAddresses.length;
 require(addressCount <= 150);
 for(uint256 i = 0; i < addressCount; i++){
 require(userAddresses[i] != address(0));
 whitelisted[userAddresses[i]] = true;
 }
 }
 uint256 public sellPrice;
 uint256 public buyPrice;
 function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
 sellPrice = newSellPrice;
 buyPrice = newBuyPrice;
 }
 function buyTokens() payable public {
 uint amount = msg.value * buyPrice;
 _transfer(address(this), msg.sender, amount);
 }
 function sellTokens(uint256 amount) public {
 uint256 etherAmount = amount * sellPrice/(10**decimals);
 require(address(this).balance >= etherAmount);
 _transfer(msg.sender, address(this), amount);
 msg.sender.transfer(etherAmount);
 }
 bool internal initialized;
 function initialize(
 address payable _owner
 ) public {
 require(!initialized);
 require(owner == address(0));
 name = "Envoy";
 symbol = "NVOY";
 decimals = 18;
 totalSupply = 250000000 * (10**decimals);
 owner = _owner;
 balanceOf[owner] = totalSupply;
 emit Transfer(address(0), owner, totalSupply);
 initialized = true;
 }
}
contract Proxy {
 function implementation() public view returns (address);
 function () payable external {
 address _impl = implementation();
 require(_impl != address(0));
 assembly {
 let ptr := mload(0x40)
 calldatacopy(ptr, 0, calldatasize)
 let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
 let size := returndatasize
 returndatacopy(ptr, 0, size)
 switch result
 case 0 { revert(ptr, size) }
 default { return(ptr, size) }
 }
 }
}
contract UpgradeabilityProxy is Proxy {
 event Upgraded(address indexed implementation);
 bytes32 private constant implementationPosition = keccak256("EtherAuthority.io.proxy.implementation");
 constructor () public {}
 function implementation() public view returns (address impl) {
 bytes32 position = implementationPosition;
 assembly {
 impl := sload(position)
 }
 }
 function setImplementation(address newImplementation) internal {
 bytes32 position = implementationPosition;
 assembly {
 sstore(position, newImplementation)
 }
 }
 function _upgradeTo(address newImplementation) internal {
 address currentImplementation = implementation();
 require(currentImplementation != newImplementation);
 setImplementation(newImplementation);
 emit Upgraded(newImplementation);
 }
}
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
 event ProxyOwnershipTransferred(address previousOwner, address newOwner);
 bytes32 private constant proxyOwnerPosition = keccak256("EtherAuthority.io.proxy.owner");
 constructor () public {
 setUpgradeabilityOwner(msg.sender);
 }
 modifier onlyProxyOwner() {
 require(msg.sender == proxyOwner());
 _;
 }
 function proxyOwner() public view returns (address owner) {
 bytes32 position = proxyOwnerPosition;
 assembly {
 owner := sload(position)
 }
 }
 function setUpgradeabilityOwner(address newProxyOwner) internal {
 bytes32 position = proxyOwnerPosition;
 assembly {
 sstore(position, newProxyOwner)
 }
 }
 function transferProxyOwnership(address newOwner) public onlyProxyOwner {
 require(newOwner != address(0));
 emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
 setUpgradeabilityOwner(newOwner);
 }
 function upgradeTo(address implementation) public onlyProxyOwner {
 _upgradeTo(implementation);
 }
 function upgradeToAndCall(address implementation, bytes memory data) payable public onlyProxyOwner {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 _upgradeTo(implementation);
 (bool success,) = address(this).call.value(msg.value).gas(200000)(data);
 require(success,'initialize function errored');
 }
 function generateData() public view returns(bytes memory){
 return abi.encodeWithSignature("initialize(address)",msg.sender);
 }
}
contract EnvoyChain_proxy is OwnedUpgradeabilityProxy {
 constructor() public OwnedUpgradeabilityProxy() {
 }
}