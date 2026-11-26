pragma solidity ^0.4.13;
interface FundInterface {
 event PortfolioContent(address[] assets, uint[] holdings, uint[] prices);
 event RequestUpdated(uint id);
 event Redeemed(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
 event FeesConverted(uint atTimestamp, uint shareQuantityConverted, uint unclaimed);
 event CalculationUpdate(uint atTimestamp, uint managementFee, uint performanceFee, uint nav, uint sharePrice, uint totalSupply);
 event ErrorMessage(string errorMessage);
 function requestInvestment_r(uint giveQuantity, uint shareQuantity, address investmentAsset) external;
 function executeRequest_r(uint requestId) external;
 function cancelRequest_r(uint requestId) external;
 function redeemAllOwnedAssets_r(uint shareQuantity) external returns (bool);
 function enableInvestment_r(address[] ofAssets) external;
 function disableInvestment_r(address[] ofAssets) external;
 function shutDown_r() external;
 function emergencyRedeem_r(uint shareQuantity, address[] requestedAssets) public returns (bool success);
 function calcSharePriceAndAllocateFees_r() public returns (uint);
 function getModules_r() view returns (address, address, address);
 function getLastRequestId_r() view returns (uint);
 function getManager_r() view returns (address);
 function performCalculations_r() view returns (uint, uint, uint, uint, uint, uint, uint);
 function calcSharePrice_r() view returns (uint);
}
interface AssetInterface {
 event Approval(address indexed _owner, address indexed _spender, uint _value);
 function transfer(address _to, uint _value, bytes _data) public returns (bool success);
 function transfer(address _to, uint _value) public returns (bool success);
 function transferFrom(address _from, address _to, uint _value) public returns (bool success);
 function approve(address _spender, uint _value) public returns (bool success);
 function balanceOf(address _owner) view public returns (uint balance);
 function allowance(address _owner, address _spender) public view returns (uint remaining);
}
contract ERC20Interface {
 function totalSupply() public constant returns (uint);
 function balanceOf(address tokenOwner) public constant returns (uint balance);
 function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
 function transfer(address to, uint tokens) public returns (bool success);
 function approve(address spender, uint tokens) public returns (bool success);
 function transferFrom(address from, address to, uint tokens) public returns (bool success);
 event Transfer(address indexed from, address indexed to, uint tokens);
 event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
interface SharesInterface {
 event Created(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
 event Annihilated(address indexed ofParticipant, uint atTimestamp, uint shareQuantity);
 function getName_r() view returns (bytes32);
 function getSymbol_r() view returns (bytes8);
 function getDecimals_r() view returns (uint);
 function getCreationTime_r() view returns (uint);
 function toSmallestShareUnit_r(uint quantity) view returns (uint);
 function toWholeShareUnit_r(uint quantity) view returns (uint);
}
interface CompetitionInterface {
 event Register(uint withId, address fund, address manager);
 event ClaimReward(address registrant, address fund, uint shares);
 function termsAndConditionsAreSigned_r(address byManager, uint8 v, bytes32 r, bytes32 s) view returns (bool);
 function isWhitelisted_r(address x) view returns (bool);
 function isCompetitionActive_r() view returns (bool);
 function getMelonAsset_r() view returns (address);
 function getRegistrantId_r(address x) view returns (uint);
 function getRegistrantFund_r(address x) view returns (address);
 function getCompetitionStatusOfRegistrants_r() view returns (address[], address[], bool[]);
 function getTimeTillEnd_r() view returns (uint);
 function getEtherValue_r(uint amount) view returns (uint);
 function calculatePayout_r(uint payin) view returns (uint);
 function registerForCompetition_r(address fund, uint8 v, bytes32 r, bytes32 s) payable;
 function batchAddToWhitelist_r(uint maxBuyinQuantity, address[] whitelistants);
 function withdrawMln_r(address to, uint amount);
 function claimReward_r();
}
interface ComplianceInterface {
 function isInvestmentPermitted_r(
 address ofParticipant,
 uint256 giveQuantity,
 uint256 shareQuantity
 ) view returns (bool);
 function isRedemptionPermitted_r(
 address ofParticipant,
 uint256 shareQuantity,
 uint256 receiveQuantity
 ) view returns (bool);
}
contract DBC {
 modifier pre_cond(bool condition) {
 require(condition);
 _;
 }
 modifier post_cond(bool condition) {
 _;
 assert(condition);
 }
 modifier invariant(bool condition) {
 require(condition);
 _;
 assert(condition);
 }
}
contract Owned is DBC {
 address public owner;
 function Owned() { owner = msg.sender; }
 function changeOwner_r(address ofNewOwner) pre_cond(isOwner_r()) { owner = ofNewOwner; }
 function isOwner_r() internal returns (bool) { return msg.sender == owner; }
}
contract CompetitionCompliance is ComplianceInterface, DBC, Owned {
 address public competitionAddress;
 function CompetitionCompliance(address ofCompetition) public {
 competitionAddress = ofCompetition;
 }
 function isInvestmentPermitted_r(
 address ofParticipant,
 uint256 giveQuantity,
 uint256 shareQuantity
 )
 view
 returns (bool)
 {
 return competitionAddress == ofParticipant;
 }
 function isRedemptionPermitted_r(
 address ofParticipant,
 uint256 shareQuantity,
 uint256 receiveQuantity
 )
 view
 returns (bool)
 {
 return competitionAddress == ofParticipant;
 }
 function isCompetitionAllowed_r(
 address x
 )
 view
 returns (bool)
 {
 return CompetitionInterface(competitionAddress).isWhitelisted_r(x) && CompetitionInterface(competitionAddress).isCompetitionActive_r();
 }
 function changeCompetitionAddress_r(
 address ofCompetition
 )
 pre_cond(isOwner_r())
 {
 competitionAddress = ofCompetition;
 }
}
contract DSAuthority {
 function canCall_r(
 address src, address dst, bytes4 sig
 ) public view returns (bool);
}
contract DSAuthEvents {
 event LogSetAuthority (address indexed authority);
 event LogSetOwner (address indexed owner);
}
contract DSAuth is DSAuthEvents {
 DSAuthority public authority;
 address public owner;
 function DSAuth() public {
 owner = msg.sender;
 LogSetOwner(msg.sender);
 }
 function setOwner_r(address owner_)
 public
 auth
 {
 owner = owner_;
 LogSetOwner(owner);
 }
 function setAuthority_r(DSAuthority authority_)
 public
 auth
 {
 authority = authority_;
 LogSetAuthority(authority);
 }
 modifier auth {
 require(isAuthorized_r(msg.sender, msg.sig));
 _;
 }
 function isAuthorized_r(address src, bytes4 sig) internal view returns (bool) {
 if (src == address(this)) {
 return true;
 } else if (src == owner) {
 return true;
 } else if (authority == DSAuthority(0)) {
 return false;
 } else {
 return authority.canCall_r(src, this, sig);
 }
 }
}
contract DSExec {
 function tryExec_r( address target_r, bytes calldata_r, uint value_r)
 internal
 returns (bool call_ret)
 {
 return target_r.call.value_r(value_r)(calldata_r);
 }
 function exec_r( address target_r, bytes calldata_r, uint value_r)
 internal
 {
 if(!tryExec_r(target_r, calldata_r, value_r)) {
 revert();
 }
 }
 function exec_r( address t, bytes c )
 internal
 {
 exec_r(t, c, 0);
 }
 function exec_r( address t, uint256 v )
 internal
 {
 bytes memory c; exec_r(t, c, v);
 }
 function tryExec_r( address t, bytes c )
 internal
 returns (bool)
 {
 return tryExec_r(t, c, 0);
 }
 function tryExec_r( address t, uint256 v )
 internal
 returns (bool)
 {
 bytes memory c; return tryExec_r(t, c, v);
 }
}
contract DSMath {
 function add_r(uint x, uint y) internal pure returns (uint z) {
 require((z = x + y) >= x);
 }
 function sub_r(uint x, uint y) internal pure returns (uint z) {
 require((z = x - y) <= x);
 }
 function mul_r(uint x, uint y) internal pure returns (uint z) {
 require(y == 0 || (z = x * y) / y == x);
 }
 function min_r(uint x, uint y) internal pure returns (uint z) {
 return x <= y ? x : y;
 }
 function max_r(uint x, uint y) internal pure returns (uint z) {
 return x >= y ? x : y;
 }
 function imin_r(int x, int y) internal pure returns (int z) {
 return x <= y ? x : y;
 }
 function imax_r(int x, int y) internal pure returns (int z) {
 return x >= y ? x : y;
 }
 uint constant WAD = 10 ** 18;
 uint constant RAY = 10 ** 27;
 function wmul_r(uint x, uint y) internal pure returns (uint z) {
 z = add_r(mul_r(x, y), WAD / 2) / WAD;
 }
 function rmul_r(uint x, uint y) internal pure returns (uint z) {
 z = add_r(mul_r(x, y), RAY / 2) / RAY;
 }
 function wdiv_r(uint x, uint y) internal pure returns (uint z) {
 z = add_r(mul_r(x, WAD), y / 2) / y;
 }
 function rdiv_r(uint x, uint y) internal pure returns (uint z) {
 z = add_r(mul_r(x, RAY), y / 2) / y;
 }
 function rpow_r(uint x, uint n) internal pure returns (uint z) {
 z = n % 2 != 0 ? x : RAY;
 for (n /= 2; n != 0; n /= 2) {
 x = rmul_r(x, x);
 if (n % 2 != 0) {
 z = rmul_r(z, x);
 }
 }
 }
}
contract Asset is DSMath, ERC20Interface {
 mapping (address => uint) balances;
 mapping (address => mapping (address => uint)) allowed;
 uint public _totalSupply;
 function transfer(address _to, uint _value)
 public
 returns (bool success)
 {
 require(balances[msg.sender] >= _value);
 require(balances[_to] + _value >= balances[_to]);
 balances[msg.sender] = sub_r(balances[msg.sender], _value);
 balances[_to] = add_r(balances[_to], _value);
 emit Transfer(msg.sender, _to, _value);
 return true;
 }
 function transferFrom(address _from, address _to, uint _value)
 public
 returns (bool)
 {
 require(_from != address(0));
 require(_to != address(0));
 require(_to != address(this));
 require(balances[_from] >= _value);
 require(allowed[_from][msg.sender] >= _value);
 require(balances[_to] + _value >= balances[_to]);
 balances[_to] += _value;
 balances[_from] -= _value;
 allowed[_from][msg.sender] -= _value;
 emit Transfer(_from, _to, _value);
 return true;
 }
 function approve(address _spender, uint _value) public returns (bool) {
 require(_spender != address(0));
 allowed[msg.sender][_spender] = _value;
 emit Approval(msg.sender, _spender, _value);
 return true;
 }
 function allowance(address _owner, address _spender)
 constant
 public
 returns (uint)
 {
 return allowed[_owner][_spender];
 }
 function balanceOf(address _owner) constant public returns (uint) {
 return balances[_owner];
 }
 function totalSupply() view public returns (uint) {
 return _totalSupply;
 }
}
contract Shares is SharesInterface, Asset {
 bytes32 public name;
 bytes8 public symbol;
 uint public decimal;
 uint public creationTime;
 function Shares(bytes32 _name, bytes8 _symbol, uint _decimal, uint _creationTime) {
 name = _name;
 symbol = _symbol;
 decimal = _decimal;
 creationTime = _creationTime;
 }
 function transfer(address _to, uint _value)
 public
 returns (bool success)
 {
 require(balances[msg.sender] >= _value);
 require(balances[_to] + _value >= balances[_to]);
 balances[msg.sender] = sub_r(balances[msg.sender], _value);
 balances[_to] = add_r(balances[_to], _value);
 emit Transfer(msg.sender, _to, _value);
 return true;
 }
 function getName_r() view returns (bytes32) { return name; }
 function getSymbol_r() view returns (bytes8) { return symbol; }
 function getDecimals_r() view returns (uint) { return decimal; }
 function getCreationTime_r() view returns (uint) { return creationTime; }
 function toSmallestShareUnit_r(uint quantity) view returns (uint) { return mul_r(quantity, 10 ** getDecimals_r()); }
 function toWholeShareUnit_r(uint quantity) view returns (uint) { return quantity / (10 ** getDecimals_r()); }
 function createShares_r(address recipient, uint shareQuantity) internal {
 _totalSupply = add_r(_totalSupply, shareQuantity);
 balances[recipient] = add_r(balances[recipient], shareQuantity);
 emit Created(msg.sender, now, shareQuantity);
 emit Transfer(address(0), recipient, shareQuantity);
 }
 function annihilateShares_r(address recipient, uint shareQuantity) internal {
 _totalSupply = sub_r(_totalSupply, shareQuantity);
 balances[recipient] = sub_r(balances[recipient], shareQuantity);
 emit Annihilated(msg.sender, now, shareQuantity);
 emit Transfer(recipient, address(0), shareQuantity);
 }
}
contract Fund is DSMath, DBC, Owned, Shares, FundInterface {
 event OrderUpdated(address exchange, bytes32 orderId, UpdateType updateType);
 struct Modules {
 CanonicalPriceFeed pricefeed;
 ComplianceInterface compliance;
 RiskMgmtInterface riskmgmt;
 }
 struct Calculations {
 uint gav;
 uint managementFee;
 uint performanceFee;
 uint unclaimedFees;
 uint nav;
 uint highWaterMark;
 uint totalSupply;
 uint timestamp;
 }
 enum UpdateType { make, take, cancel }
 enum RequestStatus { active, cancelled, executed }
 struct Request {
 address participant;
 RequestStatus status;
 address requestAsset;
 uint shareQuantity;
 uint giveQuantity;
 uint receiveQuantity;
 uint timestamp;
 uint atUpdateId;
 }
 struct Exchange {
 address exchange;
 address exchangeAdapter;
 bool takesCustody;
 }
 struct OpenMakeOrder {
 uint id;
 uint expiresAt;
 }
 struct Order {
 address exchangeAddress;
 bytes32 orderId;
 UpdateType updateType;
 address makerAsset;
 address takerAsset;
 uint makerQuantity;
 uint takerQuantity;
 uint timestamp;
 uint fillTakerQuantity;
 }
 uint public constant MAX_FUND_ASSETS = 20;
 uint public constant ORDER_EXPIRATION_TIME = 86400;
 uint public MANAGEMENT_FEE_RATE;
 uint public PERFORMANCE_FEE_RATE;
 address public VERSION;
 Asset public QUOTE_ASSET;
 Modules public modules;
 Exchange[] public exchanges;
 Calculations public atLastUnclaimedFeeAllocation;
 Order[] public orders;
 mapping (address => mapping(address => OpenMakeOrder)) public exchangesToOpenMakeOrders;
 bool public isShutDown;
 Request[] public requests;
 mapping (address => bool) public isInvestAllowed;
 address[] public ownedAssets;
 mapping (address => bool) public isInAssetList;
 mapping (address => bool) public isInOpenMakeOrder;
 function Fund(
 address ofManager,
 bytes32 withName,
 address ofQuoteAsset,
 uint ofManagementFee,
 uint ofPerformanceFee,
 address ofCompliance,
 address ofRiskMgmt,
 address ofPriceFeed,
 address[] ofExchanges,
 address[] ofDefaultAssets
 )
 Shares(withName, "MLNF", 18, now)
 {
 require(ofManagementFee < 10 ** 18);
 require(ofPerformanceFee < 10 ** 18);
 isInvestAllowed[ofQuoteAsset] = true;
 owner = ofManager;
 MANAGEMENT_FEE_RATE = ofManagementFee;
 PERFORMANCE_FEE_RATE = ofPerformanceFee;
 VERSION = msg.sender;
 modules.compliance = ComplianceInterface(ofCompliance);
 modules.riskmgmt = RiskMgmtInterface(ofRiskMgmt);
 modules.pricefeed = CanonicalPriceFeed(ofPriceFeed);
 for (uint i = 0; i < ofExchanges.length; ++i) {
 require(modules.pricefeed.exchangeIsRegistered_r(ofExchanges[i]));
 var (ofExchangeAdapter, takesCustody, ) = modules.pricefeed.getExchangeInformation_r(ofExchanges[i]);
 exchanges.push(Exchange({
 exchange: ofExchanges[i],
 exchangeAdapter: ofExchangeAdapter,
 takesCustody: takesCustody
 }));
 }
 QUOTE_ASSET = Asset(ofQuoteAsset);
 ownedAssets.push(ofQuoteAsset);
 isInAssetList[ofQuoteAsset] = true;
 require(address(QUOTE_ASSET) == modules.pricefeed.getQuoteAsset_r());
 for (uint j = 0; j < ofDefaultAssets.length; j++) {
 require(modules.pricefeed.assetIsRegistered_r(ofDefaultAssets[j]));
 isInvestAllowed[ofDefaultAssets[j]] = true;
 }
 atLastUnclaimedFeeAllocation = Calculations({
 gav: 0,
 managementFee: 0,
 performanceFee: 0,
 unclaimedFees: 0,
 nav: 0,
 highWaterMark: 10 ** getDecimals_r(),
 totalSupply: _totalSupply,
 timestamp: now
 });
 }
 function enableInvestment_r(address[] ofAssets)
 external
 pre_cond(isOwner_r())
 {
 for (uint i = 0; i < ofAssets.length; ++i) {
 require(modules.pricefeed.assetIsRegistered_r(ofAssets[i]));
 isInvestAllowed[ofAssets[i]] = true;
 }
 }
 function disableInvestment_r(address[] ofAssets)
 external
 pre_cond(isOwner_r())
 {
 for (uint i = 0; i < ofAssets.length; ++i) {
 isInvestAllowed[ofAssets[i]] = false;
 }
 }
 function shutDown_r() external pre_cond(msg.sender == VERSION) { isShutDown = true; }
 function requestInvestment_r(
 uint giveQuantity,
 uint shareQuantity,
 address investmentAsset
 )
 external
 pre_cond(!isShutDown)
 pre_cond(isInvestAllowed[investmentAsset])
 pre_cond(modules.compliance.isInvestmentPermitted_r(msg.sender, giveQuantity, shareQuantity))
 {
 requests.push(Request({
 participant: msg.sender,
 status: RequestStatus.active,
 requestAsset: investmentAsset,
 shareQuantity: shareQuantity,
 giveQuantity: giveQuantity,
 receiveQuantity: shareQuantity,
 timestamp: now,
 atUpdateId: modules.pricefeed.getLastUpdateId_r()
 }));
 emit RequestUpdated(getLastRequestId_r());
 }
 function executeRequest_r(uint id)
 external
 pre_cond(!isShutDown)
 pre_cond(requests[id].status == RequestStatus.active)
 pre_cond(
 _totalSupply == 0 ||
 (
 now >= add_r(requests[id].timestamp, modules.pricefeed.getInterval_r()) &&
 modules.pricefeed.getLastUpdateId_r() >= add_r(requests[id].atUpdateId, 2)
 )
 )
 {
 Request request = requests[id];
 var (isRecent, , ) =
 modules.pricefeed.getPriceInfo_r(address(request.requestAsset));
 require(isRecent);
 uint costQuantity = toWholeShareUnit_r(mul_r(request.shareQuantity, calcSharePriceAndAllocateFees_r()));
 if (request.requestAsset != address(QUOTE_ASSET)) {
 var (isPriceRecent, invertedRequestAssetPrice, requestAssetDecimal) = modules.pricefeed.getInvertedPriceInfo_r(request.requestAsset);
 if (!isPriceRecent) {
 revert();
 }
 costQuantity = mul_r(costQuantity, invertedRequestAssetPrice) / 10 ** requestAssetDecimal;
 }
 if (
 isInvestAllowed[request.requestAsset] &&
 costQuantity <= request.giveQuantity
 ) {
 request.status = RequestStatus.executed;
 require(AssetInterface(request.requestAsset).transferFrom(request.participant, address(this), costQuantity));
 createShares_r(request.participant, request.shareQuantity);
 if (!isInAssetList[request.requestAsset]) {
 ownedAssets.push(request.requestAsset);
 isInAssetList[request.requestAsset] = true;
 }
 } else {
 revert();
 }
 }
 function cancelRequest_r(uint id)
 external
 pre_cond(requests[id].status == RequestStatus.active)
 pre_cond(requests[id].participant == msg.sender || isShutDown)
 {
 requests[id].status = RequestStatus.cancelled;
 }
 function redeemAllOwnedAssets_r(uint shareQuantity)
 external
 returns (bool success)
 {
 return emergencyRedeem_r(shareQuantity, ownedAssets);
 }
 function callOnExchange_r(
 uint exchangeIndex,
 bytes4 method,
 address[5] orderAddresses,
 uint[8] orderValues,
 bytes32 identifier,
 uint8 v,
 bytes32 r,
 bytes32 s
 )
 external
 {
 require(
 modules.pricefeed.exchangeMethodIsAllowed_r(
 exchanges[exchangeIndex].exchange, method
 )
 );
 require(
 exchanges[exchangeIndex].exchangeAdapter.delegatecall(
 method, exchanges[exchangeIndex].exchange,
 orderAddresses, orderValues, identifier, v, r, s
 )
 );
 }
 function addOpenMakeOrder_r(
 address ofExchange,
 address ofSellAsset,
 uint orderId
 )
 pre_cond(msg.sender == address(this))
 {
 isInOpenMakeOrder[ofSellAsset] = true;
 exchangesToOpenMakeOrders[ofExchange][ofSellAsset].id = orderId;
 exchangesToOpenMakeOrders[ofExchange][ofSellAsset].expiresAt = add_r(now, ORDER_EXPIRATION_TIME);
 }
 function removeOpenMakeOrder_r(
 address ofExchange,
 address ofSellAsset
 )
 pre_cond(msg.sender == address(this))
 {
 delete exchangesToOpenMakeOrders[ofExchange][ofSellAsset];
 }
 function orderUpdateHook_r(
 address ofExchange,
 bytes32 orderId,
 UpdateType updateType,
 address[2] orderAddresses,
 uint[3] orderValues
 )
 pre_cond(msg.sender == address(this))
 {
 if (updateType == UpdateType.make || updateType == UpdateType.take) {
 orders.push(Order({
 exchangeAddress: ofExchange,
 orderId: orderId,
 updateType: updateType,
 makerAsset: orderAddresses[0],
 takerAsset: orderAddresses[1],
 makerQuantity: orderValues[0],
 takerQuantity: orderValues[1],
 timestamp: block.timestamp,
 fillTakerQuantity: orderValues[2]
 }));
 }
 emit OrderUpdated(ofExchange, orderId, updateType);
 }
 function calcGav_r() returns (uint gav) {
 uint[] memory allAssetHoldings = new uint[](ownedAssets.length);
 uint[] memory allAssetPrices = new uint[](ownedAssets.length);
 address[] memory tempOwnedAssets;
 tempOwnedAssets = ownedAssets;
 delete ownedAssets;
 for (uint i = 0; i < tempOwnedAssets.length; ++i) {
 address ofAsset = tempOwnedAssets[i];
 uint assetHoldings = add_r(
 uint(AssetInterface(ofAsset).balanceOf(address(this))),
 quantityHeldInCustodyOfExchange_r(ofAsset)
 );
 var (isRecent, assetPrice, assetDecimals) = modules.pricefeed.getPriceInfo_r(ofAsset);
 if (!isRecent) {
 revert();
 }
 allAssetHoldings[i] = assetHoldings;
 allAssetPrices[i] = assetPrice;
 gav = add_r(gav, mul_r(assetHoldings, assetPrice) / (10 ** uint256(assetDecimals)));
 if (assetHoldings != 0 || ofAsset == address(QUOTE_ASSET) || isInOpenMakeOrder[ofAsset]) {
 ownedAssets.push(ofAsset);
 } else {
 isInAssetList[ofAsset] = false;
 }
 }
 emit PortfolioContent(tempOwnedAssets, allAssetHoldings, allAssetPrices);
 }
 function addAssetToOwnedAssets_r (address ofAsset)
 public
 pre_cond(isOwner_r() || msg.sender == address(this))
 {
 isInOpenMakeOrder[ofAsset] = true;
 if (!isInAssetList[ofAsset]) {
 ownedAssets.push(ofAsset);
 isInAssetList[ofAsset] = true;
 }
 }
 function calcUnclaimedFees_r(uint gav)
 view
 returns (
 uint managementFee,
 uint performanceFee,
 uint unclaimedFees)
 {
 uint timePassed = sub_r(now, atLastUnclaimedFeeAllocation.timestamp);
 uint gavPercentage = mul_r(timePassed, gav) / (1 years);
 managementFee = wmul_r(gavPercentage, MANAGEMENT_FEE_RATE);
 uint valuePerShareExclMgmtFees = _totalSupply > 0 ? calcValuePerShare_r(sub_r(gav, managementFee), _totalSupply) : toSmallestShareUnit_r(1);
 if (valuePerShareExclMgmtFees > atLastUnclaimedFeeAllocation.highWaterMark) {
 uint gainInSharePrice = sub_r(valuePerShareExclMgmtFees, atLastUnclaimedFeeAllocation.highWaterMark);
 uint investmentProfits = wmul_r(gainInSharePrice, _totalSupply);
 performanceFee = wmul_r(investmentProfits, PERFORMANCE_FEE_RATE);
 }
 unclaimedFees = add_r(managementFee, performanceFee);
 }
 function calcNav_r(uint gav, uint unclaimedFees)
 view
 returns (uint nav)
 {
 nav = sub_r(gav, unclaimedFees);
 }
 function calcValuePerShare_r(uint totalValue, uint numShares)
 view
 pre_cond(numShares > 0)
 returns (uint valuePerShare)
 {
 valuePerShare = toSmallestShareUnit_r(totalValue) / numShares;
 }
 function performCalculations_r()
 view
 returns (
 uint gav,
 uint managementFee,
 uint performanceFee,
 uint unclaimedFees,
 uint feesShareQuantity,
 uint nav,
 uint sharePrice
 )
 {
 gav = calcGav_r();
 (managementFee, performanceFee, unclaimedFees) = calcUnclaimedFees_r(gav);
 nav = calcNav_r(gav, unclaimedFees);
 feesShareQuantity = (gav == 0) ? 0 : mul_r(_totalSupply, unclaimedFees) / gav;
 uint totalSupplyAccountingForFees = add_r(_totalSupply, feesShareQuantity);
 sharePrice = _totalSupply > 0 ? calcValuePerShare_r(gav, totalSupplyAccountingForFees) : toSmallestShareUnit_r(1);
 }
 function calcSharePriceAndAllocateFees_r() public returns (uint)
 {
 var (
 gav,
 managementFee,
 performanceFee,
 unclaimedFees,
 feesShareQuantity,
 nav,
 sharePrice
 ) = performCalculations_r();
 createShares_r(owner, feesShareQuantity);
 uint highWaterMark = atLastUnclaimedFeeAllocation.highWaterMark >= sharePrice ? atLastUnclaimedFeeAllocation.highWaterMark : sharePrice;
 atLastUnclaimedFeeAllocation = Calculations({
 gav: gav,
 managementFee: managementFee,
 performanceFee: performanceFee,
 unclaimedFees: unclaimedFees,
 nav: nav,
 highWaterMark: highWaterMark,
 totalSupply: _totalSupply,
 timestamp: now
 });
 emit FeesConverted(now, feesShareQuantity, unclaimedFees);
 emit CalculationUpdate(now, managementFee, performanceFee, nav, sharePrice, _totalSupply);
 return sharePrice;
 }
 function emergencyRedeem_r(uint shareQuantity, address[] requestedAssets)
 public
 pre_cond(balances[msg.sender] >= shareQuantity)
 returns (bool)
 {
 address ofAsset;
 uint[] memory ownershipQuantities = new uint[](requestedAssets.length);
 address[] memory redeemedAssets = new address[](requestedAssets.length);
 for (uint i = 0; i < requestedAssets.length; ++i) {
 ofAsset = requestedAssets[i];
 require(isInAssetList[ofAsset]);
 for (uint j = 0; j < redeemedAssets.length; j++) {
 if (ofAsset == redeemedAssets[j]) {
 revert();
 }
 }
 redeemedAssets[i] = ofAsset;
 uint assetHoldings = add_r(
 uint(AssetInterface(ofAsset).balanceOf(address(this))),
 quantityHeldInCustodyOfExchange_r(ofAsset)
 );
 if (assetHoldings == 0) continue;
 ownershipQuantities[i] = mul_r(assetHoldings, shareQuantity) / _totalSupply;
 if (uint(AssetInterface(ofAsset).balanceOf(address(this))) < ownershipQuantities[i]) {
 isShutDown = true;
 emit ErrorMessage("CRITICAL ERR: Not enough assetHoldings for owed ownershipQuantitiy");
 return false;
 }
 }
 annihilateShares_r(msg.sender, shareQuantity);
 for (uint k = 0; k < requestedAssets.length; ++k) {
 ofAsset = requestedAssets[k];
 if (ownershipQuantities[k] == 0) {
 continue;
 } else if (!AssetInterface(ofAsset).transfer(msg.sender, ownershipQuantities[k])) {
 revert();
 }
 }
 emit Redeemed(msg.sender, now, shareQuantity);
 return true;
 }
 function quantityHeldInCustodyOfExchange_r(address ofAsset) returns (uint) {
 uint totalSellQuantity;
 uint totalSellQuantityInApprove;
 for (uint i; i < exchanges.length; i++) {
 if (exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset].id == 0) {
 continue;
 }
 var (sellAsset, , sellQuantity, ) = GenericExchangeInterface(exchanges[i].exchangeAdapter).getOrder_r(exchanges[i].exchange, exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset].id);
 if (sellQuantity == 0) {
 delete exchangesToOpenMakeOrders[exchanges[i].exchange][ofAsset];
 }
 totalSellQuantity = add_r(totalSellQuantity, sellQuantity);
 if (!exchanges[i].takesCustody) {
 totalSellQuantityInApprove += sellQuantity;
 }
 }
 if (totalSellQuantity == 0) {
 isInOpenMakeOrder[sellAsset] = false;
 }
 return sub_r(totalSellQuantity, totalSellQuantityInApprove);
 }
 function calcSharePrice_r() view returns (uint sharePrice) {
 (, , , , , sharePrice) = performCalculations_r();
 return sharePrice;
 }
 function getModules_r() view returns (address, address, address) {
 return (
 address(modules.pricefeed),
 address(modules.compliance),
 address(modules.riskmgmt)
 );
 }
 function getLastRequestId_r() view returns (uint) { return requests.length - 1; }
 function getLastOrderIndex_r() view returns (uint) { return orders.length - 1; }
 function getManager_r() view returns (address) { return owner; }
 function getOwnedAssetsLength_r() view returns (uint) { return ownedAssets.length; }
 function getExchangeInfo_r() view returns (address[], address[], bool[]) {
 address[] memory ofExchanges = new address[](exchanges.length);
 address[] memory ofAdapters = new address[](exchanges.length);
 bool[] memory takesCustody = new bool[](exchanges.length);
 for (uint i = 0; i < exchanges.length; i++) {
 ofExchanges[i] = exchanges[i].exchange;
 ofAdapters[i] = exchanges[i].exchangeAdapter;
 takesCustody[i] = exchanges[i].takesCustody;
 }
 return (ofExchanges, ofAdapters, takesCustody);
 }
 function orderExpired_r(address ofExchange, address ofAsset) view returns (bool) {
 uint expiryTime = exchangesToOpenMakeOrders[ofExchange][ofAsset].expiresAt;
 require(expiryTime > 0);
 return block.timestamp >= expiryTime;
 }
 function getOpenOrderInfo_r(address ofExchange, address ofAsset) view returns (uint, uint) {
 OpenMakeOrder order = exchangesToOpenMakeOrders[ofExchange][ofAsset];
 return (order.id, order.expiresAt);
 }
}
contract Competition is CompetitionInterface, DSMath, DBC, Owned {
 struct Registrant {
 address fund;
 address registrant;
 bool hasSigned;
 uint buyinQuantity;
 uint payoutQuantity;
 bool isRewarded;
 }
 struct RegistrantId {
 uint id;
 bool exists;
 }
 bytes public constant TERMS_AND_CONDITIONS = hex"12208E21FD34B8B2409972D30326D840C9D747438A118580D6BA8C0735ED53810491";
 uint public MELON_BASE_UNIT = 10 ** 18;
 address public custodian;
 uint public startTime;
 uint public endTime;
 uint public payoutRate;
 uint public bonusRate;
 uint public totalMaxBuyin;
 uint public currentTotalBuyin;
 uint public maxRegistrants;
 uint public prizeMoneyAsset;
 uint public prizeMoneyQuantity;
 address public MELON_ASSET;
 ERC20Interface public MELON_CONTRACT;
 address public COMPETITION_VERSION;
 Registrant[] public registrants;
 mapping (address => address) public registeredFundToRegistrants;
 mapping(address => RegistrantId) public registrantToRegistrantIds;
 mapping(address => uint) public whitelistantToMaxBuyin;
 event Register(uint withId, address fund, address manager);
 function Competition(
 address ofMelonAsset,
 address ofCompetitionVersion,
 address ofCustodian,
 uint ofStartTime,
 uint ofEndTime,
 uint ofPayoutRate,
 uint ofTotalMaxBuyin,
 uint ofMaxRegistrants
 ) {
 MELON_ASSET = ofMelonAsset;
 MELON_CONTRACT = ERC20Interface(MELON_ASSET);
 COMPETITION_VERSION = ofCompetitionVersion;
 custodian = ofCustodian;
 startTime = ofStartTime;
 endTime = ofEndTime;
 payoutRate = ofPayoutRate;
 totalMaxBuyin = ofTotalMaxBuyin;
 maxRegistrants = ofMaxRegistrants;
 }
 function termsAndConditionsAreSigned_r(address byManager, uint8 v, bytes32 r, bytes32 s) view returns (bool) {
 return ecrecover(
 keccak256("\x19Ethereum Signed Message:\n34", TERMS_AND_CONDITIONS),
 v,
 r,
 s
 ) == byManager;
 }
 function isWhitelisted_r(address x) view returns (bool) { return whitelistantToMaxBuyin[x] > 0; }
 function isCompetitionActive_r() view returns (bool) { return now >= startTime && now < endTime; }
 function getMelonAsset_r() view returns (address) { return MELON_ASSET; }
 function getRegistrantId_r(address x) view returns (uint) { return registrantToRegistrantIds[x].id; }
 function getRegistrantFund_r(address x) view returns (address) { return registrants[getRegistrantId_r(x)].fund; }
 function getTimeTillEnd_r() view returns (uint) {
 if (now > endTime) {
 return 0;
 }
 return sub_r(endTime, now);
 }
 function getEtherValue_r(uint amount) view returns (uint) {
 address feedAddress = Version(COMPETITION_VERSION).CANONICAL_PRICEFEED();
 var (isRecent, price, ) = CanonicalPriceFeed(feedAddress).getPriceInfo_r(MELON_ASSET);
 if (!isRecent) {
 revert();
 }
 return mul_r(price, amount) / 10 ** 18;
 }
 function calculatePayout_r(uint payin) view returns (uint payoutQuantity) {
 payoutQuantity = mul_r(payin, payoutRate) / 10 ** 18;
 }
 function getCompetitionStatusOfRegistrants_r()
 view
 returns(
 address[],
 address[],
 bool[]
 )
 {
 address[] memory fundAddrs = new address[](registrants.length);
 address[] memory fundRegistrants = new address[](registrants.length);
 bool[] memory isRewarded = new bool[](registrants.length);
 for (uint i = 0; i < registrants.length; i++) {
 fundAddrs[i] = registrants[i].fund;
 fundRegistrants[i] = registrants[i].registrant;
 isRewarded[i] = registrants[i].isRewarded;
 }
 return (fundAddrs, fundRegistrants, isRewarded);
 }
 function registerForCompetition_r(
 address fund,
 uint8 v,
 bytes32 r,
 bytes32 s
 )
 payable
 pre_cond(isCompetitionActive_r() && !Version(COMPETITION_VERSION).isShutDown())
 pre_cond(termsAndConditionsAreSigned_r(msg.sender, v, r, s) && isWhitelisted_r(msg.sender))
 {
 require(registeredFundToRegistrants[fund] == address(0) && registrantToRegistrantIds[msg.sender].exists == false);
 require(add_r(currentTotalBuyin, msg.value_r) <= totalMaxBuyin && registrants.length < maxRegistrants);
 require(msg.value_r <= whitelistantToMaxBuyin[msg.sender]);
 require(Version(COMPETITION_VERSION).getFundByManager_r(msg.sender) == fund);
 uint payoutQuantity = calculatePayout_r(msg.value_r);
 registeredFundToRegistrants[fund] = msg.sender;
 registrantToRegistrantIds[msg.sender] = RegistrantId({id: registrants.length, exists: true});
 currentTotalBuyin = add_r(currentTotalBuyin, msg.value_r);
 FundInterface fundContract = FundInterface(fund);
 MELON_CONTRACT.approve(fund, payoutQuantity);
 fundContract.requestInvestment_r(payoutQuantity, getEtherValue_r(payoutQuantity), MELON_ASSET);
 fundContract.executeRequest_r(fundContract.getLastRequestId_r());
 custodian.transfer(msg.value_r);
 emit Register(registrants.length, fund, msg.sender);
 registrants.push(Registrant({
 fund: fund,
 registrant: msg.sender,
 hasSigned: true,
 buyinQuantity: msg.value_r,
 payoutQuantity: payoutQuantity,
 isRewarded: false
 }));
 }
 function batchAddToWhitelist_r(
 uint maxBuyinQuantity,
 address[] whitelistants
 )
 pre_cond(isOwner_r())
 pre_cond(now < endTime)
 {
 for (uint i = 0; i < whitelistants.length; ++i) {
 whitelistantToMaxBuyin[whitelistants[i]] = maxBuyinQuantity;
 }
 }
 function withdrawMln_r(address to, uint amount)
 pre_cond(isOwner_r())
 {
 MELON_CONTRACT.transfer(to, amount);
 }
 function claimReward_r()
 pre_cond(getRegistrantFund_r(msg.sender) != address(0))
 {
 require(block.timestamp >= endTime || Version(COMPETITION_VERSION).isShutDown());
 Registrant registrant = registrants[getRegistrantId_r(msg.sender)];
 require(registrant.isRewarded == false);
 registrant.isRewarded = true;
 uint balance = AssetInterface(registrant.fund).balanceOf(address(this));
 require(AssetInterface(registrant.fund).transfer(registrant.registrant, balance));
 emit ClaimReward(msg.sender, registrant.fund, balance);
 }
}
contract DSNote {
 event LogNote(
 bytes4 indexed sig,
 address indexed guy,
 bytes32 indexed foo,
 bytes32 indexed bar,
 uint wad,
 bytes fax
 ) anonymous;
 modifier note {
 bytes32 foo;
 bytes32 bar;
 assembly {
 foo := calldataload(4)
 bar := calldataload(36)
 }
 LogNote(msg.sig, msg.sender, foo, bar, msg.value_r, msg.data);
 _;
 }
}
contract DSGroup is DSExec, DSNote {
 address[] public members;
 uint public quorum;
 uint public window;
 uint public actionCount;
 mapping (uint => Action) public actions;
 mapping (uint => mapping (address => bool)) public confirmedBy;
 mapping (address => bool) public isMember;
 event Proposed (uint id, bytes calldata_r);
 event Confirmed (uint id, address member);
 event Triggered (uint id);
 struct Action {
 address target_r;
 bytes calldata_r;
 uint value_r;
 uint confirmations_r;
 uint deadline_r;
 bool triggered_r;
 }
 function DSGroup(
 address[] members_,
 uint quorum_,
 uint window_
 ) {
 members = members_;
 quorum = quorum_;
 window = window_;
 for (uint i = 0; i < members.length; i++) {
 isMember[members[i]] = true;
 }
 }
 function memberCount_r() constant returns (uint) {
 return members.length;
 }
 function target_r(uint id) constant returns (address) {
 return actions[id].target_r;
 }
 function calldata_r(uint id) constant returns (bytes) {
 return actions[id].calldata_r;
 }
 function value_r(uint id) constant returns (uint) {
 return actions[id].value_r;
 }
 function confirmations_r(uint id) constant returns (uint) {
 return actions[id].confirmations_r;
 }
 function deadline_r(uint id) constant returns (uint) {
 return actions[id].deadline_r;
 }
 function triggered_r(uint id) constant returns (bool) {
 return actions[id].triggered_r;
 }
 function confirmed_r(uint id) constant returns (bool) {
 return confirmations_r(id) >= quorum;
 }
 function expired_r(uint id) constant returns (bool) {
 return now > deadline_r(id);
 }
 function deposit_r() note payable {
 }
 function propose_r(
 address target_r,
 bytes calldata_r,
 uint value_r
 ) onlyMembers note returns (uint id) {
 id = ++actionCount;
 actions[id].target_r = target_r;
 actions[id].calldata_r = calldata_r;
 actions[id].value_r = value_r;
 actions[id].deadline_r = now + window;
 Proposed(id, calldata_r);
 }
 function confirm_r(uint id) onlyMembers onlyActive(id) note {
 assert(!confirmedBy[id][msg.sender]);
 confirmedBy[id][msg.sender] = true;
 actions[id].confirmations_r++;
 Confirmed(id, msg.sender);
 }
 function trigger_r(uint id) onlyMembers onlyActive(id) note {
 assert(confirmed_r(id));
 actions[id].triggered_r = true;
 exec_r(actions[id].target_r, actions[id].calldata_r, actions[id].value_r);
 Triggered(id);
 }
 modifier onlyMembers {
 assert(isMember[msg.sender]);
 _;
 }
 modifier onlyActive(uint id) {
 assert(!expired_r(id));
 assert(!triggered_r(id));
 _;
 }
 function getInfo_r() constant returns (
 uint quorum_,
 uint memberCount_r,
 uint window_,
 uint actionCount_
 ) {
 return (quorum, members.length, window, actionCount);
 }
 function getActionStatus_r(uint id) constant returns (
 uint confirmations_r,
 uint deadline_r,
 bool triggered_r,
 address target_r,
 uint value_r
 ) {
 return (
 actions[id].confirmations_r,
 actions[id].deadline_r,
 actions[id].triggered_r,
 actions[id].target_r,
 actions[id].value_r
 );
 }
}
contract DSGroupFactory is DSNote {
 mapping (address => bool) public isGroup;
 function newGroup_r(
 address[] members,
 uint quorum,
 uint window
 ) note returns (DSGroup group) {
 group = new DSGroup(members, quorum, window);
 isGroup[group] = true;
 }
}
contract DSThing is DSAuth, DSNote, DSMath {
 function S_r(string s) internal pure returns (bytes4) {
 return bytes4(keccak256(s));
 }
}
interface GenericExchangeInterface {
 event OrderUpdated(uint id);
 function makeOrder_r(
 address onExchange,
 address sellAsset,
 address buyAsset,
 uint sellQuantity,
 uint buyQuantity
 ) external returns (uint);
 function takeOrder_r(address onExchange, uint id, uint quantity) external returns (bool);
 function cancelOrder_r(address onExchange, uint id) external returns (bool);
 function isApproveOnly_r() view returns (bool);
 function getLastOrderId_r(address onExchange) view returns (uint);
 function isActive_r(address onExchange, uint id) view returns (bool);
 function getOwner_r(address onExchange, uint id) view returns (address);
 function getOrder_r(address onExchange, uint id) view returns (address, address, uint, uint);
 function getTimestamp_r(address onExchange, uint id) view returns (uint);
}
contract CanonicalRegistrar is DSThing, DBC {
 struct Asset {
 bool exists;
 bytes32 name;
 bytes8 symbol;
 uint decimals;
 string url;
 string ipfsHash;
 address breakIn;
 address breakOut;
 uint[] standards;
 bytes4[] functionSignatures;
 uint price;
 uint timestamp;
 }
 struct Exchange {
 bool exists;
 address adapter;
 bool takesCustody;
 bytes4[] functionSignatures;
 }
 mapping (address => Asset) public assetInformation;
 address[] public registeredAssets;
 mapping (address => Exchange) public exchangeInformation;
 address[] public registeredExchanges;
 function registerAsset_r(
 address ofAsset,
 bytes32 inputName,
 bytes8 inputSymbol,
 uint inputDecimals,
 string inputUrl,
 string inputIpfsHash,
 address[2] breakInBreakOut,
 uint[] inputStandards,
 bytes4[] inputFunctionSignatures
 )
 auth
 pre_cond(!assetInformation[ofAsset].exists)
 {
 assetInformation[ofAsset].exists = true;
 registeredAssets.push(ofAsset);
 updateAsset_r(
 ofAsset,
 inputName,
 inputSymbol,
 inputDecimals,
 inputUrl,
 inputIpfsHash,
 breakInBreakOut,
 inputStandards,
 inputFunctionSignatures
 );
 assert(assetInformation[ofAsset].exists);
 }
 function registerExchange_r(
 address ofExchange,
 address ofExchangeAdapter,
 bool inputTakesCustody,
 bytes4[] inputFunctionSignatures
 )
 auth
 pre_cond(!exchangeInformation[ofExchange].exists)
 {
 exchangeInformation[ofExchange].exists = true;
 registeredExchanges.push(ofExchange);
 updateExchange_r(
 ofExchange,
 ofExchangeAdapter,
 inputTakesCustody,
 inputFunctionSignatures
 );
 assert(exchangeInformation[ofExchange].exists);
 }
 function updateAsset_r(
 address ofAsset,
 bytes32 inputName,
 bytes8 inputSymbol,
 uint inputDecimals,
 string inputUrl,
 string inputIpfsHash,
 address[2] ofBreakInBreakOut,
 uint[] inputStandards,
 bytes4[] inputFunctionSignatures
 )
 auth
 pre_cond(assetInformation[ofAsset].exists)
 {
 Asset asset = assetInformation[ofAsset];
 asset.name = inputName;
 asset.symbol = inputSymbol;
 asset.decimals = inputDecimals;
 asset.url = inputUrl;
 asset.ipfsHash = inputIpfsHash;
 asset.breakIn = ofBreakInBreakOut[0];
 asset.breakOut = ofBreakInBreakOut[1];
 asset.standards = inputStandards;
 asset.functionSignatures = inputFunctionSignatures;
 }
 function updateExchange_r(
 address ofExchange,
 address ofExchangeAdapter,
 bool inputTakesCustody,
 bytes4[] inputFunctionSignatures
 )
 auth
 pre_cond(exchangeInformation[ofExchange].exists)
 {
 Exchange exchange = exchangeInformation[ofExchange];
 exchange.adapter = ofExchangeAdapter;
 exchange.takesCustody = inputTakesCustody;
 exchange.functionSignatures = inputFunctionSignatures;
 }
 function removeAsset_r(
 address ofAsset,
 uint assetIndex
 )
 auth
 pre_cond(assetInformation[ofAsset].exists)
 {
 require(registeredAssets[assetIndex] == ofAsset);
 delete assetInformation[ofAsset];
 delete registeredAssets[assetIndex];
 for (uint i = assetIndex; i < registeredAssets.length-1; i++) {
 registeredAssets[i] = registeredAssets[i+1];
 }
 registeredAssets.length--;
 assert(!assetInformation[ofAsset].exists);
 }
 function removeExchange_r(
 address ofExchange,
 uint exchangeIndex
 )
 auth
 pre_cond(exchangeInformation[ofExchange].exists)
 {
 require(registeredExchanges[exchangeIndex] == ofExchange);
 delete exchangeInformation[ofExchange];
 delete registeredExchanges[exchangeIndex];
 for (uint i = exchangeIndex; i < registeredExchanges.length-1; i++) {
 registeredExchanges[i] = registeredExchanges[i+1];
 }
 registeredExchanges.length--;
 assert(!exchangeInformation[ofExchange].exists);
 }
 function getName_r(address ofAsset) view returns (bytes32) { return assetInformation[ofAsset].name; }
 function getSymbol_r(address ofAsset) view returns (bytes8) { return assetInformation[ofAsset].symbol; }
 function getDecimals_r(address ofAsset) view returns (uint) { return assetInformation[ofAsset].decimals; }
 function assetIsRegistered_r(address ofAsset) view returns (bool) { return assetInformation[ofAsset].exists; }
 function getRegisteredAssets_r() view returns (address[]) { return registeredAssets; }
 function assetMethodIsAllowed_r(
 address ofAsset, bytes4 querySignature
 )
 returns (bool)
 {
 bytes4[] memory signatures = assetInformation[ofAsset].functionSignatures;
 for (uint i = 0; i < signatures.length; i++) {
 if (signatures[i] == querySignature) {
 return true;
 }
 }
 return false;
 }
 function exchangeIsRegistered_r(address ofExchange) view returns (bool) { return exchangeInformation[ofExchange].exists; }
 function getRegisteredExchanges_r() view returns (address[]) { return registeredExchanges; }
 function getExchangeInformation_r(address ofExchange)
 view
 returns (address, bool)
 {
 Exchange exchange = exchangeInformation[ofExchange];
 return (
 exchange.adapter,
 exchange.takesCustody
 );
 }
 function getExchangeFunctionSignatures_r(address ofExchange)
 view
 returns (bytes4[])
 {
 return exchangeInformation[ofExchange].functionSignatures;
 }
 function exchangeMethodIsAllowed_r(
 address ofExchange, bytes4 querySignature
 )
 returns (bool)
 {
 bytes4[] memory signatures = exchangeInformation[ofExchange].functionSignatures;
 for (uint i = 0; i < signatures.length; i++) {
 if (signatures[i] == querySignature) {
 return true;
 }
 }
 return false;
 }
}
interface SimplePriceFeedInterface {
 event PriceUpdated(bytes32 hash);
 function update_r(address[] ofAssets, uint[] newPrices) external;
 function getQuoteAsset_r() view returns (address);
 function getLastUpdateId_r() view returns (uint);
 function getPrice_r(address ofAsset) view returns (uint price, uint timestamp);
 function getPrices_r(address[] ofAssets) view returns (uint[] prices, uint[] timestamps);
}
contract SimplePriceFeed is SimplePriceFeedInterface, DSThing, DBC {
 struct Data {
 uint price;
 uint timestamp;
 }
 mapping(address => Data) public assetsToPrices;
 address public QUOTE_ASSET;
 uint public updateId;
 CanonicalRegistrar public registrar;
 CanonicalPriceFeed public superFeed;
 function SimplePriceFeed(
 address ofRegistrar,
 address ofQuoteAsset,
 address ofSuperFeed
 ) {
 registrar = CanonicalRegistrar(ofRegistrar);
 QUOTE_ASSET = ofQuoteAsset;
 superFeed = CanonicalPriceFeed(ofSuperFeed);
 }
 function update_r(address[] ofAssets, uint[] newPrices)
 external
 auth
 {
 _updatePrices_r(ofAssets, newPrices);
 }
 function getQuoteAsset_r() view returns (address) { return QUOTE_ASSET; }
 function getLastUpdateId_r() view returns (uint) { return updateId; }
 function getPrice_r(address ofAsset)
 view
 returns (uint price, uint timestamp)
 {
 Data data = assetsToPrices[ofAsset];
 return (data.price, data.timestamp);
 }
 function getPrices_r(address[] ofAssets)
 view
 returns (uint[], uint[])
 {
 uint[] memory prices = new uint[](ofAssets.length);
 uint[] memory timestamps = new uint[](ofAssets.length);
 for (uint i; i < ofAssets.length; i++) {
 var (price, timestamp) = getPrice_r(ofAssets[i]);
 prices[i] = price;
 timestamps[i] = timestamp;
 }
 return (prices, timestamps);
 }
 function _updatePrices_r(address[] ofAssets, uint[] newPrices)
 internal
 pre_cond(ofAssets.length == newPrices.length)
 {
 updateId++;
 for (uint i = 0; i < ofAssets.length; ++i) {
 require(registrar.assetIsRegistered_r(ofAssets[i]));
 require(assetsToPrices[ofAssets[i]].timestamp != now);
 assetsToPrices[ofAssets[i]].timestamp = now;
 assetsToPrices[ofAssets[i]].price = newPrices[i];
 }
 emit PriceUpdated(keccak256(ofAssets, newPrices));
 }
}
contract StakingPriceFeed is SimplePriceFeed {
 OperatorStaking public stakingContract;
 AssetInterface public stakingToken;
 function StakingPriceFeed(
 address ofRegistrar,
 address ofQuoteAsset,
 address ofSuperFeed
 )
 SimplePriceFeed(ofRegistrar, ofQuoteAsset, ofSuperFeed)
 {
 stakingContract = OperatorStaking(ofSuperFeed);
 stakingToken = AssetInterface(stakingContract.stakingToken());
 }
 function depositStake_r(uint amount, bytes data)
 external
 auth
 {
 require(stakingToken.transferFrom(msg.sender, address(this), amount));
 require(stakingToken.approve(stakingContract, amount));
 stakingContract.stake_r(amount, data);
 }
 function unstake_r(uint amount, bytes data)
 external
 auth
 {
 stakingContract.unstake_r(amount, data);
 }
 function withdrawStake_r()
 external
 auth
 {
 uint amountToWithdraw = stakingContract.stakeToWithdraw(address(this));
 stakingContract.withdrawStake_r();
 require(stakingToken.transfer(msg.sender, amountToWithdraw));
 }
}
interface RiskMgmtInterface {
 function isMakePermitted_r(
 uint orderPrice,
 uint referencePrice,
 address sellAsset,
 address buyAsset,
 uint sellQuantity,
 uint buyQuantity
 ) view returns (bool);
 function isTakePermitted_r(
 uint orderPrice,
 uint referencePrice,
 address sellAsset,
 address buyAsset,
 uint sellQuantity,
 uint buyQuantity
 ) view returns (bool);
}
contract OperatorStaking is DBC {
 event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
 event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);
 event StakeBurned(address indexed user, uint256 amount, bytes data);
 struct StakeData {
 uint amount;
 address staker;
 }
 struct Node {
 StakeData data;
 uint prev;
 uint next;
 }
 Node[] internal stakeNodes;
 uint public minimumStake;
 uint public numOperators;
 uint public withdrawalDelay;
 mapping (address => bool) public isRanked;
 mapping (address => uint) public latestUnstakeTime;
 mapping (address => uint) public stakeToWithdraw;
 mapping (address => uint) public stakedAmounts;
 uint public numStakers;
 AssetInterface public stakingToken;
 function OperatorStaking(
 AssetInterface _stakingToken,
 uint _minimumStake,
 uint _numOperators,
 uint _withdrawalDelay
 )
 public
 {
 require(address(_stakingToken) != address(0));
 stakingToken = _stakingToken;
 minimumStake = _minimumStake;
 numOperators = _numOperators;
 withdrawalDelay = _withdrawalDelay;
 StakeData memory temp = StakeData({ amount: 0, staker: address(0) });
 stakeNodes.push(Node(temp, 0, 0));
 }
 function stake_r(
 uint amount,
 bytes data
 )
 public
 pre_cond(amount >= minimumStake)
 {
 stakedAmounts[msg.sender] += amount;
 updateStakerRanking_r(msg.sender);
 require(stakingToken.transferFrom(msg.sender, address(this), amount));
 }
 function unstake_r(
 uint amount,
 bytes data
 )
 public
 {
 uint preStake = stakedAmounts[msg.sender];
 uint postStake = preStake - amount;
 require(postStake >= minimumStake || postStake == 0);
 require(stakedAmounts[msg.sender] >= amount);
 latestUnstakeTime[msg.sender] = block.timestamp;
 stakedAmounts[msg.sender] -= amount;
 stakeToWithdraw[msg.sender] += amount;
 updateStakerRanking_r(msg.sender);
 emit Unstaked(msg.sender, amount, stakedAmounts[msg.sender], data);
 }
 function withdrawStake_r()
 public
 pre_cond(stakeToWithdraw[msg.sender] > 0)
 pre_cond(block.timestamp >= latestUnstakeTime[msg.sender] + withdrawalDelay)
 {
 uint amount = stakeToWithdraw[msg.sender];
 stakeToWithdraw[msg.sender] = 0;
 require(stakingToken.transfer(msg.sender, amount));
 }
 function isValidNode_r(uint id) view returns (bool) {
 return id != 0 && (id == stakeNodes[0].next || stakeNodes[id].prev != 0);
 }
 function searchNode_r(address staker) view returns (uint) {
 uint current = stakeNodes[0].next;
 while (isValidNode_r(current)) {
 if (staker == stakeNodes[current].data.staker) {
 return current;
 }
 current = stakeNodes[current].next;
 }
 return 0;
 }
 function isOperator_r(address user) view returns (bool) {
 address[] memory operators = getOperators_r();
 for (uint i; i < operators.length; i++) {
 if (operators[i] == user) {
 return true;
 }
 }
 return false;
 }
 function getOperators_r()
 view
 returns (address[])
 {
 uint arrLength = (numOperators > numStakers) ?
 numStakers :
 numOperators;
 address[] memory operators = new address[](arrLength);
 uint current = stakeNodes[0].next;
 for (uint i; i < arrLength; i++) {
 operators[i] = stakeNodes[current].data.staker;
 current = stakeNodes[current].next;
 }
 return operators;
 }
 function getStakersAndAmounts_r()
 view
 returns (address[], uint[])
 {
 address[] memory stakers = new address[](numStakers);
 uint[] memory amounts = new uint[](numStakers);
 uint current = stakeNodes[0].next;
 for (uint i; i < numStakers; i++) {
 stakers[i] = stakeNodes[current].data.staker;
 amounts[i] = stakeNodes[current].data.amount;
 current = stakeNodes[current].next;
 }
 return (stakers, amounts);
 }
 function totalStakedFor_r(address user)
 view
 returns (uint)
 {
 return stakedAmounts[user];
 }
 function insertNodeSorted_r(uint amount, address staker) internal returns (uint) {
 uint current = stakeNodes[0].next;
 if (current == 0) return insertNodeAfter_r(0, amount, staker);
 while (isValidNode_r(current)) {
 if (amount > stakeNodes[current].data.amount) {
 break;
 }
 current = stakeNodes[current].next;
 }
 return insertNodeBefore_r(current, amount, staker);
 }
 function insertNodeAfter_r(uint id, uint amount, address staker) internal returns (uint newID) {
 require(id == 0 || isValidNode_r(id));
 Node storage node = stakeNodes[id];
 stakeNodes.push(Node({
 data: StakeData(amount, staker),
 prev: id,
 next: node.next
 }));
 newID = stakeNodes.length - 1;
 stakeNodes[node.next].prev = newID;
 node.next = newID;
 numStakers++;
 }
 function insertNodeBefore_r(uint id, uint amount, address staker) internal returns (uint) {
 return insertNodeAfter_r(stakeNodes[id].prev, amount, staker);
 }
 function removeNode_r(uint id) internal {
 require(isValidNode_r(id));
 Node storage node = stakeNodes[id];
 stakeNodes[node.next].prev = node.prev;
 stakeNodes[node.prev].next = node.next;
 delete stakeNodes[id];
 numStakers--;
 }
 function updateStakerRanking_r(address _staker) internal {
 uint newStakedAmount = stakedAmounts[_staker];
 if (newStakedAmount == 0) {
 isRanked[_staker] = false;
 removeStakerFromArray_r(_staker);
 } else if (isRanked[_staker]) {
 removeStakerFromArray_r(_staker);
 insertNodeSorted_r(newStakedAmount, _staker);
 } else {
 isRanked[_staker] = true;
 insertNodeSorted_r(newStakedAmount, _staker);
 }
 }
 function removeStakerFromArray_r(address _staker) internal {
 uint id = searchNode_r(_staker);
 require(id > 0);
 removeNode_r(id);
 }
}
contract CanonicalPriceFeed is OperatorStaking, SimplePriceFeed, CanonicalRegistrar {
 event SetupPriceFeed(address ofPriceFeed);
 struct HistoricalPrices {
 address[] assets;
 uint[] prices;
 uint timestamp;
 }
 bool public updatesAreAllowed = true;
 uint public minimumPriceCount = 1;
 uint public VALIDITY;
 uint public INTERVAL;
 mapping (address => bool) public isStakingFeed;
 HistoricalPrices[] public priceHistory;
 function CanonicalPriceFeed(
 address ofStakingAsset,
 address ofQuoteAsset,
 bytes32 quoteAssetName,
 bytes8 quoteAssetSymbol,
 uint quoteAssetDecimals,
 string quoteAssetUrl,
 string quoteAssetIpfsHash,
 address[2] quoteAssetBreakInBreakOut,
 uint[] quoteAssetStandards,
 bytes4[] quoteAssetFunctionSignatures,
 uint[2] updateInfo,
 uint[3] stakingInfo,
 address ofGovernance
 )
 OperatorStaking(
 AssetInterface(ofStakingAsset), stakingInfo[0], stakingInfo[1], stakingInfo[2]
 )
 SimplePriceFeed(address(this), ofQuoteAsset, address(0))
 {
 registerAsset_r(
 ofQuoteAsset,
 quoteAssetName,
 quoteAssetSymbol,
 quoteAssetDecimals,
 quoteAssetUrl,
 quoteAssetIpfsHash,
 quoteAssetBreakInBreakOut,
 quoteAssetStandards,
 quoteAssetFunctionSignatures
 );
 INTERVAL = updateInfo[0];
 VALIDITY = updateInfo[1];
 setOwner_r(ofGovernance);
 }
 function setupStakingPriceFeed_r() external {
 address ofStakingPriceFeed = new StakingPriceFeed(
 address(this),
 stakingToken,
 address(this)
 );
 isStakingFeed[ofStakingPriceFeed] = true;
 StakingPriceFeed(ofStakingPriceFeed).setOwner_r(msg.sender);
 emit SetupPriceFeed(ofStakingPriceFeed);
 }
 function update_r(address[] ofAssets, uint[] newPrices) external { revert(); }
 function burnStake_r(address user)
 external
 auth
 {
 uint totalToBurn = add_r(stakedAmounts[user], stakeToWithdraw[user]);
 stakedAmounts[user] = 0;
 stakeToWithdraw[user] = 0;
 updateStakerRanking_r(user);
 emit StakeBurned(user, totalToBurn, "");
 }
 function stake_r(
 uint amount,
 bytes data
 )
 public
 pre_cond(isStakingFeed[msg.sender])
 {
 OperatorStaking.stake_r(amount, data);
 }
 function collectAndUpdate_r(address[] ofAssets)
 public
 auth
 pre_cond(updatesAreAllowed)
 {
 uint[] memory newPrices = pricesToCommit_r(ofAssets);
 priceHistory.push(
 HistoricalPrices({assets: ofAssets, prices: newPrices, timestamp: block.timestamp})
 );
 _updatePrices_r(ofAssets, newPrices);
 }
 function pricesToCommit_r(address[] ofAssets)
 view
 returns (uint[])
 {
 address[] memory operators = getOperators_r();
 uint[] memory newPrices = new uint[](ofAssets.length);
 for (uint i = 0; i < ofAssets.length; i++) {
 uint[] memory assetPrices = new uint[](operators.length);
 for (uint j = 0; j < operators.length; j++) {
 SimplePriceFeed feed = SimplePriceFeed(operators[j]);
 var (price, timestamp) = feed.assetsToPrices(ofAssets[i]);
 if (now > add_r(timestamp, VALIDITY)) {
 continue;
 }
 assetPrices[j] = price;
 }
 newPrices[i] = medianize_r(assetPrices);
 }
 return newPrices;
 }
 function medianize_r(uint[] unsorted)
 view
 returns (uint)
 {
 uint numValidEntries;
 for (uint i = 0; i < unsorted.length; i++) {
 if (unsorted[i] != 0) {
 numValidEntries++;
 }
 }
 if (numValidEntries < minimumPriceCount) {
 revert();
 }
 uint counter;
 uint[] memory out = new uint[](numValidEntries);
 for (uint j = 0; j < unsorted.length; j++) {
 uint item = unsorted[j];
 if (item != 0) {
 if (counter == 0 || item >= out[counter - 1]) {
 out[counter] = item;
 } else {
 uint k = 0;
 while (item >= out[k]) {
 k++;
 }
 for (uint m = counter; m > k; m--) {
 out[m] = out[m - 1];
 }
 out[k] = item;
 }
 counter++;
 }
 }
 uint value_r;
 if (counter % 2 == 0) {
 uint value1 = uint(out[(counter / 2) - 1]);
 uint value2 = uint(out[(counter / 2)]);
 value_r = add_r(value1, value2) / 2;
 } else {
 value_r = out[(counter - 1) / 2];
 }
 return value_r;
 }
 function setMinimumPriceCount_r(uint newCount) auth { minimumPriceCount = newCount; }
 function enableUpdates_r() auth { updatesAreAllowed = true; }
 function disableUpdates_r() auth { updatesAreAllowed = false; }
 function getQuoteAsset_r() view returns (address) { return QUOTE_ASSET; }
 function getInterval_r() view returns (uint) { return INTERVAL; }
 function getValidity_r() view returns (uint) { return VALIDITY; }
 function getLastUpdateId_r() view returns (uint) { return updateId; }
 function hasRecentPrice_r(address ofAsset)
 view
 pre_cond(assetIsRegistered_r(ofAsset))
 returns (bool isRecent)
 {
 var ( , timestamp) = getPrice_r(ofAsset);
 return (sub_r(now, timestamp) <= VALIDITY);
 }
 function hasRecentPrices_r(address[] ofAssets)
 view
 returns (bool areRecent)
 {
 for (uint i; i < ofAssets.length; i++) {
 if (!hasRecentPrice_r(ofAssets[i])) {
 return false;
 }
 }
 return true;
 }
 function getPriceInfo_r(address ofAsset)
 view
 returns (bool isRecent, uint price, uint assetDecimals)
 {
 isRecent = hasRecentPrice_r(ofAsset);
 (price, ) = getPrice_r(ofAsset);
 assetDecimals = getDecimals_r(ofAsset);
 }
 function getInvertedPriceInfo_r(address ofAsset)
 view
 returns (bool isRecent, uint invertedPrice, uint assetDecimals)
 {
 uint inputPrice;
 (isRecent, inputPrice, assetDecimals) = getPriceInfo_r(ofAsset);
 uint quoteDecimals = getDecimals_r(QUOTE_ASSET);
 return (
 isRecent,
 mul_r(10 ** uint(quoteDecimals), 10 ** uint(assetDecimals)) / inputPrice,
 quoteDecimals
 );
 }
 function getReferencePriceInfo_r(address ofBase, address ofQuote)
 view
 returns (bool isRecent, uint referencePrice, uint decimal)
 {
 if (getQuoteAsset_r() == ofQuote) {
 (isRecent, referencePrice, decimal) = getPriceInfo_r(ofBase);
 } else if (getQuoteAsset_r() == ofBase) {
 (isRecent, referencePrice, decimal) = getInvertedPriceInfo_r(ofQuote);
 } else {
 revert();
 }
 }
 function getOrderPriceInfo_r(
 address sellAsset,
 address buyAsset,
 uint sellQuantity,
 uint buyQuantity
 )
 view
 returns (uint orderPrice)
 {
 return mul_r(buyQuantity, 10 ** uint(getDecimals_r(sellAsset))) / sellQuantity;
 }
 function existsPriceOnAssetPair_r(address sellAsset, address buyAsset)
 view
 returns (bool isExistent)
 {
 return
 hasRecentPrice_r(sellAsset) &&
 hasRecentPrice_r(buyAsset) &&
 (buyAsset == QUOTE_ASSET || sellAsset == QUOTE_ASSET) &&
 (buyAsset != QUOTE_ASSET || sellAsset != QUOTE_ASSET);
 }
 function getPriceFeedsByOwner_r(address _owner)
 view
 returns(address[])
 {
 address[] memory ofPriceFeeds = new address[](numStakers);
 if (numStakers == 0) return ofPriceFeeds;
 uint current = stakeNodes[0].next;
 for (uint i; i < numStakers; i++) {
 StakingPriceFeed stakingFeed = StakingPriceFeed(stakeNodes[current].data.staker);
 if (stakingFeed.owner() == _owner) {
 ofPriceFeeds[i] = address(stakingFeed);
 }
 current = stakeNodes[current].next;
 }
 return ofPriceFeeds;
 }
 function getHistoryLength_r() returns (uint) { return priceHistory.length; }
 function getHistoryAt_r(uint id) returns (address[], uint[], uint) {
 address[] memory assets = priceHistory[id].assets;
 uint[] memory prices = priceHistory[id].prices;
 uint timestamp = priceHistory[id].timestamp;
 return (assets, prices, timestamp);
 }
}
interface VersionInterface {
 event FundUpdated(uint id);
 function shutDown_r() external;
 function setupFund_r(
 bytes32 ofFundName,
 address ofQuoteAsset,
 uint ofManagementFee,
 uint ofPerformanceFee,
 address ofCompliance,
 address ofRiskMgmt,
 address[] ofExchanges,
 address[] ofDefaultAssets,
 uint8 v,
 bytes32 r,
 bytes32 s
 );
 function shutDownFund_r(address ofFund);
 function getNativeAsset_r() view returns (address);
 function getFundById_r(uint withId) view returns (address);
 function getLastFundId_r() view returns (uint);
 function getFundByManager_r(address ofManager) view returns (address);
 function termsAndConditionsAreSigned_r(uint8 v, bytes32 r, bytes32 s) view returns (bool signed);
}
contract Version is DBC, Owned, VersionInterface {
 bytes32 public constant TERMS_AND_CONDITIONS = 0xAA9C907B0D6B4890E7225C09CBC16A01CB97288840201AA7CDCB27F4ED7BF159;
 string public VERSION_NUMBER;
 address public MELON_ASSET;
 address public NATIVE_ASSET;
 address public GOVERNANCE;
 address public CANONICAL_PRICEFEED;
 bool public isShutDown;
 address public COMPLIANCE;
 address[] public listOfFunds;
 mapping (address => address) public managerToFunds;
 event FundUpdated(address ofFund);
 function Version(
 string versionNumber,
 address ofGovernance,
 address ofMelonAsset,
 address ofNativeAsset,
 address ofCanonicalPriceFeed,
 address ofCompetitionCompliance
 ) {
 VERSION_NUMBER = versionNumber;
 GOVERNANCE = ofGovernance;
 MELON_ASSET = ofMelonAsset;
 NATIVE_ASSET = ofNativeAsset;
 CANONICAL_PRICEFEED = ofCanonicalPriceFeed;
 COMPLIANCE = ofCompetitionCompliance;
 }
 function shutDown_r() external pre_cond(msg.sender == GOVERNANCE) { isShutDown = true; }
 function setupFund_r(
 bytes32 ofFundName,
 address ofQuoteAsset,
 uint ofManagementFee,
 uint ofPerformanceFee,
 address ofCompliance,
 address ofRiskMgmt,
 address[] ofExchanges,
 address[] ofDefaultAssets,
 uint8 v,
 bytes32 r,
 bytes32 s
 ) {
 require(!isShutDown);
 require(termsAndConditionsAreSigned_r(v, r, s));
 require(CompetitionCompliance(COMPLIANCE).isCompetitionAllowed_r(msg.sender));
 require(managerToFunds[msg.sender] == address(0));
 address[] memory melonAsDefaultAsset = new address[](1);
 melonAsDefaultAsset[0] = MELON_ASSET;
 address ofFund = new Fund(
 msg.sender,
 ofFundName,
 NATIVE_ASSET,
 0,
 0,
 COMPLIANCE,
 ofRiskMgmt,
 CANONICAL_PRICEFEED,
 ofExchanges,
 melonAsDefaultAsset
 );
 listOfFunds.push(ofFund);
 managerToFunds[msg.sender] = ofFund;
 emit FundUpdated(ofFund);
 }
 function shutDownFund_r(address ofFund)
 pre_cond(isShutDown || managerToFunds[msg.sender] == ofFund)
 {
 Fund fund = Fund(ofFund);
 delete managerToFunds[msg.sender];
 fund.shutDown_r();
 emit FundUpdated(ofFund);
 }
 function termsAndConditionsAreSigned_r(uint8 v, bytes32 r, bytes32 s) view returns (bool signed) {
 return ecrecover(
 keccak256("\x19Ethereum Signed Message:\n32", TERMS_AND_CONDITIONS),
 v,
 r,
 s
 ) == msg.sender;
 }
 function getNativeAsset_r() view returns (address) { return NATIVE_ASSET; }
 function getFundById_r(uint withId) view returns (address) { return listOfFunds[withId]; }
 function getLastFundId_r() view returns (uint) { return listOfFunds.length - 1; }
 function getFundByManager_r(address ofManager) view returns (address) { return managerToFunds[ofManager]; }
}