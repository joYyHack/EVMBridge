import { ethers } from "hardhat";
import { constants } from "ethers";
import { parseEther, formatEther } from "ethers/lib/utils";
import { privKey } from "./utils/encoding";
import { faucet } from "./utils/faucet";

async function main() {
  const [_, alice] = await ethers.getSigners();

  const erc20Factory = await ethers.getContractFactory("RandomERC20", alice);
  const ERC20 = await erc20Factory.deploy("Random", "RND");
  await ERC20.deployed();

  await ERC20.mint(parseEther((100).toString()));

  console.log(
    `ERC20 ${await ERC20.symbol()} token deployed at: ${ERC20.address}`
  );
  console.log(
    `Alice's balance: ${formatEther(
      await ERC20.balanceOf(alice.address)
    ).toString()} of ${await ERC20.symbol()} tokens`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
