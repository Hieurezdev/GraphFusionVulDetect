pragma solidity >=0.8.0;
// [flatten] spdx removed
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)
// [flatten] version pragma removed

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
// [flatten] spdx removed
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)
// [flatten] version pragma removed

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}
// [flatten] spdx removed
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)
// [flatten] version pragma removed
// [flatten] import inlined;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
// [flatten] version pragma removed

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
// [flatten] version pragma removed

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
// [flatten] version pragma removed

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// [flatten] version pragma removed
// [flatten] import inlined;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// [flatten] spdx removed
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
// [flatten] version pragma removed

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
// [flatten] spdx removed
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)
// [flatten] version pragma removed

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// [flatten] spdx removed
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}
// [flatten] spdx removed
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)
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
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

contract UniswapHandler {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;

    /**
     * @dev Swaps tokens
     * @param _path An array of addresses from tokenIn to tokenOut
     * @param _amountIn Amount of input tokens
     * @param _amountOutMin Mininum amount of output tokens
     * @param _recipient Address to send output tokens to
     * @return Amount of output tokens received
     */
//    SWC-116-Block values as a proxy for time:L38
    function _swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient
    ) internal returns (uint256) {
        IERC20(_path[0]).safeIncreaseAllowance(address(router), _amountIn);

        uint256[] memory amounts = router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _recipient,
            block.timestamp + 120
        );

        return amounts[_path.length - 1];
    }

    function getReserves(address _tokenIn, address _tokenOut)
        external
        view
        returns (uint256 reserveIn, uint256 reserveOut)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(
            factory.getPair(_tokenIn, _tokenOut)
        );

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        return
            _tokenIn < _tokenOut ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /**
     * @dev Gets the min amount from a swap
     * @param _amountIn Amount of input token
     * @param _path An array of addresses from tokenIn to tokenOut
     * @return Min amount out
     */
    function getAmountOutMin(uint256 _amountIn, address[] memory _path)
        public
        view
        returns (uint256)
    {
        uint256[] memory amountOutMins = router.getAmountsOut(_amountIn, _path);
        return amountOutMins[_path.length - 1];
    }

    function getAmountsOut(uint256 _amountIn, address[] memory _path)
        external
        view
        returns (uint256[] memory)
    {
        return router.getAmountsOut(_amountIn, _path);
    }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

