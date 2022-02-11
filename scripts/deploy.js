// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Verifier = await ethers.getContractFactory("Verifier");
  const verifier = await Verifier.deploy();
  const MoveVerifier = await ethers.getContractFactory("MoveVerifier");
  const moveVerifier = await MoveVerifier.deploy();
  const DarkForest = await ethers.getContractFactory("DarkForest");
  const darkForest = await DarkForest.deploy(verifier.address, moveVerifier.address);

  

  console.log("Darkforest address:", darkForest.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });