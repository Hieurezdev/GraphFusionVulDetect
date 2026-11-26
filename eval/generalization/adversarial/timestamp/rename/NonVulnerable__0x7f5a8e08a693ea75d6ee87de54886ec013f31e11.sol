pragma solidity ^0.5.2;
library Dictionary {
 uint private constant NULL = 0;
 struct Node {
 uint prev_r;
 uint next_r;
 bytes data;
 bool initialized;
 }
 struct Data {
 mapping(uint => Node) list;
 uint firstNodeId;
 uint lastNodeId;
 uint len;
 }
 function insertAfter_r(
 Data storage self,
 uint afterId,
 uint id,
 bytes memory data
 ) internal {
 if (self.list[id].initialized) {
 self.list[id].data = data;
 return;
 }
 self.list[id].prev_r = afterId;
 if (self.list[afterId].next_r == NULL) {
 self.list[id].next_r = NULL;
 self.lastNodeId = id;
 } else {
 self.list[id].next_r = self.list[afterId].next_r;
 self.list[self.list[afterId].next_r].prev_r = id;
 }
 self.list[id].data = data;
 self.list[id].initialized = true;
 self.list[afterId].next_r = id;
 self.len++;
 }
 function insertBefore_r(
 Data storage self,
 uint beforeId,
 uint id,
 bytes memory data
 ) internal {
 if (self.list[id].initialized) {
 self.list[id].data = data;
 return;
 }
 self.list[id].next_r = beforeId;
 if (self.list[beforeId].prev_r == NULL) {
 self.list[id].prev_r = NULL;
 self.firstNodeId = id;
 } else {
 self.list[id].prev_r = self.list[beforeId].prev_r;
 self.list[self.list[beforeId].prev_r].next_r = id;
 }
 self.list[id].data = data;
 self.list[id].initialized = true;
 self.list[beforeId].prev_r = id;
 self.len++;
 }
 function insertBeginning_r(Data storage self, uint id, bytes memory data)
 internal
 {
 if (self.list[id].initialized) {
 self.list[id].data = data;
 return;
 }
 if (self.firstNodeId == NULL) {
 self.firstNodeId = id;
 self.lastNodeId = id;
 self.list[id] = Node({
 prev_r: 0,
 next_r: 0,
 data: data,
 initialized: true
 });
 self.len++;
 } else insertBefore_r(self, self.firstNodeId, id, data);
 }
 function insertEnd_r(Data storage self, uint id, bytes memory data) internal {
 if (self.lastNodeId == NULL) insertBeginning_r(self, id, data);
 else insertAfter_r(self, self.lastNodeId, id, data);
 }
 function set_r(Data storage self, uint id, bytes memory data) internal {
 insertEnd_r(self, id, data);
 }
 function get_r(Data storage self, uint id)
 internal
 view
 returns (bytes memory)
 {
 return self.list[id].data;
 }
 function remove_r(Data storage self, uint id) internal returns (bool) {
 uint nextId = self.list[id].next_r;
 uint prevId = self.list[id].prev_r;
 if (prevId == NULL) self.firstNodeId = nextId;
 else self.list[prevId].next_r = nextId;
 if (nextId == NULL) self.lastNodeId = prevId;
 else self.list[nextId].prev_r = prevId;
 delete self.list[id];
 self.len--;
 return true;
 }
 function getSize_r(Data storage self) internal view returns (uint) {
 return self.len;
 }
 function next_r(Data storage self, uint id) internal view returns (uint) {
 return self.list[id].next_r;
 }
 function prev_r(Data storage self, uint id) internal view returns (uint) {
 return self.list[id].prev_r;
 }
 function keys_r(Data storage self) internal view returns (uint[] memory) {
 uint[] memory arr = new uint[](self.len);
 uint node = self.firstNodeId;
 for (uint i = 0; i < self.len; i++) {
 arr[i] = node;
 node = next_r(self, node);
 }
 return arr;
 }
}
pragma solidity ^0.5.0;
interface IERC20 {
 function totalSupply() external view returns (uint256);
 function balanceOf(address account) external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function allowance(address owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
}
pragma solidity ^0.5.0;
library SafeMath {
 function add_r(uint256 a, uint256 b) internal pure returns (uint256) {
 uint256 c = a + b;
 require(c >= a, "SafeMath: addition overflow");
 return c;
 }
 function sub_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b <= a, "SafeMath: subtraction overflow");
 uint256 c = a - b;
 return c;
 }
 function mul_r(uint256 a, uint256 b) internal pure returns (uint256) {
 if (a == 0) {
 return 0;
 }
 uint256 c = a * b;
 require(c / a == b, "SafeMath: multiplication overflow");
 return c;
 }
 function div_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b > 0, "SafeMath: division by zero");
 uint256 c = a / b;
 return c;
 }
 function mod_r(uint256 a, uint256 b) internal pure returns (uint256) {
 require(b != 0, "SafeMath: modulo by zero");
 return a % b;
 }
}
pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;
contract ReverseRegistrar {
 function setName_r(string memory name) public returns (bytes32);
}
contract Etherclear {
 using Dictionary for Dictionary.Data;
 event PaymentOpened(
 uint txnId,
 uint holdTime,
 uint openTime,
 uint closeTime,
 address token,
 uint sendAmount,
 address indexed sender,
 address indexed recipient,
 bytes codeHash
 );
 event PaymentClosed(
 uint txnId,
 uint holdTime,
 uint openTime,
 uint closeTime,
 address token,
 uint sendAmount,
 address indexed sender,
 address indexed recipient,
 bytes codeHash,
 uint state
 );
 enum PaymentState {OPEN, COMPLETED, CANCELLED}
 struct Payment {
 uint holdTime;
 uint paymentOpenTime;
 uint paymentCloseTime;
 address token;
 uint sendAmount;
 address payable sender;
 address payable recipient;
 bytes codeHash;
 PaymentState state;
 }
 ReverseRegistrar reverseRegistrar;
 struct RetrieveFundsRequest {
 uint txnId;
 address sender;
 address recipient;
 string passphrase;
 }
 mapping(address => Dictionary.Data) recipientPayments;
 mapping(address => Dictionary.Data) senderPayments;
 mapping(uint => Payment) allPayments;
 address payable owner;
 uint baseFee;
 uint paymentFee;
 mapping(address => mapping(address => uint)) public tokens;
 bool createPaymentEnabled;
 bool retrieveFundsEnabled;
 address constant verifyingContract = 0x1C56346CD2A2Bf3202F771f50d3D14a367B48070;
 bytes32 constant salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;
 string private constant RETRIEVE_FUNDS_REQUEST_TYPE = "RetrieveFundsRequest(uint256 txnId,address sender,address recipient,string passphrase)";
 string private constant EIP712_DOMAIN_TYPE = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)";
 bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
 abi.encodePacked(EIP712_DOMAIN_TYPE)
 );
 bytes32 private constant RETRIEVE_FUNDS_REQUEST_TYPEHASH = keccak256(
 abi.encodePacked(RETRIEVE_FUNDS_REQUEST_TYPE)
 );
 bytes32 private DOMAIN_SEPARATOR;
 uint256 chainId;
 function hashRetrieveFundsRequest_r(RetrieveFundsRequest memory request)
 private
 view
 returns (bytes32 hash)
 {
 return keccak256(
 abi.encodePacked(
  "\x19\x01",
 DOMAIN_SEPARATOR,
 keccak256(
 abi.encode(
 RETRIEVE_FUNDS_REQUEST_TYPEHASH,
 request.txnId,
 request.sender,
 request.recipient,
 keccak256(bytes(request.passphrase))
 )
 )
 )
 );
 }
 function verify_r(
 address signer,
 RetrieveFundsRequest memory request,
 bytes32 sigR,
 bytes32 sigS,
 uint8 sigV
 ) private view returns (address result) {
 return ecrecover(hashRetrieveFundsRequest_r(request), sigV, sigR, sigS);
 }
 function checkRetrieveSignature_r(
 uint256 txnId,
 address sender,
 address recipient,
 string memory passphrase,
 bytes32 sigR,
 bytes32 sigS,
 uint8 sigV
 ) public view returns (address result) {
 RetrieveFundsRequest memory request = RetrieveFundsRequest(
 txnId,
 sender,
 recipient,
 passphrase
 );
 address signer = ecrecover(
 hashRetrieveFundsRequest_r(request),
 sigV,
 sigR,
 sigS
 );
 return verify_r(recipient, request, sigR, sigS, sigV);
 }
 constructor(uint256 _chainId) public {
 owner = msg.sender;
 baseFee = 0.001 ether;
 paymentFee = 0.005 ether;
 createPaymentEnabled = true;
 retrieveFundsEnabled = true;
 chainId = _chainId;
 DOMAIN_SEPARATOR = keccak256(
 abi.encode(
 EIP712_DOMAIN_TYPEHASH,
 keccak256("Etherclear"),
 keccak256("1"),
 chainId,
 verifyingContract,
 salt
 )
 );
 }
 function getChainId_r() public view returns (uint256 networkID) {
 return chainId;
 }
 modifier onlyOwner {
 require(
 msg.sender == owner,
  "Only the contract owner is allowed to use this function."
 );
 _;
 }
 function setENS_r(address reverseRegistrarAddr, string memory name)
 public
 onlyOwner
 {
 reverseRegistrar = ReverseRegistrar(reverseRegistrarAddr);
 reverseRegistrar.setName_r(name);
 }
 function withdrawFees_r(address token) external onlyOwner {
 uint total = tokens[token][owner];
 tokens[token][owner] = 0;
 if (token == address(0)) {
 owner.transfer(total);
 } else {
 require(
 IERC20(token).transfer(owner, total),
  "Could not successfully withdraw token"
 );
 }
 }
 function viewBalance_r(address token, address user)
 external
 view
 returns (uint balance)
 {
 return tokens[token][user];
 }
 function changeBaseFee_r(uint newFee) external onlyOwner {
 baseFee = newFee;
 }
 function changePaymentFee_r(uint newFee) external onlyOwner {
 paymentFee = newFee;
 }
 function getBaseFee_r() public view returns (uint feeAmt) {
 return baseFee;
 }
 function getPaymentFee_r() public view returns (uint feeAmt) {
 return paymentFee;
 }
 function getPaymentsForSender_r()
 external
 view
 returns (uint[] memory result)
 {
 Dictionary.Data storage payments = senderPayments[msg.sender];
 uint[] memory keys_r = payments.keys_r();
 return keys_r;
 }
 function disableRetrieveFunds_r(bool disabled) public onlyOwner {
 retrieveFundsEnabled = !disabled;
 }
 function disableCreatePayment_r(bool disabled) public onlyOwner {
 createPaymentEnabled = !disabled;
 }
 function getPaymentsForRecipient_r()
 external
 view
 returns (uint[] memory result)
 {
 Dictionary.Data storage payments = recipientPayments[msg.sender];
 uint[] memory keys_r = payments.keys_r();
 return keys_r;
 }
 function getPaymentInfo_r(uint paymentID)
 external
 view
 returns (
 uint holdTime,
 uint paymentOpenTime,
 uint paymentCloseTime,
 address token,
 uint sendAmount,
 address sender,
 address recipient,
 bytes memory codeHash,
 uint state
 )
 {
 Payment memory txn = allPayments[paymentID];
 return (txn.holdTime, txn.paymentOpenTime, txn.paymentCloseTime, txn.token, txn.sendAmount, txn.sender, txn.recipient, txn.codeHash, uint(
 txn.state
 ));
 }
 function cancelPayment_r(uint txnId) external {
 Payment memory txn = allPayments[txnId];
 require(
 txn.sender == msg.sender,
  "Payment sender does not match message sender."
 );
 require(
 txn.state == PaymentState.OPEN,
  "Payment must be open to cancel."
 );
 txn.paymentCloseTime = now;
 txn.state = PaymentState.CANCELLED;
 delete allPayments[txnId];
 recipientPayments[txn.recipient].remove_r(txnId);
 senderPayments[txn.sender].remove_r(txnId);
 if (txn.token == address(0)) {
 tokens[address(0)][txn.sender] = SafeMath.sub_r(
 tokens[address(0)][txn.sender],
 txn.sendAmount
 );
 txn.sender.transfer(txn.sendAmount);
 } else {
 withdrawToken_r(txn.token, txn.sender, txn.sender, txn.sendAmount);
 }
 emit PaymentClosed(
 txnId,
 txn.holdTime,
 txn.paymentOpenTime,
 txn.paymentCloseTime,
 txn.token,
 txn.sendAmount,
 txn.sender,
 txn.recipient,
 txn.codeHash,
 uint(txn.state)
 );
 }
 function transferToken_r(
 address token,
 address user,
 uint originalAmount,
 uint feeAmount
 ) internal {
 require(token != address(0));
 require(
 IERC20(token).transferFrom(
 user,
 address(this),
 SafeMath.add_r(originalAmount, feeAmount)
 )
 );
 tokens[token][user] = SafeMath.add_r(
 tokens[token][msg.sender],
 originalAmount
 );
 tokens[token][owner] = SafeMath.add_r(tokens[token][owner], feeAmount);
 }
 function withdrawToken_r(
 address token,
 address userFrom,
 address userTo,
 uint amount
 ) internal {
 require(token != address(0));
 require(IERC20(token).transfer(userTo, amount));
 tokens[token][userFrom] = SafeMath.sub_r(tokens[token][userFrom], amount);
 }
 function createPayment_r(
 uint amount,
 address payable recipient,
 uint holdTime,
 bytes calldata codeHash
 ) external payable {
 return createTokenPayment_r(
 address(0),
 amount,
 recipient,
 holdTime,
 codeHash
 );
 }
 function getBalance_r(address token) external view returns (uint amt) {
 return tokens[token][msg.sender];
 }
 function getPaymentId_r(address recipient, bytes memory codeHash)
 public
 pure
 returns (uint result)
 {
 bytes memory txnIdBytes = abi.encodePacked(
 keccak256(abi.encodePacked(codeHash, recipient))
 );
 uint txnId = sliceUint_r(txnIdBytes);
 return txnId;
 }
 function createTokenPayment_r(
 address token,
 uint amount,
 address payable recipient,
 uint holdTime,
 bytes memory codeHash
 ) public payable {
 require(createPaymentEnabled, "The create payments functionality is currently disabled");
 uint paymentFeeTotal = uint(
 SafeMath.mul_r(paymentFee, amount) / (1 ether)
 );
 if (token == address(0)) {
 require(
 msg.value >= (SafeMath.add_r(
 SafeMath.add_r(amount, baseFee),
 paymentFeeTotal
 )),
  "Message value is not enough to cover amount and fees"
 );
 } else {
 require(
 msg.value >= baseFee,
  "Message value is not enough to cover base fee"
 );
 }
 Dictionary.Data storage sendertxns = senderPayments[msg.sender];
 Dictionary.Data storage recipienttxns = recipientPayments[recipient];
 uint txnId = getPaymentId_r(recipient, codeHash);
 require(
 allPayments[txnId].sender == address(0),
  "Payment ID must be unique. Use a different passphrase hash."
 );
 bytes memory val = "\x20";
 sendertxns.set_r(txnId, val);
 recipienttxns.set_r(txnId, val);
 Payment memory txn = Payment(
 holdTime,
 now,
 0,
 token,
 amount,
 msg.sender,
 recipient,
 codeHash,
 PaymentState.OPEN
 );
 allPayments[txnId] = txn;
 if (token == address(0)) {
 tokens[address(0)][msg.sender] = SafeMath.add_r(
 tokens[address(0)][msg.sender],
 amount
 );
 tokens[address(0)][owner] = SafeMath.add_r(
 tokens[address(0)][owner],
 SafeMath.sub_r(msg.value, amount)
 );
 } else {
 tokens[address(0)][owner] = SafeMath.add_r(
 tokens[address(0)][owner],
 msg.value
 );
 transferToken_r(token, msg.sender, amount, paymentFeeTotal);
 }
 emit PaymentOpened(
 txnId,
 txn.holdTime,
 txn.paymentOpenTime,
 txn.paymentCloseTime,
 txn.token,
 txn.sendAmount,
 txn.sender,
 txn.recipient,
 txn.codeHash
 );
 }
 function retrieveFundsForRecipient_r(
 uint256 txnId,
 address sender,
 address recipient,
 string memory passphrase,
 bytes32 sigR,
 bytes32 sigS,
 uint8 sigV
 ) public {
 RetrieveFundsRequest memory request = RetrieveFundsRequest(
 txnId,
 sender,
 recipient,
 passphrase
 );
 address signer = ecrecover(
 hashRetrieveFundsRequest_r(request),
 sigV,
 sigR,
 sigS
 );
 require(
 recipient == signer,
  "The message recipient must be the same as the signer of the message"
 );
 Payment memory txn = allPayments[txnId];
 require(
 txn.recipient == recipient,
  "The payment's recipient must be the same as signer of the message"
 );
 retrieveFunds_r(txn, txnId, passphrase);
 }
 function retrieveFundsAsRecipient_r(uint txnId, string memory code) public {
 Payment memory txn = allPayments[txnId];
 require(
 txn.recipient == msg.sender,
  "Message sender must match payment recipient"
 );
 retrieveFunds_r(txn, txnId, code);
 }
 function retrieveFunds_r(Payment memory txn, uint txnId, string memory code)
 private
 {
 require(retrieveFundsEnabled, "The retrieve funds functionality is currently disabled.");
 require(
 txn.state == PaymentState.OPEN,
  "Payment must be open to retrieve funds"
 );
 bytes memory actualHash = abi.encodePacked(
 keccak256(abi.encodePacked(code, txn.recipient))
 );
 require(
 sliceUint_r(actualHash) == sliceUint_r(txn.codeHash),
  "Passphrase is not correct"
 );
 require(
 (txn.paymentOpenTime + txn.holdTime) > now,
  "Hold time has already expired"
 );
 txn.paymentCloseTime = now;
 txn.state = PaymentState.COMPLETED;
 delete allPayments[txnId];
 recipientPayments[txn.recipient].remove_r(txnId);
 senderPayments[txn.sender].remove_r(txnId);
 if (txn.token == address(0)) {
 txn.recipient.transfer(txn.sendAmount);
 tokens[address(0)][txn.sender] = SafeMath.sub_r(
 tokens[address(0)][txn.sender],
 txn.sendAmount
 );
 } else {
 withdrawToken_r(txn.token, txn.sender, txn.recipient, txn.sendAmount);
 }
 emit PaymentClosed(
 txnId,
 txn.holdTime,
 txn.paymentOpenTime,
 txn.paymentCloseTime,
 txn.token,
 txn.sendAmount,
 txn.sender,
 txn.recipient,
 txn.codeHash,
 uint(txn.state)
 );
 }
 function sliceUint_r(bytes memory bs) public pure returns (uint) {
 uint start = 0;
 if (bs.length < start + 32) {
 return 0;
 }
 uint x;
 assembly {
 x := mload(add_r(bs, add_r(0x20, start)))
 }
 return x;
 }
}