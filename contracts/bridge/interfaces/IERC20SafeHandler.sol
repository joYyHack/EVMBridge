// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenType} from "../utils/enums.sol";

/**
 * @title IERC20SafeHandler
 * @author joYyHack
 * @dev The interface contains external functions for the ERC20SafeHandler smart contract
 * that manages actions of the ERC20 tokens.
 */
interface IERC20SafeHandler {
    /**
     * @dev Struct representing information about a token, including the source token address and token type.
     * By default source token address is equal to address(0) and token type is NATIVE
     */
    struct TokenInfo {
        address sourceToken;
        TokenType tokenType;
    }

    /**
     * @notice Gets the bridge address for the ERC20SafeHandler contract.
     * @return _bridge The address of the bridge contract.
     */
    function getBridgeAddress() external view returns (address _bridge);

    /**
     * @notice Gets the address of the wrapped token for the specified source token.
     * @param _sourceToken The address of the source token.
     * @return _wrappedToken The address of the wrapped token.
     */
    function getWrappedToken(
        address _sourceToken
    ) external view returns (address _wrappedToken);

    /**
     * @notice Gets information about a token.
     * @param _token The address of the token.
     * @return _tokenInfo A TokenInfo struct containing information about the token.
     */
    function getTokenInfo(
        address _token
    ) external view returns (TokenInfo memory _tokenInfo);

    /**
     * @notice Gets the amount of tokens deposited by the specified owner for the specified token.
     * @param _owner The address of the token owner.
     * @param _token The address of the token.
     * @return _amount The amount of tokens deposited by the owner.
     */
    function getDepositedAmount(
        address _owner,
        address _token
    ) external view returns (uint256 _amount);

    /**
     * @notice Deposits tokens into the contract.
     * @dev This function should ensure that tokens are deposited correctly.
     * Firstly, it sets or modifies the `_depositedAmount` and `_tokenInfos` mappings,
     * and then, using the ERC20Safe contract, locks tokens.
     * The tokenType of the deposit function is set to NATIVE, if wrapped token is presented, the error will be thrown.
     * The deposit function must be called only by the predefined bridge contract to avoid hacks.
     * @param _owner The address of the token owner.
     * @param _token The address of the token contract.
     * @param _amount The amount of tokens to be deposited.
     */
    function deposit(address _owner, address _token, uint256 _amount) external;

    /**
     * @notice Burns the specified amount of wrapped tokens for the specified owner on the target chain.
     * @dev This function should ensure that tokens are burned correctly. Burning is performed by the ERC20 Safe contract.
     * The tokenType of the burn function is set to WRAPPED, if native token is presented, the error will be thrown.
     * The burn function must be called only by the predefined bridge contract to avoid hacks.
     * @param _owner The address of the token owner.
     * @param _token The address of the token.
     * @param _amount The amount of tokens to be burned.
     */
    function burn(address _owner, address _token, uint256 _amount) external;

    /**
     * @notice Releases the specified amount of the source tokens to the specified address.
     * @dev This function should ensure that tokens are released correctly.
     * To release source tokens, the deposited amount must be greater than or equal to the given amount.
     * The `_depositedAmount` mapping is updated before the transfer.
     * The tokenType of the release function is set to NATIVE, if wrapped token is presented, the error will be thrown.
     * The release function must be called only by the predefined bridge contract to avoid hacks.
     * The bridge performs additional validation before calling the release function.
     * @param _to The address to release the tokens to.
     * @param _sourceToken The address of the source token.
     * @param _amount The amount of tokens to be released.
     */
    function release(
        address _to,
        address _sourceToken,
        uint256 _amount
    ) external;

    /**
     * @notice Withdraws the specified amount of wrapped tokens to the specified address.
     * @dev This function should ensure that tokens are withdrawn correctly. It detects whether the wrapped token exists
     * on the target chain or not. If it exists, the token is minted to the intended address,
     * if not, the wrapped version of the source token is deployed.
     * Depending on the `_isSourceTokenPermit` flag, the respective version is deployed.
     * The name and symbol of the wrapped token are the same as the source token's, but with the prefixes `Wrapped` and `WRP`, respectively.
     * The tokenType of the withdraw function is set to WRAPPED, if native token is presented, the error will be thrown.
     * The withdraw function should only be called by the predefined bridge contract.
     * The bridge performs additional validation before calling the withdraw function.
     * @param _to The address to withdraw the tokens to.
     * @param _sourceToken The address of the source token.
     * @param _sourceTokenSymbol The symbol of the source token.
     * @param _sourceTokenName The name of the source token.
     * @param _isSourceTokenPermit Whether the source token is permitted.
     * @param _amount The amount of tokens to be withdrawn.
     */
    function withdraw(
        address _to,
        address _sourceToken,
        string memory _sourceTokenSymbol,
        string memory _sourceTokenName,
        bool _isSourceTokenPermit,
        uint256 _amount
    ) external;

    /**
     * @notice Grants a permit for the specified token.
     * @dev This function should ensure that permits are granted correctly..
     * @param _tokenAddress The address of the token to grant the permit for.
     * @param _owner The address of the token owner.
     * @param _amount The amount of tokens to be permitted.
     * @param _deadline The deadline for the permit.
     * @param _v The v parameter of the signature.
     * @param _r The r parameter of the signature.
     * @param _s The s parameter of the signature.
     */
    function permit(
        address _tokenAddress,
        address _owner,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}
