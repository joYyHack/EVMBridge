// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenType} from "../utils/enums.sol";

interface IValidator {
    event Verified(
        address indexed owner,
        address indexed withdrawalToken,
        uint256 amount
    );
    struct WithdrawalRequest {
        address validator;
        address bridge;
        address from;
        uint256 amount;
        address sourceToken;
        string sourceTokenSymbol;
        string sourceTokenName;
        address wrappedToken;
        TokenType withdrawalTokenType;
        uint256 nonce;
    }

    function createRequest(
        address _bridge,
        address _from,
        uint256 _amount,
        address _sourceToken,
        string memory _sourceTokenSymbol,
        string memory _sourceTokenName,
        address _wrappedToken,
        TokenType _withdrawalTokenType
    ) external view returns (WithdrawalRequest memory);

    function getNonce(address _from) external view returns (uint256 nonce);

    function verify(WithdrawalRequest memory _req, bytes memory _sig) external;
}
