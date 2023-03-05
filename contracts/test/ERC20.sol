// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SourceERC20 is ERC20("Source", "SRC") {
    function mint(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }
}
