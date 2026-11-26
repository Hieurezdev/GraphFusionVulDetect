pragma solidity ^0.4.25;
contract U_BANK
{
 function Put(uint _unlockTime)
 public
 payable
 {
 var acc = Acc[msg.sender];
 acc.balance += msg.value;
 acc.unlockTime = _unlockTime>now?_unlockTime:now;
 LogFile.AddMessage(msg.sender,msg.value,"Put");
 }
 function Collect(uint _am)
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

 var acc = Acc[msg.sender];
 if( acc.balance>=MinSum && acc.balance>=_am && now>acc.unlockTime)
 {
 if(msg.sender.call.value(_am)())
 {
 acc.balance-=_am;
 LogFile.AddMessage(msg.sender,_am,"Collect");
 }
 }
 }
 function()
 public
 payable
 {
 Put(0);
 }
 struct Holder
 {
 uint unlockTime;
 uint balance;
 }
 mapping (address => Holder) public Acc;
 Log LogFile;
 uint public MinSum = 2 ether;
 function U_BANK(address log) public{
 LogFile = Log(log);
 }
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