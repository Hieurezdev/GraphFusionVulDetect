pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;
// [flatten] spdx removed
// [flatten] version pragma removed

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
// [flatten] spdx removed
// [flatten] version pragma removed

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// [flatten] spdx removed
// [flatten] version pragma removed

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] pragma hoisted

interface IBasketFacet {

    event TokenAdded(address indexed _token);
    event TokenRemoved(address indexed _token);
    event EntryFeeSet(uint256 fee);
    event ExitFeeSet(uint256 fee);
    event AnnualizedFeeSet(uint256 fee);
    event FeeBeneficiarySet(address indexed beneficiary);
    event EntryFeeBeneficiaryShareSet(uint256 share);
    event ExitFeeBeneficiaryShareSet(uint256 share);

    event PoolJoined(address indexed who, uint256 amount);
    event PoolExited(address indexed who, uint256 amount);
    event FeeCharged(uint256 amount);
    event LockSet(uint256 lockBlock);
    event CapSet(uint256 cap);

    /** 
        @notice Sets entry fee paid when minting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setEntryFee(uint256 _fee) external;

    /**
        @notice Get the entry fee
        @return Current entry fee
    */
    function getEntryFee() external view returns(uint256);

    /**
        @notice Set the exit fee paid when exiting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setExitFee(uint256 _fee) external;

    /**
        @notice Get the exit fee
        @return Current exit fee
    */
    function getExitFee() external view returns(uint256);

    /**
        @notice Set the annualized fee. Often referred to as streaming fee
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setAnnualizedFee(uint256 _fee) external;

    /**
        @notice Get the annualized fee.
        @return Current annualized fee.
    */
    function getAnnualizedFee() external view returns(uint256);

    /**
        @notice Set the address receiving the fees.
    */
    function setFeeBeneficiary(address _beneficiary) external;

    /**
        @notice Get the fee benificiary
        @return The current fee beneficiary
    */
    function getFeeBeneficiary() external view returns(address);

    /**
        @notice Set the fee beneficiaries share of the entry fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100% 
    */
    function setEntryFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the entry fee beneficiary share
        @return Feeshare amount
    */
    function getEntryFeeBeneficiaryShare() external view returns(uint256);

    /**
        @notice Set the fee beneficiaries share of the exit fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100% 
    */
    function setExitFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the exit fee beneficiary share
        @return Feeshare amount
    */
    function getExitFeeBeneficiaryShare() external view returns(uint256);

    /**
        @notice Calculate the oustanding annualized fee
        @return Amount of pool tokens to be minted to charge the annualized fee
    */
    function calcOutStandingAnnualizedFee() external view returns(uint256);

    /**
        @notice Charges the annualized fee
    */
    function chargeOutstandingAnnualizedFee() external;

    /**
        @notice Pulls underlying from caller and mints the pool token
        @param _amount Amount of pool tokens to mint
    */
    function joinPool(uint256 _amount) external;

    /**
        @notice Burns pool tokens from the caller and returns underlying assets
    */
    function exitPool(uint256 _amount) external;

    /**
        @notice Get if the pool is locked or not. (not accepting exit and entry)
        @return Boolean indicating if the pool is locked
    */
    function getLock() external view returns (bool);

    /**
        @notice Get the block until which the pool is locked
        @return The lock block
    */
    function getLockBlock() external view returns (uint256);

    /**
        @notice Set the lock block
        @param _lock Block height of the lock
    */
    function setLock(uint256 _lock) external;

    /**
        @notice Get the maximum of pool tokens that can be minted
        @return Cap
    */
    function getCap() external view returns (uint256);

    /**
        @notice Set the maximum of pool tokens that can be minted
        @param _maxCap Max cap 
    */
    function setCap(uint256 _maxCap) external;

    /**
        @notice Get the amount of tokens owned by the pool
        @param _token Addres of the token
        @return Amount owned by the contract
    */
    function balance(address _token) external view returns (uint256);

    /**
        @notice Get the tokens in the pool
        @return Array of tokens in the pool
    */
    function getTokens() external view returns (address[] memory);

    /**
        @notice Add a token to the pool. Should have at least a balance of 10**6
        @param _token Address of the token to add
    */
    function addToken(address _token) external;

    /**
        @notice Removes a token from the pool
        @param _token Address of the token to remove
    */
    function removeToken(address _token) external;

    /**
        @notice Checks if a token was added to the pool
        @param _token address of the token
        @return If token is in the pool or not
    */
    function getTokenInPool(address _token) external view returns (bool);

