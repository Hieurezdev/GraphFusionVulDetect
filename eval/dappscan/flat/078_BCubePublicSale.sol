pragma solidity 0.5.17;
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// [flatten] version pragma removed

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}
// [flatten] version pragma removed


/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }
}
// [flatten] version pragma removed

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
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
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// [flatten] version pragma removed

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// [flatten] version pragma removed

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
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
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}
// SWC-102-Outdated Compiler Version: L2
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

contract BCubePublicSale is WhitelistedRole, ReentrancyGuard {
  using SafeMath for uint256;
  using SignedSafeMath for int256;
  using SafeCast for uint256;
  using SafeERC20 for IERC20;

  /// @dev allowance is # of BCUBE each participant can withdraw from treasury.
  /// @param currentAllowance this allowance is in 4 stages tracked by currentAllowance
  /// @param shareWithdrawn tracks the amount of BCUBE already withdrawn from treasury
  /// @param dollarUnitsPayed 1 dollar = 100,000,000 dollar units.
  /// This tracks dollar units payed by user to this contract
  /// @param allocatedBcubePrivateRound amount of BCUBE allocated to this user during the Public Round stage
  /// @param allocatedBcubePublicRound amount of BCUBE allocated to this user during the Private Round stage
  /// @param allocatedBcubePrivateAllocation amount of BCUBE allocated in a private allocation
  struct UserInfo {
    uint256 dollarUnitsPayed;
    uint256 allocatedBcubePrivateAllocation;
    uint256 allocatedBcubePrivateRound;
    uint256 allocatedBcubePublicRound;
    uint256 currentAllowance;
    uint256 shareWithdrawn;
  }

  modifier onlyWhitelisted() {
    require(
      isWhitelisted(_msgSender()) || privateSaleWhitelisted.isWhitelisted(_msgSender()),
      "BCubePublicSale: caller does not have the Whitelisted role"
    );
    _;
  }

  modifier onlyWhileOpen {
    require(isOpen(), "BCubePublicSale: not open");
    _;
  }

  /// @dev ensuring BCUBE allocations in public sale don't exceed 15m
  modifier tokensRemaining() {
    require(
      netSoldBcube < currentHardcap(),
      "BCubePublicSale: All tokens sold"
    );
    _;
  }

  mapping(address => UserInfo) public bcubeAllocationRegistry;

  /// @dev variables whose instance fetch prices of USDT, ETH from Chainlink oracles
  AggregatorV3Interface internal priceFeedETH;
  AggregatorV3Interface internal priceFeedUSDT;

  /// @dev the Private Sale contract, used to check for private-sale whitelisted users
  WhitelistedRole internal privateSaleWhitelisted;

  IERC20 public usdt;

  uint256 public openingTime;
  uint256 public closingTime;

  uint256 public constant HARD_CAP               = 15_000_000e18;               // 15m
  uint256 public constant PRIVATE_ALLOCATION_CAP =  6666666666666666666666667;  // 6.666666666666666666666667m
  uint256 public constant PUBLIC_LAUNCHPAD_CAP   =  2_250_000e18;               // 2.75m

  // Global min per wallet, in Dollar Units (1 dollar = 100,000,000 dollar units)
  uint256 public minContributionDollarUnits = 500e8;    // $500
  // Global max par wallet, in Dollar Units (1 dollar = 100,000,000 dollar units)
  uint256 public maxContributionDollarUnits = 50000e8;  // $50k
  
  uint256 public netSoldBcube;
  uint256 public netPrivateAllocatedBcube;
  uint256 public launchpadReservedBcube = PUBLIC_LAUNCHPAD_CAP;
  
  // Address where funds are collected
  address payable private wallet;
  
  event LogEtherReceived(address indexed sender, uint256 value);
  event LogBcubeBuyUsingEth(
    address indexed buyer,
    uint256 incomingWei,
    uint256 allocation
  );
  event LogBcubeBuyUsingUsdt(
      address indexed buyer,
      uint256 incomingUsdtUnits,
      uint256 allocation
  );
  event LogETHPriceFeedChange(address indexed newChainlinkETHPriceFeed);
  event LogUSDTPriceFeedChange(address indexed newChainlinkUSDTPriceFeed);
  event LogUSDTInstanceChange(address indexed newUsdtContract);
  event LogPublicSaleTimeExtension(
    uint256 previousClosingTime,
    uint256 newClosingTime
  );
  event LogPrivateAllocationChanged(
    address wallet,
    uint256 newAllocation
  );
  event LogLaunchpadReserveChanged(uint256 newReserve);
  event LogLimitChanged(uint256 _newMin, uint256 _newMax);
  
  /**
    * @param _openingTime public sale starting time
    * @param _closingTime public sale closing time
    * @param _chainlinkETHPriceFeed address of the ETH price feed
    * @param _chainlinkUSDTPriceFeed address of the USDT price feed
    * @param _usdtContract address of the USDT ERC20 contract
    * @param _privateSale address of the Private Sale contract
    * @param _wallet team wallet: where ETH end USDT will be transferred
    */
  constructor(
    uint256 _openingTime,
    uint256 _closingTime,
    address _chainlinkETHPriceFeed,
    address _chainlinkUSDTPriceFeed,
    address _usdtContract,
    address _privateSale,
    address payable _wallet
  )
    public WhitelistedRole()
  {
    openingTime = _openingTime;
    closingTime = _closingTime;
    priceFeedETH = AggregatorV3Interface(_chainlinkETHPriceFeed);
    priceFeedUSDT = AggregatorV3Interface(_chainlinkUSDTPriceFeed);
    usdt = IERC20(_usdtContract);
    privateSaleWhitelisted = WhitelistedRole(_privateSale);
    wallet = _wallet;
  }

  function setAdmin(address _admin) public onlyWhitelistAdmin {
    // Add new admin for whitelisting, and remove msgSender as admin
    addWhitelistAdmin(_admin);
    renounceWhitelistAdmin();
  }

  function setContributionsLimits(uint256 _min, uint256 _max) public onlyWhitelistAdmin {
    minContributionDollarUnits = _min;
    maxContributionDollarUnits = _max;
    emit LogLimitChanged(_min, _max);
  }

  function() external payable {
    emit LogEtherReceived(_msgSender(), msg.value);
  }

  /// @dev public sale is open if current date is between openingTime and closingTime
  // SWC-120-Weak Sources of Randomness from Chain Attributes: L162
  function isOpen() public view returns (bool) {
      // solhint-disable-next-line not-rely-on-time
      return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }

  function currentHardcap() public view returns (uint256) {
    return HARD_CAP.sub(PRIVATE_ALLOCATION_CAP).sub(launchpadReservedBcube);
  }

  // SWC-120-Weak Sources of Randomness from Chain Attributes: L173
  function setPrivateAllocation(address _wallet, uint256 _allocation)
    external
    onlyWhitelistAdmin {
    require(block.timestamp <= closingTime, "BCubePublicSale: sale is closed");
    uint256 _previousAllocation = bcubeAllocationRegistry[_wallet].allocatedBcubePrivateAllocation;
    uint256 _newPrivateAllocation = netPrivateAllocatedBcube.sub(_previousAllocation).add(_allocation);
    require(
      _newPrivateAllocation <= PRIVATE_ALLOCATION_CAP,
      "BCubePublicSale: private allocation exceed PRIVATE_ALLOCATION_CAP"
    );
    netPrivateAllocatedBcube = _newPrivateAllocation;
    bcubeAllocationRegistry[_wallet].allocatedBcubePrivateAllocation = _allocation; 
    emit LogPrivateAllocationChanged(_wallet, _allocation);
  }

  function decreaseLaunchpadReservedBcube(uint256 _newReserve)
    external
    onlyWhitelistAdmin
    onlyWhileOpen {
    require(_newReserve <= launchpadReservedBcube, "BCubePublicSale: new reserve can only be decreased");
    require(_newReserve >= 0, "BCubePublicSale: new reserve MUST BE >= 0");
    launchpadReservedBcube = _newReserve;
    emit LogLaunchpadReserveChanged(_newReserve);
  }

  function calcRate() private view returns (uint256, uint8) {
    // Two phases, with two different prices
    // Phase 1 - Private Round: the first 1,333333333333333333333333m tokens at 0.15 USD
    // Phase 2 - Public Round: the remaining tokens at 0.20 USD

    if (netSoldBcube < 1333333333333333333333333) { 
      return (66666666666, 1);    // Private round
    } else {
      return (5e10, 2);           // Public round
    }
  }

  /// @dev allowing resetting ETH priceFeed instance, in case current Chainlink contracts upgrade
  function setETHPriceFeed(address _newChainlinkETHPriceFeed)
    external
    onlyWhitelistAdmin
  {
    priceFeedETH = AggregatorV3Interface(_newChainlinkETHPriceFeed);
    emit LogETHPriceFeedChange(_newChainlinkETHPriceFeed);
  }

  /// @dev allowing resetting USDT priceFeed instance, in case current Chainlink contracts upgrade
  function setUSDTPriceFeed(address _newChainlinkUSDTPriceFeed)
    external
    onlyWhitelistAdmin
  {
    priceFeedUSDT = AggregatorV3Interface(_newChainlinkUSDTPriceFeed);
    emit LogUSDTPriceFeedChange(_newChainlinkUSDTPriceFeed);
  }

  /// @dev allowing resetting USDT instance, in case current contract upgrades
  function setUSDTInstance(address _newUsdtContract)
    external
    onlyWhitelistAdmin
  {
    usdt = IERC20(_newUsdtContract);
    emit LogUSDTInstanceChange(_newUsdtContract);
  }

  /// @dev to extend the current closing time of public sale
  function extendClosingTime(uint256 _newClosingTime)
    external
    onlyWhitelistAdmin
  {
    emit LogPublicSaleTimeExtension(closingTime, _newClosingTime);
    closingTime = _newClosingTime;
  }

  /// @dev allowing users to allocate BCUBEs for themselves using ETH
  /// only KYC/AML whitelisted users can call this, while the sale is open and allocation hard cap is not reached
  /// @dev it fetches current price of ETH, multiples that by incoming ETH to calc total incoming dollar units, then
  /// allocates appropriate amount of BCUBE to user based on current rate, stage
  function buyBcubeUsingETH()
    external
    payable
    onlyWhitelisted
    onlyWhileOpen
    tokensRemaining
    nonReentrant
  {
    uint256 allocation;
    uint256 ethPrice = uint256(fetchETHPrice());
    uint256 dollarUnits = ethPrice.mul(msg.value).div(1e18);
    allocation = executeAllocation(dollarUnits);
    wallet.transfer(msg.value);

    emit LogBcubeBuyUsingEth(_msgSender(), msg.value, allocation);
  }

  /// @dev allowing users to allocate BCUBEs for themselves using USDT
  /// does all things similar to the above function, but for USDT
  // SWC-107-Reentrancy: L264 - L278
  function buyBcubeUsingUSDT(uint256 incomingUsdt)
    external
    onlyWhitelisted
    onlyWhileOpen
    tokensRemaining
    nonReentrant
  {
    uint256 allocation;
    uint256 usdtPrice = uint256(fetchUSDTPrice());
    uint256 dollarUnits = usdtPrice.mul(incomingUsdt).div(1e6);
    allocation = executeAllocation(dollarUnits);
    usdt.safeTransferFrom(_msgSender(), wallet, incomingUsdt);
    
    emit LogBcubeBuyUsingUsdt(_msgSender(), incomingUsdt, allocation);
  }

  /// @dev stageCap is max net BCUBEs allocated until a given stage i.e. 8m, 15m for stages "pre-ico" and "ico"
  /// @dev based on current netSoldBcube, fetches rate from calcRate()
  /// check that contribution is >= 500 USD (minimal contribution)
  /// then calculates BCUBEs allocated to user from #BCUBE = rate * dollarUnits
  /// => #wBCUBE = ((#wBCUBE / unit dollar) for this stage) * dollarUnits
  /// Now, if new netAllocatedBcube does not exceed stageCap, the user is directly assigned their calculated BCUBE share
  /// but if it exceeds the stage cap, then the user's BCUBE share for this stage remains same until stageCap (a1),
  /// and the exceeding allocation is recalculated using rate of the next stage (a2)
  /// then a1 + a2 is allocated to the user
  /// Math for this can be found in the README
  function executeAllocation(uint256 dollarUnits) private returns (uint256) {
    uint256 finalAllocation;
    uint256 bcubeAllocatedToUser;
    uint256 rate;
    uint8 stage;
    uint256 stageCap;
    uint256 a1;
    uint256 a2;
    uint256 dollarUnitsUnused;
    uint256 totalContribution = bcubeAllocationRegistry[_msgSender()]
      .dollarUnitsPayed
      .add(dollarUnits);
    require(
      totalContribution >= minContributionDollarUnits,
      "BCubePublicSale: Minimum contribution not reached."
    );
    require(
      totalContribution <= maxContributionDollarUnits,
      "BCubePublicSale: Maximum contribution exceeded"
    );  
    (rate, stage) = calcRate();
    uint256 current_hardcap = currentHardcap();
    if (stage == 1) {
      stageCap = 1333333333333333333333333;
    } else {
      stageCap = current_hardcap;
    }
    bcubeAllocatedToUser = rate.mul(dollarUnits);
    finalAllocation = netSoldBcube.add(bcubeAllocatedToUser);
    require(finalAllocation <= current_hardcap, "BCubePublicSale: Hard cap exceeded");
    bcubeAllocationRegistry[_msgSender()].dollarUnitsPayed = totalContribution;
    if (finalAllocation <= stageCap) {
      netSoldBcube = finalAllocation;
      if (stage == 1) {
        bcubeAllocationRegistry[_msgSender()].allocatedBcubePrivateRound = bcubeAllocationRegistry[_msgSender()]
          .allocatedBcubePrivateRound
          .add(bcubeAllocatedToUser);
      } else {
        bcubeAllocationRegistry[_msgSender()].allocatedBcubePublicRound = bcubeAllocationRegistry[_msgSender()]
          .allocatedBcubePublicRound
          .add(bcubeAllocatedToUser);
      }
      return bcubeAllocatedToUser;
    } else {
      uint256 total;
      a1 = stageCap.sub(netSoldBcube);
      dollarUnitsUnused = dollarUnits.sub(a1.div(rate));
      netSoldBcube = stageCap;
      bcubeAllocationRegistry[_msgSender()].allocatedBcubePrivateRound = bcubeAllocationRegistry[_msgSender()]
        .allocatedBcubePrivateRound
        .add(a1);
      (rate, stage) = calcRate();
      a2 = dollarUnitsUnused.mul(rate);
      netSoldBcube = netSoldBcube.add(a2);
      total = a1.add(a2);
      bcubeAllocationRegistry[_msgSender()].allocatedBcubePublicRound = bcubeAllocationRegistry[_msgSender()]
        .allocatedBcubePublicRound
        .add(a2);
      return total;
    }
  }

  /// @dev fetching ETH price from chainlink oracle
  function fetchETHPrice() public view returns (uint256) {
    (, int256 price, , , ) = priceFeedETH.latestRoundData();
    return toUint256(price);
  }

  /// @dev fetching USDT price from chainlink oracle
  function fetchUSDTPrice() public view returns (uint256) {
    (, int256 price, , , ) = priceFeedUSDT.latestRoundData();
    uint256 ethUSD = fetchETHPrice();
    return toUint256(price).mul(ethUSD).div(1e18);
  }

  function toUint256(int256 value) internal pure returns (uint256) {
    require(value >= 0, "SafeCast: value must be positive");
    return uint256(value);
  }

}