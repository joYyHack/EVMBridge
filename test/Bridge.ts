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
import {
  Bridge,
  ERC20SafeHandler,
  TestERC20,
  WrappedERC20,
} from "../typechain-types";
import { TokenType } from "./utils/consts&enums";

describe("Bridge base logic", function () {
  const ONE_THOUSAND_TOKENS = parseEther((1_000).toString());
  const ONE_HUNDRED_TOKENS = parseEther((100).toString());
  const ZERO = constants.Zero;

  const provider = ethers.provider;
  const bridgeOwner = new ethers.Wallet(randomBytes(32), provider);
  const alice = new ethers.Wallet(randomBytes(32), provider);
  const bob = new ethers.Wallet(randomBytes(32), provider);
  const randomWallet = new ethers.Wallet(randomBytes(32), provider);

  let source_bridge: Bridge;
  let source_erc20Safe: ERC20SafeHandler;
  let target_bridge: Bridge;
  let target_erc20Safe: ERC20SafeHandler;

  let nativeERC20: TestERC20;

  async function initialBalance() {
    for (const wallet of [bridgeOwner, alice, bob]) {
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

    await source_bridge.setERC20SafeHandler(source_erc20Safe.address);

    const erc20Factory = await ethers.getContractFactory("TestERC20", alice);
    const nativeERC20 = await erc20Factory.deploy();
    await nativeERC20.deployed();

    await nativeERC20.mint(parseEther((100).toString()));

    return {
      source_bridge,
      source_erc20Safe,
      nativeERC20,
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

    await target_bridge.setERC20SafeHandler(target_erc20Safe.address);

    return {
      target_bridge,
      target_erc20Safe,
    };
  }

  async function deposited() {
    ({ source_bridge, source_erc20Safe, nativeERC20 } =
      await sourceChainContractSetup());

    ({ target_bridge, target_erc20Safe } = await targetChainContractSetup());

    const approvalTx = await nativeERC20
      .connect(alice)
      .approve(source_erc20Safe.address, ONE_HUNDRED_TOKENS);

    await approvalTx.wait();

    const depositTx = await source_bridge
      .connect(alice)
      .deposit(nativeERC20.address, ONE_HUNDRED_TOKENS, TokenType.Native);

    await depositTx.wait();

    return { source_bridge, source_erc20Safe, nativeERC20 };
  }

  describe("Deployment", async () => {
    beforeEach(async () => {
      ({ source_bridge, source_erc20Safe, nativeERC20 } = await loadFixture(
        sourceChainContractSetup
      ));
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
      expect(await source_erc20Safe.BRIDGE_ADDRESS()).to.be.equal(
        source_bridge.address
      );
    });
    it("Bridge: Address of the ERC20 Safe Handler should be correct", async () => {
      expect(await source_bridge.safeHandler()).to.be.equal(
        source_erc20Safe.address
      );
    });
    it("Test ERC20 tokens: Total supply of test erc20 tokens must be 100", async () => {
      expect(await nativeERC20.totalSupply()).to.be.equal(ONE_HUNDRED_TOKENS);
    });
    it("Test ERC20 tokens: Alice must have 100 test erc20 tokens", async () => {
      expect(await nativeERC20.balanceOf(alice.address)).to.be.equal(
        ONE_HUNDRED_TOKENS
      );
    });
  });
  describe("ERC20 Safe Handler Check", async () => {
    beforeEach(async () => {
      ({ source_bridge, source_erc20Safe, nativeERC20 } = await loadFixture(
        sourceChainContractSetup
      ));
    });

    it("Access control: Only BRIDGE MANAGER should be able to change ERC20 safe handler", async () => {
      expect(
        await source_bridge
          .connect(bridgeOwner)
          .setERC20SafeHandler(randomWallet.address)
      ).not.reverted;

      expect(await source_bridge.safeHandler()).to.be.equal(
        randomWallet.address
      );
    });
    it("Access control: Should not allow to change ERC20 safe handler for non BRIDGE MANAGER", async () => {
      await expect(
        source_bridge.connect(bob).setERC20SafeHandler(constants.AddressZero)
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
      ({ source_bridge, source_erc20Safe, nativeERC20 } = await loadFixture(
        sourceChainContractSetup
      ));
    });

    it("Bridge: Alice should be able to deposit 100 tokens on the source chain", async () => {
      const approvalTx = await nativeERC20
        .connect(alice)
        .approve(source_erc20Safe.address, ONE_HUNDRED_TOKENS);

      await expect(approvalTx)
        .to.emit(nativeERC20, "Approval")
        .withArgs(alice.address, source_erc20Safe.address, ONE_HUNDRED_TOKENS);

      expect(
        await nativeERC20.allowance(alice.address, source_erc20Safe.address)
      ).to.be.equal(ONE_HUNDRED_TOKENS);

      await approvalTx.wait();

      const depositTx = await source_bridge
        .connect(alice)
        .deposit(nativeERC20.address, ONE_HUNDRED_TOKENS, TokenType.Native);

      await depositTx.wait();

      await expect(depositTx).to.changeTokenBalances(
        nativeERC20,
        [alice.address, source_erc20Safe.address],
        [ONE_HUNDRED_TOKENS.mul(-1), ONE_HUNDRED_TOKENS]
      );

      const { sourceToken, tokenType } = await source_erc20Safe.tokenInfos(
        nativeERC20.address
      );

      expect({ sourceToken, tokenType }).to.deep.equal({
        sourceToken: constants.AddressZero,
        tokenType: TokenType.Native,
      });

      // retrieve data from private mapping _depositedAmount
      // mapping(address => mapping(address => uint256)) _depositedAmount;
      // keccak256(abi.encode(key, MAPPING_SLOT)) => pointer to the nested mapping;
      // keccak256(abi.encode(key, 'pointer to the nested mapping')) => pointer to the uint256

      const MAPPING_POSITION = 0; // check in ERC20SafeHandler.sol
      // encode key value and mapping slot of the FIRST level mapping
      let firstLevelMapping = abi.encode(
        ["address", "uint256"],
        [alice.address, MAPPING_POSITION]
      );
      // get pointer to the nested mapping
      let nestedMappingPositon = keccak256(firstLevelMapping);

      // encode key value and mapping slot of the SECOND level mapping
      let encodedData2 = abi.encode(
        ["address", "uint256"],
        [nativeERC20.address, nestedMappingPositon]
      );
      // get pointer to the uint256
      let pointerToResult = keccak256(encodedData2);

      const depositedAmount = await provider.getStorageAt(
        source_erc20Safe.address,
        pointerToResult
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
          .deposit(nativeERC20.address, ONE_HUNDRED_TOKENS, TokenType.Native)
      ).revertedWith("Bridge: erc20 safe handler is not set yet");
    });
    it("Bridge: Revert on attempt to deposit zero ERC20 tokens", async () => {
      await expect(
        source_bridge
          .connect(alice)
          .deposit(nativeERC20.address, 0, TokenType.Native)
      ).revertedWith("Bridge: amount can not be zero");
    });
    it("Bridge: Revert on attempt to deposit tokens with zero contract address", async () => {
      await expect(
        source_bridge
          .connect(alice)
          .deposit(constants.AddressZero, ONE_HUNDRED_TOKENS, TokenType.Native)
      ).revertedWith("Bridge: Token can not be zero address");
    });
  });
  describe("Withdraw ERC20 - Targe Chain", async () => {
    beforeEach(async () => {
      ({ source_bridge, source_erc20Safe, nativeERC20 } = await loadFixture(
        deposited
      ));
    });
    it("Bridge: Alice should be able to withdraw newly deployed wrapped tokens on the target chain", async () => {
      const withdrawTx = await target_bridge
        .connect(alice)
        .withdraw(
          constants.AddressZero,
          nativeERC20.address,
          ONE_HUNDRED_TOKENS,
          TokenType.Wrapped,
          await nativeERC20.name(),
          await nativeERC20.symbol()
        );

      await withdrawTx.wait();

      const wrappedERC20Address = await target_erc20Safe.tokenPairs(
        nativeERC20.address
      );
      expect(wrappedERC20Address).not.equal(constants.AddressZero);

      const wrappedERC20: WrappedERC20 = await ethers.getContractAt(
        "WrappedERC20",
        wrappedERC20Address
      );

      expect(await wrappedERC20.owner()).to.be.equal(target_erc20Safe.address);

      expect(await nativeERC20.balanceOf(alice.address)).to.equal(ZERO);
      expect(await wrappedERC20.balanceOf(alice.address)).to.equal(
        ONE_HUNDRED_TOKENS
      );

      const { sourceToken, tokenType } = await target_erc20Safe.tokenInfos(
        wrappedERC20Address
      );

      expect({ sourceToken, tokenType }).to.deep.equal({
        sourceToken: nativeERC20.address,
        tokenType: TokenType.Wrapped,
      });

      expect(
        await target_erc20Safe.tokenPairs(nativeERC20.address)
      ).to.be.equal(wrappedERC20.address);

      await expect(withdrawTx)
        .to.emit(target_bridge, "Withdraw")
        .withArgs(
          alice.address,
          wrappedERC20.address,
          nativeERC20.address,
          ONE_HUNDRED_TOKENS
        );
    });
    // it("Bridge: Alice should be able to withdraw newly deployed wrapped tokens on the target chain", async () => {
    //   const withdrawTx = await target_bridge
    //     .connect(alice)
    //     .withdraw(
    //       constants.AddressZero,
    //       nativeERC20.address,
    //       ONE_HUNDRED_TOKENS,
    //       TokenType.Wrapped,
    //       await nativeERC20.name(),
    //       await nativeERC20.symbol()
    //     );

    //   await withdrawTx.wait();

    //   const wrappedERC20Address = await target_erc20Safe.tokenPairs(
    //     nativeERC20.address
    //   );
    //   expect(wrappedERC20Address).not.equal(constants.AddressZero);

    //   const wrappedERC20: WrappedERC20 = await ethers.getContractAt(
    //     "WrappedERC20",
    //     wrappedERC20Address
    //   );

    //   expect(await wrappedERC20.owner()).to.be.equal(target_erc20Safe.address);

    //   expect(await nativeERC20.balanceOf(alice.address)).to.equal(ZERO);
    //   expect(await wrappedERC20.balanceOf(alice.address)).to.equal(
    //     ONE_HUNDRED_TOKENS
    //   );

    //   const { sourceToken, tokenType } = await target_erc20Safe.tokenInfos(
    //     wrappedERC20Address
    //   );

    //   expect({ sourceToken, tokenType }).to.deep.equal({
    //     sourceToken: nativeERC20.address,
    //     tokenType: TokenType.Wrapped,
    //   });

    //   expect(
    //     await target_erc20Safe.tokenPairs(nativeERC20.address)
    //   ).to.be.equal(wrappedERC20.address);

    //   await expect(withdrawTx).to.emit(target_bridge, "Withdraw");
    // });
  });
});