    /**
        @notice Calculate the amounts of underlying needed to mint that pool amount.
        @param _amount Amount of pool tokens to mint
        @return tokens Tokens needed
        @return amounts Amounts of underlying needed
    */
    function calcTokensForAmount(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    /**
        @notice Calculate the amounts of underlying to receive when burning that pool amount
        @param _amount Amount of pool tokens to burn
        @return tokens Tokens returned
        @return amounts Amounts of underlying returned
    */
    function calcTokensForAmountExit(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);
}
// [flatten] spdx removed
// [flatten] version pragma removed

library LibERC20Storage {
  bytes32 constant ERC_20_STORAGE_POSITION = keccak256(
    // Compatible with pie-smart-pools
    "PCToken.storage.location"
  );

  struct ERC20Storage {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
  }

  function erc20Storage() internal pure returns (ERC20Storage storage es) {
    bytes32 position = ERC_20_STORAGE_POSITION;
    assembly {
      es.slot := position
    }
  }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

library LibERC20 {
  using SafeMath for uint256;

  // Need to include events locally because `emit Interface.Event(params)` does not work
  event Transfer(address indexed from, address indexed to, uint256 amount);

  function mint(address _to, uint256 _amount) internal {
    LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

    es.balances[_to] = es.balances[_to].add(_amount);
    es.totalSupply = es.totalSupply.add(_amount);
    emit Transfer(address(0), _to, _amount);
  }

  function burn(address _from, uint256 _amount) internal {
    LibERC20Storage.ERC20Storage storage es = LibERC20Storage.erc20Storage();

    es.balances[_from] = es.balances[_from].sub(_amount);
    es.totalSupply = es.totalSupply.sub(_amount);
    emit Transfer(_from, address(0), _amount);
  }
}
// [flatten] spdx removed
// [flatten] version pragma removed

library LibReentryProtectionStorage {
  bytes32 constant REENTRY_STORAGE_POSITION = keccak256(
    "diamond.standard.reentry.storage"
  );

  struct RPStorage {
    uint256 lockCounter;
  }

  function rpStorage() internal pure returns (RPStorage storage bs) {
    bytes32 position = REENTRY_STORAGE_POSITION;
    assembly {
      bs.slot := position
    }
  }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;

contract ReentryProtection {
  modifier noReentry {
    // Use counter to only write to storage once
    LibReentryProtectionStorage.RPStorage storage s = LibReentryProtectionStorage.rpStorage();
    s.lockCounter++;
    uint256 lockValue = s.lockCounter;
    _;
    require(
      lockValue == s.lockCounter,
      "ReentryProtectionFacet.noReentry: reentry detected"
    );
  }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;

contract CallProtection {
    modifier protectedCall() {
        require(
            msg.sender == LibDiamond.diamondStorage().contractOwner ||
            msg.sender == address(this), "NOT_ALLOWED"
        );
        _;
    }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;

library LibBasketStorage {
  bytes32 constant BASKET_STORAGE_POSITION = keccak256(
    "diamond.standard.basket.storage"
  );

  struct BasketStorage {
    uint256 lockBlock;
    uint256 maxCap;
    IERC20[] tokens;
    mapping(address => bool) inPool;
    uint256 entryFee;
    uint256 entryFeeBeneficiaryShare; // amount of entry fee that goes to feeBeneficiary
    uint256 exitFee;
    uint256 exitFeeBeneficiaryShare; // amount of exit fee that goes to the pool itself
    uint256 annualizedFee;
    uint256 lastAnnualizedFeeClaimed;
    address feeBeneficiary;
  }

  function basketStorage() internal pure returns (BasketStorage storage bs) {
    bytes32 position = BASKET_STORAGE_POSITION;
    assembly {
      bs.slot := position
    }
  }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

contract BasketFacet is ReentryProtection, CallProtection, IBasketFacet {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MIN_AMOUNT = 10**6;
    uint256 public constant MAX_ENTRY_FEE = 10**17; // 10%
    uint256 public constant MAX_EXIT_FEE = 10**17; // 10%
    uint256 public constant MAX_ANNUAL_FEE = 10**17; // 10%

    

    function addToken(address _token) external override protectedCall {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        require(!bs.inPool[_token], "TOKEN_ALREADY_IN_POOL");
        // Enforce minimum to avoid rounding errors; (Minimum value is the same as in Balancer)
        require(balance(_token) >= MIN_AMOUNT, "BALANCE_TOO_SMALL");

        bs.inPool[_token] = true;
        bs.tokens.push(IERC20(_token));

        emit TokenAdded(_token);
    }

    function removeToken(address _token) external override protectedCall {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();

        require(bs.inPool[_token], "TOKEN_NOT_IN_POOL");

        bs.inPool[_token] = false;

        // remove token from array
        // TODO consider limiting max amount of tokens to mitigate running out of gas.
        // SWC-128-DoS With Block Gas Limit: L46 - L53
        for(uint256 i; i < bs.tokens.length; i ++) {
            if(address(bs.tokens[i]) == _token) {
                bs.tokens[i] = bs.tokens[bs.tokens.length - 1];
                bs.tokens.pop();

                break;
            }
        }

        emit TokenRemoved(_token);
    }

    function setEntryFee(uint256 _fee) external override protectedCall {
        require(_fee <= MAX_ENTRY_FEE, "FEE_TOO_BIG");
        LibBasketStorage.basketStorage().entryFee = _fee;
        emit EntryFeeSet(_fee);
    }

    function getEntryFee() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().entryFee;
    }

    function setExitFee(uint256 _fee) external override protectedCall {
        require(_fee <= MAX_EXIT_FEE, "FEE_TOO_BIG");
        LibBasketStorage.basketStorage().exitFee = _fee;
        emit ExitFeeSet(_fee);
    }

    function getExitFee() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().exitFee;
    }

    function setAnnualizedFee(uint256 _fee) external override protectedCall {
        require(_fee <= MAX_ANNUAL_FEE, "FEE_TOO_BIG");
        LibBasketStorage.basketStorage().annualizedFee = _fee;
        emit AnnualizedFeeSet(_fee);
    }

    function getAnnualizedFee() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().annualizedFee;
    }

    function setFeeBeneficiary(address _beneficiary) external override protectedCall {
        LibBasketStorage.basketStorage().feeBeneficiary = _beneficiary;
        emit FeeBeneficiarySet(_beneficiary);
    }

    function getFeeBeneficiary() external view override returns(address) {
        return LibBasketStorage.basketStorage().feeBeneficiary;
    }

    function setEntryFeeBeneficiaryShare(uint256 _share) external override protectedCall {
        require(_share <= 10**18, "FEE_SHARE_TOO_BIG");
        LibBasketStorage.basketStorage().entryFeeBeneficiaryShare = _share;
        emit EntryFeeBeneficiaryShareSet(_share);
    }

    function getEntryFeeBeneficiaryShare() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().entryFeeBeneficiaryShare;
    }

    function setExitFeeBeneficiaryShare(uint256 _share) external override protectedCall {
        require(_share <= 10**18, "FEE_SHARE_TOO_BIG");
        LibBasketStorage.basketStorage().exitFeeBeneficiaryShare = _share;
        emit ExitFeeBeneficiaryShareSet(_share);
    }

    function getExitFeeBeneficiaryShare() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().exitFeeBeneficiaryShare;
    }


    function joinPool(uint256 _amount) external override noReentry {
        require(!this.getLock(), "POOL_LOCKED");
        chargeOutstandingAnnualizedFee();
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply;
        require(totalSupply.add(_amount) < this.getCap(), "MAX_POOL_CAP_REACHED");

        uint256 feeAmount = _amount.mul(bs.entryFee).div(10**18);

        // SWC-128-DoS With Block Gas Limit: L128 - L132
        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 tokenAmount = balance(address(token)).mul(_amount.add(feeAmount)).div(totalSupply);
            require(tokenAmount != 0, "AMOUNT_TOO_SMALL");
            token.safeTransferFrom(msg.sender, address(this), tokenAmount);
        }

        // If there is any fee that should go to the beneficiary mint it
        if(
            feeAmount != 0 &&
            bs.entryFeeBeneficiaryShare != 0 &&
            bs.feeBeneficiary != address(0)
        ) {
            uint256 feeBeneficiaryShare = feeAmount.mul(bs.entryFeeBeneficiaryShare).div(10**18);
            if(feeBeneficiaryShare != 0) {
                LibERC20.mint(bs.feeBeneficiary, feeBeneficiaryShare);
            }
        }

        LibERC20.mint(msg.sender, _amount);
        emit PoolJoined(msg.sender, _amount);
    }

