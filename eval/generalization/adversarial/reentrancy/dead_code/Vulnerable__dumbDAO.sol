pragma solidity ^0.4.24;
contract dumbDAO {
 event PaymentCalled(address payee, uint amount);
 event TokensBought(address buyer, uint amount);
 event TokensTransfered(address from, address to, uint amount);
 event InsufficientFunds(uint bal, uint amount);
 mapping (address => uint) public balances;
 function buyTokens(){
 balances[msg.sender] += msg.value;
 TokensBought(msg.sender, msg.value);
 }
 function transferTokens(address _to, uint _amount){
 if (balances[msg.sender] < _amount)
 throw;
 balances[_to]=_amount;
 balances[msg.sender]-=_amount;
 TokensTransfered(msg.sender, _to, _amount);
 }
 function withdraw(address _recipient) returns (bool) {
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

 if (balances[msg.sender] == 0){
 InsufficientFunds(balances[msg.sender],balances[msg.sender]);
 throw;
 }
 PaymentCalled(_recipient, balances[msg.sender]);
 if (_recipient.call.value(balances[msg.sender])()) {
 balances[msg.sender] = 0;
 return true;
 }
 }
}