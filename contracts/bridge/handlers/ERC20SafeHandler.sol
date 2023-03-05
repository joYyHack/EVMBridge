// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/IERC20SafeHandler.sol";
import "../ERC20/ERC20Safe.sol";

contract ERC20SafeHandler is IERC20SafeHandler, ERC20Safe, Context {
    address public immutable BRIDGE_ADDRESS;

    // source token for token type - native is address(0)
    struct TokenInfo {
        address sourceToken;
        TokenType tokenType;
    }

    // owner => token address => amount
    mapping(address => mapping(address => uint256)) _depositedAmount;
    // token from current chain => token token info
    mapping(address => TokenInfo) public tokenInfos;
    // token from opposite chain => token from current chain
    mapping(address => address) public tokenReversePairs;

    modifier tokenIsValid(address _token, TokenType _tokenType) {
        TokenInfo memory token = tokenInfos[_token];

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

    function deposit(
        address _owner,
        address _tokenAddress,
        uint256 _amount
    ) external onlyBridge tokenIsValid(_tokenAddress, TokenType.Native) {
        _depositedAmount[_owner][_tokenAddress] += _amount;
        TokenInfo storage token = tokenInfos[_tokenAddress];
        token.tokenType = TokenType.Native;

        _lock(_owner, _tokenAddress, _amount);
    }

    function burn(
        address _owner,
        address _tokenAddress,
        uint256 _amount
    ) external onlyBridge tokenIsValid(_tokenAddress, TokenType.Wrapped) {
        _burn(_owner, _tokenAddress, _amount);
    }

    function release(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyBridge tokenIsValid(_token, TokenType.Native) {
        require(
            _depositedAmount[_to][_token] >= _amount,
            "ERC20SafeHandler: Locked amount is lower than the provided"
        );

        _depositedAmount[_to][_token] -= _amount;
        _release(_to, _token, _amount);
    }

    function withdraw(
        address _to,
        address _sourceToken,
        uint256 _amount
    ) external onlyBridge tokenIsValid(_sourceToken, TokenType.Native) {
        address wrappedToken = tokenReversePairs[_sourceToken];
        if (wrappedToken == address(0)) {
            wrappedToken = address(new WrappedERC20("Test", "TST"));

            tokenInfos[wrappedToken] = TokenInfo(
                _sourceToken,
                TokenType.Wrapped
            );
            tokenReversePairs[_sourceToken] = wrappedToken;
        }

        require(
            tokenInfos[wrappedToken].sourceToken == _sourceToken &&
                tokenReversePairs[_sourceToken] == wrappedToken,
            "ERC20SafeHandler: Source token doesn't match provided token from opposite chain"
        );

        _mint(_to, wrappedToken, _amount);
    }
}
