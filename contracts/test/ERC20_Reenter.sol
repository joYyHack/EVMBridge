// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../Bridge.sol";

contract ReenterERC20 is ERC20("Reenter", "RNTR") {
    struct ReenterDepositData {
        address bridge;
        address token;
        uint256 amount;
    }

    struct ReenterReleaseData {
        address bridge;
        address token;
        uint256 amount;
        bytes signature;
    }

    ReenterDepositData public reenterDeposit;
    ReenterReleaseData public reenterRelease;
    bool public reenterPrepared;

    function prepareReenterDeposit(address _bridge, uint256 _amount) public {
        reenterDeposit = ReenterDepositData(_bridge, address(this), _amount);

        reenterPrepared = true;
    }

    function prepareReenterRelease(
        address _bridge,
        uint256 _amount,
        bytes memory _signature
    ) public {
        reenterRelease = ReenterReleaseData(
            _bridge,
            address(this),
            _amount,
            _signature
        );

        reenterPrepared = true;
    }

    function mint(uint256 _amount) public {
        _mint(_msgSender(), _amount);
    }

    function transfer(
        address _to,
        uint256 _amount
    ) public virtual override returns (bool) {
        super.transfer(_to, _amount);

        if (reenterPrepared) {
            attackRelease();
            reenterPrepared = false;
        }

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        super.transferFrom(_from, _to, _amount);

        if (reenterPrepared) {
            attackDeposit();
            reenterPrepared = false;
        }

        return true;
    }

    function attackDeposit() public {
        Bridge(reenterDeposit.bridge).deposit(
            address(this),
            100 * 10 ** decimals()
        );
    }

    function attackRelease() public {
        Bridge(reenterRelease.bridge).release(
            reenterRelease.token,
            reenterRelease.amount,
            reenterRelease.signature
        );
    }
}
