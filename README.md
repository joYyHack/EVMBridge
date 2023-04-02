# Bridge for the EVM compatible chains for ERC20 tokens
> * ### The bridge is currently available on the Sepolia and Mumbai chains.  
> * ### Bridge supports [ERC20 Permits (EIP2612)](https://eips.ethereum.org/EIPS/eip-2612)
> * ### Related projects [EVMBridge Client](https://github.com/joYyHack/EVMBridge-client) and [EVMBridge Validator](https://github.com/joYyHack/EVMBridge-validator)

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Overview](#overview)
- [Deployments](#deployments-by-evm-chain)
- [Diagram](#diagram)
### Overview

The Bridge smart contract provides a bidirectional transfer of ERC20 tokens between EVM-compatible chains. This means that users can move their tokens from Chain A to Chain B and vice versa with ease. Additionally, the Bridge supports the ERC20 Permit standard (ERC2612), enabling gasless transactions by pre-approving token transfers. With the Bridge, users have greater flexibility and control over their tokens, eliminating the need to rely on centralized exchanges or custodians for transfers between chains.

### Deployments by EVM Chain

<table>
<tr>
<th>Network</th>
<th>Bridge</th>
<th>ERC20 Safe</th>
<th>Validator</th>
</tr>

<tr><td>Ethereum Sepolia</td><td>

[0xce56e2D1e03e653bc95F113177A2Be6002068B7E](https://sepolia.etherscan.io/address/0xce56e2D1e03e653bc95F113177A2Be6002068B7E#code)

</td><td>

[0x268653b20B3a3aE011A42d2b0D6b9F97eC42ca2d](https://sepolia.etherscan.io/address/0x268653b20B3a3aE011A42d2b0D6b9F97eC42ca2d#code)

</td><td>

[0xb564990E0fD557345f4e87F10ECA0F641a557671](https://sepolia.etherscan.io/address/0xb564990E0fD557345f4e87F10ECA0F641a557671#code)

</td></tr>
<tr><td>Polygon Mumbai</td><td>

[0xce56e2D1e03e653bc95F113177A2Be6002068B7E](https://mumbai.polygonscan.com/address/0xce56e2D1e03e653bc95F113177A2Be6002068B7E#code)

</td><td>

[0x268653b20B3a3aE011A42d2b0D6b9F97eC42ca2d](https://mumbai.polygonscan.com/address/0x268653b20B3a3aE011A42d2b0D6b9F97eC42ca2d#code)

</td><td>

[0xb564990E0fD557345f4e87F10ECA0F641a557671](https://mumbai.polygonscan.com/address/0xb564990E0fD557345f4e87F10ECA0F641a557671#code)

</td></tr>

### Diagram
#### User flow
