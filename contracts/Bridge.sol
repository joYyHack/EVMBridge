// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./bridge/interfaces/IBridge.sol";
import "./bridge/interfaces/IERC20SafeHandler.sol";
import "./bridge/interfaces/IValidator.sol";
import "./bridge/utils/constants.sol";
import {TokenType} from "./bridge/utils/enums.sol";

contract Bridge is IBridge, AccessControl {
    IERC20SafeHandler public erc20Safe;
    IValidator public validator;
    bytes32 public constant BRIDGE_MANAGER = keccak256("BRIDGE_MANAGER");

    modifier erc20SafeIsSet() {
        require(
            address(erc20Safe) != address(0),
            "Bridge: erc20 safe handler is not set yet"
        );
        _;
    }
    modifier validatorIsSet() {
        require(
            address(validator) != address(0),
            "Bridge: validator is not set yet"
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
        erc20Safe = IERC20SafeHandler(_safeHandler);
    }

    function setValidator(
        address _validator
    ) external onlyRole(BRIDGE_MANAGER) {
        validator = IValidator(_validator);
    }

    function deposit(address _token, uint256 _amount) external erc20SafeIsSet {
        erc20Safe.deposit(_msgSender(), _token, _amount);
        emit Deposit(_msgSender(), _token, _amount);
    }

    function burn(address _token, uint256 _amount) external erc20SafeIsSet {
        erc20Safe.burn(_msgSender(), _token, _amount);
        emit Burn(
            _msgSender(),
            _token,
            erc20Safe.getTokenInfo(_token).sourceToken,
            _amount
        );
    }

    function release(
        address _sourceToken,
        uint256 _amount,
        bytes memory _signature
    ) external erc20SafeIsSet validatorIsSet {
        IValidator.WithdrawalRequest memory req = _createRequest(
            _sourceToken,
            _amount,
            TokenType.Native
        );

        validator.verify(req, _signature);

        erc20Safe.release(_msgSender(), _sourceToken, _amount);
        emit Release(_msgSender(), _sourceToken, _amount);
    }

    function withdraw(
        address _sourceToken,
        uint256 _amount,
        bytes memory _signature
    ) external erc20SafeIsSet validatorIsSet {
        IValidator.WithdrawalRequest memory req = _createRequest(
            _sourceToken,
            _amount,
            TokenType.Wrapped
        );

        validator.verify(req, _signature);

        erc20Safe.withdraw(_msgSender(), _sourceToken, _amount);

        emit Withdraw(
            _msgSender(),
            _sourceToken,
            erc20Safe.getWrappedToken(_sourceToken),
            _amount
        );
    }

    function _createRequest(
        address _sourceToken,
        uint256 _amount,
        TokenType _tokenType
    ) internal view returns (IValidator.WithdrawalRequest memory) {
        return
            validator.createRequest(
                address(this),
                _msgSender(),
                _amount,
                _sourceToken,
                erc20Safe.getWrappedToken(_sourceToken),
                _tokenType
            );
    }
}
