// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "../bridge/ERC20/WrappedERC20.sol";
import "../Bridge.sol";

contract ReenterWrappedERC20 is WrappedERC20("Reenter", "RNTR") {
    struct ReenterWithdrawData {
        address bridge;
        address sourceToken;
        string sourceTokenSymbol;
        string sourceTokenName;
        bool isSourceTokenPermit;
        uint256 amount;
        bytes signature;
    }
    struct ReenterBurnData {
        address bridge;
        address token;
        uint256 amount;
    }

    ReenterWithdrawData public reenterWithdraw;
    ReenterBurnData public reenterBurn;
    bool public reenterPrepared;

    function prepareReenterWithdraw(
        address _bridge,
        address _sourceToken,
        string memory _sourceTokenSymbol,
        string memory _sourceTokenName,
        bool _isSourceTokenPermit,
        uint256 _amount,
        bytes memory _signature
    ) public {
        reenterWithdraw = ReenterWithdrawData(
            _bridge,
            _sourceToken,
            _sourceTokenSymbol,
            _sourceTokenName,
            _isSourceTokenPermit,
            _amount,
            _signature
        );

        reenterPrepared = true;
    }

    function prepareReenterBurn(address _bridge, uint256 _amount) public {
        reenterBurn = ReenterBurnData(_bridge, address(this), _amount);
        reenterPrepared = true;
    }

    function mint(address _account, uint256 _amount) public override {
        super.mint(_account, _amount);

        if (reenterPrepared) {
            attackWithdraw();
            reenterPrepared = false;
        }
    }

    function burnFrom(address _owner, uint256 _amount) public override {
        super.burnFrom(_owner, _amount);
        if (reenterPrepared) {
            attackBurn();
            reenterPrepared = false;
        }
    }

    function attackWithdraw() internal {
        Bridge(reenterWithdraw.bridge).withdraw(
            reenterWithdraw.sourceToken,
            reenterWithdraw.sourceTokenSymbol,
            reenterWithdraw.sourceTokenName,
            reenterWithdraw.isSourceTokenPermit,
            reenterWithdraw.amount,
            reenterWithdraw.signature
        );
    }

    function attackBurn() internal {
        Bridge(reenterBurn.bridge).burn(reenterBurn.token, reenterBurn.amount);
    }
}
