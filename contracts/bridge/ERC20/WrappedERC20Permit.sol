// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./WrappedERC20.sol";

/**
 * @title WrappedERC20Permit
 * @author joYyHack
 * @dev A wrapper contract that extends the functionality of the WrappedERC20 contract and adds the permit method for permitting token transfers.
 * It also registers the IERC20Permit interface for ERC20Permit to work with other contracts.
 */
contract WrappedERC20Permit is WrappedERC20, ERC20Permit, ERC165Storage {
    /**
     * @dev Creates an instance of the WrappedERC20Permit contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    constructor(
        string memory _name,
        string memory _symbol
    )
        WrappedERC20(_name, _symbol)
        ERC20Permit(string.concat("Wrapped_", _name))
    {
        _registerInterface(type(IERC20Permit).interfaceId);
    }
}
