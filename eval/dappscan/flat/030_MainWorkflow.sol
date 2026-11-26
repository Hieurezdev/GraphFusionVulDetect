pragma solidity 0.8.10;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
// [flatten] version pragma removed
// [flatten] import inlined;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}
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
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

contract MainWorkflow is DataStore, ReentrancyGuard {
    
    using SafeERC20 for ERC20;
    using Generic for *;
    using Guaranteed for *;
    using Lottery for DataTypes.Lottery;
    using OverSubscribe for DataTypes.OverSubscriptions;
    using Live for *;
    using Vesting for *;
    using LpProvision for DataTypes.Lp;
    using History for DataTypes.History;

    IManager internal _manager;
    address internal _campaignOwner; 
  
    modifier notAborted() {
        _require(!_isAborted(), Error.Code.Aborted);
        _;
    }
    
    constructor(IManager manager, address campaignOwner) {
        _manager = manager;
        _campaignOwner = campaignOwner;
    }
    
    //--------------------//
    // EXTERNAL FUNCTIONS //
    //--------------------//
   

    // uint : Guaranteed Amount or Lottery Amount
    // bool : bool guaranteed or pending
    // uint : over-subscribe max amount
    function getSubscribable(address user) external view returns (uint amount, bool guaranteed, uint overSubAmt) {
        if (getState(DataTypes.Ok.Finalized)) {
            (amount, guaranteed) = _store().getGuaranteedAmt(user);
            overSubAmt = _store().overSubscription.data.stdOverSubQty;
        }
    }

    function subscribe(uint amtBasic, uint amtOverSub, uint priority, uint eggTotalQty) external payable {
        DataTypes.Subscriptions storage subs = _subscriptions();
        bool subscribed = subs.items[msg.sender].paidCapital != 0; 
        uint capital = amtBasic + amtOverSub;
        
        _require(!_isAborted() && !subscribed && capital > 0 && _isPeriod(DataTypes.Period.Subscription), Error.Code.ValidationError);
        _transferIn(capital, DataTypes.FundType.Currency);
        
        // Try to subscribe with checks on amounts 
        (uint maxAlloc, bool isGuaranteed) = _store().getGuaranteedAmt(msg.sender);
        
        if (isGuaranteed) {
            _guaranteed().subscribe(amtBasic, maxAlloc);
        } else {
            _lottery().subscribe(amtBasic);
        }
   
        // Over-subscribe & Egg transfer in. 
        if (amtOverSub > 0) {
            _overSubscriptions().subscribe(amtOverSub, priority, eggTotalQty);
            _transferIn(eggTotalQty, DataTypes.FundType.Egg);
        }
      
        // Record
        _recordSubscription(subs, capital);
        
        // History
        // Data1 : Bit 0: Guaranteed | Bit 1 onwards: Amount in Currency
        // Data2 : 120 bits: OverSub Amt, 120 bits: EggBurnAmt, 16 bits: Priority 
         _require(amtBasic <= type(uint256).max >> 1 && amtOverSub <= type(uint120).max && priority <= type(uint16).max && eggTotalQty <= type(uint120).max, Error.Code.ValidationError);
         uint pack1 = (amtBasic << 1) | (isGuaranteed ? 1 : 0);
         uint pack2 = (amtOverSub) | (eggTotalQty << 120) | (priority << 240);
        _history().record(DataTypes.ActionType.Subscribe, msg.sender, pack1, pack2, true);
    }
    
    function getSubscriptionResult(address user) external view returns (DataTypes.SubscriptionResultParams memory p) {
        if (getState(DataTypes.Ok.Tally)) {
            p = _store().getSubscriptionResult(user);
        }
    }
    
    function getSubscription(address user) external view returns (DataTypes.SubscriptionParams memory p) {
        (p.guaranteedAmount, p.guaranteed) = _store().getGuaranteedSubscription(user);
        p.inLottery = _lottery().items[user].exist;
        p.lotteryAmount = _lottery().data.eachAllocationAmount;
        (, p.overSubAmount, p.priority, p.eggBurnAmount) = _overSubscriptions().getSubscription(user);
    }
    
    function getSubscribersCount() external view returns (uint) {
        return _subscriptions().count;
    }
    
    function getUserWhitelistInfo(address user) external view returns (bool, uint, uint, uint) {
        return _live().getUserWhitelistInfo(user);
    }
    
    function getHistory(address user, bool investor) external view returns (DataTypes.Action[] memory) {
        return (investor ?  _history().investor[user] : _history().campaignOwner[user]);
    }
    
    // Note: finishUp can only be called once
    // If a campaign is aborted, the campaignOwner will have o call fundOut() to get back their tokens.
    function finishUp() external nonReentrant {
        
         // Can call finishUp only after Public IDO ended OR hardCap is met //
         bool ok = (!_isAborted() && 
            !getState(DataTypes.Ok.FinishedUp) &&
            (_isPeriod(DataTypes.Period.IdoEnded) || (_hasOpened() && _live().getAllocLeftForLive() == 0)) );
         _require(ok, Error.Code.ValidationError);
        
        // Set state. Only called once.
        _setState(DataTypes.Ok.FinishedUp, true);
        
        // Depending on the sales amount, there might be some tokens left that need to return to campaign Owner
        uint fundInTokens = getFundInTokenRequired();
        
        // Has met SoftCap ?
        (bool softCapMet, uint fee, uint totalAfterFeeLp, uint unusedLpTokensQty, uint unsoldTokensQty) = _getFinishUpStats();
        _store().finalState = softCapMet ?  DataTypes.FinalState.Success : DataTypes.FinalState.Failure;    
        
        if (softCapMet) {
            // Send fee
            _transferOut(_manager.getFeeVault(), fee, DataTypes.FundType.Currency);
        
            // Project owner can get back the raised proceeding if there's no team vesting
            if (!_vesting().hasTeamVesting() ) {
                _transferOut(_campaignOwner, totalAfterFeeLp, DataTypes.FundType.Currency);
            } else {
                _vesting().data.teamLockAmount = totalAfterFeeLp;
            }
        
            // Return unsold & unused-lp tokens
            _transferOut(_campaignOwner, unusedLpTokensQty + unsoldTokensQty, DataTypes.FundType.Token);
            
            // Burn Used Eggs in over-subscription 
            uint burnAmt = _overSubscriptions().getBurnableEggsAfterTally();
            if (burnAmt>0) {
                ERC20Burnable(_manager.getEggAddress()).burn(burnAmt);
            }
        } else {
            // Refund all fundIn tokens to campaign Owner
            _transferOut(_campaignOwner, fundInTokens, DataTypes.FundType.Token);
        }
    }
    
    function buyTokens(uint fund) external payable {
        uint available = getAllocLeftForLive();
        _require(!_isAborted() && _isLivePeriod() && fund > 0 && available > 0 && fund <= available, Error.Code.CannotBuyToken);
        _store().buyTokens(fund, _isPeriod(DataTypes.Period.IdoWhitelisted));
    
        _transferIn(fund, DataTypes.FundType.Currency);
        _history().record(DataTypes.ActionType.BuyTokens, msg.sender, fund, true);
    }

     // Refund any excess/un-used fund from subscription //
    function refundExcess() external nonReentrant {
        (bool refunded, uint capital, uint egg) = getRefundable(msg.sender);
        _require(!refunded && getState(DataTypes.Ok.Tally), Error.Code.CannotRefundExcess);

        _subscriptions().items[msg.sender].refundedUnusedCapital = true;
        _history().record(DataTypes.ActionType.RefundExcess, msg.sender, capital, egg, true);

        _transferOut(msg.sender, capital, DataTypes.FundType.Currency);
        _transferOut(msg.sender, egg, DataTypes.FundType.Egg);
    }
    
    // Note: when a campaign did not hit softCap, or cancelled, users get a full refund.
    function returnFund() external nonReentrant {
        _require( (_store().finalState == DataTypes.FinalState.Failure ||
            _store().finalState == DataTypes.FinalState.Aborted) && 
            _store().returnFunds.amount[msg.sender]==0, Error.Code.CannotReturnFund);
      
        bool hasTally = getState(DataTypes.Ok.Tally);
        // If not yet Tally (eg when a  campaign is cancelled before Tally is called), we also need to return the subscription
        DataTypes.PurchaseDetail memory purchase = getPurchaseDetail(msg.sender, !hasTally);
    
        // Get total user purchase in currency
        uint total = purchase.total;
            
        if (total > 0) {
            _transferOut(msg.sender, total, DataTypes.FundType.Currency);
                
            uint egg;
            if (hasTally) {
                // Returns Egg if user has successfully subscribed in Over-subscription & Tally
                egg = _overSubscriptions().getBurnableEggs(msg.sender);
            } else {
                // if a campaign is cancelled before Tally, we need to return the egg amount
                (, , , egg) = _overSubscriptions().getSubscription(msg.sender);
            }
            _transferOut(msg.sender, egg, DataTypes.FundType.Egg);
                
            // Update 
           _store().returnFunds.amount[msg.sender] = total;
           
           _history().record(DataTypes.ActionType.ReturnFund, msg.sender, total, egg, true);
        }
    }
    
    function getClaimableByIntervals(address user, bool investor) external view returns (DataTypes.ClaimIntervalResult memory) {
        uint total = investor ? _getTotalPurchased(user) : _vesting().data.teamLockAmount;
        return _vesting().getClaimableByIntervals(user, investor).scaleBy(total);
    }
    
    function getClaimableByLinear(address user, bool investor) external view returns (DataTypes.ClaimLinearResult memory) {
        uint total = investor ? _getTotalPurchased(user) : _vesting().data.teamLockAmount;
        return _vesting().getClaimableByLinear(user, investor).scaleBy(total);
    }
    
    
    
    //--------------------//
    // PUBLIC FUCNTIONS   //
    //--------------------//
    
    function getFundInTokenRequired() public view override returns(uint) {
        (uint lpTokensNeeded, ) = _lp().getMaxRequiredTokensQty();
        return super.getFundInTokenRequired() + lpTokensNeeded;
    }
    
    function getPurchaseDetail(address user, bool includeRefundable) public view returns (DataTypes.PurchaseDetail memory) {
        return _store().getPurchaseDetail(user, getState(DataTypes.Ok.Tally), includeRefundable);
    }
    
    // uint : Amount subscribed by Guaranteed
    // uint : Max amount from lottery
    // uint : Max amount from over-subscribe
    function peekTally() public view returns (uint, uint, uint) {
        return (_guaranteed().totalSubscribed, _lottery().getTotal(), _overSubscriptions().getTotal());
    }
    
    // bool : refunded ?
    // uint : Refundable capital (if not yet refund), or the refunded Amount
    // uint : Refundable eggs (if not yet refund), or the refunded Eggs
    function getRefundable(address user) public view returns(bool refunded, uint capital, uint eggs) {
        // can only refund when tally is done //
        if (getState(DataTypes.Ok.Tally)) {
            refunded = _subscriptions().items[user].refundedUnusedCapital;
        
            uint lotteryRefund = _lottery().getRefundable(user);
            (capital, eggs) = _overSubscriptions().getRefundable(user);
            capital += lotteryRefund;
        }
    }
    
    // Get the fund currency needed for the LP provision. This amount is "after fee"
    function getLpFund() public view returns (uint fund) {
        (, fund) = _lp().getRequiredTokensQty(_raisedAmount(true));
    }
    
    //--------------------//
    // INTERNAL FUNCTIONS //
    //--------------------//
    
    function _fundIn(uint amtAcknowledged) internal {
        _require(!getState(DataTypes.Ok.FundedIn) &&
            getState(DataTypes.Ok.Finalized) &&
            _isPeriod(DataTypes.Period.Setup) &&
            getFundInTokenRequired() == amtAcknowledged, Error.Code.ValidationError);

        _setState(DataTypes.Ok.FundedIn, true);
        _transferIn(amtAcknowledged, DataTypes.FundType.Token);
        _history().record(DataTypes.ActionType.FundIn, msg.sender, amtAcknowledged, false);
    }
    
    // Note : CampaignOwner can fund out in these situations
    // 1. During setup Period
    // 2. When IDO ended & softcap not met 
    // 3. Aborted campaign
    function _fundOut(uint amtAcknowledged) internal nonReentrant {
        _require( getState(DataTypes.Ok.FundedIn) && 
            (_isPeriod(DataTypes.Period.Setup) || _store().finalState == DataTypes.FinalState.Failure || _isAborted()) && 
            getFundInTokenRequired() == amtAcknowledged, Error.Code.ValidationError);
      
        _setState(DataTypes.Ok.FundedIn, false);
        _transferOut(msg.sender, amtAcknowledged, DataTypes.FundType.Token);
        _history().record(DataTypes.ActionType.FundOut, msg.sender, amtAcknowledged, false);
    }

    
    //--------------------//
    // INTERNAL FUCNTIONS //
    //--------------------//

    function _tallySubscription(uint splitRatio) internal {
        _require(_canTally() && splitRatio<=Constant.PCNT_100, Error.Code.ValidationError);
        
        // Amount left after Guranteed has gotten their allocation
        uint amtLeft = _data().hardCap - _guaranteed().totalSubscribed;

        // Split the amount according to the splitRatio sent in by FE/Deployer
        uint amtForLottery = (amtLeft * splitRatio) / Constant.PCNT_100;
 
        // allocate to lottery & over-subcription
        _lottery().tally(amtForLottery);
        _overSubscriptions().tally(amtLeft - amtForLottery);

        // Final left over
        _live().allocLeftAtOpen = _lottery().getFinalLeftOver() + _overSubscriptions().getFinalLeftOver();
        _setState(DataTypes.Ok.Tally, true);
    }

    function _claim(bool investor) internal nonReentrant {
        _claim(investor, _vesting().updateClaim(msg.sender, investor));
    }

    function _transferIn(uint amount, DataTypes.FundType fundType) internal {
        if (amount > 0) {
           
            if (fundType == DataTypes.FundType.Currency && _isBnbCurrency()) {
                _require(amount == msg.value, Error.Code.InvalidAmount);
            } else {
                ERC20(_getAddress(fundType)).safeTransferFrom(msg.sender, address(this), amount); 
            }
        }
    }
    
    function _transferOut(address to, uint amount, DataTypes.FundType fundType) internal  {
        _transferOut(to, _getAddress(fundType), amount);
    }
//    SWC-107-Reentrancy:L342
    function _transferOut(address to, address token, uint amount) internal  {
        
        if (amount > 0 && to != Constant.ZERO_ADDRESS) {
             
            if (token == Constant.ZERO_ADDRESS) {
                (bool success, ) = to.call{ value: amount}("");
                _require(success, Error.Code.ValidationError);
            } else {
                 ERC20(token).safeTransfer(to, amount); 
            }
        }
    }
    
    function _getLpInterface() internal view returns (ILpProvider) {
        return ILpProvider(address(_manager));
    }
    

    //--------------------//
    // PRIVATE FUCNTIONS //
    //--------------------//
    
    
    function _getAddress(DataTypes.FundType fundType) private view returns (address) {
        if (fundType == DataTypes.FundType.Currency) {
            return _data().currency;
        } else if (fundType == DataTypes.FundType.Token) {
            return _data().token;
        } else if (fundType == DataTypes.FundType.Egg) {
            return _manager.getEggAddress();
        } else if (fundType == DataTypes.FundType.WBnb) {
            return _getLpInterface().getWBnb();
        }
        return address(0);
    }
    
    // releasePcnt: 1E6 means 100%
    function _claim(bool investor, uint releasePcnt) private {
        
        // Can only claim when softcap met
       _require(_store().finalState == DataTypes.FinalState.Success, Error.Code.SoftCapNotMet);
    
        uint total;
        if (releasePcnt>0) {
            if (investor) {
                 total = getTokensForCapital((_getTotalPurchased(msg.sender) * releasePcnt) / Constant.PCNT_100);
                 _require(total > 0, Error.Code.InvalidAmount); // Disallow investor to claim 0
                _transferOut(msg.sender, total, DataTypes.FundType.Token);
            } else {
                total = (_vesting().data.teamLockAmount * releasePcnt) / Constant.PCNT_100;
                _transferOut(msg.sender, total, DataTypes.FundType.Currency);
            }
            _history().record(investor ? DataTypes.ActionType.ClaimTokens : DataTypes.ActionType.ClaimFund,
                msg.sender, total, investor);
        }
    }
    
    
    // bool : softcap met ?
    // uint : Fee amt : In currency unit
    // uint : TotalAfterFeeLp : Total raised, after deducting for fee & Lp. In currency unit
    // uint : UnusedLpTokensQty
    // uint : UnsoldTokensQty
    function _getFinishUpStats() private view returns(bool softCapMet, uint feeAmt, uint totalAfterFeeLp, uint unusedLpTokensQty, uint unsoldTokensQty) {

        uint amtReturn = _data().hardCap;
        uint total = getTotalAllocSold();
        
        // Has met SoftCap ?
        softCapMet = total >= _data().softCap;
        if (softCapMet) {
            if (_data().feePcnt > 0 ) {
                feeAmt = _getFeeAmount(total);
                total -= feeAmt;
            }
            
            // Deduct for LP ?
            DataTypes.Lp storage lp = _lp();
            if (lp.enabled) {
                
                (uint totalLpTokens, ) = _lp().getMaxRequiredTokensQty();
        
                // LP creation is based on the totalRaisedAmount after deducting for fee first
                (uint lpTokensUsed, uint lpFundUsed) = lp.getRequiredTokensQty(total);
                total -= lpFundUsed;
                unusedLpTokensQty = totalLpTokens - lpTokensUsed;
            }
            amtReturn = getAllocLeftForLive();
        } 
        totalAfterFeeLp = total;
        unsoldTokensQty = getTokensForCapital(amtReturn);
    }
    
    function _getTotalPurchased(address user) private view returns (uint) {
        return getPurchaseDetail(user, false).total;
    }
    
    function _recordSubscription(DataTypes.Subscriptions storage param, uint capital) private {
        param.items[msg.sender] = DataTypes.SubItem(capital, false);
        param.count++ ;
    }
}


