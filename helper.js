const { ethers } = require("ethers");

const networkConfig = {
  11155111: {
    name: "sepolia",
    vrfCoordinatorV2: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625",
    entranceFee: ethers.utils.parseEther("0.01"),
    gasLane:
      "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae",
    subscriptionId: "0",
    callbackGasLimit: "50000",
    interval: "30",
  },
  31337: {
    name: "develop",
    entranceFee: ethers.utils.parseEther("0.01"),
    gasLane:
      "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae",
    callbackGasLimit: "50000",
    interval: "30",
  },
};
const developmentChains = ["develop", "sepolia"];

module.exports = {
  networkConfig,
  developmentChains,
};
