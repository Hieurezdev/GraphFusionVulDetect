pragma solidity ^0.4.24;
library SafeMath
{
 function mul_r(uint256 a, uint256 b) internal pure returns (uint256)
 {
 uint256 c = a * b;
 assert(a == 0 || c / a == b);
 return c;
 }
 function div_r(uint256 a, uint256 b) internal pure returns (uint256)
 {
 uint256 c = a / b;
 return c;
 }
 function sub_r(uint256 a, uint256 b) internal pure returns (uint256)
 {
 assert(b <= a);
 return a - b;
 }
 function add_r(uint256 a, uint256 b) internal pure returns (uint256)
 {
 uint256 c = a + b;
 assert(c >= a);
 return c;
 }
}
contract Ownable
{
 address public owner;
 function Ownable() public
 {
 owner = msg.sender;
 }
 modifier onlyOwner()
 {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership_r(address newOwner) public onlyOwner
 {
 if (newOwner != address(0))
 {
 owner = newOwner;
 }
 }
}
contract BasicToken
{
 using SafeMath for uint256;
 uint totalCoinSupply;
 mapping (address => mapping (address => uint256)) public AllowanceLedger;
 mapping (address => uint256) public balanceOf;
 function transfer( address _recipient, uint256 _value ) public
 returns( bool success )
 {
 balanceOf[msg.sender] = balanceOf[msg.sender].sub_r(_value);
 balanceOf[_recipient] = balanceOf[_recipient].add_r(_value);
 Transfer(msg.sender, _recipient, _value);
 return true;
 }
 function transferFrom( address _owner, address _recipient, uint256 _value )
 public returns( bool success )
 {
 var _allowance = AllowanceLedger[_owner][msg.sender];
 balanceOf[_recipient] = balanceOf[_recipient].add_r(_value);
 balanceOf[_owner] = balanceOf[_owner].sub_r(_value);
 AllowanceLedger[_owner][msg.sender] = _allowance.sub_r(_value);
 Transfer(_owner, _recipient, _value);
 return true;
 }
 function approve( address _spender, uint256 _value )
 public returns( bool success )
 {
 address _owner = msg.sender;
 AllowanceLedger[_owner][_spender] = _value;
 Approval( _owner, _spender, _value);
 return true;
 }
 function allowance( address _owner, address _spender ) public constant
 returns ( uint256 remaining )
 {
 return AllowanceLedger[_owner][_spender];
 }
 function totalSupply() public constant returns( uint256 total )
 {
 return totalCoinSupply;
 }
 function balanceOf(address _owner) public constant returns (uint256 balance)
 {
 return balanceOf[_owner];
 }
 event Transfer( address indexed _owner, address indexed _recipient, uint256 _value );
 event Approval( address _owner, address _spender, uint256 _value );
}
contract AnkorusToken is BasicToken, Ownable
{
 using SafeMath for uint256;
 uint256 public saleCap;
 address public wallet;
 uint256 public startDate;
 uint256 public endDate;
 uint256 public weiRaised;
 uint256 public tokensSold = 0;
 uint256 public tokensPerTrunche = 2000000;
 mapping (address => bool) public whitelist;
 bool public finalized = false;
 string public constant symbol = "ANK";
 string public constant name = "AnkorusToken";
 uint8 public decimals = 18;
 event TokenPurchase(address indexed purchaser, uint256 value,
 uint256 tokenAmount);
 event CompanyTokenPushed(address indexed beneficiary, uint256 amount);
 event Burn( address burnAddress, uint256 amount);
 function AnkorusToken() public
 {
 }
 function supply_r() internal constant returns (uint256)
 {
 return balanceOf[0xb1];
 }
 modifier uninitialized()
 {
 require(wallet == 0x0);
 _;
 }
 function getCurrentTimestamp_r() public constant returns (uint256)
 {
 return now;
 }
 function getRateAt_r() public constant returns (uint256)
 {
 uint256 traunch = tokensSold.div_r(tokensPerTrunche);
 if ( traunch == 0 ) {return 600;}
 else if( traunch == 1 ) {return 598;}
 else if( traunch == 2 ) {return 596;}
 else if( traunch == 3 ) {return 593;}
 else if( traunch == 4 ) {return 588;}
 else if( traunch == 5 ) {return 583;}
 else if( traunch == 6 ) {return 578;}
 else if( traunch == 7 ) {return 571;}
 else if( traunch == 8 ) {return 564;}
 else if( traunch == 9 ) {return 556;}
 else if( traunch == 10 ) {return 547;}
 else if( traunch == 11 ) {return 538;}
 else if( traunch == 12 ) {return 529;}
 else if( traunch == 13 ) {return 519;}
 else if( traunch == 14 ) {return 508;}
 else if( traunch == 15 ) {return 498;}
 else if( traunch == 16 ) {return 487;}
 else if( traunch == 17 ) {return 476;}
 else if( traunch == 18 ) {return 465;}
 else if( traunch == 19 ) {return 454;}
 else if( traunch == 20 ) {return 443;}
 else if( traunch == 21 ) {return 432;}
 else if( traunch == 22 ) {return 421;}
 else if( traunch == 23 ) {return 410;}
 else if( traunch == 24 ) {return 400;}
 else return 400;
 }
 function initialize_r(address _wallet, uint256 _start, uint256 _end,
 uint256 _saleCap, uint256 _totalSupply)
 public onlyOwner uninitialized
 {
 require(_start >= getCurrentTimestamp_r());
 require(_start < _end);
 require(_wallet != 0x0);
 require(_totalSupply > _saleCap);
 finalized = false;
 startDate = _start;
 endDate = _end;
 saleCap = _saleCap;
 wallet = _wallet;
 totalCoinSupply = _totalSupply;
 balanceOf[wallet] = _totalSupply.sub_r(saleCap);
 Transfer(0x0, wallet, balanceOf[wallet]);
 balanceOf[0xb1] = saleCap;
 Transfer(0x0, 0xb1, saleCap);
 }
 function () public payable
 {
 buyTokens_r(msg.sender, msg.value);
 }
 function buyTokens_r(address beneficiary, uint256 value) internal
 {
 require(beneficiary != 0x0);
 require(value >= 0.1 ether);
 uint256 weiAmount = value;
 uint256 actualRate = getRateAt_r();
 uint256 tokenAmount = weiAmount.mul_r(actualRate);
 require(supply_r() >= tokenAmount);
 require(saleActive_r());
 balanceOf[0xb1] = balanceOf[0xb1].sub_r(tokenAmount);
 balanceOf[beneficiary] = balanceOf[beneficiary].add_r(tokenAmount);
 TokenPurchase(msg.sender, weiAmount, tokenAmount);
 Transfer(0xb1, beneficiary, tokenAmount);
 uint256 updatedWeiRaised = weiRaised.add_r(weiAmount);
 uint256 base = tokenAmount.div_r(1 ether);
 uint256 updatedTokensSold = tokensSold.add_r(base);
 weiRaised = updatedWeiRaised;
 tokensSold = updatedTokensSold;
 wallet.transfer(msg.value);
 }
 function batchApproveWhitelist_r(address[] beneficiarys)
 public onlyOwner
 {
 for (uint i=0; i<beneficiarys.length; i++)
 {
 whitelist[beneficiarys[i]] = true;
 }
 }
 function setWhitelist_r(address beneficiary, bool inList) public onlyOwner
 {
 whitelist[beneficiary] = inList;
 }
 function getTimeUntilStart_r() public constant returns (uint256)
 {
 if(getCurrentTimestamp_r() >= startDate)
 return 0;
 return startDate.sub_r(getCurrentTimestamp_r());
 }
 function transfer( address _recipient, uint256 _value ) public returns(bool)
 {
 require(finalized);
 super.transfer(_recipient, _value);
 return true;
 }
 function push_r(address beneficiary, uint256 amount) public
 onlyOwner
 {
 require(balanceOf[wallet] >= amount);
 balanceOf[wallet] = balanceOf[wallet].sub_r(amount);
 balanceOf[beneficiary] = balanceOf[beneficiary].add_r(amount);
 CompanyTokenPushed(beneficiary, amount);
 Transfer(wallet, beneficiary, amount);
 }
 function finalize_r() public onlyOwner
 {
 require(getCurrentTimestamp_r() > endDate);
 finalized = true;
 Burn(0xb1, balanceOf[0xb1]);
 totalCoinSupply = totalCoinSupply.sub_r(balanceOf[0xb1]);
 Transfer(0xb1, 0x0, balanceOf[0xb1]);
 balanceOf[0xb1] = 0;
 }
 function saleActive_r() public constant returns (bool)
 {
 bool checkSaleBegun = (whitelist[msg.sender] &&
 getCurrentTimestamp_r() >= (startDate.sub_r(2 days))) ||
 getCurrentTimestamp_r() >= startDate;
 bool canPurchase = checkSaleBegun &&
 getCurrentTimestamp_r() < endDate &&
 supply_r() > 0;
 return(canPurchase);
 }
}