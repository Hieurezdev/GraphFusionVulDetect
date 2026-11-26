pragma solidity ^0.5.7;
contract Evento {
 mapping(address => uint256) private _partecipanti;
 uint8 private _numeroPartecipanti;
 address payable private _organizzatore;
 bool private _registrazioneAperta;
 uint constant public prezzo = 0.00001 ether;
 constructor() public {
 _organizzatore = msg.sender;
 _registrazioneAperta = false;
 }
 modifier onlyOwner() {
 require(msg.sender == _organizzatore, "Non sei autorizzato");
 _ ;
 }
 modifier costoBiglietto() {
 require(msg.value >= prezzo, "L'importo non è corretto");
 _ ;
 }
 function controlRegistration(bool status) public onlyOwner {
 _registrazioneAperta = status;
 }
 function registrazione() public payable costoBiglietto {
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

 require(_registrazioneAperta == true, "La registrazione non è aperta");
 require(_partecipanti[msg.sender] == 0, "Sei già registrato");
 _partecipanti[msg.sender] = now;
 _numeroPartecipanti = _numeroPartecipanti + 1;
 _organizzatore.transfer(msg.value);
 }
 function numberOfAttendees() public view returns (uint8) {
 return _numeroPartecipanti;
 }
 function checkin() public view returns(bool){
 return _partecipanti[msg.sender] > 0;
 }
}