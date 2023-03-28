// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./bridge/interfaces/IValidator.sol";
import {TokenType} from "./bridge/utils/enums.sol";

import "hardhat/console.sol";

contract Validator is IValidator, EIP712, Context {
    address constant VALIDATOR_ADDRESS =
        0xe1AB69E519d887765cF0bb51D0cFFF2264B38080;

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
    mapping(address => uint256) private _nonces;

    constructor() EIP712("Validator", "0.1") {}

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

    function getNonce(address _from) external view returns (uint256 nonce) {
        return _nonces[_from];
    }

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
