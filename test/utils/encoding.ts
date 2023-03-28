import { BigNumber, Wallet, constants, utils } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC20, ERC20Permit, IValidator } from "../../typechain-types";
import { TokenType } from "./consts&enums";
import { _TypedDataEncoder } from "@ethersproject/hash";

type WithdrawalRequest = IValidator.WithdrawalRequestStruct;
type PermitRequest = {
  owner: string;
  spender: string;
  value: BigNumber;
  nonce: BigNumber;
  deadline: BigNumber;
};
type SignedPermitRequest = PermitRequest & {
  v: number;
  r: string;
  s: string;
};

export const privKey = (hexName: string) => {
  return "0x" + hexName.padEnd(64, "0");
};

export const createWithdrawalRequest = (
  validator: string,
  bridge: string,
  from: string,
  amount: BigNumber,
  sourceToken: string,
  sourceTokenSymbol: string,
  sourceTokenName: string,
  isSourceTokenPermit: boolean,
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
    sourceTokenSymbol,
    sourceTokenName,
    isSourceTokenPermit,
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
      { name: "sourceTokenSymbol", type: "string" },
      { name: "sourceTokenName", type: "string" },
      { name: "isSourceTokenPermit", type: "bool" },
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

export const createPermitRequest = async (
  owner: Wallet | SignerWithAddress,
  spender: string,
  token: ERC20Permit,
  amount: BigNumber
): Promise<PermitRequest> => {
  return {
    owner: owner.address,
    spender: spender,
    value: amount,
    nonce: await token.nonces(owner.address),
    deadline: constants.MaxUint256,
  };
};

export const signPermitRequest = async (
  owner: Wallet | SignerWithAddress,
  token: ERC20Permit,
  request: PermitRequest,
  domainName?: string
): Promise<SignedPermitRequest> => {
  const chainId = (await owner.provider?.getNetwork())?.chainId;

  const domain = {
    name: domainName ? domainName : await token.name(),
    version: "1",
    chainId: chainId ?? 31337,
    verifyingContract: token.address,
  };

  const requestType = {
    Permit: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
      { name: "value", type: "uint256" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
  };

  _TypedDataEncoder.hashDomain(domain);
  _TypedDataEncoder.from(requestType).hash(request);

  const rawSignature = await owner._signTypedData(domain, requestType, request);
  const signature = utils.splitSignature(rawSignature);
  if (domainName) {
    console.log("domain", domain);
    console.log("struct", _TypedDataEncoder.from(requestType).hash(request));
    console.log("domain", _TypedDataEncoder.hashDomain(domain));
  }
  return {
    ...request,
    v: signature.v,
    r: signature.r,
    s: signature.s,
  };
};
