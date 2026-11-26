pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;
library SafeMath {
 function mul_r(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 require(c / a == b);
 return c;
 }
 function div_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b > 0);
 uint256 c = a / b;
 return c;
 }
 function sub_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b <= a);
 uint256 c = a - b;
 return c;
 }
 function add_r(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 require(c >= a);
 return c;
 }
 function mod_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b != 0);
 return a % b;
 }
}
contract Ownable {
 address private _owner;
 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 constructor () internal {
 _owner = msg.sender;
 emit OwnershipTransferred(address(0), _owner);
 }
 function owner() public view returns (address) {
 return _owner;
 }
 modifier onlyOwner() {
 require(isOwner_r());
 _;
 }
 function isOwner_r() public view returns (bool) {
 return msg.sender == _owner;
 }
 function renounceOwnership_r() public onlyOwner {
 emit OwnershipTransferred(_owner, address(0));
 _owner = address(0);
 }
 function transferOwnership_r(address newOwner) public onlyOwner {
 _transferOwnership_r(newOwner);
 }
 function _transferOwnership_r(address newOwner) internal {
 require(newOwner != address(0));
 emit OwnershipTransferred(_owner, newOwner);
 _owner = newOwner;
 }
}
interface IErc20 {
 event Transfer(
 address indexed from,
 address indexed to,
 uint256 value
 );
 event Approval(
 address indexed owner,
 address indexed spender,
 uint256 value
 );
 function totalSupply(
 )
 external
 view
 returns (uint256);
 function balanceOf(
 address who
 )
 external
 view
 returns (uint256);
 function allowance(
 address owner,
 address spender
 )
 external
 view
 returns (uint256);
 function transfer(
 address to,
 uint256 value
 )
 external;
 function transferFrom(
 address from,
 address to,
 uint256 value
 )
 external;
 function approve(
 address spender,
 uint256 value
 )
 external;
 function name()
 external
 view
 returns (string memory);
 function symbol()
 external
 view
 returns (string memory);
 function decimals()
 external
 view
 returns (uint8);
}
library Monetary {
 struct Price {
 uint256 value;
 }
 struct Value {
 uint256 value;
 }
}
contract IPriceOracle {
 uint256 public constant ONE_DOLLAR = 10 ** 36;
 function getPrice_r(
 address token
 )
 public
 view
 returns (Monetary.Price memory);
}
library Require {
 uint256 constant ASCII_ZERO = 48;
 uint256 constant ASCII_RELATIVE_ZERO = 87;
 uint256 constant ASCII_LOWER_EX = 120;
 bytes2 constant COLON = 0x3a20;
 bytes2 constant COMMA = 0x2c20;
 bytes2 constant LPAREN = 0x203c;
 byte constant RPAREN = 0x3e;
 uint256 constant FOUR_BIT_MASK = 0xf;
 function that_r(
 bool must,
 bytes32 file,
 bytes32 reason
 )
 internal
 pure
 {
 if (!must) {
 revert(
 string(
 abi.encodePacked(
 stringify_r(file),
 COLON,
 stringify_r(reason)
 )
 )
 );
 }
 }
 function that_r(
 bool must,
 bytes32 file,
 bytes32 reason,
 uint256 payloadA
 )
 internal
 pure
 {
 if (!must) {
 revert(
 string(
 abi.encodePacked(
 stringify_r(file),
 COLON,
 stringify_r(reason),
 LPAREN,
 stringify_r(payloadA),
 RPAREN
 )
 )
 );
 }
 }
 function that_r(
 bool must,
 bytes32 file,
 bytes32 reason,
 uint256 payloadA,
 uint256 payloadB
 )
 internal
 pure
 {
 if (!must) {
 revert(
 string(
 abi.encodePacked(
 stringify_r(file),
 COLON,
 stringify_r(reason),
 LPAREN,
 stringify_r(payloadA),
 COMMA,
 stringify_r(payloadB),
 RPAREN
 )
 )
 );
 }
 }
 function that_r(
 bool must,
 bytes32 file,
 bytes32 reason,
 address payloadA
 )
 internal
 pure
 {
 if (!must) {
 revert(
 string(
 abi.encodePacked(
 stringify_r(file),
 COLON,
 stringify_r(reason),
 LPAREN,
 stringify_r(payloadA),
 RPAREN
 )
 )
 );
 }
 }
 function that_r(
 bool must,
 bytes32 file,
 bytes32 reason,
 address payloadA,
 uint256 payloadB
 )
 internal
 pure
 {
 if (!must) {
 revert(
 string(
 abi.encodePacked(
 stringify_r(file),
 COLON,
 stringify_r(reason),
 LPAREN,
 stringify_r(payloadA),
 COMMA,
 stringify_r(payloadB),
 RPAREN
 )
 )
 );
 }
 }
 function that_r(
 bool must,
 bytes32 file,
 bytes32 reason,
 address payloadA,
 uint256 payloadB,
 uint256 payloadC
 )
 internal
 pure
 {
 if (!must) {
 revert(
 string(
 abi.encodePacked(
 stringify_r(file),
 COLON,
 stringify_r(reason),
 LPAREN,
 stringify_r(payloadA),
 COMMA,
 stringify_r(payloadB),
 COMMA,
 stringify_r(payloadC),
 RPAREN
 )
 )
 );
 }
 }
 function stringify_r(
 bytes32 input
 )
 private
 pure
 returns (bytes memory)
 {
 bytes memory result = abi.encodePacked(input);
 for (uint256 i = 32; i > 0; ) {
 i--;
 if (result[i] != 0) {
 uint256 length = i + 1;
 assembly {
 mstore(result, length)
 }
 return result;
 }
 }
 return new bytes(0);
 }
 function stringify_r(
 uint256 input
 )
 private
 pure
 returns (bytes memory)
 {
 if (input == 0) {
 return "0";
 }
 uint256 j = input;
 uint256 length;
 while (j != 0) {
 length++;
 j /= 10;
 }
 bytes memory bstr = new bytes(length);
 j = input;
 for (uint256 i = length; i > 0; ) {
 i--;
 bstr[i] = byte(uint8(ASCII_ZERO + (j % 10)));
 j /= 10;
 }
 return bstr;
 }
 function stringify_r(
 address input
 )
 private
 pure
 returns (bytes memory)
 {
 uint256 z = uint256(input);
 bytes memory result = new bytes(42);
 result[0] = byte(uint8(ASCII_ZERO));
 result[1] = byte(uint8(ASCII_LOWER_EX));
 for (uint256 i = 0; i < 20; i++) {
 uint256 shift = i * 2;
 result[41 - shift] = char_r(z & FOUR_BIT_MASK);
 z = z >> 4;
 result[40 - shift] = char_r(z & FOUR_BIT_MASK);
 z = z >> 4;
 }
 return result;
 }
 function char_r(
 uint256 input
 )
 private
 pure
 returns (byte)
 {
 if (input < 10) {
 return byte(uint8(input + ASCII_ZERO));
 }
 return byte(uint8(input + ASCII_RELATIVE_ZERO));
 }
}
library Math {
 using SafeMath for uint256;
 bytes32 constant FILE = "Math";
 function getPartial_r(
 uint256 target,
 uint256 numerator,
 uint256 denominator
 )
 internal
 pure
 returns (uint256)
 {
 return target.mul_r(numerator).div_r(denominator);
 }
 function getPartialRoundUp_r(
 uint256 target,
 uint256 numerator,
 uint256 denominator
 )
 internal
 pure
 returns (uint256)
 {
 if (target == 0 || numerator == 0) {
 return SafeMath.div_r(0, denominator);
 }
 return target.mul_r(numerator).sub_r(1).div_r(denominator).add_r(1);
 }
 function to128_r(
 uint256 number
 )
 internal
 pure
 returns (uint128)
 {
 uint128 result = uint128(number);
 Require.that_r(
 result == number,
 FILE,
  "Unsafe cast to uint128"
 );
 return result;
 }
 function to96_r(
 uint256 number
 )
 internal
 pure
 returns (uint96)
 {
 uint96 result = uint96(number);
 Require.that_r(
 result == number,
 FILE,
  "Unsafe cast to uint96"
 );
 return result;
 }
 function to32_r(
 uint256 number
 )
 internal
 pure
 returns (uint32)
 {
 uint32 result = uint32(number);
 Require.that_r(
 result == number,
 FILE,
  "Unsafe cast to uint32"
 );
 return result;
 }
 function min_r(
 uint256 a,
 uint256 b
 )
 internal
 pure
 returns (uint256)
 {
 return a < b ? a : b;
 }
 function max_r(
 uint256 a,
 uint256 b
 )
 internal
 pure
 returns (uint256)
 {
 return a > b ? a : b;
 }
}
library Time {
 function currentTime_r()
 internal
 view
 returns (uint32)
 {
 return Math.to32_r(block.timestamp);
 }
}
interface IMakerOracle {
 event LogNote(
 bytes4 indexed msgSig,
 address indexed msgSender,
 bytes32 indexed arg1,
 bytes32 indexed arg2,
 uint256 msgValue,
 bytes msgData
 ) anonymous;
 function peek_r()
 external
 view
 returns (bytes32, bool);
 function read_r()
 external
 view
 returns (bytes32);
}
interface IOasisDex {
 struct OfferInfo {
 uint256 pay_amt;
 address pay_gem;
 uint256 buy_amt;
 address buy_gem;
 address owner;
 uint64 timestamp;
 }
 struct SortInfo {
 uint256 next;
 uint256 prev;
 uint256 delb;
 }
 function last_offer_id_r()
 external
 view
 returns (uint256);
 function offers_r(
 uint256 id
 )
 external
 view
 returns (OfferInfo memory);
 function close_time_r()
 external
 view
 returns (uint64);
 function stopped_r()
 external
 view
 returns (bool);
 function buyEnabled_r()
 external
 view
 returns (bool);
 function matchingEnabled_r()
 external
 view
 returns (bool);
 function _rank_r(
 uint256 id
 )
 external
 view
 returns (SortInfo memory);
 function _best_r(
 address sell_gem,
 address buy_gem
 )
 external
 view
 returns (uint256);
 function _span_r(
 address sell_gem,
 address buy_gem
 )
 external
 view
 returns (uint256);
 function _dust_r(
 address gem
 )
 external
 view
 returns (uint256);
 function _near_r(
 uint256 id
 )
 external
 view
 returns (uint256);
 function isActive_r(
 uint256 id
 )
 external
 view
 returns (bool);
 function getOwner_r(
 uint256 id
 )
 external
 view
 returns (address);
 function getOffer_r(
 uint256 id
 )
 external
 view
 returns (uint256, address, uint256, address);
 function getMinSell_r(
 address pay_gem
 )
 external
 view
 returns (uint256);
 function getBestOffer_r(
 address sell_gem,
 address buy_gem
 )
 external
 view
 returns (uint256);
 function getWorseOffer_r(
 uint256 id
 )
 external
 view
 returns (uint256);
 function getBetterOffer_r(
 uint256 id
 )
 external
 view
 returns (uint256);
 function getOfferCount_r(
 address sell_gem,
 address buy_gem
 )
 external
 view
 returns (uint256);
 function getFirstUnsortedOffer_r()
 external
 view
 returns (uint256);
 function getNextUnsortedOffer_r(
 uint256 id
 )
 external
 view
 returns (uint256);
 function isOfferSorted_r(
 uint256 id
 )
 external
 view
 returns (bool);
 function getBuyAmount_r(
 address buy_gem,
 address pay_gem,
 uint256 pay_amt
 )
 external
 view
 returns (uint256);
 function getPayAmount_r(
 address pay_gem,
 address buy_gem,
 uint256 buy_amt
 )
 external
 view
 returns (uint256);
 function isClosed_r()
 external
 view
 returns (bool);
 function getTime_r()
 external
 view
 returns (uint64);
 function bump_r(
 bytes32 id_
 )
 external;
 function buy_r(
 uint256 id,
 uint256 quantity
 )
 external
 returns (bool);
 function cancel_r(
 uint256 id
 )
 external
 returns (bool);
 function kill_r(
 bytes32 id
 )
 external;
 function make_r(
 address pay_gem,
 address buy_gem,
 uint128 pay_amt,
 uint128 buy_amt
 )
 external
 returns (bytes32);
 function take_r(
 bytes32 id,
 uint128 maxTakeAmount
 )
 external;
 function offer_r(
 uint256 pay_amt,
 address pay_gem,
 uint256 buy_amt,
 address buy_gem
 )
 external
 returns (uint256);
 function offer_r(
 uint256 pay_amt,
 address pay_gem,
 uint256 buy_amt,
 address buy_gem,
 uint256 pos
 )
 external
 returns (uint256);
 function offer_r(
 uint256 pay_amt,
 address pay_gem,
 uint256 buy_amt,
 address buy_gem,
 uint256 pos,
 bool rounding
 )
 external
 returns (uint256);
 function insert_r(
 uint256 id,
 uint256 pos
 )
 external
 returns (bool);
 function del_rank_r(
 uint256 id
 )
 external
 returns (bool);
 function sellAllAmount_r(
 address pay_gem,
 uint256 pay_amt,
 address buy_gem,
 uint256 min_fill_amount
 )
 external
 returns (uint256);
 function buyAllAmount_r(
 address buy_gem,
 uint256 buy_amt,
 address pay_gem,
 uint256 max_fill_amount
 )
 external
 returns (uint256);
}
contract DaiPriceOracle is
 Ownable,
 IPriceOracle
{
 using SafeMath for uint256;
 bytes32 constant FILE = "DaiPriceOracle";
 uint256 constant DECIMALS = 18;
 uint256 constant EXPECTED_PRICE = ONE_DOLLAR / (10 ** DECIMALS);
 struct PriceInfo {
 uint128 price;
 uint32 lastUpdate;
 }
 struct DeviationParams {
 uint64 denominator;
 uint64 maximumPerSecond;
 uint64 maximumAbsolute;
 }
 event PriceSet(
 PriceInfo newPriceInfo
 );
 PriceInfo public g_priceInfo;
 address public g_poker;
 DeviationParams public DEVIATION_PARAMS;
 uint256 public OASIS_ETH_AMOUNT;
 IErc20 public WETH;
 IErc20 public DAI;
 IMakerOracle public MEDIANIZER;
 IOasisDex public OASIS;
 address public UNISWAP;
 constructor(
 address poker,
 address weth,
 address dai,
 address medianizer,
 address oasis,
 address uniswap,
 uint256 oasisEthAmount,
 DeviationParams memory deviationParams
 )
 public
 {
 g_poker = poker;
 MEDIANIZER = IMakerOracle(medianizer);
 WETH = IErc20(weth);
 DAI = IErc20(dai);
 OASIS = IOasisDex(oasis);
 UNISWAP = uniswap;
 DEVIATION_PARAMS = deviationParams;
 OASIS_ETH_AMOUNT = oasisEthAmount;
 g_priceInfo = PriceInfo({
 lastUpdate: uint32(block.timestamp),
 price: uint128(EXPECTED_PRICE)
 });
 }
 function ownerSetPokerAddress_r(
 address newPoker
 )
 external
 onlyOwner
 {
 g_poker = newPoker;
 }
 function updatePrice(
 Monetary.Price memory minimum,
 Monetary.Price memory maximum
 )
 public
 returns (PriceInfo memory)
 {
 Require.that_r(
 msg.sender == g_poker,
 FILE,
  "Only poker can call updatePrice",
 msg.sender
 );
 Monetary.Price memory newPrice = getBoundedTargetPrice_r();
 Require.that_r(
 newPrice.value >= minimum.value,
 FILE,
  "newPrice below minimum",
 newPrice.value,
 minimum.value
 );
 Require.that_r(
 newPrice.value <= maximum.value,
 FILE,
  "newPrice above maximum",
 newPrice.value,
 maximum.value
 );
 g_priceInfo = PriceInfo({
 price: Math.to128_r(newPrice.value),
 lastUpdate: Time.currentTime_r()
 });
 emit PriceSet(g_priceInfo);
 return g_priceInfo;
 }
 function getPrice_r(
 address
 )
 public
 view
 returns (Monetary.Price memory)
 {
 return Monetary.Price({
 value: g_priceInfo.price
 });
 }
 function getBoundedTargetPrice_r()
 public
 view
 returns (Monetary.Price memory)
 {
 Monetary.Price memory targetPrice = getTargetPrice_r();
 PriceInfo memory oldInfo = g_priceInfo;
 uint256 timeDelta = uint256(Time.currentTime_r()).sub_r(oldInfo.lastUpdate);
 (uint256 minPrice, uint256 maxPrice) = getPriceBounds_r(oldInfo.price, timeDelta);
 uint256 boundedTargetPrice = boundValue_r(targetPrice.value, minPrice, maxPrice);
 return Monetary.Price({
 value: boundedTargetPrice
 });
 }
 function getTargetPrice_r()
 public
 view
 returns (Monetary.Price memory)
 {
 Monetary.Price memory ethUsd = getMedianizerPrice_r();
 uint256 targetPrice = getMidValue_r(
 EXPECTED_PRICE,
 getOasisPrice_r(ethUsd).value,
 getUniswapPrice_r(ethUsd).value
 );
 return Monetary.Price({
 value: targetPrice
 });
 }
 function getMedianizerPrice_r()
 public
 view
 returns (Monetary.Price memory)
 {
 return Monetary.Price({
 value: uint256(MEDIANIZER.read_r())
 });
 }
 function getOasisPrice_r(
 Monetary.Price memory ethUsd
 )
 public
 view
 returns (Monetary.Price memory)
 {
 IOasisDex oasis = OASIS;
 if (
 oasis.isClosed_r()
 || !oasis.buyEnabled_r()
 || !oasis.matchingEnabled_r()
 ) {
 return Monetary.Price({
 value: g_priceInfo.price
 });
 }
 uint256 numWei = OASIS_ETH_AMOUNT;
 address dai = address(DAI);
 address weth = address(WETH);
 uint256 daiAmt1 = oasis.getBuyAmount_r(dai, weth, numWei);
 uint256 daiAmt2 = oasis.getPayAmount_r(dai, weth, numWei);
 uint256 num = numWei.mul_r(daiAmt2).add_r(numWei.mul_r(daiAmt1));
 uint256 den = daiAmt1.mul_r(daiAmt2).mul_r(2);
 uint256 oasisPrice = Math.getPartial_r(ethUsd.value, num, den);
 return Monetary.Price({
 value: oasisPrice
 });
 }
 function getUniswapPrice_r(
 Monetary.Price memory ethUsd
 )
 public
 view
 returns (Monetary.Price memory)
 {
 address uniswap = address(UNISWAP);
 uint256 ethAmt = uniswap.balance;
 uint256 daiAmt = DAI.balanceOf(uniswap);
 uint256 uniswapPrice = Math.getPartial_r(ethUsd.value, ethAmt, daiAmt);
 return Monetary.Price({
 value: uniswapPrice
 });
 }
 function getPriceBounds_r(
 uint256 oldPrice,
 uint256 timeDelta
 )
 private
 view
 returns (uint256, uint256)
 {
 DeviationParams memory deviation = DEVIATION_PARAMS;
 uint256 maxDeviation = Math.getPartial_r(
 oldPrice,
 Math.min_r(deviation.maximumAbsolute, timeDelta.mul_r(deviation.maximumPerSecond)),
 deviation.denominator
 );
 return (
 oldPrice.sub_r(maxDeviation),
 oldPrice.add_r(maxDeviation)
 );
 }
 function getMidValue_r(
 uint256 valueA,
 uint256 valueB,
 uint256 valueC
 )
 private
 pure
 returns (uint256)
 {
 uint256 maximum = Math.max_r(valueA, Math.max_r(valueB, valueC));
 if (maximum == valueA) {
 return Math.max_r(valueB, valueC);
 }
 if (maximum == valueB) {
 return Math.max_r(valueA, valueC);
 }
 return Math.max_r(valueA, valueB);
 }
 function boundValue_r(
 uint256 value,
 uint256 minimum,
 uint256 maximum
 )
 private
 pure
 returns (uint256)
 {
 assert(minimum <= maximum);
 return Math.max_r(minimum, Math.min_r(maximum, value));
 }
}