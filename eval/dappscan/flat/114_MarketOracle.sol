pragma solidity 0.4.24;
// [flatten] version pragma removed


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}
// [flatten] version pragma removed


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
// [flatten] version pragma removed
// [flatten] import inlined;


/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;


/**
 * @title Market Source
 *
 * @dev Provides the exchange rate and the 24 hour trading volume of a trading pair on a market.
 *      This can only receive data from a single trusted source, the owner address.
 *
 */
contract MarketSource is Destructible {
    using SafeMath for uint256;

    event LogExchangeRateReported(
        uint128 exchangeRate,
        uint128 volume24hrs,
        uint64 indexed timestampSec
    );

    // Name of the source reporting exchange rates
    string public _name;

    // These are the three oracle values that are continuously reported.
    // Smaller types are used here locally to save on storage gas.
    uint128 private _exchangeRate;
    uint128 private _volume24hrs;
    uint64 private _timestampSec;

    // The number of seconds after which the report must be deemed expired.
    uint64 public _reportExpirationTimeSec;

    constructor(string name, uint64 reportExpirationTimeSec) public {
        _name = name;
        _reportExpirationTimeSec = reportExpirationTimeSec;
    }

    /**
     * @param exchangeRate The average exchange rate over the past 24 hours of TOKEN:TARGET.
     *                     18 decimal fixed point number.
     * @param volume24hrs The trade volume of the past 24 hours in Token volume.
     *                    18 decimal fixed point number.
     * @param timestampSec The off chain timestamp of the observation.
     */
    function reportRate(uint128 exchangeRate, uint128 volume24hrs, uint64 timestampSec)
        external
        onlyOwner
    {
        require(exchangeRate > 0);
        require(volume24hrs > 0);

        _exchangeRate = exchangeRate;
        _volume24hrs = volume24hrs;
        _timestampSec = timestampSec;

        emit LogExchangeRateReported(exchangeRate, volume24hrs, timestampSec);
    }

    /**
     * @return Most recently reported market information.
     *         isFresh: Is true if the last report is within the expiration window and
     *                  false if the report has expired.
     *         exchangeRate: The average exchange rate over the last reported 24 hours
     *                       of TOKEN:TARGET.
     *                       18 decimal fixed point number.
     *         volume24hrs:  The trade volume of last 24 hours reported in Token volume.
     *                       18 decimal fixed point number.
     */
    function getReport()
        public
        view
        returns (bool, uint256, uint256)
    {
        bool isFresh = (uint256(_timestampSec).add(_reportExpirationTimeSec) > now);
        return (
            isFresh,
            uint256(_exchangeRate),
            uint256(_volume24hrs)
        );
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;


/**
 * @title Market Oracle
 *
 * @dev Provides the exchange rate and volume data onchain using data from a whitelisted
 *      set of market source contracts.
 *      Exchange rate is the TOKEN:TARGET rate.
 *      Volume is a 24 hour trading volume in Token volume.
 */
contract MarketOracle is Ownable {
    using SafeMath for uint256;

    // Whitelist of sources
    MarketSource[] public _whitelist;

    event LogSourceAdded(MarketSource source);
    event LogSourceRemoved(MarketSource source);
    event LogSourceExpired(MarketSource source);

    /**
     * @dev Calculates the volume weighted average of exchange rates and total trade volume.
     *      Expired market sources are ignored.
     * @return exchangeRate: Volume weighted average of exchange rates.
     *         volume: Total trade volume of the last reported 24 hours in Token volume.
     */
    //  SWC-107-Reentrancy: L34 - L60
    function getPriceAnd24HourVolume()
        external
        returns (uint256, uint256)
    {
        uint256 volumeWeightedSum = 0;
        uint256 volumeSum = 0;
        uint256 partialRate = 0;
        uint256 partialVolume = 0;
        bool isSourceFresh = false;

        for (uint256 i = 0; i < _whitelist.length; i++) {
            (isSourceFresh, partialRate, partialVolume) = _whitelist[i].getReport();

            if (!isSourceFresh) {
                emit LogSourceExpired(_whitelist[i]);
                continue;
            }

            volumeWeightedSum = volumeWeightedSum.add(partialRate.mul(partialVolume));
            volumeSum = volumeSum.add(partialVolume);
        }

        // No explicit fixed point normalization is done as dividing by volumeSum normalizes
        // to exchangeRate's format.
        uint256 exchangeRate = volumeWeightedSum.div(volumeSum);
        return (exchangeRate, volumeSum);
    }

    /**
     * @dev Adds a market source to the whitelist.
     * @param source Address of the MarketSource.
     */
    function addSource(MarketSource source)
        external
        onlyOwner
    {
        _whitelist.push(source);
        emit LogSourceAdded(source);
    }

    /**
     * @dev Removes the provided market source from the whitelist.
     * @param source Address of the MarketSource.
     */
    function removeSource(MarketSource source)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            if (_whitelist[i] == source) {
                removeSourceAtIndex(i);
                break;
            }
        }
    }

    /**
     * @dev Expunges from the whitelist any MarketSource whose associated contracts have been
     *      destructed.
     */
    function removeDestructedSources()
        external
    {
        uint256 i = 0;
        while (i < _whitelist.length) {
            if (isContractDestructed(_whitelist[i])) {
                removeSourceAtIndex(i);
            } else {
                i++;
            }
        }
    }

    /**
     * @return The number of market sources in the whitelist.
     */
    function whitelistSize()
        public
        view
        returns (uint256)
    {
        return _whitelist.length;
    }

    /**
     * @dev Checks if a contract has been destructed.
     * @param contractAddress Address of the contract.
     */
    function isContractDestructed(address contractAddress)
        private
        view
        returns (bool)
    {
        uint256 size;
        assembly { size := extcodesize(contractAddress) }
        return size == 0;
    }

   /**
    * @param index Index of the MarketSource to be removed from the whitelist.
    */
    function removeSourceAtIndex(uint256 index)
        private
    {
        emit LogSourceRemoved(_whitelist[index]);
        if (index != _whitelist.length-1) {
            _whitelist[index] = _whitelist[_whitelist.length-1];
        }
        // SWC-101-Integer Overflow and Underflow: L143
        _whitelist.length--;
    }
}
