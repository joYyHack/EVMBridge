// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title WrappedERC20
 * @author joYyHack
 * @dev This contract represents a wrapped ERC20 token that can be used to wrap a native token from another blockchain.
 * It inherits from OpenZeppelin's ERC20Burnable, Pausable and Ownable contracts.
 */
contract WrappedERC20 is ERC20Burnable, Pausable, Ownable {
    /**
     * @notice Creates a new instance of the WrappedERC20 contract.
     * @dev Calls the constructor of the parent ERC20 contract, passing a concatenation of the provided name parameter
     * with the string "Wrapped_" as the name of the token, and a concatenation of the provided symbol parameter with the string "WRP_"
     * as the symbol of the token.
     * @param _name The name of the wrapped token.
     * @param _symbol The symbol of the wrapped token.
     */
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(string.concat("Wrapped_", _name), string.concat("WRP_", _symbol)) {}

    /**
     * @notice Mints the specified amount of tokens to the specified account.
     * @dev This function can only be called by the owner of the contract.
     * @param _account The account that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _account, uint256 _amount) public virtual onlyOwner {
        _mint(_account, _amount);
    }
}
