// SPDX-License-Identifier:MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "../Bridge.sol";
import "../bridge/ERC20/WrappedERC20.sol";
import "../bridge/ERC20/WrappedERC20Permit.sol";

contract SourceERC20 is ERC20("Source", "SRC") {
    function mint(uint256 _amount) public {
        _mint(_msgSender(), _amount);
    }
}

contract RandomERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    function mint(uint256 _amount) public {
        _mint(_msgSender(), _amount);
    }
}

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

contract SourceERC20Permit is ERC20Permit, ERC165Storage {
    constructor() ERC20("Permit", "PRM") ERC20Permit("Permit") {
        _registerInterface(type(IERC20Permit).interfaceId);
    }

    function mint(uint256 _amount) public {
        _mint(_msgSender(), _amount);
    }
}

contract RandomERC20Permit is ERC20Permit, ERC165Storage {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC20Permit(_name) {
        _registerInterface(type(IERC20Permit).interfaceId);
    }

    function mint(uint256 _amount) public {
        _mint(_msgSender(), _amount);
    }
}

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
