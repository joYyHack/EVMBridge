import { constants } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { SourceERC20, SourceERC20Permit } from "../typechain-types";

async function main() {
  const network = await ethers.provider.getNetwork();
  const [bridgeOwner, validatorOwner, alice] = await ethers.getSigners();

  const bridgeFactory = await ethers.getContractFactory("Bridge", bridgeOwner);
  const bridge = await bridgeFactory.deploy();
  await bridge.deployed();

  const erc20SafeHandlerFactory = await ethers.getContractFactory(
    "ERC20SafeHandler",
    bridgeOwner
  );
  const erc20Safe = await erc20SafeHandlerFactory.deploy(bridge.address);
  await erc20Safe.deployed();

  const validatorFactory = await ethers.getContractFactory(
    "Validator",
    validatorOwner
  );
  const validator = await validatorFactory.deploy();
  await validator.deployed();

  await bridge.setERC20SafeHandler(erc20Safe.address);
  await bridge.setValidator(validator.address);

  console.log(`Bridge deployed at: ${bridge.address}`);
  console.log(`ERC20 Safe deployed at: ${erc20Safe.address}`);
  console.log(`Validator deployed at: ${validator.address}`);

  if (network.name === "sepolia" || network.name === "unknown") {
    const erc20Factory = await ethers.getContractFactory("SourceERC20", alice);
    const ERC20 = (await erc20Factory.deploy()) as SourceERC20;
    await ERC20.deployed();

    await ERC20.mint(parseEther((100).toString()));
    await ERC20.approve(erc20Safe.address, constants.MaxUint256);

    console.log(
      `ERC20 ${await ERC20.symbol()} token deployed at: ${ERC20.address}`
    );
    console.log(
      `Alice's balance: ${(
        await ERC20.balanceOf(alice.address)
      ).toString()} of ${await ERC20.symbol()} tokens`
    );

    const erc20PermitFactory = await ethers.getContractFactory(
      "SourceERC20Permit",
      alice
    );
    const ERC20Permit =
      (await erc20PermitFactory.deploy()) as SourceERC20Permit;
    await ERC20Permit.deployed();

    await ERC20Permit.mint(parseEther((100).toString()));
    await ERC20Permit.approve(erc20Safe.address, constants.MaxUint256);

    console.log(
      `ERC20Permit ${await ERC20Permit.symbol()} token deployed at: ${
        ERC20Permit.address
      }`
    );
    console.log(
      `Alice's balance: ${(
        await ERC20Permit.balanceOf(alice.address)
      ).toString()} of ${await ERC20Permit.symbol()} tokens`
    );
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
