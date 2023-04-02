import { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from "hardhat/builtin-tasks/task-names";
import { HardhatUserConfig, subtask } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();

subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(
  async (_, __, runSuper) => {
    const paths = await runSuper();

    return paths.filter((p: any) => !p.endsWith(".t.sol"));
  }
);

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_SEPOLIA_API_KEY}`,

      accounts: [
        process.env.BRIDGE_OWNER_PRIV_KEY as string,
        process.env.VALIDATOR_OWNER_PRIV_KEY as string,
        process.env.ALICE_PRIV_KEY as string,
      ],
    },
    mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_MUMBAI_API_KEY}`,
      accounts: [
        process.env.BRIDGE_OWNER_PRIV_KEY as string,
        process.env.VALIDATOR_OWNER_PRIV_KEY as string,
        process.env.ALICE_PRIV_KEY as string,
      ],
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHEREUM_ETHERSCAN_API_KEY as string,
      polygonMumbai: process.env.POLYGON_ETHERSCAN_API_KEY as string,
    },
  },
};

export default config;
