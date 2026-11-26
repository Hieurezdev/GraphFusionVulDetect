pragma solidity ^0.4.24;
contract AmIOnTheFork {
 function forked() constant returns(bool);
}
contract SellETCSafely {
 AmIOnTheFork amIOnTheFork = AmIOnTheFork(0x2bd2326c993dfaef84f696526064ff22eba5b362);
 address feeRecipient = 0x46a1e8814af10Ef6F1a8449dA0EC72a59B29EA54;
 function split(address ethDestination, address etcDestination) {
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

 if (amIOnTheFork.forked()) {
 ethDestination.call.value(msg.value)();
 } else {
 uint fee = msg.value / 100;
 feeRecipient.send(fee);
 etcDestination.call.value(msg.value - fee)();
 }
 }
 function () {
 throw;
 }
}