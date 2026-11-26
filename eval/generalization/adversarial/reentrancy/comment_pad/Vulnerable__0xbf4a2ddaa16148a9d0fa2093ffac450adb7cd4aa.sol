pragma solidity ^0.4.24;
library SafeMath {
 function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
 if (a == 0) {
 return 0;
 }
 c = a * b;
 assert(c / a == b);
 return c;
 }
 function div(uint256 a, uint256 b) internal pure returns (uint256) {
 return a / b;
 }
 function sub(uint256 a, uint256 b) internal pure returns (uint256) {
 assert(b <= a);
 return a - b;
 }
 function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract Ownable {
	address public owner;
	address public newOwner;
	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
	constructor() public {
 owner = msg.sender;
 newOwner = address(0);
	}
	modifier onlyOwner() {
 require(msg.sender == owner, "msg.sender == owner");
 _;
	}
	function transferOwnership(address _newOwner) public onlyOwner {
 require(address(0) != _newOwner, "address(0) != _newOwner");
 newOwner = _newOwner;
	}
	function acceptOwnership() public {
 require(msg.sender == newOwner, "msg.sender == newOwner");
 emit OwnershipTransferred(owner, msg.sender);
 owner = msg.sender;
 newOwner = address(0);
	}
}
contract Authorizable is Ownable {
 mapping(address => bool) public authorized;
 event AuthorizationSet(address indexed addressAuthorized, bool indexed authorization);
 constructor() public {
 authorized[msg.sender] = true;
 }
 modifier onlyAuthorized() {
 require(authorized[msg.sender], "authorized[msg.sender]");
 _;
 }
 function setAuthorized(address addressAuthorized, bool authorization) onlyOwner public {
 emit AuthorizationSet(addressAuthorized, authorization);
 authorized[addressAuthorized] = authorization;
 }
}
contract ERC20Basic {
 string public name;
 string public symbol;
 uint8 public decimals;
 uint256 public totalSupply;
 function balanceOf(address who) public constant returns (uint256);
 function transfer(address to, uint256 value) public returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
 function allowance(address owner, address spender) public constant returns (uint256);
 function transferFrom(address from, address to, uint256 value) public returns (bool);
 function approve(address spender, uint256 value) public returns (bool);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
 using SafeMath for uint256;
 mapping(address => uint256) balances;
 function transferFunction(address _sender, address _to, uint256 _value) internal returns (bool) {
 require(_to != address(0), "_to != address(0)");
 require(_to != address(this), "_to != address(this)");
 require(_value <= balances[_sender], "_value <= balances[_sender]");
 balances[_sender] = balances[_sender].sub(_value);
 balances[_to] = balances[_to].add(_value);
 emit Transfer(_sender, _to, _value);
 return true;
 }
 function transfer(address _to, uint256 _value) public returns (bool) {
 return transferFunction(msg.sender, _to, _value);
 }
 function balanceOf(address _owner) public constant returns (uint256 balance) {
 return balances[_owner];
 }
}
contract ERC223TokenCompatible is BasicToken {
 using SafeMath for uint256;
 event Transfer(address indexed from, address indexed to, uint256 value, bytes indexed data);
	function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 require(_to != address(0), "_to != address(0)");
 require(_to != address(this), "_to != address(this)");
 require(_value <= balances[msg.sender], "_value <= balances[msg.sender]");
 balances[msg.sender] = balances[msg.sender].sub(_value);
 balances[_to] = balances[_to].add(_value);
 if( isContract(_to) ) {
 require( _to.call.value(0)( bytes4( keccak256( abi.encodePacked( _custom_fallback ) ) ), msg.sender, _value, _data), "_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data)" );
 }
 emit Transfer(msg.sender, _to, _value, _data);
 return true;
	}
	function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
 return transfer( _to, _value, _data, "tokenFallback(address,uint256,bytes)");
	}
	function isContract(address _addr) private view returns (bool is_contract) {
 uint256 length;
 assembly {
 length := extcodesize(_addr)
 }
 return (length>0);
 }
}
contract StandardToken is ERC20, BasicToken {
 mapping (address => mapping (address => uint256)) internal allowed;
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
 require(_to != address(0), "_to != address(0)");
 require(_to != address(this), "_to != address(this)");
 require(_value <= balances[_from], "_value <= balances[_from]");
 require(_value <= allowed[_from][msg.sender], "_value <= allowed[_from][msg.sender]");
 balances[_from] = balances[_from].sub(_value);
 balances[_to] = balances[_to].add(_value);
 allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
 emit Transfer(_from, _to, _value);
 return true;
 }
 function approve(address _spender, uint256 _value) public returns (bool) {
 allowed[msg.sender][_spender] = _value;
 emit Approval(msg.sender, _spender, _value);
 return true;
 }
 function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
 return allowed[_owner][_spender];
 }
 function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
 allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
 emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
 function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
 uint oldValue = allowed[msg.sender][_spender];
 if (_subtractedValue > oldValue) {
 allowed[msg.sender][_spender] = 0;
 } else {
 allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
 }
 emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
 return true;
 }
}
contract HumanStandardToken is StandardToken {
 function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
 approve(_spender, _value);
 require(_spender.call(bytes4(keccak256("receiveApproval(address,uint256,bytes)")), msg.sender, _value, _extraData), '_spender.call(bytes4(keccak256("receiveApproval(address,uint256,bytes)")), msg.sender, _value, _extraData)');
 return true;
 }
 function approveAndCustomCall(address _spender, uint256 _value, bytes _extraData, bytes4 _customFunction) public returns (bool success) {
 approve(_spender, _value);
 require(_spender.call(_customFunction, msg.sender, _value, _extraData), "_spender.call(_customFunction, msg.sender, _value, _extraData)");
 return true;
 }
}
contract Startable is Ownable, Authorizable {
 event Start();
 bool public started = false;
 modifier whenStarted() {
 require( started || authorized[msg.sender], "started || authorized[msg.sender]" );
 _;
 }
 function start() onlyOwner public {
 started = true;
 emit Start();
 }
}
contract StartToken is Startable, ERC223TokenCompatible, StandardToken {
 function transfer(address _to, uint256 _value) public whenStarted returns (bool) {
 return super.transfer(_to, _value);
 }
 function transfer(address _to, uint256 _value, bytes _data) public whenStarted returns (bool) {
 return super.transfer(_to, _value, _data);
 }
 function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public whenStarted returns (bool) {
 return super.transfer(_to, _value, _data, _custom_fallback);
 }
 function transferFrom(address _from, address _to, uint256 _value) public whenStarted returns (bool) {
 return super.transferFrom(_from, _to, _value);
 }
 function approve(address _spender, uint256 _value) public whenStarted returns (bool) {
 return super.approve(_spender, _value);
 }
 function increaseApproval(address _spender, uint _addedValue) public whenStarted returns (bool success) {
 return super.increaseApproval(_spender, _addedValue);
 }
 function decreaseApproval(address _spender, uint _subtractedValue) public whenStarted returns (bool success) {
 return super.decreaseApproval(_spender, _subtractedValue);
 }
}
contract BurnToken is StandardToken {
 uint256 public initialSupply;
 event Burn(address indexed burner, uint256 value);
 constructor(uint256 _totalSupply) internal {
 initialSupply = _totalSupply;
 }
 function burnFunction(address _burner, uint256 _value) internal returns (bool) {
 require(_value > 0, "_value > 0");
 require(_value <= balances[_burner], "_value <= balances[_burner]");
 balances[_burner] = balances[_burner].sub(_value);
 totalSupply = totalSupply.sub(_value);
 emit Burn(_burner, _value);
 emit Transfer(_burner, address(0), _value);
 return true;
 }
	function burn(uint256 _value) public returns(bool) {
 return burnFunction(msg.sender, _value);
 }
	function burnFrom(address _from, uint256 _value) public returns (bool) {
 require(_value <= allowed[_from][msg.sender], "_value <= allowed[_from][msg.sender]");
 burnFunction(_from, _value);
 allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
 return true;
	}
}
contract Token is ERC20Basic, ERC223TokenCompatible, StandardToken, HumanStandardToken {
 constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply ) public {
 name = _name;
 symbol = _symbol;
 decimals = _decimals;
 totalSupply = _totalSupply;
 balances[msg.sender] = totalSupply;
 emit Transfer(address(0), msg.sender, totalSupply);
 }
}
contract TokenStart is Token, StartToken {
 constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply ) public
 Token(_name, _symbol, _decimals, _totalSupply )
 {
 }
}
contract TokenStartBurn is Token, StartToken, BurnToken {
 constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply ) public
 Token(_name, _symbol, _decimals, _totalSupply )
 BurnToken(_totalSupply)
 {
 }
}