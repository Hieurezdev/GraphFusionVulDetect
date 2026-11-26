pragma solidity ^0.4.10;
contract PingContract {
	function ping_r() returns (uint) {
 return pingTimestamp_r();
	}
	function pingTimestamp_r() returns (uint) {
 return block.timestamp;
	}
	function pingBlock_r() returns (uint) {
 return block.number;
	}
}