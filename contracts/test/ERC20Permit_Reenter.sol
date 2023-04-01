// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "../Bridge.sol";

contract ReenterERC20Permit is ERC20Permit, ERC165Storage {
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

    constructor()
        ERC20("Reenter_Permit", "RNTR_PRM")
        ERC20Permit("Reenter_Permit")
    {
        _registerInterface(type(IERC20Permit).interfaceId);
    }

    function mint(uint256 _amount) public {
        _mint(_msgSender(), _amount);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        super.transferFrom(_from, _to, _amount);

        if (reenterPrepared) {
            attackDepositPermit();
            reenterPrepared = false;
        }

        return true;
    }

    function attackDepositPermit() public {
        Bridge(reenter.bridge).depositPermit(
            reenter.token,
            reenter.amount,
            reenter.deadline,
            reenter.v,
            reenter.r,
            reenter.s
        );
    }
}
