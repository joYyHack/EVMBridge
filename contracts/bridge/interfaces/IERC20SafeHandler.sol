// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenType} from "../utils/enums.sol";

interface IERC20SafeHandler {
    function deposit(
        address _owner,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function burn(
        address _owner,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function release(address _to, address _token, uint256 _amount) external;

    function withdraw(
        address _to,
        address _sourceToken,
        uint256 _amount
    ) external;
}
