// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/IERC20SafeHandler.sol";
import "../ERC20/ERC20Safe.sol";

contract ERC20SafeHandler is IERC20SafeHandler, ERC20Safe, Context {
    address immutable BRIDGE_ADDRESS;

    struct TokenInfo {
        address sourceToken;
        TokenType tokenType;
    }

    mapping(address => TokenInfo) public tokenInfos;
    mapping(address => mapping(address => uint256)) _depositedAmount;

    modifier tokenIsValid(address _token, TokenType _tokenType) {
        TokenInfo memory token = tokenInfos[_token];

        require(
            token.tokenType == _tokenType,
            "ERC20SafeHandler: Token type mismatch"
        );

        require(
            !(_tokenType == TokenType.Native &&
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
        uint256 _amount,
        TokenType _tokenType
    ) external onlyBridge tokenIsValid(_tokenAddress, _tokenType) {
        if (_tokenType == TokenType.Native) {
            _depositedAmount[_owner][_tokenAddress] += _amount;
            _lock(_owner, _tokenAddress, _amount);
        } else {
            _burn(_owner, _tokenAddress, _amount);
        }

        TokenInfo storage token = tokenInfos[_tokenAddress];
        token.tokenType = _tokenType;
    }

    function withdraw(
        address _to,
        address _token,
        address _sourceToken,
        uint256 _amount,
        TokenType _tokenType,
        string memory _name,
        string memory _symbol
    ) external onlyBridge tokenIsValid(_token, _tokenType) {
        // if wrapped and exists - mint, if wrapped and doesn't exist - create and mint
        if (_tokenType == TokenType.Wrapped) {
            address wrappedToken = _token;
            if (_token == address(0)) {
                wrappedToken = address(new WrappedERC20(_name, _symbol));
                tokenInfos[wrappedToken] = TokenInfo(_sourceToken, _tokenType);
            }

            require(
                tokenInfos[wrappedToken].sourceToken == _sourceToken,
                "ERC20SafeHandler: Source token doesn't match provided token from opposite chain"
            );

            _mint(_to, wrappedToken, _amount);
        }

        // if native - release
        if (_tokenType == TokenType.Native) {
            require(
                _depositedAmount[_to][_token] >= _amount,
                "ERC20SafeHandler: Locked amount is lower than the provided"
            );

            _depositedAmount[_to][_token] -= _amount;
            _release(_to, _token, _amount);
        }
    }
}
