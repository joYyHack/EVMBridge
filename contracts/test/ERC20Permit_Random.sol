// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract RandomERC20Permit is ERC20Permit, ERC165Storage {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _registerInterface(type(IERC20Permit).interfaceId);
    }

    function mint(uint256 _amount) public {
        _mint(_msgSender(), _amount);
    }
}
