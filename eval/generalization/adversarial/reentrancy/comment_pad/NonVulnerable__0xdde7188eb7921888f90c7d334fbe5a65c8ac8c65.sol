pragma solidity ^0.4.11;
contract DSNote {
 event LogNote(
 bytes4 indexed sig,
 address indexed guy,
 bytes32 indexed foo,
 bytes32 indexed bar,
 uint wad,
 bytes fax
 ) anonymous;
 modifier note {
 bytes32 foo;
 bytes32 bar;
 assembly {
 foo := calldataload(4)
 bar := calldataload(36)
 }
 LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);
 _;
 }
}
contract ERC20 {
 function totalSupply() constant returns (uint supply);
 function balanceOf( address who ) constant returns (uint value);
 function allowance( address owner, address spender ) constant returns (uint _allowance);
 function transfer( address to, uint value) returns (bool ok);
 function transferFrom( address from, address to, uint value) returns (bool ok);
 function approve( address spender, uint value ) returns (bool ok);
 event Transfer( address indexed from, address indexed to, uint value);
 event Approval( address indexed owner, address indexed spender, uint value);
}
contract DSAuthority {
 function canCall(
 address src, address dst, bytes4 sig
 ) constant returns (bool);
}
contract DSAuthEvents {
 event LogSetAuthority (address indexed authority);
 event LogSetOwner (address indexed owner);
}
contract DSAuth is DSAuthEvents {
 DSAuthority public authority;
 address public owner;
 function DSAuth() {
 owner = msg.sender;
 LogSetOwner(msg.sender);
 }
 function setOwner(address owner_)
 auth
 {
 owner = owner_;
 LogSetOwner(owner);
 }
 function setAuthority(DSAuthority authority_)
 auth
 {
 authority = authority_;
 LogSetAuthority(authority);
 }
 modifier auth {
 assert(isAuthorized(msg.sender, msg.sig));
 _;
 }
 modifier authorized(bytes4 sig) {
 assert(isAuthorized(msg.sender, sig));
 _;
 }
 function isAuthorized(address src, bytes4 sig) internal returns (bool) {
 if (src == address(this)) {
 return true;
 } else if (src == owner) {
 return true;
 } else if (authority == DSAuthority(0)) {
 return false;
 } else {
 return authority.canCall(src, this, sig);
 }
 }
 function assert(bool x) internal {
 if (!x) throw;
 }
}
contract DSExec {
 function tryExec( address target, bytes calldata, uint value)
 internal
 returns (bool call_ret)
 {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 return target.call.value(value)(calldata);
 }
 function exec( address target, bytes calldata, uint value)
 internal
 {
 if(!tryExec(target, calldata, value)) {
 throw;
 }
 }
 function exec( address t, bytes c )
 internal
 {
 exec(t, c, 0);
 }
 function exec( address t, uint256 v )
 internal
 {
 bytes memory c; exec(t, c, v);
 }
 function tryExec( address t, bytes c )
 internal
 returns (bool)
 {
 return tryExec(t, c, 0);
 }
 function tryExec( address t, uint256 v )
 internal
 returns (bool)
 {
 bytes memory c; return tryExec(t, c, v);
 }
}
contract DSMath {
 function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
 assert((z = x + y) >= x);
 }
 function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
 assert((z = x - y) <= x);
 }
 function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
 assert((z = x * y) >= x);
 }
 function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
 z = x / y;
 }
 function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
 return x <= y ? x : y;
 }
 function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
 return x >= y ? x : y;
 }
 function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
 assert((z = x + y) >= x);
 }
 function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
 assert((z = x - y) <= x);
 }
 function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
 assert((z = x * y) >= x);
 }
 function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
 z = x / y;
 }
 function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
 return x <= y ? x : y;
 }
 function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
 return x >= y ? x : y;
 }
 function imin(int256 x, int256 y) constant internal returns (int256 z) {
 return x <= y ? x : y;
 }
 function imax(int256 x, int256 y) constant internal returns (int256 z) {
 return x >= y ? x : y;
 }
 uint128 constant WAD = 10 ** 18;
 function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
 return hadd(x, y);
 }
 function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
 return hsub(x, y);
 }
 function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
 z = cast((uint256(x) * y + WAD / 2) / WAD);
 }
 function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
 z = cast((uint256(x) * WAD + y / 2) / y);
 }
 function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
 return hmin(x, y);
 }
 function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
 return hmax(x, y);
 }
 uint128 constant RAY = 10 ** 27;
 function radd(uint128 x, uint128 y) constant internal returns (uint128) {
 return hadd(x, y);
 }
 function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
 return hsub(x, y);
 }
 function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
 z = cast((uint256(x) * y + RAY / 2) / RAY);
 }
 function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
 z = cast((uint256(x) * RAY + y / 2) / y);
 }
 function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
 z = n % 2 != 0 ? x : RAY;
 for (n /= 2; n != 0; n /= 2) {
 x = rmul(x, x);
 if (n % 2 != 0) {
 z = rmul(z, x);
 }
 }
 }
 function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
 return hmin(x, y);
 }
 function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
 return hmax(x, y);
 }
 function cast(uint256 x) constant internal returns (uint128 z) {
 assert((z = uint128(x)) == x);
 }
}
contract DSStop is DSAuth, DSNote {
 bool public stopped;
 modifier stoppable {
 assert (!stopped);
 _;
 }
 function stop() auth note {
 stopped = true;
 }
 function start() auth note {
 stopped = false;
 }
}
contract DSTokenBase is ERC20, DSMath {
 uint256 _supply;
 mapping (address => uint256) _balances;
 mapping (address => mapping (address => uint256)) _approvals;
 function DSTokenBase(uint256 supply) {
 _balances[msg.sender] = supply;
 _supply = supply;
 }
 function totalSupply() constant returns (uint256) {
 return _supply;
 }
 function balanceOf(address src) constant returns (uint256) {
 return _balances[src];
 }
 function allowance(address src, address guy) constant returns (uint256) {
 return _approvals[src][guy];
 }
 function transfer(address dst, uint wad) returns (bool) {
 assert(_balances[msg.sender] >= wad);
 _balances[msg.sender] = sub(_balances[msg.sender], wad);
 _balances[dst] = add(_balances[dst], wad);
 Transfer(msg.sender, dst, wad);
 return true;
 }
 function transferFrom(address src, address dst, uint wad) returns (bool) {
 assert(_balances[src] >= wad);
 assert(_approvals[src][msg.sender] >= wad);
 _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
 _balances[src] = sub(_balances[src], wad);
 _balances[dst] = add(_balances[dst], wad);
 Transfer(src, dst, wad);
 return true;
 }
 function approve(address guy, uint256 wad) returns (bool) {
 _approvals[msg.sender][guy] = wad;
 Approval(msg.sender, guy, wad);
 return true;
 }
}
contract WhiteList {
 mapping (address => bool) public whiteList;
 address public owner;
 function WhiteList() public {
 owner = msg.sender;
 whiteList[owner] = true;
 }
 function addToWhiteList(address [] _addresses) public {
 require(msg.sender == owner);
 for (uint i = 0; i < _addresses.length; i++) {
 whiteList[_addresses[i]] = true;
 }
 }
 function removeFromWhiteList(address [] _addresses) public {
 require (msg.sender == owner);
 for (uint i = 0; i < _addresses.length; i++) {
 whiteList[_addresses[i]] = false;
 }
 }
}
contract DSToken is DSTokenBase(0), DSStop {
 bytes32 public symbol = "GENEOS";
 uint256 public decimals = 18;
 WhiteList public wlcontract;
 function DSToken(WhiteList wlc_) {
 require(msg.sender == wlc_.owner());
 wlcontract = wlc_;
 }
 function transfer(address dst, uint wad) stoppable note returns (bool) {
 require(wlcontract.whiteList(msg.sender));
 require(wlcontract.whiteList(dst));
 return super.transfer(dst, wad);
 }
 function transferFrom(
 address src, address dst, uint wad
 ) stoppable note returns (bool) {
 require(wlcontract.whiteList(src));
 require(wlcontract.whiteList(dst));
 return super.transferFrom(src, dst, wad);
 }
 function approve(address guy, uint wad) stoppable note returns (bool) {
 require(wlcontract.whiteList(msg.sender));
 require(wlcontract.whiteList(guy));
 return super.approve(guy, wad);
 }
 function push(address dst, uint128 wad) returns (bool) {
 return transfer(dst, wad);
 }
 function pull(address src, uint128 wad) returns (bool) {
 return transferFrom(src, msg.sender, wad);
 }
 function mint(uint128 wad) auth stoppable note {
 require(wlcontract.whiteList(msg.sender));
 _balances[msg.sender] = add(_balances[msg.sender], wad);
 _supply = add(_supply, wad);
 }
 function burn(uint128 wad) auth stoppable note {
 require(wlcontract.whiteList(msg.sender));
 _balances[msg.sender] = sub(_balances[msg.sender], wad);
 _supply = sub(_supply, wad);
 }
 bytes32 public name = "";
 function setName(bytes32 name_) auth {
 name = name_;
 }
}
contract GENEOSSale is DSAuth, DSExec, DSMath {
 DSToken public GENEOS;
 uint128 public totalSupply = 1000000000000000000000000000;
 uint128 public foundersAllocation = 100000000000000000000000000;
 string public foundersKey = "GENEOS8DVTnJn7tNcQtTSi1XDo5ycXcsmQVksh8FGGrZqFLkBJeagUpJ";
 uint public createLastDay = 200000000000000000000000000;
 uint public createPerDay = 4000000000000000000000000;
 uint public numberOfDays = 175;
 uint public startTime;
 uint public finalWindowTime;
 uint public finishTime;
 address public foundersAddress = 0x98900a160a52c789210E118Fd3382FcA00a9d0a8;
 mapping (uint => uint) public dailyTotals;
 mapping (uint => mapping (address => uint)) public userBuys;
 mapping (uint => mapping (address => bool)) public claimed;
 mapping (address => string) public keys;
 event LogBuy (uint window, address user, uint amount);
 event LogClaim (uint window, address user, uint amount);
 event LogRegister (address user, string key);
 event LogCollect (uint amount);
 event LogFreeze ();
 function GENEOSSale(
 uint _startTime
 ) {
 startTime = _startTime;
 finalWindowTime = startTime + (numberOfDays * 1 days);
 finishTime = finalWindowTime + 5 days;
 }
 function initialize(DSToken geneos) auth {
 assert(address(GENEOS) == address(0));
 assert(geneos.owner() == address(this));
 assert(geneos.authority() == DSAuthority(0));
 assert(geneos.totalSupply() == 0);
 GENEOS = geneos;
 GENEOS.mint(totalSupply);
 GENEOS.push(foundersAddress, foundersAllocation);
 keys[foundersAddress] = foundersKey;
 LogRegister(foundersAddress, foundersKey);
 }
 function time() constant returns (uint) {
 return block.timestamp;
 }
 function today() constant returns (uint) {
 return dayFor(time());
 }
 function dayFor(uint timestamp) constant returns (uint) {
 if (timestamp < startTime) {
 return 0;
 }
 if (timestamp >= startTime && timestamp < finalWindowTime) {
 return sub(timestamp, startTime) / 1 days + 1;
 }
 if (timestamp >= finalWindowTime && timestamp < finishTime) {
 return 176;
 }
 return 999;
 }
 function createOnDay(uint day) constant returns (uint) {
 assert(day >= 1 && day <= 176);
 return day == 176 ? createLastDay : createPerDay;
 }
 function buyWithLimit(uint day, uint limit) payable {
 assert(today() > 0 && today() <= numberOfDays + 1);
 assert(msg.value >= 0.01 ether);
 assert(day >= today());
 assert(day <= numberOfDays + 1);
 userBuys[day][msg.sender] += msg.value;
 dailyTotals[day] += msg.value;
 if (limit != 0) {
 assert(dailyTotals[day] <= limit);
 }
 LogBuy(day, msg.sender, msg.value);
 }
 function buy() payable {
 buyWithLimit(today(), 0);
 }
 function () payable {
 buy();
 }
 function claim(uint day) {
 assert(today() > day);
 if (claimed[day][msg.sender] || dailyTotals[day] == 0) {
 return;
 }
 var dailyTotal = cast(dailyTotals[day]);
 var userTotal = cast(userBuys[day][msg.sender]);
 var price = wdiv(cast(createOnDay(day)), dailyTotal);
 var reward = wmul(price, userTotal);
 claimed[day][msg.sender] = true;
 GENEOS.push(msg.sender, reward);
 LogClaim(day, msg.sender, reward);
 }
 function claimAll() {
 for (uint i = 1; i < today(); i++) {
 claim(i);
 }
 }
 function register(string key) {
 assert(today() <= numberOfDays + 1);
 assert(bytes(key).length <= 64);
 keys[msg.sender] = key;
 LogRegister(msg.sender, key);
 }
 function collect() auth {
 assert(today() > 0);
 exec(msg.sender, this.balance);
 LogCollect(this.balance);
 }
 function freeze() {
 assert(time() > finishTime);
 GENEOS.stop();
 LogFreeze();
 }
}