// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WrappedERC20 is ERC20Burnable, Pausable, Ownable {
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(string.concat("wrapped_", name), string.concat("WRP_", symbol)) {}

    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);
    }
}
