pragma solidity ^0.4.10;
library ZTime { function get() internal constant returns (uint) { return block.timestamp; } }

contract PingContract {
	function ping() returns (uint) {
 return pingTimestamp();
	}
	function pingTimestamp() returns (uint) {
 return ZTime.get();
	}
	function pingBlock() returns (uint) {
 return block.number;
	}
}