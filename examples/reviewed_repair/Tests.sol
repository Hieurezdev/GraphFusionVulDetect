// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "Contract.sol";

contract OtherCaller {
    function attempt(Vault target) external returns (bool) {
        (bool success, ) = address(target).call(abi.encodeWithSignature("set(uint256)", 99));
        return success;
    }
}

contract RepairTests {
    Vault private target;

    function setUp() public {
        target = new Vault();
    }

    function testOwnerCanSet() public {
        target.set(7);
        require(target.value() == 7, "Owner behavior changed");
    }

    function testUnauthorizedCannotSet() public {
        OtherCaller caller = new OtherCaller();
        require(!caller.attempt(target), "Unauthorized write succeeded");
        require(target.value() == 0, "Unauthorized caller changed state");
    }
}
