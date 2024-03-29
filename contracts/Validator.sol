// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./bridge/interfaces/IValidator.sol";
import {TokenType} from "./bridge/utils/enums.sol";

/**
 * @title Validator
 * @author joYyHack
 * @notice Validator is an implementation of the IValidator interface
 * that verifies token withdrawal requests and emits an event upon successful verification.
 * @dev Inherits from EIP712, Context and Ownable contracts from OpenZeppelin.
 */
contract Validator is IValidator, EIP712, Context, Ownable {
    /**
     * @dev Address of the validator, immutable after construction.
     */
    address immutable VALIDATOR_ADDRESS;

    /**
     * @notice Constant hash of the WithdrawalRequest struct.
     */
    bytes32 internal constant WITHDRAWAL_REQ_TYPE_HASH =
        keccak256(
            abi.encodePacked(
                "WithdrawalRequest(",
                "address validator,",
                "address bridge,",
                "address from,",
                "uint256 amount,",
                "address sourceToken,",
                "string sourceTokenSymbol,",
                "string sourceTokenName,",
                "bool isSourceTokenPermit,",
                "address wrappedToken,",
                "uint8 withdrawalTokenType,",
                "uint256 nonce",
                ")"
            )
        );

    /**
     * @dev Mapping to store nonces for addresses.
     */
    mapping(address => uint256) private _nonces;

    /**
     * @notice Constructor that initializes the EIP712 contract with domain information and sets the owner as the validator.
     */
    constructor() EIP712("Validator", "0.1") {
        VALIDATOR_ADDRESS = owner();
    }

    /// @inheritdoc IValidator
    function verify(WithdrawalRequest memory _req, bytes memory _sig) external {
        bytes32 digest = _hashTypedDataV4(_hash(_req));
        address signer = ECDSA.recover(digest, _sig);
        require(
            signer == VALIDATOR_ADDRESS && _nonces[_req.from] == _req.nonce,
            "Validator: signature does not match request"
        );
        require(
            _msgSender() == _req.bridge,
            "Validator: only bridge can verify request"
        );

        _nonces[_req.from]++;

        emit Verified(
            _req.from,
            _req.withdrawalTokenType == TokenType.Native
                ? _req.sourceToken
                : _req.wrappedToken,
            _req.amount
        );
    }

    /// @inheritdoc IValidator
    function createRequest(
        address _bridge,
        address _from,
        uint256 _amount,
        address _sourceToken,
        string memory _sourceTokenSymbol,
        string memory _sourceTokenName,
        bool _isSourceTokenPermit,
        address _wrappedToken,
        TokenType _withdrawalTokenType
    ) external view returns (WithdrawalRequest memory) {
        return
            WithdrawalRequest(
                VALIDATOR_ADDRESS,
                _bridge,
                _from,
                _amount,
                _sourceToken,
                _sourceTokenSymbol,
                _sourceTokenName,
                _isSourceTokenPermit,
                _wrappedToken,
                _withdrawalTokenType,
                _nonces[_from]
            );
    }

    /// @inheritdoc IValidator
    function getNonce(address _from) external view returns (uint256 nonce) {
        return _nonces[_from];
    }

    /**
     * @notice Internal function that hashes a WithdrawalRequest instance.
     * @param _req The WithdrawalRequest instance to hash.
     * @return The hash of the WithdrawalRequest instance.
     */
    function _hash(
        WithdrawalRequest memory _req
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    WITHDRAWAL_REQ_TYPE_HASH,
                    _req.validator,
                    _req.bridge,
                    _req.from,
                    _req.amount,
                    _req.sourceToken,
                    keccak256(bytes(_req.sourceTokenSymbol)),
                    keccak256(bytes(_req.sourceTokenName)),
                    _req.isSourceTokenPermit,
                    _req.wrappedToken,
                    _req.withdrawalTokenType,
                    _req.nonce
                )
            );
    }
}
