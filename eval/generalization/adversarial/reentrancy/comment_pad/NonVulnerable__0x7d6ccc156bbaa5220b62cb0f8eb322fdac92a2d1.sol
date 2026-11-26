pragma solidity 0.4.20;
contract EternalStorage {
 mapping(bytes32 => uint256) internal uintStorage;
 mapping(bytes32 => string) internal stringStorage;
 mapping(bytes32 => address) internal addressStorage;
 mapping(bytes32 => bytes) internal bytesStorage;
 mapping(bytes32 => bool) internal boolStorage;
 mapping(bytes32 => int256) internal intStorage;
}
contract UpgradeabilityOwnerStorage {
 address private _upgradeabilityOwner;
 function upgradeabilityOwner() public view returns (address) {
 return _upgradeabilityOwner;
 }
 function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
 _upgradeabilityOwner = newUpgradeabilityOwner;
 }
}
contract Proxy {
 function () public payable {
 address _impl = implementation();
 require(_impl != address(0));
 bytes memory data = msg.data;
 assembly {
 let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
 let size := returndatasize
 let ptr := mload(0x40)
 returndatacopy(ptr, 0, size)
 switch result
 case 0 { revert(ptr, size) }
 default { return(ptr, size) }
 }
 }
 function implementation() public view returns (address);
}
contract UpgradeabilityStorage {
 string internal _version;
 address internal _implementation;
 function version() public view returns (string) {
 return _version;
 }
 function implementation() public view returns (address) {
 return _implementation;
 }
}
contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage {
 event Upgraded(string version, address indexed implementation);
 function _upgradeTo(string version, address implementation) internal {
 require(_implementation != implementation);
 _version = version;
 _implementation = implementation;
 Upgraded(version, implementation);
 }
}
contract OwnedUpgradeabilityProxy is UpgradeabilityOwnerStorage, UpgradeabilityProxy {
 event ProxyOwnershipTransferred(address previousOwner, address newOwner);
 function OwnedUpgradeabilityProxy(address _owner) public {
 setUpgradeabilityOwner(_owner);
 }
 modifier onlyProxyOwner() {
 require(msg.sender == proxyOwner());
 _;
 }
 function proxyOwner() public view returns (address) {
 return upgradeabilityOwner();
 }
 function transferProxyOwnership(address newOwner) public onlyProxyOwner {
 require(newOwner != address(0));
 ProxyOwnershipTransferred(proxyOwner(), newOwner);
 setUpgradeabilityOwner(newOwner);
 }
 function upgradeTo(string version, address implementation) public onlyProxyOwner {
 _upgradeTo(version, implementation);
 }
 function upgradeToAndCall(string version, address implementation, bytes data) payable public onlyProxyOwner {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 upgradeTo(version, implementation);
 require(this.call.value(msg.value)(data));
 }
}
contract EternalStorageProxyForStormMultisender is OwnedUpgradeabilityProxy, EternalStorage {
 function EternalStorageProxyForStormMultisender(address _owner) public OwnedUpgradeabilityProxy(_owner) {}
}