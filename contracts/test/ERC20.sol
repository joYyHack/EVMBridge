// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20("Test", "TST") {
    function mint(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }
}
