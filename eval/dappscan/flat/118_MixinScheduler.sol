pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed


library LibRichErrors {

    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR =
        0x08c379a0;

    // solhint-disable func-name-mixedcase
    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(
        string memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            STANDARD_ERROR_SELECTOR,
            bytes(message)
        );
    }
    // solhint-enable func-name-mixedcase

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData)
        internal
        pure
    {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}
// [flatten] version pragma removed


library LibSafeMathRichErrors {

    // bytes4(keccak256("Uint256BinOpError(uint8,uint256,uint256)"))
    bytes4 internal constant UINT256_BINOP_ERROR_SELECTOR =
        0xe946c1bb;

    // bytes4(keccak256("Uint256DowncastError(uint8,uint256)"))
    bytes4 internal constant UINT256_DOWNCAST_ERROR_SELECTOR =
        0xc996af7b;

    enum BinOpErrorCodes {
        ADDITION_OVERFLOW,
        MULTIPLICATION_OVERFLOW,
        SUBTRACTION_UNDERFLOW,
        DIVISION_BY_ZERO
    }

    enum DowncastErrorCodes {
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT32,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT64,
        VALUE_TOO_LARGE_TO_DOWNCAST_TO_UINT96
    }

    // solhint-disable func-name-mixedcase
    function Uint256BinOpError(
        BinOpErrorCodes errorCode,
        uint256 a,
        uint256 b
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_BINOP_ERROR_SELECTOR,
            errorCode,
            a,
            b
        );
    }

    function Uint256DowncastError(
        DowncastErrorCodes errorCode,
        uint256 a
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            UINT256_DOWNCAST_ERROR_SELECTOR,
            errorCode,
            a
        );
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;


library LibSafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        if (c / a != b) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.MULTIPLICATION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b == 0) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.DIVISION_BY_ZERO,
                a,
                b
            ));
        }
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (b > a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.SUBTRACTION_UNDERFLOW,
                a,
                b
            ));
        }
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        if (c < a) {
            LibRichErrors.rrevert(LibSafeMathRichErrors.Uint256BinOpError(
                LibSafeMathRichErrors.BinOpErrorCodes.ADDITION_OVERFLOW,
                a,
                b
            ));
        }
        return c;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed


interface IStructs {

    /// @dev Status for a pool that actively traded during the current epoch.
    /// (see MixinExchangeFees).
    /// @param feesCollected Fees collected in ETH by this pool.
    /// @param weightedStake Amount of weighted stake in the pool.
    /// @param membersStake Amount of non-operator stake in the pool.
    struct ActivePool {
        uint256 feesCollected;
        uint256 weightedStake;
        uint256 membersStake;
    }

    /// @dev Holds state for unfinalized epoch rewards.
    /// @param rewardsAvailable Rewards (ETH) available to the epoch
    ///        being finalized (the previous epoch). This is simply the balance
    ///        of the contract at the end of the epoch.
    /// @param poolsRemaining The number of active pools in the last
    ///        epoch that have yet to be finalized through `finalizePools()`.
    /// @param totalFeesCollected The total fees collected for the epoch being finalized.
    /// @param totalWeightedStake The total fees collected for the epoch being finalized.
    /// @param totalRewardsFinalized Amount of rewards that have been paid during finalization.
    struct UnfinalizedState {
        uint256 rewardsAvailable;
        uint256 poolsRemaining;
        uint256 totalFeesCollected;
        uint256 totalWeightedStake;
        uint256 totalRewardsFinalized;
    }

    /// @dev Encapsulates a balance for the current and next epochs.
    /// Note that these balances may be stale if the current epoch
    /// is greater than `currentEpoch`.
    /// Always load this struct using _loadSyncedBalance or _loadUnsyncedBalance.
    /// @param isInitialized
    /// @param currentEpoch the current epoch
    /// @param currentEpochBalance balance in the current epoch.
    /// @param nextEpochBalance balance in `currentEpoch+1`.
    struct StoredBalance {
        // SWC-135-Code With No Effects: L62
        bool isInitialized;
        uint32 currentEpoch;
        uint96 currentEpochBalance;
        uint96 nextEpochBalance;
    }

    /// @dev Balance struct for stake.
    /// @param currentEpochBalance Balance in the current epoch.
    /// @param nextEpochBalance Balance in the next epoch.
    struct StakeBalance {
        uint256 currentEpochBalance;
        uint256 nextEpochBalance;
    }

    /// @dev Statuses that stake can exist in.
    enum StakeStatus {
        ACTIVE,
        INACTIVE,
        DELEGATED
    }

    /// @dev Info used to describe a status.
    /// @param status of the stake.
    /// @param poolId Unique Id of pool. This is set when status=DELEGATED.
    struct StakeInfo {
        StakeStatus status;
        bytes32 poolId;
    }

