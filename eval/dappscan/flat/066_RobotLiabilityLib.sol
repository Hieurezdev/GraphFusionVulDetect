pragma solidity ^0.4.24;
// [flatten] version pragma removed


/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param _sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 _hash, bytes _sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (_sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(_hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 _hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    );
  }
}
// [flatten] version pragma removed


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
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
// [flatten] import inlined;
// [flatten] import inlined;


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}
// [flatten] version pragma removed
// [flatten] import inlined;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
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
// [flatten] import inlined;


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}
// [flatten] version pragma removed
// [flatten] import inlined;


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

contract XRT is MintableToken, BurnableToken {
    string public constant name     = "Robonomics Alpha";
    string public constant symbol   = "XRT";
    uint   public constant decimals = 9;

    uint256 public constant INITIAL_SUPPLY = 5 * (10 ** uint256(decimals));

    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;

contract RobotLiabilityABI {
    function ask(
        bytes   _model,
        bytes   _objective,

        ERC20   _token,
        uint256 _cost,

        address _validator,
        uint256 _validator_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    ) external returns (bool);

    function bid(
        bytes   _model,
        bytes   _objective,
        
        ERC20   _token,
        uint256 _cost,

        uint256 _lighthouse_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    ) external returns (bool);

    function finalize(
        bytes _result,
        bytes _signature,
        bool  _agree
    ) external returns (bool);
}
// [flatten] version pragma removed

contract LightContract {
    /**
     * @dev Shared code smart contract 
     */
    address lib;

    constructor(address _library) public {
        lib = _library;
    }

    function() public {
        require(lib.delegatecall(msg.data));
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

// Standard robot liability light contract
contract RobotLiability is RobotLiabilityAPI, LightContract {
    constructor(address _lib) public LightContract(_lib)
    { factory = LiabilityFactory(msg.sender); }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;


/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

/**
  @dev Ambix contract is used for morph Token set to another
  Token's by rule (recipe). In distillation process given
  Token's are burned and result generated by emission.
  
  The recipe presented as equation in form:
  (N1 * A1 & N'1 * A'1 & N''1 * A''1 ...)
  | (N2 * A2 & N'2 * A'2 & N''2 * A''2 ...) ...
  | (Nn * An & N'n * A'n & N''n * A''n ...)
  = M1 * B1 & M2 * B2 ... & Mm * Bm 
    where A, B - input and output tokens
          N, M - token value coeficients
          n, m - input / output dimetion size 
          | - is alternative operator (logical OR)
          & - is associative operator (logical AND)
  This says that `Ambix` should receive (approve) left
  part of equation and send (transfer) right part.
*/
contract Ambix is Ownable {
    address[][] public A;
    uint256[][] public N;
    address[] public B;
    uint256[] public M;

    /**
     * @dev Append token recipe source alternative
     * @param _a Token recipe source token addresses
     * @param _n Token recipe source token counts
     **/
    //SWC-128-DoS With Block Gas Limit: L36
    function appendSource(
        address[] _a,
        uint256[] _n
    ) public onlyOwner {
        require(_a.length == _n.length);
        A.length++;
        N.length++;

        uint256 ix = A.length - 1;
        for (uint256 i = 0; i < _a.length; ++i) {
            require(_a[i] != 0);

            A[ix].push(_a[i]);
            N[ix].push(_n[i]);
        }
    }

    /**
     * @dev Erase token recipe at '_ix' index
     * @param _ix Token recipe index
     */
    function removeSource(uint256 _ix) public onlyOwner {
        A[_ix].length = 0;
        N[_ix].length = 0;
    }

    /**
     * @dev Set sink of token recipe
     * @param _b Token recipe sink token list
     * @param _m Token recipe sink token counts
     */
    function setSink(
        address[] _b,
        uint256[] _m
    ) public onlyOwner{
        B = _b;
        M = _m;
    }

    /**
     * @dev Run distillation process
     * @param _ix Source alternative index
     */
    function run(uint256 _ix) {
        require(_ix < A.length);
        uint256 i;

        if (N[_ix][0] > 0) {
            // Static conversion

            StandardBurnableToken token = StandardBurnableToken(A[_ix][0]);
            // Token count multiplier
            uint256 mux = token.allowance(msg.sender, this) / N[_ix][0];
            require(mux > 0);

            // Burning run
            for (i = 0; i < A[_ix].length; ++i) {
                token = StandardBurnableToken(A[_ix][i]);
                token.burnFrom(msg.sender, mux * N[_ix][i]);
            }

            // Transfer up
            for (i = 0; i < B.length; ++i) {
                token = StandardBurnableToken(B[i]);
                require(token.transfer(msg.sender, M[i] * mux));
            }

        } else {
            // Dynamic conversion
            //   Let source token total supply is finite and decrease on each conversion,
            //   just convert finite supply of source to tokens on balance of ambix.
            //         dynamicRate = balance(sink) / total(source)

            // Is available for single source and single sink only
            require(A[_ix].length == 1 && B.length == 1);

            StandardBurnableToken source = StandardBurnableToken(A[_ix][0]);
            StandardBurnableToken sink = StandardBurnableToken(B[0]);

            uint256 scale = 10 ** 18 * sink.balanceOf(this) / source.totalSupply();

            uint256 allowance = source.allowance(msg.sender, this);
            require(allowance > 0);
            source.burnFrom(msg.sender, allowance);

            uint256 reward = scale * allowance / 10 ** 18;
            require(reward > 0);
            require(sink.transfer(msg.sender, reward));
        }
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;


/// @title Dutch auction contract - distribution of Gnosis tokens using an auction.
/// @author Stefan George - <stefan.george@consensys.net>
/// @author Airalab - <research@aira.life> 
contract DutchAuction {

    /*
     *  Events
     */
    event BidSubmission(address indexed sender, uint256 amount);

    /*
     *  Constants
     */
    uint constant public MAX_TOKENS_SOLD = 9000000 * 10**9; // 9M
    uint constant public WAITING_PERIOD = 7 days;

    /*
     *  Storage
     */
    XRT              public xrt;
    Ambix            public ambix;
    LiabilityFactory public factory;
    address public wallet;
    address public owner;
    uint public ceiling;
    uint public priceFactor;
    uint public startBlock;
    uint public endTime;
    uint public totalReceived;
    uint public finalPrice;
    mapping (address => uint) public bids;
    Stages public stage;

    /*
     *  Enums
     */
    enum Stages {
        AuctionDeployed,
        AuctionSetUp,
        AuctionStarted,
        AuctionEnded,
        TradingStarted
    }

    /*
     *  Modifiers
     */
    modifier atStage(Stages _stage) {
        // Contract on stage
        require(stage == _stage);
        _;
    }

    modifier isOwner() {
        // Only owner is allowed to proceed
        require(msg.sender == owner);
        _;
    }

    modifier isWallet() {
        // Only wallet is allowed to proceed
        require(msg.sender == wallet);
        _;
    }

    modifier isValidPayload() {
        require(msg.data.length == 4 || msg.data.length == 36);
        _;
    }

    modifier timedTransitions() {
        if (stage == Stages.AuctionStarted && calcTokenPrice() <= calcStopPrice())
            finalizeAuction();
        if (stage == Stages.AuctionEnded && now > endTime + WAITING_PERIOD)
            stage = Stages.TradingStarted;
        _;
    }

    /*
     *  Public functions
     */
    /// @dev Contract constructor function sets owner.
    /// @param _wallet Gnosis wallet.
    /// @param _ceiling Auction ceiling.
    /// @param _priceFactor Auction price factor.
    constructor(address _wallet, uint _ceiling, uint _priceFactor)
        public
    {
        require(_wallet != 0 && _ceiling != 0 && _priceFactor != 0);
        owner = msg.sender;
        wallet = _wallet;
        ceiling = _ceiling;
        priceFactor = _priceFactor;
        stage = Stages.AuctionDeployed;
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param _xrt Robonomics token address.
    /// @param _ambix Distillation cube address.
    /// @param _factory Robonomics liability factory address.
    function setup(address _xrt, address _ambix, address _factory)
        public
        isOwner
        atStage(Stages.AuctionDeployed)
    {
        // Validate argument
        require(_xrt != 0 && _ambix != 0 && _factory != 0);
        xrt = XRT(_xrt);
        ambix = Ambix(_ambix);
        factory = LiabilityFactory(_factory);

        // Validate token balance
        require(xrt.balanceOf(this) == MAX_TOKENS_SOLD);

        stage = Stages.AuctionSetUp;
    }

    /// @dev Starts auction and sets startBlock.
    function startAuction()
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        stage = Stages.AuctionStarted;
        startBlock = block.number;
    }

    /// @dev Changes auction ceiling and start price factor before auction is started.
    /// @param _ceiling Updated auction ceiling.
    /// @param _priceFactor Updated start price factor.
    function changeSettings(uint _ceiling, uint _priceFactor)
        public
        isWallet
        atStage(Stages.AuctionSetUp)
    {
        ceiling = _ceiling;
        priceFactor = _priceFactor;
    }

    /// @dev Calculates current token price.
    /// @return Returns token price.
    function calcCurrentTokenPrice()
        public
        timedTransitions
        returns (uint)
    {
        if (stage == Stages.AuctionEnded || stage == Stages.TradingStarted)
            return finalPrice;
        return calcTokenPrice();
    }

    /// @dev Returns correct stage, even if a function with timedTransitions modifier has not yet been called yet.
    /// @return Returns current auction stage.
    function updateStage()
        public
        timedTransitions
        returns (Stages)
    {
        return stage;
    }

    /// @dev Allows to send a bid to the auction.
    /// @param receiver Bid will be assigned to this address if set.
    function bid(address receiver)
        public
        payable
        isValidPayload
        timedTransitions
        atStage(Stages.AuctionStarted)
        returns (uint amount)
    {
        require(msg.value > 0);
        amount = msg.value;

        // If a bid is done on behalf of a user via ShapeShift, the receiver address is set.
        if (receiver == 0)
            receiver = msg.sender;

        // Prevent that more than 90% of tokens are sold. Only relevant if cap not reached.
        uint maxWei = (MAX_TOKENS_SOLD / 10**18) * calcTokenPrice() - totalReceived;
        uint maxWeiBasedOnTotalReceived = ceiling - totalReceived;
        if (maxWeiBasedOnTotalReceived < maxWei)
            maxWei = maxWeiBasedOnTotalReceived;

        // Only invest maximum possible amount.
        if (amount > maxWei) {
            amount = maxWei;
            // Send change back to receiver address. In case of a ShapeShift bid the user receives the change back directly.
            receiver.transfer(msg.value - amount);
        }

        // Forward funding to ether wallet
        wallet.transfer(amount);

        bids[receiver] += amount;
        totalReceived += amount;
        if (maxWei == amount)
            // When maxWei is equal to the big amount the auction is ended and finalizeAuction is triggered.
            finalizeAuction();
        BidSubmission(receiver, amount);
    }

    /// @dev Claims tokens for bidder after auction.
    /// @param receiver Tokens will be assigned to this address if set.
    function claimTokens(address receiver)
        public
        isValidPayload
        timedTransitions
        atStage(Stages.TradingStarted)
    {
        if (receiver == 0)
            receiver = msg.sender;
        uint tokenCount = bids[receiver] * 10**18 / finalPrice;
        bids[receiver] = 0;
        require(xrt.transfer(receiver, tokenCount));
    }

    /// @dev Calculates stop price.
    /// @return Returns stop price.
    function calcStopPrice()
        constant
        public
        returns (uint)
    {
        return totalReceived * 10**18 / MAX_TOKENS_SOLD + 1;
    }

    /// @dev Calculates token price.
    /// @return Returns token price.
    function calcTokenPrice()
        constant
        public
        returns (uint)
    {
        return priceFactor * 10**18 / (block.number - startBlock + 7500) + 1;
    }

    /*
     *  Private functions
     */
    function finalizeAuction()
        private
    {
        stage = Stages.AuctionEnded;
        if (totalReceived == ceiling)
            finalPrice = calcTokenPrice();
        else
            finalPrice = calcStopPrice();
        uint soldTokens = totalReceived * 10**18 / finalPrice;

        // Auction contract transfers all unsold tokens to Ambix contract
        require(xrt.transfer(ambix, MAX_TOKENS_SOLD - soldTokens));

        endTime = now;
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

contract LighthouseAPI {
    address[] public members;
    mapping(address => uint256) indexOf;

    mapping(address => uint256) public balances;

    uint256 public minimalFreeze;
    uint256 public timeoutBlocks;

    LiabilityFactory public factory;
    XRT              public xrt;

    uint256 public keepaliveBlock = 0;
    uint256 public marker = 0;
    uint256 public quota = 0;

    function quotaOf(address _member) public view returns (uint256)
    { return balances[_member] / minimalFreeze; }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

contract Lighthouse is LighthouseAPI, LightContract {
    constructor(
        address _lib,
        uint256 _minimalFreeze,
        uint256 _timeoutBlocks
    ) 
        public
        LightContract(_lib)
    {
        minimalFreeze = _minimalFreeze;
        timeoutBlocks = _timeoutBlocks;
        factory = LiabilityFactory(msg.sender);
        xrt = factory.xrt();
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

contract LiabilityFactory {
    constructor(
        address _robot_liability_lib,
        address _lighthouse_lib,
        DutchAuction _auction,
        XRT _xrt,
        ENS _ens
    ) public {
        robotLiabilityLib = _robot_liability_lib;
        lighthouseLib = _lighthouse_lib;
        auction = _auction;
        xrt = _xrt;
        ens = _ens;
    }

    /**
     * @dev New liability created 
     */
    event NewLiability(address indexed liability);

    /**
     * @dev New lighthouse created
     */
    event NewLighthouse(address indexed lighthouse, string name);

    /**
     * @dev Robonomics dutch auction contract
     */
    DutchAuction public auction;

    /**
     * @dev Robonomics network protocol token
     */
    XRT public xrt;

    /**
     * @dev Ethereum name system
     */
    ENS public ens;

    /**
     * @dev Total GAS utilized by Robonomics network
     */
    uint256 public totalGasUtilizing = 0;

    /**
     * @dev GAS utilized by liability contracts
     */
    mapping(address => uint256) public gasUtilizing;

    /**
     * @dev The count of utilized gas for switch to next epoch 
     */
    uint256 public constant gasEpoch = 347 * 10**10;

    /**
     * @dev Weighted average gasprice
     */
    uint256 public constant gasPrice = 10 * 10**9;

    /**
     * @dev Used market orders accounting
     */
    mapping(bytes32 => bool) public usedHash;

    /**
     * @dev Lighthouse accounting
     */
    mapping(address => bool) public isLighthouse;

    /**
     * @dev Robot liability shared code smart contract
     */
    address public robotLiabilityLib;

    /**
     * @dev Lightouse shared code smart contract
     */
    address public lighthouseLib;

    /**
     * @dev XRT emission value for utilized gas
     */
    function wnFromGas(uint256 _gas) public view returns (uint256) {
        // Current gas utilization epoch
        uint256 epoch = totalGasUtilizing / gasEpoch;

        // XRT emission with addition coefficient by gas utilzation epoch
        uint256 wn = _gas * gasPrice * 2**epoch / 3**epoch / auction.finalPrice();

        // Check to not permit emission decrease below wn=gas
        return wn < _gas ? _gas : wn;
    }

    /**
     * @dev Only lighthouse guard
     */
    modifier onlyLighthouse {
        require(isLighthouse[msg.sender]);
        _;
    }

    /**
     * @dev Parameter can be used only once
     * @param _hash Single usage hash
     */
    function usedHashGuard(bytes32 _hash) internal {
        require(!usedHash[_hash]);
        usedHash[_hash] = true;
    }

    /**
     * @dev Create robot liability smart contract
     * @param _ask ABI-encoded ASK order message 
     * @param _bid ABI-encoded BID order message 
     */
    function createLiability(
        bytes _ask,
        bytes _bid
    )
        external 
        onlyLighthouse
        returns (RobotLiability liability)
    {
        // Store in memory available gas
        uint256 gasinit = gasleft();

        // Create liability
        liability = new RobotLiability(robotLiabilityLib);
        emit NewLiability(liability);

        // Parse messages
        require(liability.call(abi.encodePacked(bytes4(0x82fbaa25), _ask))); // liability.ask(...)
        usedHashGuard(liability.askHash());

        require(liability.call(abi.encodePacked(bytes4(0x66193359), _bid))); // liability.bid(...)
        usedHashGuard(liability.bidHash());

        // Transfer lighthouse fee to lighthouse worker directly
        require(xrt.transferFrom(liability.promisor(),
                                 tx.origin,
                                 liability.lighthouseFee()));

        // Transfer liability security and hold on contract
        ERC20 token = liability.token();
        require(token.transferFrom(liability.promisee(),
                                   liability,
                                   liability.cost()));

        // Transfer validator fee and hold on contract
        if (address(liability.validator()) != 0 && liability.validatorFee() > 0)
            require(xrt.transferFrom(liability.promisee(),
                                     liability,
                                     liability.validatorFee()));

        // Accounting gas usage of transaction
        uint256 gas = gasinit - gasleft() + 110525; // Including observation error
        totalGasUtilizing       += gas;
        gasUtilizing[liability] += gas;
     }

    /**
     * @dev Create lighthouse smart contract
     * @param _minimalFreeze Minimal freeze value of XRT token
     * @param _timeoutBlocks Max time of lighthouse silence in blocks
     * @param _name Lighthouse subdomain,
     *              example: for 'my-name' will created 'my-name.lighthouse.0.robonomics.eth' domain
     */
    function createLighthouse(
        uint256 _minimalFreeze,
        uint256 _timeoutBlocks,
        string  _name
    )
        external
        returns (address lighthouse)
    {
        // Name reservation check
        bytes32 subnode = keccak256(abi.encodePacked(lighthouseNode, keccak256(_name)));
        require(ens.resolver(subnode) == 0);

        // Create lighthouse
        lighthouse = new Lighthouse(lighthouseLib, _minimalFreeze, _timeoutBlocks);
        emit NewLighthouse(lighthouse, _name);
        isLighthouse[lighthouse] = true;

        bytes32 lighthouseNode
            // lighthouse.0.robonomics.eth
            = 0x1e42a8e8e1e8cf36e83d096dcc74af801d0a194a14b897f9c8dfd403b4eebeda;

        // Register subnode
        ens.setSubnodeOwner(lighthouseNode, keccak256(_name), this);

        // Register lighthouse address
        PublicResolver resolver = PublicResolver(ens.resolver(lighthouseNode));
        ens.setResolver(subnode, resolver);
        resolver.setAddr(subnode, lighthouse);
    }

    /**
     * @dev Is called whan after liability finalization
     * @param _gas Liability finalization gas expenses
     */
    function liabilityFinalized(
        uint256 _gas
    )
        external
        returns (bool)
    {
        require(gasUtilizing[msg.sender] > 0);

        uint256 gas = _gas - gasleft();
        totalGasUtilizing        += gas;
        gasUtilizing[msg.sender] += gas;
        require(xrt.mint(tx.origin, wnFromGas(gasUtilizing[msg.sender])));
        return true;
    }
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;

contract RobotLiabilityAPI {
    bytes   public model;
    bytes   public objective;
    bytes   public result;

    ERC20   public token;
    uint256 public cost;
    uint256 public lighthouseFee;
    uint256 public validatorFee;

    bytes32 public askHash;
    bytes32 public bidHash;

    address public promisor;
    address public promisee;
    address public validator;

    bool    public isConfirmed;
    bool    public isFinalized;

    LiabilityFactory public factory;
}
// [flatten] version pragma removed
// [flatten] import inlined;
// [flatten] import inlined;
// [flatten] import inlined;

contract RobotLiabilityLib is RobotLiabilityABI
                            , RobotLiabilityAPI {
    using ECRecovery for bytes32;

    function ask(
        bytes   _model,
        bytes   _objective,

        ERC20   _token,
        uint256 _cost,

        address _validator,
        uint256 _validator_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    )
        external
        returns (bool)
    {
        require(msg.sender == address(factory));
        require(block.number < _deadline);

        model        = _model;
        objective    = _objective;
        token        = _token;
        cost         = _cost;
        validator    = _validator;
        validatorFee = _validator_fee;

        askHash = keccak256(abi.encodePacked(
            _model
          , _objective
          , _token
          , _cost
          , _validator
          , _validator_fee
          , _deadline
          , _nonce
        ));

        promisee = askHash
            .toEthSignedMessageHash()
            .recover(_signature);
        return true;
    }

    function bid(
        bytes   _model,
        bytes   _objective,
        
        ERC20   _token,
        uint256 _cost,

        uint256 _lighthouse_fee,

        uint256 _deadline,
        bytes32 _nonce,
        bytes   _signature
    )
        external
        returns (bool)
    {
        require(msg.sender == address(factory));
        require(block.number < _deadline);
        //SWC-133-Hash Collisions With Multiple Variable Length Arguments: L74-L75
        require(keccak256(abi.encodePacked(model, objective))
                == keccak256(abi.encodePacked(_model, _objective)));
        require(_token == token);
        require(_cost == cost);

        lighthouseFee = _lighthouse_fee;

        bidHash = keccak256(abi.encodePacked(
            _model
          , _objective
          , _token
          , _cost
          , _lighthouse_fee
          , _deadline
          , _nonce
        ));

        promisor = bidHash
            .toEthSignedMessageHash()
            .recover(_signature);
        return true;
    }

    /**
     * @dev Finalize this liability
     * @param _result Result data hash
     * @param _agree Validation network confirmation
     * @param _signature Result sender signature
     */
     //SWC-107-Reentrancy: L104
    function finalize(
        bytes _result,
        bytes _signature,
        bool  _agree
    )
        external
        returns (bool)
    {
        uint256 gasinit = gasleft();
        require(!isFinalized);

        address resultSender = keccak256(abi.encodePacked(this, _result))
            .toEthSignedMessageHash()
            .recover(_signature);
        require(resultSender == promisor);

        if (validator == 0) {
            require(factory.isLighthouse(msg.sender));
            require(token.transfer(promisor, cost));
        } else {
            require(msg.sender == validator);

            isConfirmed = _agree;
            if (isConfirmed)
                require(token.transfer(promisor, cost));
            else
                require(token.transfer(promisee, cost));

            if (validatorFee > 0)
                require(factory.xrt().transfer(validator, validatorFee));
        }

        result = _result;
        isFinalized = true;

        require(factory.liabilityFinalized(gasinit));
        return true;
    }
}
