// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./bridge/interfaces/IBridge.sol";
import "./bridge/interfaces/IERC20SafeHandler.sol";
import "./bridge/utils/constants.sol";
import {TokenType} from "./bridge/utils/enums.sol";

contract Bridge is IBridge, AccessControl {
    IERC20SafeHandler public safeHandler;
    bytes32 public constant BRIDGE_MANAGER = keccak256("BRIDGE_MANAGER");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(BRIDGE_MANAGER, _msgSender());
    }

    function setERC20SafeHandler(
        address _safeHandler
    ) external onlyRole(BRIDGE_MANAGER) {
        safeHandler = IERC20SafeHandler(_safeHandler);
    }

    function deposit(
        address _tokenAddress,
        uint256 _amount,
        TokenType _tokenType
    ) external {
        require(
            address(safeHandler) != address(0),
            "Bridge: erc20 safe handler is not set yet"
        );
        require(_amount > 0, "Bridge: amount can not be zero");
        require(
            _tokenAddress != address(0),
            "Bridge: Token can not be zero address"
        );

        safeHandler.deposit(_msgSender(), _tokenAddress, _amount, _tokenType);

        emit Deposit(_msgSender(), _tokenAddress, _amount);
    }

    function withdraw(
        address _token,
        address _sourceToken,
        uint256 _amount,
        TokenType _tokenType,
        string memory _name,
        string memory _symbol
    ) external {
        require(
            address(safeHandler) != address(0),
            "Brdige: erc20 safe handler is not set"
        );
        require(_amount > 0, "Bridge: amount can not be zero");
        require(
            !(_token == address(0) && _sourceToken == address(0)),
            "Bridge: Token and source token can not be zero address at the same time"
        );
        // if _token == address(0) then the wrapped token will be deployed it must have token's name and symbol
        require(
            !(_token == address(0) &&
                (keccak256(bytes(_name)) == EMPTY_STRING_HASH ||
                    keccak256(bytes(_symbol)) == EMPTY_STRING_HASH)),
            "Bridge: Token that will be deployed must have name and symbol"
        );

        safeHandler.withdraw(
            _msgSender(),
            _token,
            _sourceToken,
            _amount,
            _tokenType,
            _name,
            _symbol
        );

        // if _token initially is zero address then it is deployed but new address is not returned - need to fix
        //emit Withdraw(_msgSender(), _token, _sourceToken, _amount);
    }
}
