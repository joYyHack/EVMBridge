// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IERC20SafeHandler.sol";
import "../ERC20/ERC20Safe.sol";

/**
 * @title ERC20SafeHandler
 * @author joYyHack
 * @notice This contract handles ERC20 tokens safely by wrapping them and interacting with the bridge.
 */
contract ERC20SafeHandler is IERC20SafeHandler, ERC20Safe, Context {
    /**
     * @dev The address of the predefined bridge contract.
     * This address is set during contract deployment and cannot be changed.
     */
    address immutable BRIDGE_ADDRESS;

    /**
     * @dev Stores the deposited amount of tokens with a nested mapping structure, where the first key represents the owner's address
     * and the second key represents the token address. The value is the deposited amount of tokens.
     * owner => token address => amount
     */
    mapping(address => mapping(address => uint256)) _depositedAmount;
    /**
     * @dev Maps the token address from the opposite chain to the token address on the current chain.
     * token from opposite chain => token from current chain
     */
    mapping(address => address) _tokenSourceMap;
    /**
     * @dev Maps the token address on the current chain to its corresponding TokenInfo struct, which contains information about the token.
     * token from current chain => token token info
     */
    mapping(address => TokenInfo) _tokenInfos;

    /**
     * @notice Modifier to validate the provided token address and amount.
     * @dev Ensures that the token address is non-zero and the amount is greater than 0.
     * Functions using this modifier will only be executed if the provided token address and amount are valid.
     * @param _token The address of the token.
     * @param _amount The amount of tokens.
     */
    modifier tokenAndAmountAreValid(address _token, uint256 _amount) {
        require(_token != address(0), "ERC20SafeHandler: zero address");
        require(
            _amount > 0,
            "ERC20SafeHandler: token amount has to be greater than 0"
        );
        _;
    }
    /**
     * @notice Modifier to validate the provided token and its type.
     * @dev Ensures that the token has the specified token type and that it is not both native and has a source token at the same time.
     * Functions using this modifier will only be executed if the provided token and token type are valid.
     * @param _token The address of the token.
     * @param _tokenType The type of the token.
     */
    modifier tokenIsValid(address _token, TokenType _tokenType) {
        TokenInfo memory token = _tokenInfos[_token];

        require(
            token.tokenType == _tokenType,
            "ERC20SafeHandler: Token type mismatch"
        );

        require(
            !(token.tokenType == TokenType.Native &&
                token.sourceToken != address(0)),
            "ERC20SafeHandler: Token can not be native and has a source token at the same time"
        );

        _;
    }

    /**
     * @notice Modifier to allow only the predefined bridge contract to execute the function.
     * @dev Ensures that only the bridge contract address can call the function that uses this modifier.
     */
    modifier onlyBridge() {
        require(
            _msgSender() == BRIDGE_ADDRESS,
            "ERC20SafeHandler: msg.sender must be a bridge"
        );
        _;
    }

    /**
     * @notice Creates a new instance of the ERC20SafeHandler contract.
     * @dev Sets the address of the bridge contract during the deployment of the ERC20SafeHandler contract.
     * The provided bridge address must be a non-zero address.
     * @param bridgeAddress The address of the bridge contract.
     */
    constructor(address bridgeAddress) {
        require(
            bridgeAddress != address(0),
            "ERC20SafeHandler: Bridge address is zero address"
        );
        BRIDGE_ADDRESS = bridgeAddress;
    }

    /// @inheritdoc IERC20SafeHandler
    function getBridgeAddress() external view returns (address _bridge) {
        return BRIDGE_ADDRESS;
    }

    /// @inheritdoc IERC20SafeHandler
    function getWrappedToken(
        address _sourceToken
    ) external view returns (address _wrappedToken) {
        return _tokenSourceMap[_sourceToken];
    }

    /// @inheritdoc IERC20SafeHandler
    function getTokenInfo(
        address _token
    ) external view returns (TokenInfo memory _tokenInfo) {
        return _tokenInfos[_token];
    }

    /// @inheritdoc IERC20SafeHandler
    function getDepositedAmount(
        address _owner,
        address _token
    ) external view returns (uint256 _amount) {
        return _depositedAmount[_owner][_token];
    }

    /// @inheritdoc IERC20SafeHandler
    function deposit(
        address _owner,
        address _token,
        uint256 _amount
    )
        external
        onlyBridge
        tokenIsValid(_token, TokenType.Native)
        tokenAndAmountAreValid(_token, _amount)
    {
        _depositedAmount[_owner][_token] += _amount;

        //TODO: do I need to explicitly define struct in storage to modify it?
        // _tokenInfos[_token] <- this expression returns pointer to the struct

        // TokenInfo storage token = _tokenInfos[_token];
        // token.tokenType = TokenType.Native;
        _tokenInfos[_token].tokenType = TokenType.Native;

        _lock(_owner, _token, _amount);
    }

    /// @inheritdoc IERC20SafeHandler
    function burn(
        address _owner,
        address _token,
        uint256 _amount
    )
        external
        onlyBridge
        tokenIsValid(_token, TokenType.Wrapped)
        tokenAndAmountAreValid(_token, _amount)
    {
        _burn(_owner, _token, _amount);
    }

    /// @inheritdoc IERC20SafeHandler
    function release(
        address _to,
        address _sourceToken,
        uint256 _amount
    )
        external
        onlyBridge
        tokenIsValid(_sourceToken, TokenType.Native)
        tokenAndAmountAreValid(_sourceToken, _amount)
    {
        require(
            _depositedAmount[_to][_sourceToken] >= _amount,
            "ERC20SafeHandler: Locked amount is lower than the provided"
        );

        _depositedAmount[_to][_sourceToken] -= _amount;
        _release(_to, _sourceToken, _amount);
    }

    /// @inheritdoc IERC20SafeHandler
    function withdraw(
        address _to,
        address _sourceToken,
        string memory _sourceTokenSymbol,
        string memory _sourceTokenName,
        bool _isSourceTokenPermit,
        uint256 _amount
    )
        external
        onlyBridge
        tokenIsValid(_sourceToken, TokenType.Native)
        tokenAndAmountAreValid(_sourceToken, _amount)
    {
        address wrappedToken = _tokenSourceMap[_sourceToken];
        if (wrappedToken == address(0)) {
            IERC20 wrappedTokenContract = _isSourceTokenPermit
                ? new WrappedERC20Permit(_sourceTokenName, _sourceTokenSymbol)
                : new WrappedERC20(_sourceTokenName, _sourceTokenSymbol);

            wrappedToken = address(wrappedTokenContract);

            _tokenInfos[wrappedToken] = TokenInfo(
                _sourceToken,
                TokenType.Wrapped
            );
            _tokenSourceMap[_sourceToken] = wrappedToken;
        }

        require(
            _tokenInfos[wrappedToken].sourceToken == _sourceToken &&
                _tokenSourceMap[_sourceToken] == wrappedToken,
            "ERC20SafeHandler: Source token doesn't match provided token from opposite chain"
        );

        _mint(_to, wrappedToken, _amount);
    }

    /// @inheritdoc IERC20SafeHandler
    function permit(
        address _tokenAddress,
        address _owner,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external onlyBridge {
        _permit(_tokenAddress, _owner, _amount, _deadline, _v, _r, _s);
    }
}