    // Must be overwritten to withdraw from strategies
    function exitPool(uint256 _amount) external override virtual noReentry {
        require(!this.getLock(), "POOL_LOCKED");
        chargeOutstandingAnnualizedFee();
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply;

        uint256 feeAmount = _amount.mul(bs.exitFee).div(10**18);

        // SWC-128-DoS With Block Gas Limit: L161 - L168
        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 tokenBalance = balance(address(token));
            // redeem less tokens if there is an exit fee
            uint256 tokenAmount = tokenBalance.mul(_amount.sub(feeAmount)).div(totalSupply);
            require(tokenBalance.sub(tokenAmount) >= MIN_AMOUNT, "TOKEN_BALANCE_TOO_LOW");
            token.safeTransfer(msg.sender, tokenAmount);
        }

         // If there is any fee that should go to the beneficiary mint it
        if(
            feeAmount != 0 &&
            bs.exitFeeBeneficiaryShare != 0 &&
            bs.feeBeneficiary != address(0)
        ) {
            uint256 feeBeneficiaryShare = feeAmount.mul(bs.exitFeeBeneficiaryShare).div(10**18);
            if(feeBeneficiaryShare != 0) {
                LibERC20.mint(bs.feeBeneficiary, feeBeneficiaryShare);
            }
        }

