import { BigNumber, Wallet } from "ethers";
import { IValidator } from "../../typechain-types";
import { TokenType } from "./consts&enums";

type WithdrawalRequest = IValidator.WithdrawalRequestStruct;

export const privKey = (hexName: string) => {
  return "0x" + hexName.padEnd(64, "0");
};

export const createWithdrawalRequest = (
  validator: string,
  bridge: string,
  from: string,
  amount: BigNumber,
  sourceToken: string,
  wrappedToken: string,
  withdrawalTokenType: TokenType,
  nonce: BigNumber
): WithdrawalRequest => {
  return {
    validator,
    bridge,
    from,
    amount,
    sourceToken,
    wrappedToken,
    withdrawalTokenType,
    nonce,
  };
};

export const signWithdrawalRequest = async (
  validatorWallet: Wallet,
  validatorContractAddress: string,
  request: WithdrawalRequest
) => {
  const chainId = (await validatorWallet.provider.getNetwork()).chainId;
  const domain = {
    name: "Validator",
    version: "0.1",
    chainId: chainId,
    verifyingContract: validatorContractAddress,
  };

  const requestType = {
    WithdrawalRequest: [
      { name: "validator", type: "address" },
      { name: "bridge", type: "address" },
      { name: "from", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "sourceToken", type: "address" },
      { name: "wrappedToken", type: "address" },
      { name: "withdrawalTokenType", type: "uint8" },
      { name: "nonce", type: "uint256" },
    ],
  };

  const signature = await validatorWallet._signTypedData(
    domain,
    requestType,
    request
  );

  return signature;
};