    /// @dev Struct to represent a fraction.
    /// @param numerator of fraction.
    /// @param denominator of fraction.
    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    /// @dev State for keeping track of which pool a maker has joined, and if the operator has
    /// added them (see MixinStakingPool).
    /// @param poolId Unique Id of staking pool.
    /// @param confirmed Whether the operator has added the maker to the pool.
    struct MakerPoolJoinStatus {
        bytes32 poolId;
        bool confirmed;
    }

    /// @dev Holds the metadata for a staking pool.
    /// @param initialized True iff the balance struct is initialized.
    /// @param operator of the pool.
    /// @param operatorShare Fraction of the total balance owned by the operator, in ppm.
    /// @param numberOfMakers Number of makers in the pool.
    struct Pool {
        // SWC-135-Code With No Effects: L115
        bool initialized;
        address payable operator;
        uint32 operatorShare;
        uint32 numberOfMakers;
    }
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;


library LibStakingRichErrors {

    enum OperatorShareErrorCodes {
        OperatorShareTooLarge,
        CanOnlyDecreaseOperatorShare
    }

    enum ProtocolFeePaymentErrorCodes {
        ZeroProtocolFeePaid,
        MismatchedFeeAndPayment
    }

    enum InitializationErrorCodes {
        MixinSchedulerAlreadyInitialized,
        MixinParamsAlreadyInitialized
    }

    enum InvalidParamValueErrorCodes {
        InvalidCobbDouglasAlpha,
        InvalidRewardDelegatedStakeWeight,
        InvalidMaximumMakersInPool,
        InvalidMinimumPoolStake,
        InvalidEpochDuration
    }

    enum MakerPoolAssignmentErrorCodes {
        MakerAddressAlreadyRegistered,
        MakerAddressNotRegistered,
        MakerAddressNotPendingAdd,
        PoolIsFull
    }

    enum ExchangeManagerErrorCodes {
        ExchangeAlreadyRegistered,
        ExchangeNotRegistered
    }

    // bytes4(keccak256("OnlyCallableByExchangeError(address)"))
    bytes4 internal constant ONLY_CALLABLE_BY_EXCHANGE_ERROR_SELECTOR =
        0xb56d2df0;

    // bytes4(keccak256("ExchangeManagerError(uint8,address)"))
    bytes4 internal constant EXCHANGE_MANAGER_ERROR_SELECTOR =
        0xb9588e43;

    // bytes4(keccak256("InsufficientBalanceError(uint256,uint256)"))
    bytes4 internal constant INSUFFICIENT_BALANCE_ERROR_SELECTOR =
        0x84c8b7c9;

    // bytes4(keccak256("OnlyCallableByPoolOperatorOrMakerError(address,bytes32)"))
    bytes4 internal constant ONLY_CALLABLE_BY_POOL_OPERATOR_OR_MAKER_ERROR_SELECTOR =
        0x7677eb13;

    // bytes4(keccak256("MakerPoolAssignmentError(uint8,address,bytes32)"))
    bytes4 internal constant MAKER_POOL_ASSIGNMENT_ERROR_SELECTOR =
        0x69945e3f;

    // bytes4(keccak256("BlockTimestampTooLowError(uint256,uint256)"))
    bytes4 internal constant BLOCK_TIMESTAMP_TOO_LOW_ERROR_SELECTOR =
        0xa6bcde47;

    // bytes4(keccak256("OnlyCallableByStakingContractError(address)"))
    bytes4 internal constant ONLY_CALLABLE_BY_STAKING_CONTRACT_ERROR_SELECTOR =
        0xca1d07a2;

    // bytes4(keccak256("OnlyCallableIfInCatastrophicFailureError()"))
    bytes internal constant ONLY_CALLABLE_IF_IN_CATASTROPHIC_FAILURE_ERROR =
        hex"3ef081cc";

    // bytes4(keccak256("OnlyCallableIfNotInCatastrophicFailureError()"))
    bytes internal constant ONLY_CALLABLE_IF_NOT_IN_CATASTROPHIC_FAILURE_ERROR =
        hex"7dd020ce";

    // bytes4(keccak256("OperatorShareError(uint8,bytes32,uint32)"))
    bytes4 internal constant OPERATOR_SHARE_ERROR_SELECTOR =
        0x22df9597;

    // bytes4(keccak256("PoolExistenceError(bytes32,bool)"))
    bytes4 internal constant POOL_EXISTENCE_ERROR_SELECTOR =
        0x9ae94f01;

    // bytes4(keccak256("InvalidStakeStatusError(uint8)"))
    bytes4 internal constant INVALID_STAKE_STATUS_ERROR_SELECTOR =
        0x7cf20260;

    // bytes4(keccak256("ProxyDestinationCannotBeNilError()"))
    bytes internal constant PROXY_DESTINATION_CANNOT_BE_NIL_ERROR =
        hex"6eff8285";

    // bytes4(keccak256("InitializationError(uint8)"))
    bytes4 internal constant INITIALIZATION_ERROR_SELECTOR =
        0x0b02d773;

    // bytes4(keccak256("InvalidParamValueError(uint8)"))
    bytes4 internal constant INVALID_PARAM_VALUE_ERROR_SELECTOR =
        0xfc45bd11;

    // bytes4(keccak256("InvalidProtocolFeePaymentError(uint8,uint256,uint256)"))
    bytes4 internal constant INVALID_PROTOCOL_FEE_PAYMENT_ERROR_SELECTOR =
        0xefd6cb33;

    // bytes4(keccak256("PreviousEpochNotFinalizedError(uint256,uint256)"))
    bytes4 internal constant PREVIOUS_EPOCH_NOT_FINALIZED_ERROR_SELECTOR =
        0x614b800a;

    // solhint-disable func-name-mixedcase
    function OnlyCallableByExchangeError(
        address senderAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_CALLABLE_BY_EXCHANGE_ERROR_SELECTOR,
            senderAddress
        );
    }

