// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/IERC20SafeHandler.sol";
import "../ERC20/ERC20Safe.sol";

contract ERC20SafeHandler is IERC20SafeHandler, ERC20Safe, Context {
    address immutable BRIDGE_ADDRESS;

    // owner => token address => amount
    mapping(address => mapping(address => uint256)) _depositedAmount;
    // token from opposite chain => token from current chain
    mapping(address => address) _tokenSourceMap;
    // token from current chain => token token info
    mapping(address => TokenInfo) _tokenInfos;

    modifier tokenAndAmountAreValid(address _token, uint256 _amount) {
        require(_token != address(0), "ERC20SafeHandler: zero address");
        require(
            _amount > 0,
            "ERC20SafeHandler: token amount has to be greater than 0"
        );
        _;
    }

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

    modifier onlyBridge() {
        require(
            _msgSender() == BRIDGE_ADDRESS,
            "ERC20SafeHandler: msg.sender must be a bridge"
        );
        _;
    }

    constructor(address bridgeAddress) {
        BRIDGE_ADDRESS = bridgeAddress;
    }

    function getBridgeAddress() external view returns (address _bridge) {
        return BRIDGE_ADDRESS;
    }

    function getWrappedToken(
        address _sourceToken
    ) external view returns (address _wrappedToken) {
        return _tokenSourceMap[_sourceToken];
    }

    function getTokenInfo(
        address _token
    ) external view returns (TokenInfo memory _tokenInfo) {
        return _tokenInfos[_token];
    }

    function getDepositedAmount(
        address _owner,
        address _token
    ) external view returns (uint256 _amount) {
        return _depositedAmount[_owner][_token];
    }

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

    function withdraw(
        address _to,
        address _sourceToken,
        uint256 _amount
    )
        external
        onlyBridge
        tokenIsValid(_sourceToken, TokenType.Native)
        tokenAndAmountAreValid(_sourceToken, _amount)
    {
        address wrappedToken = _tokenSourceMap[_sourceToken];
        if (wrappedToken == address(0)) {
            wrappedToken = address(new WrappedERC20("Test", "TST"));

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
}
