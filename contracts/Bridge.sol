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

    modifier safeHandlerIsSet() {
        require(
            address(safeHandler) != address(0),
            "Bridge: erc20 safe handler is not set yet"
        );
        _;
    }
    modifier tokenAndAmountAreValid(address _token, uint256 _amount) {
        require(
            _token != address(0) && _amount > 0,
            "Bridge: amount or address are incorrect"
        );
        _;
    }

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
        address _token,
        uint256 _amount
    ) external safeHandlerIsSet tokenAndAmountAreValid(_token, _amount) {
        safeHandler.deposit(_msgSender(), _token, _amount);
        emit Deposit(_msgSender(), _token, _amount);
    }

    function burn(
        address _token,
        uint256 _amount
    ) external safeHandlerIsSet tokenAndAmountAreValid(_token, _amount) {
        safeHandler.burn(_msgSender(), _token, _amount);
        // if _token initially is zero address then it is deployed but new address is not returned - need to fix
        emit Burn(_msgSender(), _token, _token, _amount);
    }

    function release(
        address _token,
        uint256 _amount
    ) external safeHandlerIsSet tokenAndAmountAreValid(_token, _amount) {
        safeHandler.release(_msgSender(), _token, _amount);
        emit Release(_msgSender(), _token, _amount);
    }

    function withdraw(
        address _sourceToken,
        uint256 _amount
    ) external safeHandlerIsSet tokenAndAmountAreValid(_sourceToken, _amount) {
        safeHandler.withdraw(_msgSender(), _sourceToken, _amount);

        // if _token initially is zero address then it is deployed but new address is not returned - need to fix
        emit Withdraw(_msgSender(), _sourceToken, _sourceToken, _amount);
    }
}
