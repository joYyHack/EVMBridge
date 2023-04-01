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

    function depositPermit(
        address _token,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function burn(address _token, uint256 _amount) external;

    function burnPermit(
        address _token,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function release(
        address _sourceToken,
        uint256 _amount,
        bytes memory _signature
    ) external;

    function withdraw(
        address _sourceToken,
        string memory _sourceTokenSymbol,
        string memory _sourceTokenName,
        bool _isSourceTokenPermit,
        uint256 _amount,
        bytes memory _signature
    ) external;
}
