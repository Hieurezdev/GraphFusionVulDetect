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