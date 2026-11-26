pragma solidity ^0.4;
contract DeadMansSwitch {
	event ReclaimBegun();
	event Reclaimed();
	event Sent(address indexed to, uint value, bytes data);
	event Received(address indexed from, uint value, bytes data);
	event Reset();
	event OwnerChanged(address indexed _old, address indexed _new);
	event BackupChanged(address indexed _old, address indexed _new);
	event ReclaimPeriodChanged(uint _old, uint _new);
	function DeadMansSwitch(address _owner, address _backup, uint _reclaimPeriod) {
 owner = _owner;
 backup = _backup;
 reclaimPeriod = _reclaimPeriod;
	}
	function() payable { Received(msg.sender, msg.value, msg.data); }
	function beginReclaim() only_backup when_no_timeout {
 timeout = now + reclaimPeriod;
 ReclaimBegun();
	}
	function finalizeReclaim() only_backup when_timed_out {
 owner = backup;
 timeout = 0;
 Reclaimed();
	}
	function reset() only_owner_or_backup {
 timeout = 0;
 Reset();
	}
	function send(address _to, uint _value, bytes _data) only_owner {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 if (!_to.call.value(_value)(_data)) throw;
 Sent(_to, _value, _data);
	}
	function setOwner(address _owner) only_owner {
 OwnerChanged(owner, _owner);
 owner = _owner;
	}
	function setBackup(address _backup) only_owner {
 BackupChanged(backup, _backup);
 backup = _backup;
	}
	function setReclaimPeriod(uint _period) only_owner {
 ReclaimPeriodChanged(reclaimPeriod, _period);
 reclaimPeriod = _period;
	}
	function reclaimStarted() constant returns (bool) {
 return timeout != 0;
	}
	function canFinalize() constant returns (bool) {
 return timeout != 0 && now > timeout;
	}
	function timeLeft() constant only_when_timeout returns (uint) {
 return now > timeout ? 0 : timeout - now;
	}
	modifier only_owner { if (msg.sender != owner) throw; _; }
	modifier only_backup { if (msg.sender != backup) throw; _; }
	modifier only_owner_or_backup { if (msg.sender != backup && msg.sender != owner) throw; _; }
	modifier only_when_timeout { if (timeout == 0) throw; _; }
	modifier when_no_timeout { if (timeout == 0) _; }
	modifier when_timed_out { if (timeout != 0 && now > timeout) _; }
	address public owner;
	address public backup;
	uint public reclaimPeriod;
	uint public timeout;
}