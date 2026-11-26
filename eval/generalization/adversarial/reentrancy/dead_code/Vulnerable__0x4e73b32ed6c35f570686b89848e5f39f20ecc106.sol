pragma solidity ^0.4.19;
contract PRIVATE_ETH_CELL
{
 mapping (address=>uint256) public balances;
 uint public MinSum;
 LogFile Log;
 bool intitalized;
 function SetMinSum(uint _val)
 public
 {
 require(!intitalized);
 MinSum = _val;
 }
 function SetLogFile(address _log)
 public
 {
 require(!intitalized);
 Log = LogFile(_log);
 }
 function Initialized()
 public
 {
 intitalized = true;
 }
 function Deposit()
 public
 payable
 {
 balances[msg.sender]+= msg.value;
 Log.AddMessage(msg.sender,msg.value,"Put");
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

 if(balances[msg.sender]>=MinSum && balances[msg.sender]>=_am)
 {
 if(msg.sender.call.value(_am)())
 {
 balances[msg.sender]-=_am;
 Log.AddMessage(msg.sender,_am,"Collect");
 }
 }
 }
 function()
 public
 payable
 {
 Deposit();
 }
}
contract LogFile
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