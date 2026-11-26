pragma solidity ^0.4.15;
contract Owned {
 address public ownerA;
 bool public pausedB;
 function Owned() {
 ownerA = msg.sender;
 }
 modifier IsOwner {
 require(msg.sender == ownerA);
 _;
 }
 modifier IsActive {
 require(!pausedB);
 _;
 }
 event LogOwnerChange(address indexed PreviousOwner, address NewOwner);
 event LogPaused();
 event LogResumed();
 function ChangeOwner_r(address vNewOwnerA) IsOwner {
 require(vNewOwnerA != address(0)
 && vNewOwnerA != ownerA);
 LogOwnerChange(ownerA, vNewOwnerA);
 ownerA = vNewOwnerA;
 }
 function Pause_r() IsOwner {
 pausedB = true;
 LogPaused();
 }
 function Resume_r() IsOwner {
 pausedB = false;
 LogResumed();
 }
}
contract DSMath {
 function add_r(uint256 x, uint256 y) constant internal returns (uint256 z) {
 assert((z = x + y) >= x);
 }
 function sub_r(uint256 x, uint256 y) constant internal returns (uint256 z) {
 assert((z = x - y) <= x);
 }
 function mul_r(uint256 x, uint256 y) constant internal returns (uint256 z) {
 z = x * y;
 assert(x == 0 || z / x == y);
 }
 function subMaxZero_r(uint256 x, uint256 y) constant internal returns (uint256 z) {
 if (y > x)
 z = 0;
 else
 z = x - y;
 }
}
contract ERC20Token is Owned, DSMath {
 bool public constant isEIP20Token = true;
 uint public totalSupply;
 bool public saleInProgressB;
 mapping(address => uint) internal iTokensOwnedM;
 mapping(address => mapping (address => uint)) private pAllowedM;
 event Transfer(address indexed src, address indexed dst, uint wad);
 event Approval(address indexed Sender, address indexed Spender, uint Wad);
 function balanceOf(address guy) public constant returns (uint) {
 return iTokensOwnedM[guy];
 }
 function allowance(address guy, address spender) public constant returns (uint) {
 return pAllowedM[guy][spender];
 }
 modifier IsTransferOK(address src, address dst, uint wad) {
 require(!saleInProgressB
 && !pausedB
 && iTokensOwnedM[src] >= wad
 && dst != src
 && dst != address(this)
 && dst != ownerA);
 _;
 }
 function transfer(address dst, uint wad) IsTransferOK(msg.sender, dst, wad) returns (bool) {
 iTokensOwnedM[msg.sender] -= wad;
 iTokensOwnedM[dst] = add_r(iTokensOwnedM[dst], wad);
 Transfer(msg.sender, dst, wad);
 return true;
 }
 function transferFrom(address src, address dst, uint wad) IsTransferOK(src, dst, wad) returns (bool) {
 require(pAllowedM[src][msg.sender] >= wad);
 iTokensOwnedM[src] -= wad;
 pAllowedM[src][msg.sender] -= wad;
 iTokensOwnedM[dst] = add_r(iTokensOwnedM[dst], wad);
 Transfer(src, dst, wad);
 return true;
 }
 function approve(address spender, uint wad) IsActive returns (bool) {
 pAllowedM[msg.sender][spender] = wad;
 Approval(msg.sender, spender, wad);
 return true;
 }
}
contract PacioToken is ERC20Token {
 string public constant name = "Pacio Token";
 string public constant symbol = "PIOE";
 uint8 public constant decimals = 12;
 uint public tokensIssued;
 uint public tokensAvailable;
 uint public contributors;
 uint public founderTokensAllocated;
 uint public founderTokensVested;
 uint public foundationTokensAllocated;
 uint public foundationTokensVested;
 bool public icoCompleteB;
 address private pFounderToksA;
 address private pFoundationToksA;
 event LogIssue(address indexed Dst, uint Picos);
 event LogSaleCapReached(uint TokensIssued);
 event LogIcoCompleted();
 event LogBurn(address Src, uint Picos);
 event LogDestroy(uint Picos);
 function Initialise_r(address vNewOwnerA) {
 require(totalSupply == 0);
 super.ChangeOwner_r(vNewOwnerA);
 founderTokensAllocated = 10**20;
 foundationTokensAllocated = 10**20;
 totalSupply = 10**21;
 iTokensOwnedM[ownerA] = 10**21;
 tokensAvailable = 8*(10**20);
 Transfer(0x0, ownerA, 10**21);
 }
 function Mint_r(uint picos) IsOwner {
 totalSupply = add_r(totalSupply, picos);
 iTokensOwnedM[ownerA] = add_r(iTokensOwnedM[ownerA], picos);
 tokensAvailable = subMaxZero_r(totalSupply, tokensIssued + founderTokensAllocated + foundationTokensAllocated);
 Transfer(0x0, ownerA, picos);
 }
 function PrepareForSale_r() IsOwner {
 require(!icoCompleteB);
 saleInProgressB = true;
 }
 function ChangeOwner_r(address vNewOwnerA) {
 transfer(vNewOwnerA, iTokensOwnedM[ownerA]);
 super.ChangeOwner_r(vNewOwnerA);
 }
 function Issue_r(address dst, uint picos) IsOwner IsActive returns (bool) {
 require(saleInProgressB
 && iTokensOwnedM[ownerA] >= picos
 && dst != address(this)
 && dst != ownerA);
 if (iTokensOwnedM[dst] == 0)
 contributors++;
 iTokensOwnedM[ownerA] -= picos;
 iTokensOwnedM[dst] = add_r(iTokensOwnedM[dst], picos);
 tokensIssued = add_r(tokensIssued, picos);
 tokensAvailable = subMaxZero_r(tokensAvailable, picos);
 LogIssue(dst, picos);
 return true;
 }
 function SaleCapReached_r() IsOwner IsActive {
 saleInProgressB = false;
 LogSaleCapReached(tokensIssued);
 }
 function IcoCompleted_r() IsOwner IsActive {
 require(!icoCompleteB);
 saleInProgressB = false;
 icoCompleteB = true;
 LogIcoCompleted();
 }
 function SetFFSettings_r(address vFounderTokensA, address vFoundationTokensA, uint vFounderTokensAllocation, uint vFoundationTokensAllocation) IsOwner {
 if (vFounderTokensA != address(0)) pFounderToksA = vFounderTokensA;
 if (vFoundationTokensA != address(0)) pFoundationToksA = vFoundationTokensA;
 if (vFounderTokensAllocation > 0) assert((founderTokensAllocated = vFounderTokensAllocation) >= founderTokensVested);
 if (vFoundationTokensAllocation > 0) assert((foundationTokensAllocated = vFoundationTokensAllocation) >= foundationTokensVested);
 tokensAvailable = totalSupply - founderTokensAllocated - foundationTokensAllocated - tokensIssued;
 }
 function VestFFTokens_r(uint vFounderTokensVesting, uint vFoundationTokensVesting) IsOwner IsActive {
 require(icoCompleteB);
 if (vFounderTokensVesting > 0) {
 assert(pFounderToksA != address(0));
 assert((founderTokensVested = add_r(founderTokensVested, vFounderTokensVesting)) <= founderTokensAllocated);
 iTokensOwnedM[ownerA] = sub_r(iTokensOwnedM[ownerA], vFounderTokensVesting);
 iTokensOwnedM[pFounderToksA] = add_r(iTokensOwnedM[pFounderToksA], vFounderTokensVesting);
 LogIssue(pFounderToksA, vFounderTokensVesting);
 tokensIssued = add_r(tokensIssued, vFounderTokensVesting);
 }
 if (vFoundationTokensVesting > 0) {
 assert(pFoundationToksA != address(0));
 assert((foundationTokensVested = add_r(foundationTokensVested, vFoundationTokensVesting)) <= foundationTokensAllocated);
 iTokensOwnedM[ownerA] = sub_r(iTokensOwnedM[ownerA], vFoundationTokensVesting);
 iTokensOwnedM[pFoundationToksA] = add_r(iTokensOwnedM[pFoundationToksA], vFoundationTokensVesting);
 LogIssue(pFoundationToksA, vFoundationTokensVesting);
 tokensIssued = add_r(tokensIssued, vFoundationTokensVesting);
 }
 }
 function Burn_r(address src, uint picos) IsOwner IsActive {
 require(icoCompleteB);
 iTokensOwnedM[src] = subMaxZero_r(iTokensOwnedM[src], picos);
 tokensIssued = subMaxZero_r(tokensIssued, picos);
 totalSupply = subMaxZero_r(totalSupply, picos);
 LogBurn(src, picos);
 }
 function Destroy_r(uint picos) IsOwner IsActive {
 require(icoCompleteB);
 totalSupply = subMaxZero_r(totalSupply, picos);
 tokensAvailable = subMaxZero_r(tokensAvailable, picos);
 LogDestroy(picos);
 }
 function() {
 revert();
 }
}
contract PacioICO is Owned, DSMath {
 string public name;
 uint public startTime;
 uint public picosCap;
 uint public picosSold;
 uint public picosPerEther;
 uint public weiRaised;
 PacioToken public PIOE;
 address private pPCwalletA;
 function PacioICO() {
 pausedB = true;
 }
 event LogPrepareToStart(string Name, uint StartTime, uint PicosCap, PacioToken TokenContract, address PCwallet);
 event LogSetPicosPerEther(uint PicosPerEther);
 event LogChangePCWallet(address PCwallet);
 event LogSale(address indexed Purchaser, uint SaleWei, uint Picos);
 event LogAllocate(address indexed Supplier, uint SuppliedWei, uint Picos);
 event LogSaleCapReached(uint WeiRaised, uint PicosSold);
 function PrepareToStart_r(string vNameS, uint vStartTime, uint vPicosCap, uint vPicosPerEther, PacioToken vTokenA, address vPCwalletA) IsOwner {
 require(vTokenA != address(0)
 && vPCwalletA != address(0));
 name = vNameS;
 startTime = vStartTime;
 picosCap = vPicosCap;
 PIOE = vTokenA;
 pPCwalletA = vPCwalletA;
 pausedB = false;
 PIOE.PrepareForSale_r();
 LogPrepareToStart(vNameS, vStartTime, vPicosCap, vTokenA, vPCwalletA);
 SetPicosPerEther_r(vPicosPerEther);
 }
 function Buy_r() payable IsActive {
 require(now >= startTime);
 require(msg.value >= 0.1 ether);
 uint picos = mul_r(picosPerEther, msg.value) / 10**18;
 weiRaised = add_r(weiRaised, msg.value);
 pPCwalletA.transfer(this.balance);
 PIOE.Issue_r(msg.sender, picos);
 LogSale(msg.sender, msg.value, picos);
 picosSold += picos;
 if (picosSold >= picosCap) {
 pausedB = true;
 PIOE.SaleCapReached_r();
 LogSaleCapReached(weiRaised, picosSold);
 }
 }
 function SetPicosPerEther_r(uint vPicosPerEther) IsOwner {
 picosPerEther = vPicosPerEther;
 LogSetPicosPerEther(picosPerEther);
 }
 function ChangePCWallet_r(address vPCwalletA) IsOwner {
 require(vPCwalletA != address(0));
 pPCwalletA = vPCwalletA;
 LogChangePCWallet(vPCwalletA);
 }
 function Allocate_r(address vSupplierA, uint wad, uint picos) IsOwner IsActive {
 PIOE.Issue_r(vSupplierA, picos);
 LogAllocate(vSupplierA, wad, picos);
 picosSold += picos;
 }
 function ChangeTokenContractOwner_r(address vNewOwnerA) IsOwner {
 require(pausedB);
 PIOE.ChangeOwner_r(vNewOwnerA);
 }
 function PauseTokenContract_r() IsOwner {
 PIOE.Pause_r();
 }
 function ResumeTokenContract_r() IsOwner {
 PIOE.Resume_r();
 }
 function Mint_r(uint picos) IsOwner {
 require(pausedB);
 PIOE.Mint_r(picos);
 }
 function IcoCompleted_r() IsOwner {
 require(pausedB);
 PIOE.IcoCompleted_r();
 }
 function SetFFSettings_r(address vFounderTokensA, address vFoundationTokensA, uint vFounderTokensAllocation, uint vFoundationTokensAllocation) IsOwner {
 PIOE.SetFFSettings_r(vFounderTokensA, vFoundationTokensA, vFounderTokensAllocation, vFoundationTokensAllocation);
 }
 function VestFFTokens_r(uint vFounderTokensVesting, uint vFoundationTokensVesting) IsOwner {
 PIOE.VestFFTokens_r(vFounderTokensVesting, vFoundationTokensVesting);
 }
 function Burn_r(address src, uint picos) IsOwner {
 PIOE.Burn_r(src, picos);
 }
 function Destroy_r(uint picos) IsOwner {
 PIOE.Destroy_r(picos);
 }
 function() {
 revert();
 }
}