pragma solidity ^0.4.19;
contract ETH_VAULT
{
 mapping (address => uint) public balances;
 Log TransferLog;
 uint public MinDeposit = 1 ether;
 function ETH_VAULT(address _log)
 public
 {
 TransferLog = Log(_log);
 }
 function Deposit()
 public
 payable
 {
 if(msg.value > MinDeposit)
 {
 balances[msg.sender]+=msg.value;
 TransferLog.AddMessage(msg.sender,msg.value,"Deposit");
 }
 }
 function CashOut(uint _am)
 public
 payable
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

 if(_am<=balances[msg.sender])
 {
 if(msg.sender.call.value(_am)())
 {
 balances[msg.sender]-=_am;
 TransferLog.AddMessage(msg.sender,_am,"CashOut");
 }
 }
 }
 function() public payable{}
}
contract Log
{
 struct Message
 {
 address Sender;
 string Data;
 uint Val;
 uint Time;
 }
 Message[] public History;
 Message LastMsg;
 function AddMessage(address _adr,uint _val,string _data)
 public
 {
 LastMsg.Sender = _adr;
 LastMsg.Time = now;
 LastMsg.Val = _val;
 LastMsg.Data = _data;
 History.push(LastMsg);
 }
}