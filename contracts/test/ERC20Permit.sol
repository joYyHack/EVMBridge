// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

contract SourceERC20Permit is ERC20Permit, ERC165Storage {
    constructor() ERC20("Permit", "PRM") ERC20Permit("Permit") {
        _registerInterface(type(IERC20Permit).interfaceId);
    }

    function mint(uint256 _amount) public {
        _mint(_msgSender(), _amount);
    }
}
