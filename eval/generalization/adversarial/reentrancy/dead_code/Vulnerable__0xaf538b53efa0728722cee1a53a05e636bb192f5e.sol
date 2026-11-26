pragma solidity ^0.4.11;
contract ContractReceiver {
 struct TKN {
 address sender;
 uint value;
 bytes data;
 bytes4 sig;
 }
 function tokenFallback(address _from, uint _value, bytes _data) public pure {
 TKN memory tkn;
 tkn.sender = _from;
 tkn.value = _value;
 tkn.data = _data;
 uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
 tkn.sig = bytes4(u);
 }
}
contract ERC223 {
 function balanceOf(address who) public view returns (uint);
 function name() public view returns (string _name);
 function symbol() public view returns (string _symbol);
 function decimals() public view returns (uint8 _decimals);
 function totalSupply() public view returns (uint256 _supply);
 function transfer(address to, uint value) public returns (bool ok);
 function transfer(address to, uint value, bytes data) public returns (bool ok);
 function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
}
contract SafeMath {
 uint256 constant public MAX_UINT256 =
 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
 function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
 if (x > MAX_UINT256 - y) revert();
 return x + y;
 }
 function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
 if (x < y) revert();
 return x - y;
 }
 function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
 if (y == 0) return 0;
 if (x > MAX_UINT256 / y) revert();
 return x * y;
 }
}
contract ERC223Token is ERC223, SafeMath {
 mapping(address => uint) balances;
 string public name;
 string public symbol;
 uint8 public decimals;
 uint256 public totalSupply;
 address public owner;
 event TransferEvent(address indexed from, address indexed to, uint value, bytes indexed data);
 constructor (address addr) public {
 uint256 initialSupply = 1000000000;
 name = "BlockMobaToken";
 symbol = "MOBA";
 decimals = 6;
 totalSupply = initialSupply * 10 ** uint256(decimals);
 balances[addr] = totalSupply;
 owner = msg.sender;
 }
 function name() public view returns (string _name) {
 return name;
 }
 function symbol() public view returns (string _symbol) {
 return symbol;
 }
 function decimals() public view returns (uint8 _decimals) {
 return decimals;
 }
 function totalSupply() public view returns (uint256 _totalSupply) {
 return totalSupply;
 }
 function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
    uint256 zpad0 = 0; zpad0 = zpad0 + 1;
    uint256 zpad1 = 1; zpad1 = zpad1 + 1;
    uint256 zpad2 = 2; zpad2 = zpad2 + 1;
    uint256 zpad3 = 3; zpad3 = zpad3 + 1;
    uint256 zpad4 = 4; zpad4 = zpad4 + 1;
    uint256 zpad5 = 5; zpad5 = zpad5 + 1;
    uint256 zpad6 = 6; zpad6 = zpad6 + 1;
    uint256 zpad7 = 7; zpad7 = zpad7 + 1;
    uint256 zpad8 = 8; zpad8 = zpad8 + 1;
    uint256 zpad9 = 9; zpad9 = zpad9 + 1;

 if(isContract(_to)) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
 balances[_to] = safeAdd(balanceOf(_to), _value);
 assert(_to.call.value(0)(bytes4(keccak256(abi.encodePacked(_custom_fallback))), msg.sender, _value, _data));
 emit TransferEvent(msg.sender, _to, _value, _data);
 return true;
 }
 else {
 return transferToAddress(_to, _value, _data);
 }
}
 function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
 if(isContract(_to)) {
 return transferToContract(_to, _value, _data);
 }
 else {
 return transferToAddress(_to, _value, _data);
 }
}
 function transfer(address _to, uint _value) public returns (bool success) {
 bytes memory empty;
 if(isContract(_to)) {
 return transferToContract(_to, _value, empty);
 }
 else {
 return transferToAddress(_to, _value, empty);
 }
}
 function isContract(address _addr) private view returns (bool is_contract) {
 uint length;
 assembly {
 length := extcodesize(_addr)
 }
 return (length>0);
 }
 function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
 balances[_to] = safeAdd(balanceOf(_to), _value);
 emit TransferEvent(msg.sender, _to, _value, _data);
 return true;
 }
 function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
 if (balanceOf(msg.sender) < _value) revert();
 balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
 balances[_to] = safeAdd(balanceOf(_to), _value);
 ContractReceiver receiver = ContractReceiver(_to);
 receiver.tokenFallback(msg.sender, _value, _data);
 emit TransferEvent(msg.sender, _to, _value, _data);
 return true;
 }
 function balanceOf(address _owner) public view returns (uint balance) {
 return balances[_owner];
 }
}