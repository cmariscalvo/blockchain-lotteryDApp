const { networks } = require("../truffle-config");
const { developmentChains } = require("../helper");
const { ethers } = require("ethers");
var VRFCoordinatorV2Mock = artifacts.require("VRFCoordinatorV2Mock");

const BASE_FEE = ethers.utils.parseEther("0.25"); // 0.25 is the premium (0.25 per request)
const GAS_PRICE_LINK = 1e9; // CALCULATED VALUE BASED ON THE GAS PRICE ON THE CHAIN

module.exports = function (deployer, network) {
  console.log("Network", network);
  if (developmentChains.includes(network)) {
    console.log("Local network detected! Deploying mocks...");
    deployer.deploy(VRFCoordinatorV2Mock, BASE_FEE, GAS_PRICE_LINK);
    console.log("Mocks deployed!");
    console.log("--------------------------------------------------");
  }
};
// module.exports = async function ({ getNamedAccounts, deployments }) {
//   const { deploy, log } = deployments;
//   const { deployer } = await getNamedAccounts();
//   const args = [BASE_FEE, GAS_PRICE_LINK];
//   if (developmentChains.includes(network.name)) {
//     log("Local network detected! Deploying mocks...");
//     await deploy("VRFCoordinatorV2Mock", {
//       from: deployer,
//       log: true,
//       args: args,
//     });
//     log("Mocks deployed!");
//     log("--------------------------------------------------");
//   }
// };

module.exports.tags = ["all", "mocks"];
