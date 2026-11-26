pragma solidity 0.5.6;
library SafeMath {
 function mul_r(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 require(c / a == b);
 return c;
 }
 function div_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b > 0);
 uint256 c = a / b;
 return c;
 }
 function sub_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b <= a);
 uint256 c = a - b;
 return c;
 }
 function add_r(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 require(c >= a);
 return c;
 }
 function mod_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b != 0);
 return a % b;
 }
}
interface IERC20 {
 function transfer(address to, uint256 value) external returns (bool);
 function approve(address spender, uint256 value) external returns (bool);
 function transferFrom(address from, address to, uint256 value) external returns (bool);
 function totalSupply() external view returns (uint256);
 function balanceOf(address who) external view returns (uint256);
 function allowance(address owner, address spender) external view returns (uint256);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ERC20 is IERC20 {
 using SafeMath for uint256;
 mapping (address => uint256) private _balances;
 mapping (address => mapping (address => uint256)) private _allowed;
 uint256 private _totalSupply;
 function totalSupply() public view returns (uint256) {
 return _totalSupply;
 }
 function balanceOf(address owner) public view returns (uint256) {
 return _balances[owner];
 }
 function allowance(address owner, address spender) public view returns (uint256) {
 return _allowed[owner][spender];
 }
 function transfer(address to, uint256 value) public returns (bool) {
 _transfer_r(msg.sender, to, value);
 return true;
 }
 function approve(address spender, uint256 value) public returns (bool) {
 _approve_r(msg.sender, spender, value);
 return true;
 }
 function transferFrom(address from, address to, uint256 value) public returns (bool) {
 _transfer_r(from, to, value);
 _approve_r(from, msg.sender, _allowed[from][msg.sender].sub_r(value));
 return true;
 }
 function increaseAllowance_r(address spender, uint256 addedValue) public returns (bool) {
 _approve_r(msg.sender, spender, _allowed[msg.sender][spender].add_r(addedValue));
 return true;
 }
 function decreaseAllowance_r(address spender, uint256 subtractedValue) public returns (bool) {
 _approve_r(msg.sender, spender, _allowed[msg.sender][spender].sub_r(subtractedValue));
 return true;
 }
 function _transfer_r(address from, address to, uint256 value) internal {
 require(to != address(0));
 _balances[from] = _balances[from].sub_r(value);
 _balances[to] = _balances[to].add_r(value);
 emit Transfer(from, to, value);
 }
 function _mint_r(address account, uint256 value) internal {
 require(account != address(0));
 _totalSupply = _totalSupply.add_r(value);
 _balances[account] = _balances[account].add_r(value);
 emit Transfer(address(0), account, value);
 }
 function _burn_r(address account, uint256 value) internal {
 require(account != address(0));
 _totalSupply = _totalSupply.sub_r(value);
 _balances[account] = _balances[account].sub_r(value);
 emit Transfer(account, address(0), value);
 }
 function _approve_r(address owner, address spender, uint256 value) internal {
 require(spender != address(0));
 require(owner != address(0));
 _allowed[owner][spender] = value;
 emit Approval(owner, spender, value);
 }
 function _burnFrom_r(address account, uint256 value) internal {
 _burn_r(account, value);
 _approve_r(account, msg.sender, _allowed[account][msg.sender].sub_r(value));
 }
}
contract IERC20Releasable {
 function release_r() public;
}
contract IOwnable {
 function isOwner_r(address who)
 public view returns(bool);
 function _isOwner_r(address)
 internal view returns(bool);
}
contract SingleOwner is IOwnable {
 address public owner;
 constructor(
 address _owner
 )
 internal
 {
 require(_owner != address(0), 'owner_req');
 owner = _owner;
 emit OwnershipTransferred(address(0), owner);
 }
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 modifier ownerOnly() {
 require(msg.sender == owner, 'owner_access');
 _;
 }
 function _isOwner_r(address _sender)
 internal
 view
 returns(bool)
 {
 return owner == _sender;
 }
 function isOwner_r(address _sender)
 public
 view
 returns(bool)
 {
 return _isOwner_r(_sender);
 }
 function setOwner_r(address _owner)
 public
 ownerOnly
 {
 address prevOwner = owner;
 owner = _owner;
 emit OwnershipTransferred(owner, prevOwner);
 }
}
contract Privileged {
 mapping(address => bool) privileged;
 function isPrivileged_r(address _addr)
 public
 view
 returns(bool)
 {
 return privileged[_addr];
 }
 function _setPrivileged_r(address _addr)
 internal
 {
 require(_addr != address(0), 'addr_req');
 privileged[_addr] = true;
 }
 function _setUnprivileged_r(address _addr)
 internal
 {
 privileged[_addr] = false;
 }
}
contract IToken is IERC20, IERC20Releasable, IOwnable {}
contract MBN is IToken, ERC20, SingleOwner, Privileged {
 string public name = 'Membrana';
 string public symbol = 'MBN';
 uint8 public decimals = 18;
 bool public isReleased;
 uint public releaseDate;
 constructor(address _owner)
 public
 SingleOwner(_owner)
 {
 super._mint_r(owner, 1000000000 * 10 ** 18);
 }
 modifier releasedOnly() {
 require(isReleased, 'released_only');
 _;
 }
 modifier notReleasedOnly() {
 require(! isReleased, 'not_released_only');
 _;
 }
 modifier releasedOrPrivilegedOnly() {
 require(isReleased || isPrivileged_r(msg.sender), 'released_or_privileged_only');
 _;
 }
 function transfer(address to, uint256 value)
 public
 releasedOrPrivilegedOnly
 returns (bool)
 {
 return super.transfer(to, value);
 }
 function transferFrom(address from, address to, uint256 value)
 public
 releasedOnly
 returns (bool)
 {
 return super.transferFrom(from, to, value);
 }
 function approve(address spender, uint256 value)
 public
 releasedOnly
 returns (bool)
 {
 return super.approve(spender, value);
 }
 function increaseAllowance_r(address spender, uint addedValue)
 public
 releasedOnly
 returns (bool)
 {
 return super.increaseAllowance_r(spender, addedValue);
 }
 function decreaseAllowance_r(address spender, uint subtractedValue)
 public
 releasedOnly
 returns (bool)
 {
 return super.decreaseAllowance_r(spender, subtractedValue);
 }
 function release_r()
 public
 ownerOnly
 notReleasedOnly
 {
 isReleased = true;
 releaseDate = now;
 }
 function setPrivileged_r(address _addr)
 public
 ownerOnly
 {
 _setPrivileged_r(_addr);
 }
 function setUnprivileged_r(address _addr)
 public
 ownerOnly
 {
 _setUnprivileged_r(_addr);
 }
}