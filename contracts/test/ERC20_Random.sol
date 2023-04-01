// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RandomERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    function mint(uint256 _amount) public {
        _mint(_msgSender(), _amount);
    }
}
