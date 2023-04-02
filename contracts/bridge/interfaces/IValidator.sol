// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenType} from "../utils/enums.sol";

/**
 * @title IValidator
 * @author joYyHack
 * @notice The IValidator interface defines the functions and events
 * required for a contract to act as a validator for token withdrawals.
 */
interface IValidator {
    /**
     * @notice Emitted when a withdrawal request is successfully verified.
     * @param owner The address of the token owner.
     * @param withdrawalToken The address of the token being withdrawn.
     * @param amount The amount of tokens withdrawn.
     */
    event Verified(
        address indexed owner,
        address indexed withdrawalToken,
        uint256 amount
    );

    /**
     * @notice Struct to store withdrawal request data.
     */
    struct WithdrawalRequest {
        address validator;
        address bridge;
        address from;
        uint256 amount;
        address sourceToken;
        string sourceTokenSymbol;
        string sourceTokenName;
        bool isSourceTokenPermit;
        address wrappedToken;
        TokenType withdrawalTokenType;
        uint256 nonce;
    }

    /**
     * @notice Creates a new withdrawal request.
     * @param _bridge The address of the bridge contract.
     * @param _from The address of the token owner.
     * @param _amount The amount of tokens to withdraw.
     * @param _sourceToken The address of the source token.
     * @param _sourceTokenSymbol The symbol of the source token.
     * @param _sourceTokenName The name of the source token.
     * @param _isSourceTokenPermit Whether the source token supports permit function.
     * @param _wrappedToken The address of the wrapped token.
     * @param _withdrawalTokenType The type of token being withdrawn.
     * @return WithdrawalRequest An instance of the WithdrawalRequest struct containing the provided data.
     */
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
    ) external view returns (WithdrawalRequest memory);

    /**
     * @notice Returns the current nonce for the given address.
     * @param _from The address to retrieve the nonce for.
     * @return nonce The current nonce for the given address.
     */
    function getNonce(address _from) external view returns (uint256 nonce);

    /**
     * @notice Verifies a withdrawal request.
     * @dev The implementation should perform necessary checks to ensure the withdrawal request is valid.
     * @param _req The withdrawal request to verify.
     * @param _sig The signature to validate the withdrawal request.
     */
    function verify(WithdrawalRequest memory _req, bytes memory _sig) external;
}