    function ExchangeManagerError(
        ExchangeManagerErrorCodes errorCodes,
        address exchangeAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            EXCHANGE_MANAGER_ERROR_SELECTOR,
            errorCodes,
            exchangeAddress
        );
    }

    function InsufficientBalanceError(
        uint256 amount,
        uint256 balance
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INSUFFICIENT_BALANCE_ERROR_SELECTOR,
            amount,
            balance
        );
    }

    function OnlyCallableByPoolOperatorOrMakerError(
        address senderAddress,
        bytes32 poolId
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_CALLABLE_BY_POOL_OPERATOR_OR_MAKER_ERROR_SELECTOR,
            senderAddress,
            poolId
        );
    }

    function MakerPoolAssignmentError(
        MakerPoolAssignmentErrorCodes errorCodes,
        address makerAddress,
        bytes32 poolId
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            MAKER_POOL_ASSIGNMENT_ERROR_SELECTOR,
            errorCodes,
            makerAddress,
            poolId
        );
    }

    function BlockTimestampTooLowError(
        uint256 epochEndTime,
        uint256 currentBlockTimestamp
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            BLOCK_TIMESTAMP_TOO_LOW_ERROR_SELECTOR,
            epochEndTime,
            currentBlockTimestamp
        );
    }

    function OnlyCallableByStakingContractError(
        address senderAddress
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_CALLABLE_BY_STAKING_CONTRACT_ERROR_SELECTOR,
            senderAddress
        );
    }

    function OnlyCallableIfInCatastrophicFailureError()
        internal
        pure
        returns (bytes memory)
    {
        return ONLY_CALLABLE_IF_IN_CATASTROPHIC_FAILURE_ERROR;
    }

    function OnlyCallableIfNotInCatastrophicFailureError()
        internal
        pure
        returns (bytes memory)
    {
        return ONLY_CALLABLE_IF_NOT_IN_CATASTROPHIC_FAILURE_ERROR;
    }

    function OperatorShareError(
        OperatorShareErrorCodes errorCodes,
        bytes32 poolId,
        uint32 operatorShare
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            OPERATOR_SHARE_ERROR_SELECTOR,
            errorCodes,
            poolId,
            operatorShare
        );
    }

    function PoolExistenceError(
        bytes32 poolId,
        bool alreadyExists
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            POOL_EXISTENCE_ERROR_SELECTOR,
            poolId,
            alreadyExists
        );
    }

    function InvalidProtocolFeePaymentError(
        ProtocolFeePaymentErrorCodes errorCodes,
        uint256 expectedProtocolFeePaid,
        uint256 actualProtocolFeePaid
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_PROTOCOL_FEE_PAYMENT_ERROR_SELECTOR,
            errorCodes,
            expectedProtocolFeePaid,
            actualProtocolFeePaid
        );
    }

    function InvalidStakeStatusError(IStructs.StakeStatus status)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_STAKE_STATUS_ERROR_SELECTOR,
            status
        );
    }

    function InitializationError(InitializationErrorCodes code)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INITIALIZATION_ERROR_SELECTOR,
            uint8(code)
        );
    }

    function InvalidParamValueError(InvalidParamValueErrorCodes code)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INVALID_PARAM_VALUE_ERROR_SELECTOR,
            uint8(code)
        );
    }

    function ProxyDestinationCannotBeNilError()
        internal
        pure
        returns (bytes memory)
    {
        return PROXY_DESTINATION_CANNOT_BE_NIL_ERROR;
    }

    function PreviousEpochNotFinalizedError(
        uint256 unfinalizedEpoch,
        uint256 unfinalizedPoolsRemaining
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            PREVIOUS_EPOCH_NOT_FINALIZED_ERROR_SELECTOR,
            unfinalizedEpoch,
            unfinalizedPoolsRemaining
        );
    }
}
// [flatten] version pragma removed


