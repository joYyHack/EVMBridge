// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenType} from "../utils/enums.sol";

interface IBridge {
    event Deposit(address indexed owner, address indexed token, uint256 amount);

    event Burn(
        address indexed owner,
        address indexed wrappedToken,
        address indexed sourceToken,
        uint256 amount
    );

    event Release(address indexed to, address indexed token, uint256 amount);

    event Withdraw(
        address indexed to,
        address indexed wrappedToken,
        address indexed sourceToken,
        uint256 amount
    );

    function deposit(address _token, uint256 _amount) external;

    function burn(address _token, uint256 _amount) external;

    function release(
        address _sourceToken,
        uint256 _amount,
        bytes memory _signature
    ) external;

    function withdraw(
        address _sourceToken,
        uint256 _amount,
        bytes memory _signature
    ) external;
}
