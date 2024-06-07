const { developmentChains, networkConfig } = require("../helper");
const { ethers } = require("ethers");
const { networks } = require("../truffle-config");
var VRFCoordinatorV2Mock = artifacts.require("VRFCoordinatorV2Mock");
var Raffle = artifacts.require("Raffle");

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("30");

module.exports = async function (deployer, network) {
  const chainId = networks[network]["network_id"];
  let vrfCoordinatorV2Address;

  if (developmentChains.includes(network)) {
    const vrfCoordinatorV2Mock = await VRFCoordinatorV2Mock.deployed();
    vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;
    const transactionReceipt = await vrfCoordinatorV2Mock.createSubscription();
    subscriptionId = transactionReceipt.logs[0].args.subId;
    vrfCoordinatorV2Mock.fundSubscription(subscriptionId, VRF_SUB_FUND_AMOUNT);
  } else {
    vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
    subscriptionId = networkConfig[chainId]["subscriptionId"];
  }
  const entranceFee = networkConfig[chainId]["entranceFee"];
  const gasLane = networkConfig[chainId]["gasLane"];
  const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"];
  const interval = networkConfig[chainId]["interval"];
  await deployer.deploy(
    Raffle,
    vrfCoordinatorV2Address,
    entranceFee,
    gasLane,
    subscriptionId,
    callbackGasLimit,
    interval
  );

  if (!developmentChains.includes(network) && process.env.ETHERSCAN_API_KEY) {
    console.log("verifying...");
    verify(raffle.address, args);
  }
};

module.exports.tags = ["all", "raffle"];