contract IOwnable {

    function transferOwnership(address newOwner)
        public;
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed
// [flatten] import inlined;


contract IAuthorizable is
    IOwnable
{
    // Event logged when a new address is authorized.
    event AuthorizedAddressAdded(
        address indexed target,
        address indexed caller
    );

    // Event logged when a currently authorized address is unauthorized.
    event AuthorizedAddressRemoved(
        address indexed target,
        address indexed caller
    );

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external;

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external;

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory);
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed


library LibAuthorizableRichErrors {

    // bytes4(keccak256("AuthorizedAddressMismatchError(address,address)"))
    bytes4 internal constant AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR =
        0x140a84db;

    // bytes4(keccak256("IndexOutOfBoundsError(uint256,uint256)"))
    bytes4 internal constant INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR =
        0xe9f83771;

    // bytes4(keccak256("SenderNotAuthorizedError(address)"))
    bytes4 internal constant SENDER_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xb65a25b9;

    // bytes4(keccak256("TargetAlreadyAuthorizedError(address)"))
    bytes4 internal constant TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR =
        0xde16f1a0;

    // bytes4(keccak256("TargetNotAuthorizedError(address)"))
    bytes4 internal constant TARGET_NOT_AUTHORIZED_ERROR_SELECTOR =
        0xeb5108a2;

    // bytes4(keccak256("ZeroCantBeAuthorizedError()"))
    bytes internal constant ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES =
        hex"57654fe4";

    // solhint-disable func-name-mixedcase
    function AuthorizedAddressMismatchError(
        address authorized,
        address target
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            AUTHORIZED_ADDRESS_MISMATCH_ERROR_SELECTOR,
            authorized,
            target
        );
    }

    function IndexOutOfBoundsError(
        uint256 index,
        uint256 length
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            INDEX_OUT_OF_BOUNDS_ERROR_SELECTOR,
            index,
            length
        );
    }

    function SenderNotAuthorizedError(address sender)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            SENDER_NOT_AUTHORIZED_ERROR_SELECTOR,
            sender
        );
    }

    function TargetAlreadyAuthorizedError(address target)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_ALREADY_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function TargetNotAuthorizedError(address target)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            TARGET_NOT_AUTHORIZED_ERROR_SELECTOR,
            target
        );
    }

    function ZeroCantBeAuthorizedError()
        internal
        pure
        returns (bytes memory)
    {
        return ZERO_CANT_BE_AUTHORIZED_ERROR_BYTES;
    }
}
// [flatten] version pragma removed


library LibOwnableRichErrors {

    // bytes4(keccak256("OnlyOwnerError(address,address)"))
    bytes4 internal constant ONLY_OWNER_ERROR_SELECTOR =
        0x1de45ad1;

    // bytes4(keccak256("TransferOwnerToZeroError()"))
    bytes internal constant TRANSFER_OWNER_TO_ZERO_ERROR_BYTES =
        hex"e69edc3e";

    // solhint-disable func-name-mixedcase
    function OnlyOwnerError(
        address sender,
        address owner
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodeWithSelector(
            ONLY_OWNER_ERROR_SELECTOR,
            sender,
            owner
        );
    }

    function TransferOwnerToZeroError()
        internal
        pure
        returns (bytes memory)
    {
        return TRANSFER_OWNER_TO_ZERO_ERROR_BYTES;
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;


contract Ownable is
    IOwnable
{
    address public owner;

    constructor ()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        _assertSenderIsOwner();
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner == address(0)) {
            LibRichErrors.rrevert(LibOwnableRichErrors.TransferOwnerToZeroError());
        } else {
            owner = newOwner;
        }
    }

    function _assertSenderIsOwner()
        internal
        view
    {
        if (msg.sender != owner) {
            LibRichErrors.rrevert(LibOwnableRichErrors.OnlyOwnerError(
                msg.sender,
                owner
            ));
        }
    }
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;


// solhint-disable no-empty-blocks
contract Authorizable is
    Ownable,
    IAuthorizable
{
    /// @dev Only authorized addresses can invoke functions with this modifier.
    modifier onlyAuthorized {
        _assertSenderIsAuthorized();
        _;
    }

    mapping (address => bool) public authorized;
    address[] public authorities;

    /// @dev Initializes the `owner` address.
    constructor()
        public
        Ownable()
    {}

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function addAuthorizedAddress(address target)
        external
        onlyOwner
    {
        _addAuthorizedAddress(target);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    function removeAuthorizedAddress(address target)
        external
        onlyOwner
    {
        if (!authorized[target]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.TargetNotAuthorizedError(target));
        }
        for (uint256 i = 0; i < authorities.length; i++) {
            if (authorities[i] == target) {
                _removeAuthorizedAddressAtIndex(target, i);
                break;
            }
        }
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external
        onlyOwner
    {
        _removeAuthorizedAddressAtIndex(target, index);
    }

    /// @dev Gets all authorized addresses.
    /// @return Array of authorized addresses.
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory)
    {
        return authorities;
    }

    /// @dev Reverts if msg.sender is not authorized.
    function _assertSenderIsAuthorized()
        internal
        view
    {
        if (!authorized[msg.sender]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.SenderNotAuthorizedError(msg.sender));
        }
    }

    /// @dev Authorizes an address.
    /// @param target Address to authorize.
    function _addAuthorizedAddress(address target)
        internal
    {
        // Ensure that the target is not the zero address.
        if (target == address(0)) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.ZeroCantBeAuthorizedError());
        }

        // Ensure that the target is not already authorized.
        if (authorized[target]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.TargetAlreadyAuthorizedError(target));
        }

        authorized[target] = true;
        authorities.push(target);
        emit AuthorizedAddressAdded(target, msg.sender);
    }

    /// @dev Removes authorizion of an address.
    /// @param target Address to remove authorization from.
    /// @param index Index of target in authorities array.
    function _removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        internal
    {
        if (!authorized[target]) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.TargetNotAuthorizedError(target));
        }
        if (index >= authorities.length) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.IndexOutOfBoundsError(
                index,
                authorities.length
            ));
        }
        if (authorities[index] != target) {
            LibRichErrors.rrevert(LibAuthorizableRichErrors.AuthorizedAddressMismatchError(
                authorities[index],
                target
            ));
        }

        delete authorized[target];
        authorities[index] = authorities[authorities.length - 1];
        authorities.length -= 1;
        emit AuthorizedAddressRemoved(target, msg.sender);
    }
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed


