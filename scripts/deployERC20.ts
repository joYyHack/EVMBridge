import { formatEther, parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";

async function main() {
  const [_, __, alice] = await ethers.getSigners();

  const erc20Factory = await ethers.getContractFactory("RandomERC20", alice);
  const ERC20 = await erc20Factory.deploy("Mumbai", "MUM");
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

  const erc20PermitFactory = await ethers.getContractFactory(
    "RandomERC20Permit",
    alice
  );
  const ERC20Permit = await erc20PermitFactory.deploy(
    "MumbaiPermit",
    "MUM_PRM"
  );
  await ERC20Permit.deployed();

  await ERC20Permit.mint(parseEther((100).toString()));

  console.log(
    `ERC20 Permit ${await ERC20Permit.symbol()} token deployed at: ${
      ERC20Permit.address
    }`
  );
  console.log(
    `Alice's balance: ${formatEther(
      await ERC20Permit.balanceOf(alice.address)
    ).toString()} of ${await ERC20Permit.symbol()} tokens`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
