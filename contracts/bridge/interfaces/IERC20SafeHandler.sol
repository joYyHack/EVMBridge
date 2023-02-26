// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenType} from "../utils/enums.sol";

interface IERC20SafeHandler {
    function deposit(
        address _owner,
        address _tokenAddress,
        uint256 _amount,
        TokenType _tokenType
    ) external;

    function withdraw(
        address _to,
        address _token,
        address _sourceToken,
        uint256 _amount,
        TokenType _tokenType,
        string memory _name,
        string memory _symbol
    ) external;
}
