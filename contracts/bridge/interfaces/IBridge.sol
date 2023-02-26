// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenType} from "../utils/enums.sol";

interface IBridge {
    event Deposit(
        address indexed owner,
        address indexed tokenAddress,
        uint256 amount
    );

    event Withdraw(
        address indexed to,
        address indexed token,
        address indexed sourceToken,
        uint256 amount
    );

    function deposit(
        address _tokenAddress,
        uint256 _amount,
        TokenType _tokenType
    ) external;

    function withdraw(
        address _token,
        address _sourceToken,
        uint256 _amount,
        TokenType _tokenType,
        string memory _name,
        string memory _symbol
    ) external;
}