contract OrderBook is UniswapHandler, Pausable {
    enum Status {
        None,
        Open,
        Filled,
        Canceled
    }
    struct Order {
        bytes32 id;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        address recipient;
        address creator;
        uint256 createdAt;
        uint256 expiration;
        Status status;
    }

    mapping(bytes32 => Order) public orders;
    mapping(address => uint256) private _nonces;

    // User addr => Token addr => Locked balance (in orders)
    mapping(address => mapping(address => uint256)) internal _lockedBalance;

    bytes32[] public openOrders;

    event OrderPlaced(
        bytes32 indexed orderId,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address indexed recipient,
        address indexed creator,
        uint256 expiration,
        uint256 timestamp
    );

    event OrderCanceled(
        bytes32 indexed orderId,
        address indexed creator,
        uint256 timestamp
    );


    /**
     * @notice Places an order
     * @param _tokenIn Source token
     * @param _tokenOut Destination token
     * @param _amountIn Amount of source token
     * @param _amountOutMin Min expected amount of dest token
     * @param _recipient Address of dest token recipient
     * @param _expiration Unix timestamp of order expiration
     */
    
    function placeOrder(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient,
        uint256 _expiration
    ) external whenNotPaused {
        require(_tokenIn != address(0), "Invalid input token address");
        require(_tokenOut != address(0), "Invalid output token address");
        require(_amountIn > 0, "Invalid input amount");
        require(_amountOutMin > 0, "Invalid output amount");
        require(_recipient != address(0), "Invalid recipient address");
        require(_expiration > block.timestamp, "Invalid expiration timestamp"); // SWC-116-Block values as a proxy for time:L76

        uint256 balance = IERC20(_tokenIn).balanceOf(msg.sender);
        require(balance >= _amountIn, "Insufficient balance");

        uint256 lockedBalance = _lockedBalance[msg.sender][_tokenIn];
        uint256 availableBalance = balance > lockedBalance
            ? balance - lockedBalance
            : 0;
        require(availableBalance >= _amountIn, "Unavailable balance");

        uint256 allowance = IERC20(_tokenIn).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= _amountIn, "Insufficient allowance");

        bytes32 id = keccak256(
            abi.encodePacked(address(this), msg.sender, _nonces[msg.sender]++)
        );

        Order storage order = orders[id];
        order.id = id;
        order.tokenIn = _tokenIn;
        order.tokenOut = _tokenOut;
        order.amountIn = _amountIn;
        order.amountOutMin = _amountOutMin;
        order.recipient = _recipient;
        order.creator = msg.sender;
        order.createdAt = block.timestamp; // SWC-116-Block values as a proxy for time:L105
        order.expiration = _expiration;

        _lockedBalance[order.creator][order.tokenIn] += order.amountIn;

        _addOpenOrder(order);

        emit OrderPlaced(
            id,
            _tokenIn,
            _tokenOut,
            _amountIn,
            _amountOutMin,
            _recipient,
            msg.sender,
            _expiration,
            block.timestamp
        );
    }

    /**
     * @notice Cancels an open order
     * @dev Can only be called by order creator
     * @param _orderId Order id
     */
    function cancelOrder(bytes32 _orderId) external {
        Order storage order = orders[_orderId];
        require(msg.sender == order.creator, "Only order creator");
        _cancelOrder(order);
    }

    /**
     * @notice Batch cancels expired orders
     * @param _orderIds An array of order ids
     */
    function cancelExpiredOrders(bytes32[] memory _orderIds) external {
        for (uint256 i = 0; i < _orderIds.length; i++) {
            bytes32 orderId = _orderIds[i];
            Order storage order = orders[orderId];
// SWC-116-Block values as a proxy for time:L145
            if (order.expiration <= block.timestamp) {
                _cancelOrder(order);
            }
        }
    }

    /**
     * @notice Cancels an open order
     * @param _order Order struct object
     */
    function _cancelOrder(Order storage _order) private {
        require(_order.status == Status.Open, "Cannot cancel unopen order");

        _order.status = Status.Canceled;
        _lockedBalance[_order.creator][_order.tokenIn] -= _order.amountIn;
        _removeOpenOrder(_order.id);

        emit OrderCanceled(_order.id, _order.creator, block.timestamp);
    }

    /**
     * @notice Removes an order from `openOrders` array
     * @param _orderId Order id
     */
    function _removeOpenOrder(bytes32 _orderId) internal {
        uint256 length = openOrders.length;
        for (uint256 i = 0; i < length; i++) {
            if (openOrders[i] == _orderId) {
                openOrders[i] = openOrders[length - 1];
                openOrders.pop();
                break;
            }
        }
    }

    /**
     * @notice Add an order to `openOrders` array
     * @param _order Order struct object
     */
    function _addOpenOrder(Order storage _order) private {
        _order.status = Status.Open;
        openOrders.push(_order.id);
    }

    /**
     * @notice Returns available `_token` balance for `_account`
     * @param _account Account address
     * @param _token Token address
     * @return Available balance
     */
    function getAvailableBalance(address _account, address _token)
        external
        view
        returns (uint256)
    {
        uint256 balance = IERC20(_token).balanceOf(_account);
        uint256 lockedBalance = _lockedBalance[_account][_token];
        return balance > lockedBalance ? balance - lockedBalance : 0;
    }

    /**
     * @notice Returns locked `_token` balance for `_account`
     * @dev Tokens are only marked as 'locked'. They are not actually stored on this contract's balance
     * @param _account Account address
     * @param _token Token address
     * @return Balance marked as 'locked'
     */
    function getLockedBalance(address _account, address _token)
        external
        view
        returns (uint256)
    {
        return _lockedBalance[_account][_token];
    }

    function getNonce(address _account) external view returns (uint256) {
        return _nonces[_account];
    }

    function getOrder(bytes32 _orderId)
        public
        view
        returns (
            bytes32 id,
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 amountOutMin,
            address recipient,
            address creator,
            uint256 createdAt,
            uint256 expiration,
            uint8 status
        )
    {
        Order storage order = orders[_orderId];
        id = order.id;
        tokenIn = order.tokenIn;
        tokenOut = order.tokenOut;
        amountIn = order.amountIn;
        amountOutMin = order.amountOutMin;
        recipient = order.recipient;
        createdAt = order.createdAt;
        creator = order.creator;
        expiration = order.expiration;
        status = uint8(order.status);
    }

    function getOpenOrders() external view returns (bytes32[] memory) {
        return openOrders;
    }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

