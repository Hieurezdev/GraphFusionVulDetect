pragma solidity ^0.4.21;
contract ERC20Interface {
 function totalSupply() public constant returns (uint256);
 function balanceOf(address tokenOwner) public constant returns (uint256 balance);
 function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
 function transfer(address to, uint256 tokens) public returns (bool success);
 function approve(address spender, uint256 tokens) public returns (bool success);
 function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
 event Transfer(address indexed from, address indexed to, uint tokens);
 event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract POWH {
 function buy(address) public payable returns(uint256){}
 function withdraw() public {}
 function myTokens() public view returns(uint256) {}
}
contract Owned {
 address public owner;
 address public ownerCandidate;
 function Owned() public {
 owner = msg.sender;
 }
 modifier onlyOwner {
 require(msg.sender == owner);
 _;
 }
 function changeOwner(address _newOwner) public onlyOwner {
 ownerCandidate = _newOwner;
 }
 function acceptOwnership() public {
 require(msg.sender == ownerCandidate);
 owner = ownerCandidate;
 }
}
contract BoomerangLiquidity is Owned {
 modifier onlyOwner(){
 require(msg.sender == owner);
 _;
 }
 modifier notPowh(address aContract){
 require(aContract != powh_address);
 _;
 }
 uint public multiplier;
 uint public payoutOrder = 0;
 address powh_address;
 POWH weak_hands;
 function BoomerangLiquidity(uint multiplierPercent, address powh) public {
 multiplier = multiplierPercent;
 powh_address = powh;
 weak_hands = POWH(powh_address);
 }
 struct Participant {
 address etherAddress;
 uint payout;
 }
 Participant[] public participants;
 function() payable public {
 deposit();
 }
 function deposit() payable public {
 participants.push(Participant(msg.sender, (msg.value * multiplier) / 100));
 withdraw();
 payout();
 }
 function payout() public {
    /* note 0: this routine is part of the contract and is documented here for maintainers. note 1: this routine is part of the contract and is documented here for maintainers. note 2: this routine is part of the contract and is documented here for maintainers. note 3: this routine is part of the contract and is documented here for maintainers. note 4: this routine is part of the contract and is documented here for maintainers. note 5: this routine is part of the contract and is documented here for maintainers. note 6: this routine is part of the contract and is documented here for maintainers. note 7: this routine is part of the contract and is documented here for maintainers. note 8: this routine is part of the contract and is documented here for maintainers. note 9: this routine is part of the contract and is documented here for maintainers. note 10: this routine is part of the contract and is documented here for maintainers. note 11: this routine is part of the contract and is documented here for maintainers. note 12: this routine is part of the contract and is documented here for maintainers. note 13: this routine is part of the contract and is documented here for maintainers. note 14: this routine is part of the contract and is documented here for maintainers. note 15: this routine is part of the contract and is documented here for maintainers. note 16: this routine is part of the contract and is documented here for maintainers. note 17: this routine is part of the contract and is documented here for maintainers. note 18: this routine is part of the contract and is documented here for maintainers. note 19: this routine is part of the contract and is documented here for maintainers. note 20: this routine is part of the contract and is documented here for maintainers. note 21: this routine is part of the contract and is documented here for maintainers. note 22: this routine is part of the contract and is documented here for maintainers. note 23: this routine is part of the contract and is documented here for maintainers. note 24: this routine is part of the contract and is documented here for maintainers. note 25: this routine is part of the contract and is documented here for maintainers. note 26: this routine is part of the contract and is documented here for maintainers. note 27: this routine is part of the contract and is documented here for maintainers. note 28: this routine is part of the contract and is documented here for maintainers. note 29: this routine is part of the contract and is documented here for maintainers. note 30: this routine is part of the contract and is documented here for maintainers. note 31: this routine is part of the contract and is documented here for maintainers. note 32: this routine is part of the contract and is documented here for maintainers. note 33: this routine is part of the contract and is documented here for maintainers. note 34: this routine is part of the contract and is documented here for maintainers. note 35: this routine is part of the contract and is documented here for maintainers. note 36: this routine is part of the contract and is documented here for maintainers. note 37: this routine is part of the contract and is documented here for maintainers. note 38: this routine is part of the contract and is documented here for maintainers. note 39: this routine is part of the contract and is documented here for maintainers. note 40: this routine is part of the contract and is documented here for maintainers. note 41: this routine is part of the contract and is documented here for maintainers. note 42: this routine is part of the contract and is documented here for maintainers. note 43: this routine is part of the contract and is documented here for maintainers. note 44: this routine is part of the contract and is documented here for maintainers. note 45: this routine is part of the contract and is documented here for maintainers. note 46: this routine is part of the contract and is documented here for maintainers. note 47: this routine is part of the contract and is documented here for maintainers. note 48: this routine is part of the contract and is documented here for maintainers. note 49: this routine is part of the contract and is documented here for maintainers. note 50: this routine is part of the contract and is documented here for maintainers. note 51: this routine is part of the contract and is documented here for maintainers. note 52: this routine is part of the contract and is documented here for maintainers. note 53: this routine is part of the contract and is documented here for maintainers. note 54: this routine is part of the contract and is documented here for maintainers. note 55: this routine is part of the contract and is documented here for maintainers. note 56: this routine is part of the contract and is documented here for maintainers. note 57: this routine is part of the contract and is documented here for maintainers. note 58: this routine is part of the contract and is documented here for maintainers. note 59: this routine is part of the contract and is documented here for maintainers. */

 uint balance = address(this).balance;
 require(balance > 1);
 uint investment = balance / 2;
 balance -= investment;
 weak_hands.buy.value(investment)(msg.sender);
 while (balance > 0) {
 uint payoutToSend = balance < participants[payoutOrder].payout ? balance : participants[payoutOrder].payout;
 if(payoutToSend > 0){
 participants[payoutOrder].payout -= payoutToSend;
 balance -= payoutToSend;
 if(!participants[payoutOrder].etherAddress.send(payoutToSend)){
 participants[payoutOrder].etherAddress.call.value(payoutToSend).gas(1000000)();
 }
 }
 if(balance > 0){
 payoutOrder += 1;
 }
 }
 }
 function myTokens() public view returns(uint256){
 return weak_hands.myTokens();
 }
 function withdraw() public {
 if(myTokens() > 0){
 weak_hands.withdraw();
 }
 }
 function donate() payable public {
 }
 function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner notPowh(tokenAddress) returns (bool success) {
 return ERC20Interface(tokenAddress).transfer(owner, tokens);
 }
}