contract IERC20Token {

    // solhint-disable no-simple-event-func-name
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /// @dev send `value` token to `to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transfer(address _to, uint256 _value)
        external
        returns (bool);

    /// @dev send `value` token to `to` from `from` on the condition it is approved by `from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return True if transfer was successful
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool);

    /// @dev `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Always true if the call has enough gas to complete execution
    function approve(address _spender, uint256 _value)
        external
        returns (bool);

    /// @dev Query total supply of token
    /// @return Total supply of token
    function totalSupply()
        external
        view
        returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return Balance of owner
    function balanceOf(address _owner)
        external
        view
        returns (uint256);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed
// [flatten] import inlined;


contract IEtherToken is
    IERC20Token
{
    function deposit()
        public
        payable;
    
    function withdraw(uint256 amount)
        public;
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed


interface IZrxVault {

    /// @dev Emmitted whenever a StakingProxy is set in a vault.
    event StakingProxySet(address stakingProxyAddress);

    /// @dev Emitted when the Staking contract is put into Catastrophic Failure Mode
    /// @param sender Address of sender (`msg.sender`)
    event InCatastrophicFailureMode(address sender);

    /// @dev Emitted when Zrx Tokens are deposited into the vault.
    /// @param staker of Zrx Tokens.
    /// @param amount of Zrx Tokens deposited.
    event Deposit(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted when Zrx Tokens are withdrawn from the vault.
    /// @param staker of Zrx Tokens.
    /// @param amount of Zrx Tokens withdrawn.
    event Withdraw(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted whenever the ZRX AssetProxy is set.
    event ZrxProxySet(address zrxProxyAddress);

    /// @dev Sets the address of the StakingProxy contract.
    /// Note that only the contract staker can call this function.
    /// @param _stakingProxyAddress Address of Staking proxy contract.
    function setStakingProxy(address payable _stakingProxyAddress)
        external;

    /// @dev Vault enters into Catastrophic Failure Mode.
    /// *** WARNING - ONCE IN CATOSTROPHIC FAILURE MODE, YOU CAN NEVER GO BACK! ***
    /// Note that only the contract staker can call this function.
    function enterCatastrophicFailure()
        external;

    /// @dev Sets the Zrx proxy.
    /// Note that only the contract staker can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param zrxProxyAddress Address of the 0x Zrx Proxy.
    function setZrxProxy(address zrxProxyAddress)
        external;

    /// @dev Deposit an `amount` of Zrx Tokens from `staker` into the vault.
    /// Note that only the Staking contract can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param staker of Zrx Tokens.
    /// @param amount of Zrx Tokens to deposit.
    function depositFrom(address staker, uint256 amount)
        external;

    /// @dev Withdraw an `amount` of Zrx Tokens to `staker` from the vault.
    /// Note that only the Staking contract can call this.
    /// Note that this can only be called when *not* in Catastrophic Failure mode.
    /// @param staker of Zrx Tokens.
    /// @param amount of Zrx Tokens to withdraw.
    function withdrawFrom(address staker, uint256 amount)
        external;

    /// @dev Withdraw ALL Zrx Tokens to `staker` from the vault.
    /// Note that this can only be called when *in* Catastrophic Failure mode.
    /// @param staker of Zrx Tokens.
    function withdrawAllFrom(address staker)
        external
        returns (uint256);

    /// @dev Returns the balance in Zrx Tokens of the `staker`
    /// @return Balance in Zrx.
    function balanceOf(address staker)
        external
        view
        returns (uint256);
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;


// solhint-disable separate-by-one-line-in-contract
contract MixinDeploymentConstants {

    // @TODO SET THESE VALUES FOR DEPLOYMENT

    // Mainnet WETH9 Address
    address constant private WETH_ADDRESS = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // Kovan WETH9 Address
    // address constant private WETH_ADDRESS = address(0xd0a1e359811322d97991e03f863a0c30c2cf029c);

    // Ropsten & Rinkeby WETH9 Address
    // address constant private WETH_ADDRESS = address(0xc778417e063141139fce010982780140aa0cd5ab);

    // @TODO SET THESE VALUES FOR DEPLOYMENT
    address constant private ZRX_VAULT_ADDRESS = address(1);

    /// @dev An overridable way to access the deployed WETH contract.
    ///      Must be view to allow overrides to access state.
    /// @return wethContract The WETH contract instance.
    function getWethContract()
        public
        view
        returns (IEtherToken wethContract)
    {
        wethContract = IEtherToken(WETH_ADDRESS);
        return wethContract;
    }

    /// @dev An overridable way to access the deployed zrxVault.
    ///      Must be view to allow overrides to access state.
    /// @return zrxVault The zrxVault contract.
    function getZrxVault()
        public
        view
        returns (IZrxVault zrxVault)
    {
        zrxVault = IZrxVault(ZRX_VAULT_ADDRESS);
        return zrxVault;
    }
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed
// [flatten] import inlined;


contract MixinConstants is
    MixinDeploymentConstants
{
    // 100% in parts-per-million.
    uint32 constant internal PPM_DENOMINATOR = 10**6;

    // The upper 16 bytes represent the pool id, so this would be pool id 1. See MixinStakinPool for more information.
    bytes32 constant internal INITIAL_POOL_ID = 0x0000000000000000000000000000000100000000000000000000000000000000;

    // The upper 16 bytes represent the pool id, so this would be an increment of 1. See MixinStakinPool for more information.
    uint256 constant internal POOL_ID_INCREMENT_AMOUNT = 0x0000000000000000000000000000000100000000000000000000000000000000;

    bytes32 constant internal NIL_POOL_ID = 0x0000000000000000000000000000000000000000000000000000000000000000;

    address constant internal NIL_ADDRESS = 0x0000000000000000000000000000000000000000;

    bytes32 constant internal UNKNOWN_STAKING_POOL_ID = 0x0000000000000000000000000000000000000000000000000000000000000000;

    uint64 constant internal INITIAL_EPOCH = 0;

    uint256 constant internal MIN_TOKEN_VALUE = 10**18;
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed
// [flatten] pragma hoisted
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;


// solhint-disable max-states-count, no-empty-blocks
contract MixinStorage is
    MixinConstants,
    Authorizable
{
    // address of staking contract
    address public stakingContract;

    // address of read-only proxy
    address public readOnlyProxy;

    // address for read-only proxy to call
    address public readOnlyProxyCallee;

    // mapping from StakeStatus to the total amount of stake in that status for the entire
    // staking system.
    mapping (uint8 => IStructs.StoredBalance) public globalStakeByStatus;

    // mapping from Owner to Amount of Active Stake
    // (access using _loadSyncedBalance or _loadUnsyncedBalance)
    mapping (address => IStructs.StoredBalance) internal _activeStakeByOwner;

    // Mapping from Owner to Amount of Inactive Stake
    // (access using _loadSyncedBalance or _loadUnsyncedBalance)
    mapping (address => IStructs.StoredBalance) internal _inactiveStakeByOwner;

    // Mapping from Owner to Amount Delegated
    // (access using _loadSyncedBalance or _loadUnsyncedBalance)
    mapping (address => IStructs.StoredBalance) internal _delegatedStakeByOwner;

    // Mapping from Owner to Pool Id to Amount Delegated
    // (access using _loadSyncedBalance or _loadUnsyncedBalance)
    mapping (address => mapping (bytes32 => IStructs.StoredBalance)) internal _delegatedStakeToPoolByOwner;

    // Mapping from Pool Id to Amount Delegated
    // (access using _loadSyncedBalance or _loadUnsyncedBalance)
    mapping (bytes32 => IStructs.StoredBalance) internal _delegatedStakeByPoolId;

    // mapping from Owner to Amount of Withdrawable Stake
    mapping (address => uint256) internal _withdrawableStakeByOwner;

    // tracking Pool Id
    bytes32 public nextPoolId = INITIAL_POOL_ID;

    // mapping from Maker Address to a struct representing the pool the maker has joined and
    // whether the operator of that pool has subsequently added the maker.
    // (access externally using `getStakingPoolIdOfMaker`)
    mapping (address => IStructs.MakerPoolJoinStatus) internal _poolJoinedByMakerAddress;

    // mapping from Pool Id to Pool
    mapping (bytes32 => IStructs.Pool) internal _poolById;

    // mapping from PoolId to balance of members
    mapping (bytes32 => uint256) public rewardsByPoolId;

    // current epoch
    uint256 public currentEpoch = INITIAL_EPOCH;

    // current epoch start time
    uint256 public currentEpochStartTimeInSeconds;

    // mapping from Pool Id to Epoch to Reward Ratio
    mapping (bytes32 => mapping (uint256 => IStructs.Fraction)) internal _cumulativeRewardsByPool;

    // mapping from Pool Id to Epoch
    mapping (bytes32 => uint256) internal _cumulativeRewardsByPoolLastStored;

    // registered 0x Exchange contracts
    mapping (address => bool) public validExchanges;

    /* Tweakable parameters */

    // Minimum seconds between epochs.
    uint256 public epochDurationInSeconds;

    // How much delegated stake is weighted vs operator stake, in ppm.
    uint32 public rewardDelegatedStakeWeight;

    // Minimum amount of stake required in a pool to collect rewards.
    uint256 public minimumPoolStake;

    // Maximum number of maker addresses allowed to be registered to a pool.
    uint256 public maximumMakersInPool;

    // Numerator for cobb douglas alpha factor.
    uint32 public cobbDouglasAlphaNumerator;

    // Denominator for cobb douglas alpha factor.
    uint32 public cobbDouglasAlphaDenominator;

    /* Finalization states */

    /// @dev The total fees collected in the current epoch, built up iteratively
    ///      in `payProtocolFee()`.
    uint256 public totalFeesCollectedThisEpoch;

    /// @dev The total weighted stake in the current epoch, built up iteratively
    ///      in `payProtocolFee()`.
    uint256 public totalWeightedStakeThisEpoch;

    /// @dev State information for each active pool in an epoch.
    ///      In practice, we only store state for `currentEpoch % 2`.
    mapping (uint256 => mapping (bytes32 => IStructs.ActivePool)) internal _activePoolsByEpoch;

    /// @dev Number of pools activated in the current epoch.
    uint256 public numActivePoolsThisEpoch;

    /// @dev State for unfinalized rewards.
    IStructs.UnfinalizedState public unfinalizedState;

    /// @dev The WETH balance of this contract that is reserved for pool reward payouts.
    uint256 public wethReservedForPoolRewards;
}
// [flatten] version pragma removed


interface IStakingEvents {

    /// @dev Emitted by MixinStake when ZRX is staked.
    /// @param staker of ZRX.
    /// @param amount of ZRX staked.
    event Stake(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted by MixinStake when ZRX is unstaked.
    /// @param staker of ZRX.
    /// @param amount of ZRX unstaked.
    event Unstake(
        address indexed staker,
        uint256 amount
    );

    /// @dev Emitted by MixinStake when ZRX is unstaked.
    /// @param staker of ZRX.
    /// @param amount of ZRX unstaked.
    event MoveStake(
        address indexed staker,
        uint256 amount,
        uint8 fromStatus,
        bytes32 indexed fromPool,
        uint8 toStatus,
        bytes32 indexed toPool
    );

    /// @dev Emitted by MixinExchangeManager when an exchange is added.
    /// @param exchangeAddress Address of new exchange.
    event ExchangeAdded(
        address exchangeAddress
    );

    /// @dev Emitted by MixinExchangeManager when an exchange is removed.
    /// @param exchangeAddress Address of removed exchange.
    event ExchangeRemoved(
        address exchangeAddress
    );

    /// @dev Emitted by MixinExchangeFees when a pool pays protocol fees
    ///      for the first time in an epoch.
    /// @param epoch The epoch in which the pool was activated.
    /// @param poolId The ID of the pool.
    event StakingPoolActivated(
        uint256 indexed epoch,
        bytes32 indexed poolId
    );

    /// @dev Emitted by MixinFinalizer when an epoch has ended.
    /// @param epoch The closing epoch.
    /// @param numActivePools Number of active pools in the closing epoch.
    /// @param rewardsAvailable Rewards available to all active pools.
    /// @param totalWeightedStake Total weighted stake across all active pools.
    /// @param totalFeesCollected Total fees collected across all active pools.
    event EpochEnded(
        uint256 indexed epoch,
        uint256 numActivePools,
        uint256 rewardsAvailable,
        uint256 totalFeesCollected,
        uint256 totalWeightedStake
    );

    /// @dev Emitted by MixinFinalizer when an epoch is fully finalized.
    /// @param epoch The epoch being finalized.
    /// @param rewardsPaid Total amount of rewards paid out.
    /// @param rewardsRemaining Rewards left over.
    event EpochFinalized(
        uint256 indexed epoch,
        uint256 rewardsPaid,
        uint256 rewardsRemaining
    );

    /// @dev Emitted by MixinFinalizer when rewards are paid out to a pool.
    /// @param epoch The epoch when the rewards were earned.
    /// @param poolId The pool's ID.
    /// @param operatorReward Amount of reward paid to pool operator.
    /// @param membersReward Amount of reward paid to pool members.
    event RewardsPaid(
        uint256 indexed epoch,
        bytes32 indexed poolId,
        uint256 operatorReward,
        uint256 membersReward
    );

    /// @dev Emitted whenever staking parameters are changed via the `setParams()` function.
    /// @param epochDurationInSeconds Minimum seconds between epochs.
    /// @param rewardDelegatedStakeWeight How much delegated stake is weighted vs operator stake, in ppm.
    /// @param minimumPoolStake Minimum amount of stake required in a pool to collect rewards.
    /// @param maximumMakersInPool Maximum number of maker addresses allowed to be registered to a pool.
    /// @param cobbDouglasAlphaNumerator Numerator for cobb douglas alpha factor.
    /// @param cobbDouglasAlphaDenominator Denominator for cobb douglas alpha factor.
    event ParamsSet(
        uint256 epochDurationInSeconds,
        uint32 rewardDelegatedStakeWeight,
        uint256 minimumPoolStake,
        uint256 maximumMakersInPool,
        uint256 cobbDouglasAlphaNumerator,
        uint256 cobbDouglasAlphaDenominator
    );

    /// @dev Emitted by MixinStakingPool when a new pool is created.
    /// @param poolId Unique id generated for pool.
    /// @param operator The operator (creator) of pool.
    /// @param operatorShare The share of rewards given to the operator, in ppm.
    event StakingPoolCreated(
        bytes32 poolId,
        address operator,
        uint32 operatorShare
    );

    /// @dev Emitted by MixinStakingPool when a new maker requests to join a pool.
    /// @param poolId Unique id of pool.
    /// @param makerAddress Adress of maker joining the pool.
    event PendingAddMakerToPool(
        bytes32 indexed poolId,
        address makerAddress
    );

    /// @dev Emitted by MixinStakingPool when a new maker is added to a pool.
    /// @param poolId Unique id of pool.
    /// @param makerAddress Adress of maker added to pool.
    event MakerAddedToStakingPool(
        bytes32 indexed poolId,
        address makerAddress
    );

    /// @dev Emitted by MixinStakingPool when a maker is removed from a pool.
    /// @param poolId Unique id of pool.
    /// @param makerAddress Adress of maker added to pool.
    event MakerRemovedFromStakingPool(
        bytes32 indexed poolId,
        address makerAddress
    );

    /// @dev Emitted when a staking pool's operator share is decreased.
    /// @param poolId Unique Id of pool.
    /// @param oldOperatorShare Previous share of rewards owned by operator.
    /// @param newOperatorShare Newly decreased share of rewards owned by operator.
    event OperatorShareDecreased(
        bytes32 indexed poolId,
        uint32 oldOperatorShare,
        uint32 newOperatorShare
    );
}
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;


contract MixinScheduler is
    IStakingEvents,
    MixinStorage
{
    using LibSafeMath for uint256;

    /// @dev Returns the earliest end time in seconds of this epoch.
    ///      The next epoch can begin once this time is reached.
    ///      Epoch period = [startTimeInSeconds..endTimeInSeconds)
    /// @return Time in seconds.
    function getCurrentEpochEarliestEndTimeInSeconds()
        public
        view
        returns (uint256)
    {
        return currentEpochStartTimeInSeconds.safeAdd(epochDurationInSeconds);
    }

    /// @dev Initializes state owned by this mixin.
    ///      Fails if state was already initialized.
    function _initMixinScheduler()
        internal
    {
        // assert the current values before overwriting them.
        _assertSchedulerNotInitialized();

        // solhint-disable-next-line
        currentEpochStartTimeInSeconds = block.timestamp;
    }

    /// @dev Moves to the next epoch, given the current epoch period has ended.
    ///      Time intervals that are measured in epochs (like timeLocks) are also incremented, given
    ///      their periods have ended.
    function _goToNextEpoch()
        internal
    {
        // get current timestamp
        // solhint-disable-next-line not-rely-on-time
        uint256 currentBlockTimestamp = block.timestamp;

        // validate that we can increment the current epoch
        uint256 epochEndTime = getCurrentEpochEarliestEndTimeInSeconds();
        // SWC-116-Block values as a proxy for time: L71
        if (epochEndTime > currentBlockTimestamp) {
            LibRichErrors.rrevert(LibStakingRichErrors.BlockTimestampTooLowError(
                epochEndTime,
                currentBlockTimestamp
            ));
        }

        // incremment epoch
        uint256 nextEpoch = currentEpoch.safeAdd(1);
        currentEpoch = nextEpoch;
        currentEpochStartTimeInSeconds = currentBlockTimestamp;
    }

    /// @dev Assert scheduler state before initializing it.
    /// This must be updated for each migration.
    function _assertSchedulerNotInitialized()
        internal
        view
    {
        if (currentEpochStartTimeInSeconds != 0) {
            LibRichErrors.rrevert(
                LibStakingRichErrors.InitializationError(
                    LibStakingRichErrors.InitializationErrorCodes.MixinSchedulerAlreadyInitialized
                )
            );
        }
    }
}
