// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./WrappedERC20Permit.sol";

abstract contract ERC20Safe {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    function _lock(
        address _owner,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        // Transfer from the owner address to this contract
        IERC20 erc20 = IERC20(_tokenAddress);
        erc20.safeTransferFrom(_owner, address(this), _amount);
    }

    function _release(
        address _to,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        // Transfer from this contract to the owner address
        IERC20 erc20 = IERC20(_tokenAddress);
        erc20.safeTransfer(_to, _amount);
    }

    function _mint(
        address _to,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        // Create new wrapped tokens
        WrappedERC20 wrappedERC20 = WrappedERC20(_tokenAddress);
        wrappedERC20.mint(_to, _amount);
    }

    function _burn(
        address _owner,
        address _tokenAddress,
        uint256 _amount
    ) internal {
        // Burn wrapped tokens
        WrappedERC20 wrappedERC20 = WrappedERC20(_tokenAddress);
        wrappedERC20.burnFrom(_owner, _amount);
    }

    function _permit(
        address _tokenAddress,
        address _owner,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        IERC20Permit erc20 = IERC20Permit(_tokenAddress);
        erc20.safePermit(_owner, address(this), _amount, _deadline, _v, _r, _s);
    }
}
