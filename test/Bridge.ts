import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import {
  parseEther,
  randomBytes,
  keccak256,
  toUtf8Bytes,
  defaultAbiCoder as abi,
  concat,
} from "ethers/lib/utils";
import { constants, BigNumber } from "ethers";
import { faucet } from "./utils/faucet";
import { getDepositedAmountFromERC20Safe } from "./utils/storageGetter";
import {
  privKey,
  createWithdrawalRequest,
  signWithdrawalRequest,
} from "./utils/encoding";
import {
  Bridge,
  IERC20SafeHandler,
  IValidator,
  SourceERC20,
  WrappedERC20,
} from "../typechain-types";
import { TokenType } from "./utils/consts&enums";

describe("Bridge base logic", function () {
  //const ONE_THOUSAND_TOKENS = parseEther((1_000).toString());
  const ONE_HUNDRED_TOKENS = parseEther((100).toString());
  const ZERO = constants.Zero;

  const provider = ethers.provider;
  const bridgeOwner = new ethers.Wallet(privKey("666"), provider);
  const alice = new ethers.Wallet(privKey("a11ce"), provider);
  const bob = new ethers.Wallet(privKey("b0b"), provider);
  const validatorWallet = new ethers.Wallet(privKey("dead"), provider);
  const randomWallet = new ethers.Wallet(randomBytes(32), provider);

  let source_bridge: Bridge;
  let source_erc20Safe: IERC20SafeHandler;
  let source_validator: IValidator;
  let source_nonce = 0;

  let target_bridge: Bridge;
  let target_erc20Safe: IERC20SafeHandler;
  let target_validator: IValidator;
  let target_nonce = 0;

  let sourceERC20: SourceERC20;
  let wrappedERC20: WrappedERC20;

  async function initialBalance() {
    for (const wallet of [bridgeOwner, alice, bob, validatorWallet]) {
      await faucet(wallet.address, provider);
    }
  }

  async function sourceChainContractSetup() {
    await initialBalance();

    const bridgeFactory = await ethers.getContractFactory(
      "Bridge",
      bridgeOwner
    );
    const source_bridge = await bridgeFactory.deploy();
    await source_bridge.deployed();

    const erc20SafeHandlerFactory = await ethers.getContractFactory(
      "ERC20SafeHandler",
      bridgeOwner
    );
    const source_erc20Safe = await erc20SafeHandlerFactory.deploy(
      source_bridge.address
    );
    await source_erc20Safe.deployed();

    const validatorFactory = await ethers.getContractFactory(
      "Validator",
      bridgeOwner
    );
    const source_validator = await validatorFactory.deploy();
    await source_validator.deployed();

    await source_bridge.setERC20SafeHandler(source_erc20Safe.address);
    await source_bridge.setValidator(source_validator.address);

    const erc20Factory = await ethers.getContractFactory("SourceERC20", alice);
    const sourceERC20 = await erc20Factory.deploy();
    await sourceERC20.deployed();

    await sourceERC20.mint(parseEther((100).toString()));

    return {
      source_bridge,
      source_erc20Safe,
      source_validator,
      sourceERC20,
    };
  }

  async function targetChainContractSetup() {
    await initialBalance();

    const bridgeFactory = await ethers.getContractFactory(
      "Bridge",
      bridgeOwner
    );
    const target_bridge = await bridgeFactory.deploy();
    await target_bridge.deployed();

    const erc20SafeHandlerFactory = await ethers.getContractFactory(
      "ERC20SafeHandler",
      bridgeOwner
    );
    const target_erc20Safe = await erc20SafeHandlerFactory.deploy(
      target_bridge.address
    );
    await target_erc20Safe.deployed();

    const validatorFactory = await ethers.getContractFactory(
      "Validator",
      bridgeOwner
    );
    const target_validator = await validatorFactory.deploy();
    await target_validator.deployed();

    await target_bridge.setERC20SafeHandler(target_erc20Safe.address);
    await target_bridge.setValidator(target_validator.address);

    return {
      target_bridge,
      target_erc20Safe,
      target_validator,
    };
  }

  async function deposited() {
    ({ source_bridge, source_erc20Safe, source_validator, sourceERC20 } =
      await sourceChainContractSetup());

    ({ target_bridge, target_erc20Safe, target_validator } =
      await targetChainContractSetup());

    const approvalTx = await sourceERC20
      .connect(alice)
      .approve(source_erc20Safe.address, ONE_HUNDRED_TOKENS);

    await approvalTx.wait();

    const depositTx = await source_bridge
      .connect(alice)
      .deposit(sourceERC20.address, ONE_HUNDRED_TOKENS);

    await depositTx.wait();

    return {
      source_bridge,
      source_erc20Safe,
      source_validator,
      sourceERC20,
      target_bridge,
      target_erc20Safe,
      target_validator,
    };
  }

  async function withdrawn() {
    ({
      source_bridge,
      source_erc20Safe,
      source_validator,
      sourceERC20,
      target_bridge,
      target_erc20Safe,
      target_validator,
    } = await deposited());

    const request = createWithdrawalRequest(
      validatorWallet.address,
      target_bridge.address,
      alice.address,
      ONE_HUNDRED_TOKENS,
      sourceERC20.address,
      constants.AddressZero,
      TokenType.Wrapped,
      BigNumber.from(target_nonce)
    );

    const signature = await signWithdrawalRequest(
      validatorWallet,
      target_validator.address,
      request
    );

    const withdrawTx = await target_bridge
      .connect(alice)
      .withdraw(sourceERC20.address, ONE_HUNDRED_TOKENS, signature);

    await withdrawTx.wait();

    const wrappedERC20Address = await target_erc20Safe.getWrappedToken(
      sourceERC20.address
    );

    const wrappedERC20: WrappedERC20 = await ethers.getContractAt(
      "WrappedERC20",
      wrappedERC20Address
    );

    return {
      source_bridge,
      source_erc20Safe,
      source_validator,
      sourceERC20,
      target_bridge,
      target_erc20Safe,
      target_validator,
      wrappedERC20,
    };
  }

  async function burnt() {
    ({
      source_bridge,
      source_erc20Safe,
      source_validator,
      sourceERC20,
      target_bridge,
      target_erc20Safe,
      target_validator,
      wrappedERC20,
    } = await withdrawn());

    const approvalTx = await wrappedERC20
      .connect(alice)
      .approve(target_erc20Safe.address, ONE_HUNDRED_TOKENS);

    await approvalTx.wait();

    const burnTx = await target_bridge
      .connect(alice)
      .burn(wrappedERC20.address, ONE_HUNDRED_TOKENS);

    await burnTx.wait();

    return {
      source_bridge,
      source_erc20Safe,
      source_validator,
      sourceERC20,
      target_bridge,
      target_erc20Safe,
      target_validator,
      wrappedERC20,
    };
  }

  describe("Deployment", async () => {
    beforeEach(async () => {
      ({ source_bridge, source_erc20Safe, source_validator, sourceERC20 } =
        await loadFixture(sourceChainContractSetup));
    });

    it("Access control: Owner of the bridge has the 'DEFAULT_ADMIN_ROLE' role", async () => {
      const DEFAULT_ADMIN_ROLE = await source_bridge.DEFAULT_ADMIN_ROLE();
      expect(
        await source_bridge.hasRole(DEFAULT_ADMIN_ROLE, bridgeOwner.address)
      ).to.be.true;
    });
    it("Access control: Owner of the bridge has the 'BRIDGE_MANAGER' role", async () => {
      const BRIDGE_MANAGER = await source_bridge.BRIDGE_MANAGER();
      expect(await source_bridge.hasRole(BRIDGE_MANAGER, bridgeOwner.address))
        .to.be.true;
    });
    it("ERC20 Safe Handler: Address of the bridge should be correct", async () => {
      expect(await source_erc20Safe.getBridgeAddress()).to.be.equal(
        source_bridge.address
      );
    });
    it("Bridge: Address of the ERC20 Safe Handler should be correct", async () => {
      expect(await source_bridge.erc20Safe()).to.be.equal(
        source_erc20Safe.address
      );
    });
    it("Bridge: Address of the validator should be correct", async () => {
      expect(await source_bridge.validator()).to.be.equal(
        source_validator.address
      );
    });
    it("Test ERC20 tokens: Total supply of test erc20 tokens must be 100", async () => {
      expect(await sourceERC20.totalSupply()).to.be.equal(ONE_HUNDRED_TOKENS);
    });
    it("Test ERC20 tokens: Alice must have 100 test erc20 tokens", async () => {
      expect(await sourceERC20.balanceOf(alice.address)).to.be.equal(
        ONE_HUNDRED_TOKENS
      );
    });
  });
  describe("ERC20 Safe Handler and Validator Check", async () => {
    beforeEach(async () => {
      ({ source_bridge, source_erc20Safe, sourceERC20 } = await loadFixture(
        sourceChainContractSetup
      ));
    });

    it("Access control: Only BRIDGE MANAGER should be able to change ERC20 safe handler or validator", async () => {
      expect(
        await source_bridge
          .connect(bridgeOwner)
          .setERC20SafeHandler(randomWallet.address)
      ).not.reverted;

      expect(
        await source_bridge
          .connect(bridgeOwner)
          .setValidator(randomWallet.address)
      ).not.reverted;

      expect(await source_bridge.erc20Safe()).to.be.equal(randomWallet.address);
      expect(await source_bridge.validator()).to.be.equal(randomWallet.address);
    });
    it("Access control: Should not allow to change ERC20 safe handler or validator for non BRIDGE MANAGER", async () => {
      await expect(
        source_bridge.connect(bob).setERC20SafeHandler(constants.AddressZero)
      ).to.be.reverted;

      await expect(
        source_bridge.connect(bob).setValidator(constants.AddressZero)
      ).to.be.reverted;

      // Doesn't work but needs to. Need to investigate
      // .revertedWith(
      //   `AccessControl: account ${bob.address} is missing role ${keccak256(
      //     toUtf8Bytes("BRIDGE_MANAGER")
      //   )}`
      // );
    });
  });
  describe("Deposit ERC20 - Source Chain", async () => {
    beforeEach(async () => {
      ({ source_bridge, source_erc20Safe, sourceERC20 } = await loadFixture(
        sourceChainContractSetup
      ));
    });

    it("Bridge: Alice should be able to deposit 100 tokens on the source chain", async () => {
      const approvalTx = await sourceERC20
        .connect(alice)
        .approve(source_erc20Safe.address, ONE_HUNDRED_TOKENS);

      await expect(approvalTx)
        .to.emit(sourceERC20, "Approval")
        .withArgs(alice.address, source_erc20Safe.address, ONE_HUNDRED_TOKENS);

      expect(
        await sourceERC20.allowance(alice.address, source_erc20Safe.address)
      ).to.be.equal(ONE_HUNDRED_TOKENS);

      await approvalTx.wait();

      const depositTx = await source_bridge
        .connect(alice)
        .deposit(sourceERC20.address, ONE_HUNDRED_TOKENS);

      await depositTx.wait();

      await expect(depositTx).to.changeTokenBalances(
        sourceERC20,
        [alice.address, source_erc20Safe.address],
        [ONE_HUNDRED_TOKENS.mul(-1), ONE_HUNDRED_TOKENS]
      );

      const { sourceToken, tokenType } = await source_erc20Safe.getTokenInfo(
        sourceERC20.address
      );

      expect({ sourceToken, tokenType }).to.deep.equal({
        sourceToken: constants.AddressZero,
        tokenType: TokenType.Native,
      });

      const depositedAmount = await getDepositedAmountFromERC20Safe(
        provider,
        alice.address,
        sourceERC20.address,
        source_erc20Safe.address
      );

      expect(BigNumber.from(depositedAmount)).to.be.equal(ONE_HUNDRED_TOKENS);

      // doesn't work why????
      // await expect(depositTx)
      //   .emit(bridge.address, "Deposit")
      //   .withArgs(alice.address, erc20_1.address, ONE_HUNDRED_TOKENS);
    });
    it("Bridge: Revert on attempt to deposit when ERC20 safe handler is not set", async () => {
      const tx = await source_bridge
        .connect(bridgeOwner)
        .setERC20SafeHandler(constants.AddressZero);

      await tx.wait();

      await expect(
        source_bridge
          .connect(alice)
          .deposit(sourceERC20.address, ONE_HUNDRED_TOKENS)
      ).revertedWith("Bridge: erc20 safe handler is not set yet");
    });
    it("ERC20SafeHandler: Revert on attempt to deposit tokens with zero contract address or zero amount", async () => {
      await expect(
        source_bridge
          .connect(alice)
          .deposit(constants.AddressZero, ONE_HUNDRED_TOKENS)
      ).revertedWith("ERC20SafeHandler: zero address");

      await expect(
        source_bridge.connect(alice).deposit(sourceERC20.address, 0)
      ).revertedWith("ERC20SafeHandler: token amount has to be greater than 0");
    });
  });
  describe("Withdraw ERC20 - Target Chain", async () => {
    beforeEach(async () => {
      ({
        source_bridge,
        source_erc20Safe,
        source_validator,
        sourceERC20,
        target_bridge,
        target_erc20Safe,
        target_validator,
      } = await loadFixture(deposited));
    });
    it("Bridge: Alice should be able to withdraw newly deployed wrapped tokens on the target chain", async () => {
      // assume that validator checked all conditions and everything is fine
      const request = createWithdrawalRequest(
        validatorWallet.address,
        target_bridge.address,
        alice.address,
        ONE_HUNDRED_TOKENS,
        sourceERC20.address,
        constants.AddressZero,
        TokenType.Wrapped,
        BigNumber.from(target_nonce)
      );

      const signature = await signWithdrawalRequest(
        validatorWallet,
        target_validator.address,
        request
      );

      const withdrawTx = await target_bridge
        .connect(alice)
        .withdraw(sourceERC20.address, ONE_HUNDRED_TOKENS, signature);

      await withdrawTx.wait();

      const wrappedERC20Address = await target_erc20Safe.getWrappedToken(
        sourceERC20.address
      );
      expect(wrappedERC20Address).not.equal(constants.AddressZero);

      const wrappedERC20: WrappedERC20 = await ethers.getContractAt(
        "WrappedERC20",
        wrappedERC20Address
      );

      expect(await wrappedERC20.owner()).to.be.equal(target_erc20Safe.address);

      expect(await sourceERC20.balanceOf(alice.address)).to.equal(ZERO);
      expect(await wrappedERC20.balanceOf(alice.address)).to.equal(
        ONE_HUNDRED_TOKENS
      );

      const { sourceToken, tokenType } = await target_erc20Safe.getTokenInfo(
        wrappedERC20Address
      );

      expect({ sourceToken, tokenType }).to.deep.equal({
        sourceToken: sourceERC20.address,
        tokenType: TokenType.Wrapped,
      });

      expect(
        await target_erc20Safe.getWrappedToken(sourceERC20.address)
      ).to.be.equal(wrappedERC20.address);

      await expect(withdrawTx).to.emit(target_bridge, "Withdraw");
    });
  });
  describe("Burn ERC20 - Target Chain", async () => {
    beforeEach(async () => {
      ({
        source_bridge,
        source_erc20Safe,
        source_validator,
        sourceERC20,
        target_bridge,
        target_erc20Safe,
        target_validator,
        wrappedERC20,
      } = await loadFixture(withdrawn));
    });
    it("Bridge: Alice should be able to burn wrapped tokens on the target chain", async () => {
      const approvalTx = await wrappedERC20
        .connect(alice)
        .approve(target_erc20Safe.address, ONE_HUNDRED_TOKENS);

      await expect(approvalTx)
        .to.emit(wrappedERC20, "Approval")
        .withArgs(alice.address, target_erc20Safe.address, ONE_HUNDRED_TOKENS);

      expect(
        await wrappedERC20.allowance(alice.address, target_erc20Safe.address)
      ).to.be.equal(ONE_HUNDRED_TOKENS);

      await approvalTx.wait();

      const burnTx = await target_bridge
        .connect(alice)
        .burn(wrappedERC20.address, ONE_HUNDRED_TOKENS);

      await burnTx.wait();

      expect(await wrappedERC20.balanceOf(alice.address)).to.equal(ZERO);

      await expect(burnTx).to.emit(target_bridge, "Burn");
    });
  });
  describe("Release ERC20 - Source Chain", async () => {
    beforeEach(async () => {
      ({
        source_bridge,
        source_erc20Safe,
        source_validator,
        sourceERC20,
        target_bridge,
        target_erc20Safe,
        target_validator,
        wrappedERC20,
      } = await loadFixture(burnt));
    });
    it("Bridge: Alice should be able to release native tokens on the source chain", async () => {
      // assume that validator checked all conditions and everything is fine
      const request = createWithdrawalRequest(
        validatorWallet.address,
        source_bridge.address,
        alice.address,
        ONE_HUNDRED_TOKENS,
        sourceERC20.address,
        constants.AddressZero,
        TokenType.Native,
        BigNumber.from(source_nonce)
      );

      const signature = await signWithdrawalRequest(
        validatorWallet,
        source_validator.address,
        request
      );

      const releaseTx = await source_bridge
        .connect(alice)
        .release(sourceERC20.address, ONE_HUNDRED_TOKENS, signature);

      await releaseTx.wait();

      expect(await sourceERC20.balanceOf(alice.address)).to.equal(
        ONE_HUNDRED_TOKENS
      );
      expect(await sourceERC20.balanceOf(source_erc20Safe.address)).to.equal(
        ZERO
      );

      expect(await wrappedERC20.balanceOf(alice.address)).to.equal(ZERO);

      const depositedAmount = await getDepositedAmountFromERC20Safe(
        provider,
        alice.address,
        sourceERC20.address,
        source_erc20Safe.address
      );
      expect(BigNumber.from(depositedAmount)).to.be.equal(ZERO);

      await expect(releaseTx).to.emit(source_bridge, "Release");
    });
  });
});
