pragma solidity 0.4.19;
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
contract ERC20 {
 function totalSupply()public view returns (uint total_Supply);
 function balanceOf(address who)public view returns (uint256);
 function allowance(address owner, address spender)public view returns (uint);
 function transferFrom(address from, address to, uint value)public returns (bool ok);
 function approve(address spender, uint value)public returns (bool ok);
 function transfer(address to, uint value)public returns (bool ok);
 event Transfer(address indexed from, address indexed to, uint value);
 event Approval(address indexed owner, address indexed spender, uint value);
}
contract AussieCoin is ERC20
{ using SafeMath for uint256;
 string public constant name = "AussieCoin";
 string public constant symbol = "AUS";
 uint8 public constant decimals = 18;
 uint public _totalsupply = 24000000 * 10 ** 18;
 address public owner;
 uint256 public _price_tokn = 5000;
 uint256 no_of_tokens;
 uint256 public startdate;
 bool stopped = false;
 mapping(address => uint) balances;
 mapping(address => mapping(address => uint)) allowed;
 enum Stages {
 NOTSTARTED,
 ICO,
 PAUSED,
 ENDED
 }
 Stages public stage;
 modifier atStage(Stages _stage) {
 if (stage != _stage)
 revert();
 _;
 }
 modifier onlyOwner() {
 if (msg.sender != owner) {
 revert();
 }
 _;
 }
 function AussieCoin() public
 {
 owner = msg.sender;
 balances[owner] = 14000000 * 10 **18;
 stage = Stages.NOTSTARTED;
 Transfer(0, owner, balances[owner]);
 }
 function start_ICO() public onlyOwner atStage(Stages.NOTSTARTED)
 {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 stage = Stages.ICO;
 balances[address(this)] = 10000000 *10**18;
 stopped = false;
 startdate = now;
 Transfer(0, address(this), balances[address(this)]);
 }
 function () public payable atStage(Stages.ICO)
 {
 require(!stopped && msg.sender != owner);
 no_of_tokens =((msg.value).mul(_price_tokn));
 transferTokens(msg.sender,no_of_tokens);
 }
 function StopICO() external onlyOwner atStage(Stages.ICO)
 {
 stage = Stages.PAUSED;
 stopped = true;
 }
 function releaseICO() external onlyOwner atStage(Stages.PAUSED)
 {
 stage = Stages.ICO;
 stopped = false;
 }
 function end_ICO() external onlyOwner atStage(Stages.ICO)
 {
 stage = Stages.ENDED;
 balances[owner] = (balances[owner]).add(balances[address(this)]);
 balances[address(this)] = 0;
 Transfer(address(this), owner , balances[address(this)]);
 }
 function totalSupply() public view returns (uint256 total_Supply) {
 total_Supply = _totalsupply;
 }
 function balanceOf(address _owner)public view returns (uint256 balance) {
 return balances[_owner];
 }
 function transferFrom( address _from, address _to, uint256 _amount )public returns (bool success) {
 require( _to != 0x0);
 require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
 balances[_from] = (balances[_from]).sub(_amount);
 allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
 balances[_to] = (balances[_to]).add(_amount);
 Transfer(_from, _to, _amount);
 return true;
 }
 function approve(address _spender, uint256 _amount)public returns (bool success) {
 require( _spender != 0x0);
 allowed[msg.sender][_spender] = _amount;
 Approval(msg.sender, _spender, _amount);
 return true;
 }
 function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
 require( _owner != 0x0 && _spender !=0x0);
 return allowed[_owner][_spender];
 }
 function transfer(address _to, uint256 _amount)public returns (bool success) {
 require( _to != 0x0);
 require(balances[msg.sender] >= _amount && _amount >= 0);
 balances[msg.sender] = (balances[msg.sender]).sub(_amount);
 balances[_to] = (balances[_to]).add(_amount);
 Transfer(msg.sender, _to, _amount);
 return true;
 }
 function transferTokens(address _to, uint256 _amount) private returns(bool success) {
 require( _to != 0x0);
 require(balances[address(this)] >= _amount && _amount > 0);
 balances[address(this)] = (balances[address(this)]).sub(_amount);
 balances[_to] = (balances[_to]).add(_amount);
 Transfer(address(this), _to, _amount);
 return true;
 }
 function drain() external onlyOwner {
 owner.transfer(this.balance);
 }
}