import { parseEther } from "ethers/lib/utils";
import { JsonRpcProvider } from "@ethersproject/providers";

const TEN_THOUSAND_ETH = parseEther((10_000).toString())
  .toHexString()
  .replace("0x0", "0x");

export const faucet = async (address: string, provider: JsonRpcProvider) => {
  await provider.send("hardhat_setBalance", [address, TEN_THOUSAND_ETH]);
};