        require(totalSupply.sub(_amount) >= MIN_AMOUNT, "POOL_TOKEN_BALANCE_TOO_LOW");
        LibERC20.burn(msg.sender, _amount);
        emit PoolExited(msg.sender, _amount);
    }


    function calcOutStandingAnnualizedFee() public view override returns(uint256) {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply;

        uint256 lastFeeClaimed = bs.lastAnnualizedFeeClaimed;
        uint256 annualizedFee = bs.annualizedFee;

        if(
            annualizedFee == 0 ||
            bs.feeBeneficiary == address(0) ||
            lastFeeClaimed == 0
        ) {
            return 0;
        }

        // SWC-116-Block values as a proxy for time: L204
        uint256 timePassed = block.timestamp.sub(lastFeeClaimed);

        return totalSupply.mul(annualizedFee).div(10**18).mul(timePassed).div(365 days);
    }

    function chargeOutstandingAnnualizedFee() public override {
        uint256 outStandingFee = calcOutStandingAnnualizedFee();
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();

        // SWC-116-Block values as a proxy for time: L214
        bs.lastAnnualizedFeeClaimed = block.timestamp;

        // if there is any fee to mint and the beneficiary is set
        // note: feeBeneficiary is already checked in calc function
        if(
            outStandingFee != 0
        ) {
            LibERC20.mint(bs.feeBeneficiary, outStandingFee);
        }

        emit FeeCharged(outStandingFee);
    }

    // returns true when locked
    function getLock() external view override returns(bool) {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        return bs.lockBlock == 0 || bs.lockBlock >= block.number;
    }

    function getTokenInPool(address _token) external view override returns(bool) {
        return LibBasketStorage.basketStorage().inPool[_token];
    }

    function getLockBlock() external view override returns(uint256) {
        return LibBasketStorage.basketStorage().lockBlock;
    }

    // lock up to and including _lock blocknumber
    function setLock(uint256 _lock) external override protectedCall {
        LibBasketStorage.basketStorage().lockBlock = _lock;
        emit LockSet(_lock);
    }

    function setCap(uint256 _maxCap) external override protectedCall {
        LibBasketStorage.basketStorage().maxCap = _maxCap;
        emit CapSet(_maxCap);
    }

    // Seperated balance function to allow yearn like strategies to be hooked up by inheriting from this contract and overriding
    function balance(address _token) public view override returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function getTokens() external view override returns (address[] memory) {
        IERC20[] memory tokens = LibBasketStorage.basketStorage().tokens;
        address[] memory result = new address[](tokens.length);

        for(uint256 i = 0; i < tokens.length; i ++) {
            result[i] = address(tokens[i]);
        }

        return(result);
    }

    function getCap() external view override returns(uint256){
        return LibBasketStorage.basketStorage().maxCap;
    }

    function calcTokensForAmount(uint256 _amount) external view override returns (address[] memory tokens, uint256[] memory amounts) {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply.add(calcOutStandingAnnualizedFee());

        tokens = new address[](bs.tokens.length);
        amounts = new uint256[](bs.tokens.length);

        // SWC-128-DoS With Block Gas Limit: L278 - L287
        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 tokenBalance = balance(address(token));
            uint256 tokenAmount = tokenBalance.mul(_amount).div(totalSupply);
            // Add entry fee
            tokenAmount = tokenAmount.add(tokenAmount.mul(bs.entryFee).div(10**18));

            tokens[i] = address(token);
            amounts[i] = tokenAmount;
        }

        return(tokens, amounts);
    }

    function calcTokensForAmountExit(uint256 _amount) external view override returns (address[] memory tokens, uint256[] memory amounts) {
        LibBasketStorage.BasketStorage storage bs = LibBasketStorage.basketStorage();
        uint256 feeAmount = _amount.mul(bs.exitFee).div(10**18);
        uint256 totalSupply = LibERC20Storage.erc20Storage().totalSupply.add(calcOutStandingAnnualizedFee());

        tokens = new address[](bs.tokens.length);
        amounts = new uint256[](bs.tokens.length);

        // SWC-128-DoS With Block Gas Limit: L301 - L308
        for(uint256 i; i < bs.tokens.length; i ++) {
            IERC20 token = bs.tokens[i];
            uint256 tokenBalance = balance(address(token));
            uint256 tokenAmount = tokenBalance.mul(_amount.sub(feeAmount)).div(totalSupply);

            tokens[i] = address(token);
            amounts[i] = tokenAmount;
        }

        return(tokens, amounts);
    }
}