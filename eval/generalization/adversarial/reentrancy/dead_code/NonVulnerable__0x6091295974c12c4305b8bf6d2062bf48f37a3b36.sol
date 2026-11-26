pragma solidity ^0.4.23;
contract DSExec {
 function tryExec( address target, bytes calldata, uint value)
 internal
 returns (bool call_ret)
 {
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

 return target.call.value(value)(calldata);
 }
 function exec( address target, bytes calldata, uint value)
 internal
 {
 if(!tryExec(target, calldata, value)) {
 revert();
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
 emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);
 _;
 }
}
contract DSSpell is DSExec, DSNote {
 address public whom;
 uint256 public mana;
 bytes public data;
 bool public done;
 constructor(address whom_, uint256 mana_, bytes data_) public {
 whom = whom_;
 mana = mana_;
 data = data_;
 }
 function cast() public note {
 require( !done );
 exec(whom, data, mana);
 done = true;
 }
}