contract MateCore is OrderBook, FeeManager, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable mate;

    constructor(
        address _router,
        address _mate,
        address _feeTo
    ) {
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(router.factory());
        mate = _mate;
        feeTo = _feeTo;
    }

    event OrderExecuted(
        bytes32 indexed orderId,
        address indexed creator,
        address indexed executor,
        uint256 amountOut,
        uint256 timestamp
    );

    /**
     * @notice Checks all params, conditions and identifies whether an order can be executed at the moment
     * @param _orderId Order id
     * @param _pathToTokenOut An array of token addresses from tokenIn to tokenOut
     */
    function canExecuteOrder(bytes32 _orderId, address[] memory _pathToTokenOut)
        external
        view
        returns (bool success, string memory reason)
    {
        return _canExecuteOrder(_orderId, _pathToTokenOut, new address[](0));
    }

    /**
     * @notice Checks all params, conditions and identifies whether an order can be executed at the moment
     * @param _orderId Order id
     * @param _pathToTokenOut An array of token addresses from tokenIn to tokenOut
     * @param _pathToMate An array of token addresses from tokenIn to $MATE
     */
    function canExecuteOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) external view returns (bool success, string memory reason) {
        return _canExecuteOrder(_orderId, _pathToTokenOut, _pathToMate);
    }

    /**
     * @notice Checks all params, conditions and identifies whether an order can be executed at the moment
     * @dev _pathToMate is used only if executor wants to receive fees in $MATE
     * @param _orderId Order id
     * @param _pathToTokenOut An array of token addresses from tokenIn to tokenOut
     * @param _pathToMate An array of token addresses from tokenIn to $MATE
     */
    function _canExecuteOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) internal view returns (bool success, string memory reason) {
        if (paused()) {
            return (false, "Paused");
        }

        Order storage order = orders[_orderId];

        uint256 balance = IERC20(order.tokenIn).balanceOf(order.creator);
        if (balance < order.amountIn) return (false, "Insufficient balance");

        uint256 allowance = IERC20(order.tokenIn).allowance(
            order.creator,
            address(this)
        );
        if (allowance < order.amountIn)
            return (false, "Insufficient allowance");
//    SWC-116-Block values as a proxy for time: L86
        if (block.timestamp > order.expiration) return (false, "Expired order");

        if (order.status != Status.Open) return (false, "Invalid status");

        if (
            _pathToTokenOut.length < 1 ||
            _pathToTokenOut[0] != order.tokenIn ||
            _pathToTokenOut[_pathToTokenOut.length - 1] != order.tokenOut
        ) return (false, "Invalid path to output token");

        if (order.tokenIn != mate && _pathToMate.length > 1) {
            if (
                _pathToMate[0] != order.tokenIn ||
                _pathToMate[_pathToMate.length - 1] != mate
            ) return (false, "Invalid path to Mate token");
        }

        (uint256 fee, uint256 executorFee) = calculateFees(order.amountIn);

        uint256 amountInWithFees = order.amountIn - fee - executorFee;

        uint256 amountOutMin = getAmountOutMin(
            amountInWithFees,
            _pathToTokenOut
        );

        if (amountOutMin < order.amountOutMin)
            return (false, "Insufficient output amount");

        return (true, "");
    }

    /**
     * @notice Executes a limit order
     * @param _orderId Order id
     * @param _pathToTokenOut An array of token addresses from tokenIn to tokenOut
     */
    function executeOrder(bytes32 _orderId, address[] memory _pathToTokenOut)
        external
    {
        _executeOrder(_orderId, _pathToTokenOut, new address[](0));
    }

    /**
     * @notice Executes a limit order
     * @param _orderId Order id
     * @param _pathToTokenOut An array of token addresses from tokenIn to tokenOut
     * @param _pathToMate An array of token addresses from tokenIn to $MATE
     */
    function executeOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) external {
        _executeOrder(_orderId, _pathToTokenOut, _pathToMate);
    }

    /**
     * @notice Executes a limit order
     * @dev _pathToMate is optional and used only if executor wants to receive fees in $MATE
     * @param _orderId Order id
     * @param _pathToTokenOut An array of token addresses from tokenIn to tokenOut
     * @param _pathToMate An array of token addresses from tokenIn to $MATE
     */
    function _executeOrder(
        bytes32 _orderId,
        address[] memory _pathToTokenOut,
        address[] memory _pathToMate
    ) internal nonReentrant whenNotPaused {
        Order storage order = orders[_orderId];

        uint256 balance = IERC20(order.tokenIn).balanceOf(order.creator);
        require(balance >= order.amountIn, "Insufficient balance");

        uint256 allowance = IERC20(order.tokenIn).allowance(
            order.creator,
            address(this)
        );
        require(allowance >= order.amountIn, "Insufficient allowance");
//    SWC-116-Block values as a proxy for time: L166
        require(block.timestamp <= order.expiration, "Expired order");

        require(order.status == Status.Open, "Invalid status");

        require(
            _pathToTokenOut.length > 1 &&
                _pathToTokenOut[0] == order.tokenIn &&
                _pathToTokenOut[_pathToTokenOut.length - 1] == order.tokenOut,
            "Invalid path to output token"
        );

        if (order.tokenIn != mate && _pathToMate.length > 1) {
            require(
                _pathToMate[0] == order.tokenIn &&
                    _pathToMate[_pathToMate.length - 1] == mate,
                "Invalid path to Mate token"
            );
        }

        (uint256 fee, uint256 executorFee) = calculateFees(order.amountIn);

        uint256 amountInWithFees = order.amountIn - fee - executorFee;

        uint256 amountOutMin = getAmountOutMin(
            amountInWithFees,
            _pathToTokenOut
        );

        require(
            amountOutMin >= order.amountOutMin,
            "Insufficient output amount"
        );

        order.status = Status.Filled;

        _lockedBalance[order.creator][order.tokenIn] -= order.amountIn;

        IERC20(order.tokenIn).safeTransferFrom(
            order.creator,
            address(this),
            order.amountIn
        );

        uint256 amountOut = _swap(
            _pathToTokenOut,
            amountInWithFees,
            order.amountOutMin,
            order.recipient
        );

        _removeOpenOrder(order.id);

        _transferFees(fee, executorFee, order.tokenIn, _pathToMate);
//    SWC-116-Block values as a proxy for time: L225
        emit OrderExecuted(
            _orderId,
            order.creator,
            msg.sender,
            amountOut,
            block.timestamp
        );
    }

    /**
     * @notice Transfers fees to `feeTo` and executor
     * @param _fee Protocol fee
     * @param _executorFee Executor fee
     * @param _tokenIn Source token of limit order
     * @param _pathToMate An array of token addresses from tokenIn to $MATE
     */
    function _transferFees(
        uint256 _fee,
        uint256 _executorFee,
        address _tokenIn,
        address[] memory _pathToMate
    ) internal {
        if (_fee > 0) {
            IERC20(_tokenIn).safeTransfer(feeTo, _fee);
        }

        if (_executorFee > 0) {
            if (_tokenIn == mate || _pathToMate.length <= 1) {
                IERC20(_tokenIn).safeTransfer(msg.sender, _executorFee);
            } else {
                _swap(
                    _pathToMate,
                    _executorFee,
                    getAmountOutMin(_executorFee, _pathToMate),
                    msg.sender
                );
            }
        }
    }

    /**
     * @notice Pauses the contract in case of emergency
     * @dev Can only be called by owner (governance)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     * @dev Can only be called by owner (governance)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
