module.exports = {
    skipFiles: [
      "BridgeExample/AllBridge1/Bridge.t.sol",
      "BridgeExample/AllBridge1/BridgeOriginal.t.sol",
      "BridgeExample/AllBridge1/WrappedToken.t.sol",
      "BridgeExample/AllBridge1/interfaces/IValidator.t.sol",
      "BridgeExample/AllBridge1/interfaces/IWrappedTokenV0.t.sol",
      "BridgeExample/AllBridge2/Bridge.t.sol",
      "BridgeExample/AllBridge2/GasOracle.t.sol",
      "BridgeExample/AllBridge2/GasUsage.t.sol",
      "BridgeExample/AllBridge2/HashUtils.t.sol",
      "BridgeExample/AllBridge2/Messenger.t.sol",
      "BridgeExample/AllBridge2/MessengerGateway.t.sol",
      "BridgeExample/AllBridge2/Pool.t.sol",
      "BridgeExample/AllBridge2/RewardManager.t.sol",
      "BridgeExample/AllBridge2/Router.t.sol",
      "BridgeExample/AllBridge2/Structs.t.sol",
      "BridgeExample/AllBridge2/WormholeMessenger.t.sol",
      "test/ERC20s.sol",
      "Validator.sol"
    ],
     configureYulOptimizer: true,
  };
  