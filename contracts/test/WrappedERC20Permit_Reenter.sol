// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "../bridge/ERC20/WrappedERC20Permit.sol";
import "../Bridge.sol";

contract ReenterWrappedERC20Permit is WrappedERC20Permit("Reenter", "RNTR") {
    struct ReenterData {
        address bridge;
        address token;
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    ReenterData public reenter;
    bool public reenterPrepared;

    function prepareReenter(
        address _bridge,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        reenter = ReenterData(
            _bridge,
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );

        reenterPrepared = true;
    }

    function burnFrom(address _owner, uint256 _amount) public override {
        super.burnFrom(_owner, _amount);
        if (reenterPrepared) {
            attackBurnPermit();
            reenterPrepared = false;
        }
    }

    function attackBurnPermit() internal {
        Bridge(reenter.bridge).burnPermit(
            reenter.token,
            reenter.amount,
            reenter.deadline,
            reenter.v,
            reenter.r,
            reenter.s
        );
    }
}
