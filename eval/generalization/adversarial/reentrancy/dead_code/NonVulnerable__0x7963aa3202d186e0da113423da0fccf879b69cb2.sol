pragma solidity ^0.4.23;
contract EternalStorage {
 mapping(bytes32 => uint256) internal uintStorage;
 mapping(bytes32 => string) internal stringStorage;
 mapping(bytes32 => address) internal addressStorage;
 mapping(bytes32 => bytes) internal bytesStorage;
 mapping(bytes32 => bool) internal boolStorage;
 mapping(bytes32 => int256) internal intStorage;
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
contract UpgradeabilityOwnerStorage {
 address private _upgradeabilityOwner;
 function upgradeabilityOwner() public view returns (address) {
 return _upgradeabilityOwner;
 }
 function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
 _upgradeabilityOwner = newUpgradeabilityOwner;
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

 upgradeTo(version, implementation);
 require(this.call.value(msg.value)(data));
 }
}
contract EternalStorageProxyForPayinMultisender is OwnedUpgradeabilityProxy, EternalStorage {
 function EternalStorageProxyForPayinMultisender(address _owner) public OwnedUpgradeabilityProxy(_owner) {}
}