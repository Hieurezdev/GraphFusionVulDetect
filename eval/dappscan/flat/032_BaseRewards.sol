pragma solidity ^0.6.12;
// [flatten] spdx removed
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// [flatten] spdx removed
// [flatten] version pragma removed

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;


contract BaseRewards is Ownable, BalanceAccounting {
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);

    struct TokenRewards {
        IERC20 gift;
        uint256 duration;
        address rewardDistribution;

        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    TokenRewards[] public tokenRewards;

    modifier updateReward(address account) {
        uint256 len = tokenRewards.length;
        for (uint i = 0; i < len; i++) {
            TokenRewards storage tr = tokenRewards[i];
            tr.rewardPerTokenStored = rewardPerToken(i);
            tr.lastUpdateTime = lastTimeRewardApplicable(i);
            if (account != address(0)) {
                tr.rewards[account] = earned(i, account);
                tr.userRewardPerTokenPaid[account] = tr.rewardPerTokenStored;
            }
        }
        _;
    }

    modifier onlyRewardDistribution(uint i) {
        require(msg.sender == tokenRewards[i].rewardDistribution, "Access denied");
        _;
    }

    function lastTimeRewardApplicable(uint i) public view returns (uint256) {
        return Math.min(block.timestamp, tokenRewards[i].periodFinish);
    }

    function rewardPerToken(uint i) public view returns (uint256) {
        TokenRewards storage tr = tokenRewards[i];
        if (totalSupply() == 0) {
            return tr.rewardPerTokenStored;
        }
        return tr.rewardPerTokenStored.add(
            lastTimeRewardApplicable(i)
                .sub(tr.lastUpdateTime)
                .mul(tr.rewardRate)
                .mul(1e18)
                .div(totalSupply())
        );
    }

    function earned(uint i, address account) public view returns (uint256) {
        TokenRewards storage tr = tokenRewards[i];
        return balanceOf(account)
            .mul(rewardPerToken(i).sub(tr.userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(tr.rewards[account]);
    }
//SWC-107-Reentrancy: L75
    function getReward(uint i) public updateReward(msg.sender) {
        TokenRewards storage tr = tokenRewards[i];
        uint256 reward = tr.rewards[msg.sender];
        if (reward > 0) {
            tr.rewards[msg.sender] = 0;
            tr.gift.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint i, uint256 reward) external onlyRewardDistribution(i) updateReward(address(0)) {
        TokenRewards storage tr = tokenRewards[i];
        uint256 duration = tr.duration;

        if (block.timestamp >= tr.periodFinish) {
            tr.rewardRate = reward.div(duration);
        } else {
            uint256 remaining = tr.periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(tr.rewardRate);
            tr.rewardRate = reward.add(leftover).div(duration);
        }

        uint balance = tr.gift.balanceOf(address(this));
        require(tr.rewardRate <= balance.div(duration), "Reward is too big");
//SWC-101-Integer Overflow and Underflow: L98
        tr.lastUpdateTime = block.timestamp;
        tr.periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    function setRewardDistribution(uint i, address _rewardDistribution) external onlyOwner {
        TokenRewards storage tr = tokenRewards[i];
        tr.rewardDistribution = _rewardDistribution;
    }

    function setDuration(uint i, uint256 _duration) external onlyRewardDistribution(i) {
        TokenRewards storage tr = tokenRewards[i];
        require(block.timestamp >= tr.periodFinish, "Access denied");
        tr.duration = _duration;
    }

    function addGift(IERC20 gift, uint256 duration, address rewardDistribution) public onlyOwner {
        TokenRewards storage tr = tokenRewards.push();
        tr.gift = gift;
        tr.duration = duration;
        tr.rewardDistribution = rewardDistribution;
        // TODO: test gas usage
        // tokenRewards.push(TokenRewards({
        //     gift: gift,
        //     duration: duration,
        //     rewardDistribution: rewardDistribution,
        //     periodFinish: 0,
        //     rewardRate: 0,
        //     lastUpdateTime: 0,
        //     rewardPerTokenStored: 0
        // }));
    }
}
