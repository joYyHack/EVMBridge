// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {TokenType} from "../utils/enums.sol";

interface IERC20SafeHandler {
    // source token for token type - native is address(0)
    struct TokenInfo {
        address sourceToken;
        TokenType tokenType;
    }

    function getBridgeAddress() external view returns (address _bridge);

    function getWrappedToken(
        address _sourceToken
    ) external view returns (address _wrappedToken);

    function getTokenInfo(
        address _token
    ) external view returns (TokenInfo memory _tokenInfo);

    function getDepositedAmount(
        address _owner,
        address token
    ) external view returns (uint256 _amount);

    function deposit(address _owner, address _token, uint256 _amount) external;

    function burn(address _owner, address _token, uint256 _amount) external;

    function release(
        address _to,
        address _sourceToken,
        uint256 _amount
    ) external;

    function withdraw(
        address _to,
        address _sourceToken,
        uint256 _amount
    ) external;
}
