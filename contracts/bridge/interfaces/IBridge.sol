// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenType} from "../utils/enums.sol";

/**
 * @title IBridge
 * @author joYyHack
 * @dev The interface contains external functions for the Bridge smart contract
 * and main events that must be emitted on each function call.
 */
interface IBridge {
    /**
     * @notice Emitted when a user deposited tokens to the bridge.
     * @param owner Owner of the tokens.
     * @param token Token contract address.
     * @param amount Amount of the deposited tokens.
     */
    event Deposit(address indexed owner, address indexed token, uint256 amount);

    /**
     * @notice Emitted when a user burned wrapped tokens on the target chain.
     * @param owner Owner of the tokens.
     * @param wrappedToken Wrapped token contract address.
     * @param sourceToken Source token contract address.
     * @param amount Amount of the burned wrapped tokens.
     */
    event Burn(
        address indexed owner,
        address indexed wrappedToken,
        address indexed sourceToken,
        uint256 amount
    );

    /**
     * @notice Emitted when a user released tokens on the source chain.
     * @param to Reciever address.
     * @param token Token contract address.
     * @param amount Amount of the released tokens.
     */
    event Release(address indexed to, address indexed token, uint256 amount);

    /**
     * @notice Emitted when a user withdrew wrapped tokens on the target chain.
     * @param to Reciever address.
     * @param wrappedToken Wrapped token contract address.
     * @param sourceToken Source token contract address.
     * @param amount Amount of the burned wrapped tokens.
     */
    event Withdraw(
        address indexed to,
        address indexed wrappedToken,
        address indexed sourceToken,
        uint256 amount
    );

    /**
     * @notice Deposit ERC20 tokens to the Bridge.
     * @dev This function transfers tokens from the sender's account to the Bridge, but
     * tokens will be locked in an ERC20 Safe contract that manages the ERC20 tokens.
     * Before calling this function, the user must approve the transfer of tokens by setting
     * sufficient approvals on the ERC20 safe contract.
     * @param _token The ERC20 token contract address.
     * @param _amount The amount of tokens to be deposited.
     */
    function deposit(address _token, uint256 _amount) external;

    /**
     * @notice Deposit ERC20 tokens to the bridge with a permit.
     * @dev Transfers tokens from the sender's account to the Bridge, using the ERC20 Permit
     * standard (ERC2612) to pre-approve the token transfer. If the token does not support permit,
     * an error is thrown. Otherwise, the permit function is called and then the deposit process
     * happens in the same way as in the deposit function above.
     * @param _token The ERC20 token contract address.
     * @param _amount The amount of tokens to be deposited.
     * @param _deadline The deadline timestamp after which the permit is no longer valid.
     * @param _v The recovery identifier for the permit signature.
     * @param _r The first 32 bytes of the permit signature.
     * @param _s The second 32 bytes of the permit signature.
     */
    function depositPermit(
        address _token,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Burn ERC20 tokens from the bridge.
     * @dev Burn tokens on behalf of the user, so the sufficent approval must be set.
     * The function can burn only wrapped tokens.
     * @param _token The ERC20 token contract address.
     * @param _amount The amount of tokens to be burned.
     */
    function burn(address _token, uint256 _amount) external;

    /**
     * @notice Burn ERC20 tokens from the bridge using a permit.
     * @dev Burn tokens on behalf of the user, using the ERC20 Permit standard (ERC2612) to pre-approve
     * the token burn. If the tokens don't support permit, the function throws an error. Otherwise, the
     * permit function is called and then the burn process happens in the same way as in the burn function.
     * @param _token The ERC20 token contract address.
     * @param _amount The amount of tokens to be burned.
     * @param _deadline The deadline timestamp after which the permit is no longer valid.
     * @param _v The recovery identifier for the permit signature.
     * @param _r The first 32 bytes of the permit signature.
     * @param _s The second 32 bytes of the permit signature.
     */
    function burnPermit(
        address _token,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Release tokens from the bridge.
     * @dev This function sends locked tokens from the Bridge to the intended user.
     * The function can release only native tokens, so if the user tries to release
     * wrapped tokens, an error will be thrown. Moreover, the user will be able to release
     * their tokens only if wrapped tokens are burned on the target chain.
     * To ensure that the user acts fairly, the signature from the trusted validator is required.
     * If the signature is not signed by the defined validator, an error will be thrown.
     * @param _sourceToken The address of the ERC20 token contract from which tokens are being released.
     * @param _amount The amount of tokens to be released.
     * @param _signature The signature of the release parameters signed by the trusted validator.
     */
    function release(
        address _sourceToken,
        uint256 _amount,
        bytes memory _signature
    ) external;

    /**
     * @notice Withdraw wrapped tokens from the bridge.
     * @dev This function withdraws wrapped versions of tokens from the Bridge and transfers them to the intended user on the target chain.
     * It checks if the wrapped tokens exist for the specified source token.
     * If they do, the function mints tokens to the user's address.
     * If they do not, the wrapped version of the source tokens is deployed.
     * Based on the `_isSourceTokenPermit` flag, the bridge will deploy the respective version.
     * The Wrapped ERC20 contract is deployed using the symbol and the name provided in the `_sourceTokenSymbol` and `_sourceTokenName` parameters, respectively.
     * The deployed contract has the prefix `WRP` and `Wrapped` added to its symbol and name.
     * This function can withdraw only wrapped tokens, so if the user tries to withdraw native tokens, an error will be thrown.
     * To ensure that the user acts fairly, a signature from the trusted validator is required.
     * If the signature is not signed by the defined validator, an error will be thrown.
     * The signature here is necessary because the contract on the target chain cannot check the validity of the token on the source chain
     * and how many tokens are locked there.
     * Users can withdraw only the amount that is equal to or less than the locked tokens on the source chain.
     * @param _sourceToken The address of the ERC20 token on the source chain.
     * @param _sourceTokenSymbol The symbol of the token on the source chain.
     * @param _sourceTokenName The name of the token on the source chain.
     * @param _isSourceTokenPermit True if the token on the source chain is an ERC2612 permit token, false otherwise.
     * @param _amount The amount of tokens to be withdrawn.
     * @param _signature The signature of the withdraw parameters signed by the trusted validator.
     */
    function withdraw(
        address _sourceToken,
        string memory _sourceTokenSymbol,
        string memory _sourceTokenName,
        bool _isSourceTokenPermit,
        uint256 _amount,
        bytes memory _signature
    ) external;
}
