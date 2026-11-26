pragma solidity 0.5.6;
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 require(c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b > 0);
 uint256 c = a / b;
 return c;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b <= a);
 uint256 c = a - b;
 return c;
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 require(c >= a);
 return c;
 }
 function mod(uint256 a, uint256 b) internal pure returns (uint256) {
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
 _transfer(msg.sender, to, value);
 return true;
 }
 function approve(address spender, uint256 value) public returns (bool) {
 _approve(msg.sender, spender, value);
 return true;
 }
 function transferFrom(address from, address to, uint256 value) public returns (bool) {
 _transfer(from, to, value);
 _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
 return true;
 }
 function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
 _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
 return true;
 }
 function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
 _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
 return true;
 }
 function _transfer(address from, address to, uint256 value) internal {
 require(to != address(0));
 _balances[from] = _balances[from].sub(value);
 _balances[to] = _balances[to].add(value);
 emit Transfer(from, to, value);
 }
 function _mint(address account, uint256 value) internal {
 require(account != address(0));
 _totalSupply = _totalSupply.add(value);
 _balances[account] = _balances[account].add(value);
 emit Transfer(address(0), account, value);
 }
 function _burn(address account, uint256 value) internal {
 require(account != address(0));
 _totalSupply = _totalSupply.sub(value);
 _balances[account] = _balances[account].sub(value);
 emit Transfer(account, address(0), value);
 }
 function _approve(address owner, address spender, uint256 value) internal {
 require(spender != address(0));
 require(owner != address(0));
 _allowed[owner][spender] = value;
 emit Approval(owner, spender, value);
 }
 function _burnFrom(address account, uint256 value) internal {
 _burn(account, value);
 _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
 }
}
contract IERC20Releasable {
 function release() public;
}
contract IOwnable {
 function isOwner(address who)
 public view returns(bool);
 function _isOwner(address)
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
 function _isOwner(address _sender)
 internal
 view
 returns(bool)
 {
 return owner == _sender;
 }
 function isOwner(address _sender)
 public
 view
 returns(bool)
 {
 return _isOwner(_sender);
 }
 function setOwner(address _owner)
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
 function isPrivileged(address _addr)
 public
 view
 returns(bool)
 {
 return privileged[_addr];
 }
 function _setPrivileged(address _addr)
 internal
 {
 require(_addr != address(0), 'addr_req');
 privileged[_addr] = true;
 }
 function _setUnprivileged(address _addr)
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
 super._mint(owner, 1000000000 * 10 ** 18);
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
 require(isReleased || isPrivileged(msg.sender), 'released_or_privileged_only');
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
 function increaseAllowance(address spender, uint addedValue)
 public
 releasedOnly
 returns (bool)
 {
 return super.increaseAllowance(spender, addedValue);
 }
 function decreaseAllowance(address spender, uint subtractedValue)
 public
 releasedOnly
 returns (bool)
 {
 return super.decreaseAllowance(spender, subtractedValue);
 }
 function release()
 public
 ownerOnly
 notReleasedOnly
 {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 isReleased = true;
 releaseDate = now;
 }
 function setPrivileged(address _addr)
 public
 ownerOnly
 {
 _setPrivileged(_addr);
 }
 function setUnprivileged(address _addr)
 public
 ownerOnly
 {
 _setUnprivileged(_addr);
 }
}