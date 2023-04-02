// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./bridge/interfaces/IBridge.sol";
import "./bridge/interfaces/IERC20SafeHandler.sol";
import "./bridge/interfaces/IValidator.sol";
import {TokenType} from "./bridge/utils/enums.sol";

/**
 * @title Bridge
 * @author joYyHack
 * @notice The Bridge smart contract provides a bidirectional transfer
 * of ERC20 tokens between EVM-compatible chains. This means that users
 * can move their tokens from Chain A to Chain B and vice versa with ease.
 * Additionally, the Bridge supports the ERC20 Permit standard (ERC2612),
 * enabling gasless transactions by pre-approving token transfers.
 * With the Bridge, users have greater flexibility and control over their tokens,
 * eliminating the need to rely on centralized exchanges
 * or custodians for transfers between chains.
 */
contract Bridge is IBridge, AccessControl, ReentrancyGuard {
    using ERC165Checker for address;

    /**
     * @dev The `IERC20SafeHandler` contract used for managing actions of the ERC20 tokens.
     */
    IERC20SafeHandler public erc20Safe;
    /**
     * @dev The `IValidator` contract used for validating signatures and processing withdrawal requests.
     */
    IValidator public validator;
    /**
     * @dev The `BRIDGE_MANAGER` constant represents the unique identifier for the Bridge Manager role, which is used
     * to grant privileged access to functions related to managing the bridge. This constant is a `bytes32` value
     * obtained by hashing the string "BRIDGE_MANAGER" using the Keccak-256 algorithm.
     *
     */
    bytes32 public constant BRIDGE_MANAGER = keccak256("BRIDGE_MANAGER");

    /**
     * @notice Modifier to check if the ERC20 safe handler is set.
     * @dev This modifier ensures that the ERC20 safe handler has been set before executing the function.
     * If the ERC20 safe handler is not set, the function will revert with an error message.
     */
    modifier erc20SafeIsSet() {
        require(
            address(erc20Safe) != address(0),
            "Bridge: erc20 safe handler is not set yet"
        );
        _;
    }
    /**
     * @notice Modifier to check if the Validator is set.
     * @dev This modifier ensures that the Validator has been set before executing the function.
     * If the Validator is not set, the function will revert with an error message.
     */
    modifier validatorIsSet() {
        require(
            address(validator) != address(0),
            "Bridge: validator is not set yet"
        );
        _;
    }

    /**
     * @notice Contract constructor.
     * @dev Sets up the DEFAULT_ADMIN_ROLE with the address of the contract deployer.
     * Grants BRIDGE_MANAGER role to the contract deployer.
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(BRIDGE_MANAGER, _msgSender());
    }

    /**
     * @notice Set the ERC20SafeHandler contract address.
     * @dev This function sets the address of the ERC20SafeHandler contract to the specified address _safeHandler.
     * Only the BRIDGE_MANAGER role is authorized to call this function.
     * The ERC20SafeHandler contract is responsible for managing ERC20 token locks, releases, burns, withdrawals etc.
     * @param _safeHandler The address of the ERC20SafeHandler contract to be set.
     */
    function setERC20SafeHandler(
        address _safeHandler
    ) external onlyRole(BRIDGE_MANAGER) {
        erc20Safe = IERC20SafeHandler(_safeHandler);
    }

    /**
     * @notice Set the validator contract address.
     * @dev This function sets the address of the validator contract to the specified address `_validator`.
     * Only the BRIDGE_MANAGER role is authorized to call this function.
     * The validator contract is responsible for validating signatures on token releases and withdrawals.
     * @param _validator The address of the validator contract to be set.
     */
    function setValidator(
        address _validator
    ) external onlyRole(BRIDGE_MANAGER) {
        validator = IValidator(_validator);
    }

    /// @inheritdoc IBridge
    function deposit(
        address _token,
        uint256 _amount
    ) external erc20SafeIsSet nonReentrant {
        erc20Safe.deposit(_msgSender(), _token, _amount);
        emit Deposit(_msgSender(), _token, _amount);
    }

    /// @inheritdoc IBridge
    function depositPermit(
        address _token,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external erc20SafeIsSet nonReentrant {
        require(_isPermitSupported(_token), "Bridge: permit is not supported");

        erc20Safe.permit(_token, _msgSender(), _amount, _deadline, _v, _r, _s);

        erc20Safe.deposit(_msgSender(), _token, _amount);
        emit Deposit(_msgSender(), _token, _amount);
    }

    /// @inheritdoc IBridge
    function burn(
        address _token,
        uint256 _amount
    ) external erc20SafeIsSet nonReentrant {
        erc20Safe.burn(_msgSender(), _token, _amount);
        emit Burn(
            _msgSender(),
            _token,
            erc20Safe.getTokenInfo(_token).sourceToken,
            _amount
        );
    }

    /// @inheritdoc IBridge
    function burnPermit(
        address _token,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external erc20SafeIsSet nonReentrant {
        require(_isPermitSupported(_token), "Bridge: permit is not supported");

        erc20Safe.permit(_token, _msgSender(), _amount, _deadline, _v, _r, _s);

        erc20Safe.burn(_msgSender(), _token, _amount);
        emit Burn(
            _msgSender(),
            _token,
            erc20Safe.getTokenInfo(_token).sourceToken,
            _amount
        );
    }

    /// @inheritdoc IBridge
    function release(
        address _sourceToken,
        uint256 _amount,
        bytes memory _signature
    ) external erc20SafeIsSet validatorIsSet nonReentrant {
        IValidator.WithdrawalRequest memory req = _createRequest(
            _sourceToken,
            IERC20Metadata(_sourceToken).symbol(),
            IERC20Metadata(_sourceToken).name(),
            _isPermitSupported(_sourceToken),
            _amount,
            TokenType.Native
        );

        validator.verify(req, _signature);

        erc20Safe.release(_msgSender(), _sourceToken, _amount);
        emit Release(_msgSender(), _sourceToken, _amount);
    }

    /// @inheritdoc IBridge
    function withdraw(
        address _sourceToken,
        string memory _sourceTokenSymbol,
        string memory _sourceTokenName,
        bool _isSourceTokenPermit,
        uint256 _amount,
        bytes memory _signature
    ) external erc20SafeIsSet validatorIsSet nonReentrant {
        IValidator.WithdrawalRequest memory req = _createRequest(
            _sourceToken,
            _sourceTokenSymbol,
            _sourceTokenName,
            _isSourceTokenPermit,
            _amount,
            TokenType.Wrapped
        );

        validator.verify(req, _signature);

        erc20Safe.withdraw(
            _msgSender(),
            _sourceToken,
            _sourceTokenSymbol,
            _sourceTokenName,
            _isSourceTokenPermit,
            _amount
        );

        emit Withdraw(
            _msgSender(),
            _sourceToken,
            erc20Safe.getWrappedToken(_sourceToken),
            _amount
        );
    }

    /**
     * @notice Utility function for creating a withdrawal request structure with the given parameters.
     * @dev This function creates a WithdrawalRequest struct with the specified source token address, symbol, name,
     * whether the source token is an ERC2612 permit token or not, the amount of tokens to withdraw, and the token type.
     * The created structure is used by the validator to check the signature.
     * If the `_tokenType` is NATIVE, then the release process is initiated, if it's WRAPPED, then a withdrawal process is initiated.
     * As this is the internal function the `_tokenType` is defined by the calling function. In the `release` function `_tokenType` is defined as NATIVE,
     * in the `withdraw` function `_tokenType` is defined as `WRAPPED`.
     * The function returns the created WithdrawalRequest struct as defined on the validator contract.
     * @param _sourceToken The address of the ERC20 token from the source chain.
     * @param _sourceTokenSymbol The symbol of the token on the source chain.
     * @param _sourceTokenName The name of the token on the source chain.
     * @param _isSourceTokenPermit True if the token on the source chain is an ERC2612 permit token, false otherwise.
     * @param _amount The amount of tokens to be withdrawn.
     * @param _tokenType The type of token being withdrawn, either NATIVE or WRAPPED.
     * @return A WithdrawalRequest struct with the specified parameters.
     */
    function _createRequest(
        address _sourceToken,
        string memory _sourceTokenSymbol,
        string memory _sourceTokenName,
        bool _isSourceTokenPermit,
        uint256 _amount,
        TokenType _tokenType
    ) internal view returns (IValidator.WithdrawalRequest memory) {
        address wrappedToken = erc20Safe.getWrappedToken(_sourceToken);

        return
            validator.createRequest(
                address(this),
                _msgSender(),
                _amount,
                _sourceToken,
                _sourceTokenSymbol,
                _sourceTokenName,
                _isSourceTokenPermit,
                wrappedToken,
                _tokenType
            );
    }

    /**
     * @notice Check if a token supports the ERC2612 permit interface.
     * @dev Checks if the given token address implements the ERC2612 permit interface.
     * @param _token The address of the token to check.
     * @return A boolean indicating if the token implements the ERC2612 permit interface.
     */
    function _isPermitSupported(address _token) internal view returns (bool) {
        return _token.supportsInterface(type(IERC20Permit).interfaceId);
    }
}
