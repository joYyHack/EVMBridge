// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./WrappedERC20.sol";

contract WrappedERC20Permit is WrappedERC20, ERC20Permit, ERC165Storage {
    constructor(
        string memory name,
        string memory symbol
    ) WrappedERC20(name, symbol) ERC20Permit(string.concat("Wrapped_", name)) {
        _registerInterface(type(IERC20Permit).interfaceId);
    }
}
