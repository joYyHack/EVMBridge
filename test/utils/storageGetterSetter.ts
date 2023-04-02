import { JsonRpcProvider } from "@ethersproject/providers";
import { defaultAbiCoder as abi, keccak256 } from "ethers/lib/utils";

export const getDepositedAmountFromERC20Safe = async (
  provider: JsonRpcProvider,
  ownerAddress: string,
  tokenAddress: string,
  erc20SafeAddress: string
) => {
  const MAPPING_POSITION = 0; // check in ERC20SafeHandler.sol

  // encode key value and mapping slot of the FIRST level mapping
  let firstLevelMapping = abi.encode(
    ["address", "uint256"],
    [ownerAddress, MAPPING_POSITION]
  );

  // get pointer to the nested mapping
  let nestedMappingPositon = keccak256(firstLevelMapping);

  // encode key value and mapping slot of the SECOND level mapping
  let secondLevelMapping = abi.encode(
    ["address", "uint256"],
    [tokenAddress, nestedMappingPositon]
  );

  // get pointer to the uint256
  let pointerToResult = keccak256(secondLevelMapping);

  const depositedAmount = await provider.getStorageAt(
    erc20SafeAddress,
    pointerToResult
  );

  return depositedAmount;
};

export const setTokenInfoForERC20Safe = async (
  provider: JsonRpcProvider,
  tokenAddress: string,
  erc20SafeAddress: string
) => {
  const MAPPING_POSITION = 2; // check in ERC20SafeHandler.sol

  // encode key value and mapping slot of the mapping
  let encodedMapping = abi.encode(
    ["address", "uint256"],
    [tokenAddress, MAPPING_POSITION]
  );

  // get pointer to the Token Info value
  let tokenInfoPosition = keccak256(encodedMapping);

  const tokenInfo = await provider.getStorageAt(
    erc20SafeAddress,
    tokenInfoPosition
  );

  return { tokenInfo, tokenInfoPosition };
};
