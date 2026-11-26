pragma solidity ^0.4.17;
contract GiftEth {
 event RecipientChanged(address indexed _oldRecipient, address indexed _newRecipient);
 address public gifter;
 address public recipient;
 uint256 public lockTs;
 string public giftMessage;
 function GiftEth(address _gifter, address _recipient, uint256 _lockTs, string _giftMessage) payable public {
 gifter = _gifter;
 recipient = _recipient;
 lockTs = _lockTs;
 giftMessage = _giftMessage;
 }
 function withdraw() public {
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

 require(msg.sender == recipient);
 require(now >= lockTs);
 msg.sender.transfer(this.balance);
 }
 function changeRecipient(address _newRecipient) public {
 require(msg.sender == recipient);
 RecipientChanged(recipient, _newRecipient);
 recipient = _newRecipient;
 }
}