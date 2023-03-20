import { ethers } from "hardhat";
import { constants } from "ethers";
import { parseEther, formatEther } from "ethers/lib/utils";
import { privKey } from "./utils/encoding";
import { faucet } from "./utils/faucet";

async function main() {
  const [bridgeOwner, alice] = await ethers.getSigners();

  // const bridgeOwner = new ethers.Wallet(privKey("666"), provider);
  // const alice = new ethers.Wallet(privKey("a11ce"), provider);

  // for (const wallet of [bridgeOwner, alice]) {
  //   await faucet(wallet.address, provider);
  // }

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
    bridgeOwner
  );
  const validator = await validatorFactory.deploy();
  await validator.deployed();

  await bridge.setERC20SafeHandler(erc20Safe.address);
  await bridge.setValidator(validator.address);

  // const erc20Factory = await ethers.getContractFactory("SourceERC20", alice);
  // const ERC20 = await erc20Factory.deploy();
  // await ERC20.deployed();

  // await ERC20.mint(parseEther((100).toString()));
  // await ERC20.approve(erc20Safe.address, constants.MaxUint256);

  console.log(`Bridge deployed at: ${bridge.address}`);
  console.log(`ERC20 Safe deployed at: ${erc20Safe.address}`);
  console.log(`Validator deployed at: ${validator.address}`);
  // console.log(
  //   `ERC20 ${await ERC20.symbol()} token deployed at: ${ERC20.address}`
  // );
  // console.log(
  //   `Alice's balance: ${formatEther(
  //     await ERC20.balanceOf(alice.address)
  //   ).toString()} of ${await ERC20.symbol()} tokens`
  // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
