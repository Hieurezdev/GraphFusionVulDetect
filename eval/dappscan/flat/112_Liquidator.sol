pragma solidity 0.8.7;
// [flatten] spdx removed
// [flatten] version pragma removed

interface ILiquidator {

    /**
     * @dev   Auctioneer was set.
     * @param auctioneer_ Address of the auctioneer.
     */
    event AuctioneerSet(address auctioneer_);

    /**
     * @dev   Funds were withdrawn from the liquidator.
     * @param token_       Address of the token that was withdrawn.
     * @param destination_ Address of where tokens were sent.
     * @param amount_      Amount of tokens that were sent.
     */
    event FundsPulled(address token_, address destination_, uint256 amount_);

    /**
     * @dev   Portion of collateral was liquidated.
     * @param swapAmount_     Amount of collateralAsset that was liquidated.
     * @param returnedAmount_ Amount of fundsAsset that was returned.
     */
    event PortionLiquidated(uint256 swapAmount_, uint256 returnedAmount_);

    /**
     * @dev Getter function that returns `collateralAsset`
     */
    function collateralAsset() external view returns (address);

    /**
     * @dev Getter function that returns `destination` - address that liquidated funds are sent to.
     */
    function destination() external view returns (address);

    /**
     * @dev Getter function that returns `auctioneer`
     */
    function auctioneer() external view returns (address);

    /**
     * @dev Getter function that returns `fundsAsset`
     */
    function fundsAsset() external view returns (address);

    /**
     * @dev Getter function that returns `owner`
     */
    function owner() external view returns (address);

    /**
     * @dev   Set the auctioneer contract address, which is used to pull the `getExpectedAmount`.
     * @dev   Can only be set by `owner`.
     * @param auctioneer_ The auctioneer contract address.
     */
    function setAuctioneer(address auctioneer_) external;

    /**
     * @dev   Pulls a specified amount of ERC-20 tokens from the contract.
     * @dev   Can only be called by `owner`.
     * @param token_       The ERC-20 token contract address.
     * @param destination_ The destination of the transfer.
     * @param amount_      The amount to transfer.
     */
    function pullFunds(address token_, address destination_, uint256 amount_) external;

    /**
     * @dev    Returns the expected amount to be returned from a flashloan given a certain amount of `collateralAsset`.
     * @param  swapAmount_     Amount of `collateralAsset` to be flash-borrowed.
     * @return expectedAmount_ Amount of `fundsAsset` that must be returned in the same transaction.
     */
    function getExpectedAmount(uint256 swapAmount_) external returns (uint256 expectedAmount_);

    /**
     * @dev   Flash loan function that:
     * @dev   1. Transfers a specified amount of `collateralAsset` to `msg.sender`.
     * @dev   2. Performs an arbitrary call to `msg.sender`, to trigger logic necessary to get `fundsAsset` (e.g., AMM swap).
     * @dev   3. Perfroms a `transferFrom`, taking the corresponding amount of `fundsAsset` from the user.
     * @dev   If the required amount of `fundsAsset` is not returned in step 3, the entire transaction reverts.
     * @param swapAmount_ Amount of `collateralAsset` that is to be borrowed in the flashloan.
     * @param data_       ABI-encoded arguments to be used in the low-level call to perform step 2.
     */
    function liquidatePortion(uint256 swapAmount_, bytes calldata data_) external;
    
}
// [flatten] spdx removed
// [flatten] version pragma removed

interface IAuctioneerLike {

    function getExpectedAmount(uint256 swapAmount_) external view returns (uint256 expectedAmount_);
    
}

interface IERC20Like {

    function approve(address account_, uint256 amount_) external;

    function balanceOf(address account_) external view returns (uint256 balance_);

    function decimals() external view returns (uint256 decimals_);

}

interface ILiquidatorLike {

    function getExpectedAmount(uint256 swapAmount_) external returns (uint256 expectedAmount_);

    function liquidatePortion(uint256 swapAmount_, bytes calldata data_) external;
    
}

interface IMapleGlobalsLike {

    function getLatestPrice(address asset_) external view returns (uint256 price_);

}

interface IOracleLike {
    
    function latestRoundData() external view returns (
        uint80  roundId,
        int256  answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80  answeredInRound
    );

}

interface IUniswapRouterLike {

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);

}
// [flatten] spdx removed
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

contract Liquidator is ILiquidator {

    address public override auctioneer;
    address public override collateralAsset;
    address public override destination;
    address public override fundsAsset;
    address public override owner;

    constructor(address owner_, address collateralAsset_, address fundsAsset_, address auctioneer_, address destination_) {
        owner           = owner_;
        collateralAsset = collateralAsset_;
        fundsAsset      = fundsAsset_;
        auctioneer      = auctioneer_;
        destination     = destination_;
    }

    function setAuctioneer(address auctioneer_) external override {
        require(msg.sender == owner, "LIQ:SA:NOT_OWNER");
        auctioneer = auctioneer_;
        emit AuctioneerSet(auctioneer_);
    }

    function pullFunds(address token_, address destination_, uint256 amount_) external override {
        require(msg.sender == owner,                                 "LIQ:PF:NOT_OWNER");
        require(ERC20Helper.transfer(token_, destination_, amount_), "LIQ:PF:TRANSFER");
        emit FundsPulled(token_, destination_, amount_);
    }

    function getExpectedAmount(uint256 swapAmount_) public view override returns (uint256 expectedAmount_) {
        return IAuctioneerLike(auctioneer).getExpectedAmount(swapAmount_);
    }
    // SWC-107-Reentrancy: L41-L51
    function liquidatePortion(uint256 swapAmount_, bytes calldata data_) external override {
        ERC20Helper.transfer(collateralAsset, msg.sender, swapAmount_);

        msg.sender.call(data_);

        uint256 returnAmount = getExpectedAmount(swapAmount_);

        require(ERC20Helper.transferFrom(fundsAsset, msg.sender, destination, returnAmount), "LIQ:LP:TRANSFER_FROM");

        emit PortionLiquidated(swapAmount_, returnAmount);
    }

}
