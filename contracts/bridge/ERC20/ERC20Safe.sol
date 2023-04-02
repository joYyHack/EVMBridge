// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./WrappedERC20Permit.sol";

/**
 * @title ERC20Safe
 * @author joYyHack
 * @notice This abstract contract provides utility functions for safe interactions
 * with ERC20 tokens, including locking, releasing, minting, and burning of tokens.
 * It also handles permit calls for ERC20Permit tokens.
 * The contract uses OpenZeppelin's SafeERC20 library for added safety when interacting
 * with ERC20 tokens.
 */
abstract contract ERC20Safe {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    /**
     * @dev Internal function that locks the specified amount of tokens from the owner's address.
     * @param _owner The address of the token owner.
     * @param _tokenAddress The address of the token contract.
     * @param _amount The amount of tokens to be locked.
     */
    function _lock(
        address _owner,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        // Transfer from the owner address to this contract
        IERC20 erc20 = IERC20(_tokenAddress);
        erc20.safeTransferFrom(_owner, address(this), _amount);
    }

    /**
     * @dev Internal function that releases the specified amount of tokens to the specified address.
     * @param _to The address to release the tokens to.
     * @param _tokenAddress The address of the token contract.
     * @param _amount The amount of tokens to be released.
     */
    function _release(
        address _to,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        // Transfer from this contract to the owner address
        IERC20 erc20 = IERC20(_tokenAddress);
        erc20.safeTransfer(_to, _amount);
    }

    /**
     * @dev Internal function that mints the specified amount of wrapped tokens to the specified address.
     * @param _to The address to mint the tokens to.
     * @param _tokenAddress The address of the wrapped token contract.
     * @param _amount The amount of tokens to be minted.
     */
    function _mint(
        address _to,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        // Create new wrapped tokens
        WrappedERC20 wrappedERC20 = WrappedERC20(_tokenAddress);
        wrappedERC20.mint(_to, _amount);
    }

    /**
     * @dev Internal function that burns the specified amount of wrapped tokens from the owner's address.
     * @param _owner The address of the token owner.
     * @param _tokenAddress The address of the token contract.
     * @param _amount The amount of tokens to be burned.
     */
    function _burn(
        address _owner,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        // Burn wrapped tokens
        WrappedERC20 wrappedERC20 = WrappedERC20(_tokenAddress);
        wrappedERC20.burnFrom(_owner, _amount);
    }

    /**
     * @dev Internal function that permits the specified amount of tokens from the owner's address.
     * @param _tokenAddress The address of the token contract.
     * @param _owner The address of the token owner.
     * @param _amount The amount of tokens to be permitted.
     * @param _deadline The deadline for the permit.
     * @param _v The recovery byte of the signature.
     * @param _r The first 32 bytes of the signature.
     * @param _s The second 32 bytes of the signature.
     */
    function _permit(
        address _tokenAddress,
        address _owner,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        IERC20Permit erc20 = IERC20Permit(_tokenAddress);
        erc20.safePermit(_owner, address(this), _amount, _deadline, _v, _r, _s);
    }
}
