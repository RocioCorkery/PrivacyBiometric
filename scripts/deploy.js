const { ethers } = require("hardhat");

async function main() {
  console.log("Starting Privacy Biometric System deployment...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  console.log("Deploying PrivacyBiometric contract...");
  const PrivacyBiometric = await ethers.getContractFactory("PrivacyBiometric");

  const privacyBiometric = await PrivacyBiometric.deploy();
  await privacyBiometric.waitForDeployment();

  const contractAddress = await privacyBiometric.getAddress();
  console.log("PrivacyBiometric deployed to:", contractAddress);

  console.log("\n=== Deployment Summary ===");
  console.log("Contract: PrivacyBiometric");
  console.log("Address:", contractAddress);
  console.log("Network:", hre.network.name);
  console.log("Deployer:", deployer.address);
  console.log("Gas used for deployment: estimating...");

  try {
    const deploymentTx = privacyBiometric.deploymentTransaction();
    if (deploymentTx) {
      const receipt = await deploymentTx.wait();
      console.log("Gas used:", receipt.gasUsed.toString());
      console.log("Transaction hash:", receipt.hash);
    }
  } catch (error) {
    console.log("Could not retrieve gas information:", error.message);
  }

  console.log("\n=== Contract Verification Instructions ===");
  console.log("To verify the contract on Etherscan, run:");
  console.log(`npx hardhat verify --network ${hre.network.name} ${contractAddress}`);

  console.log("\n=== Environment Setup ===");
  console.log("Add the following to your .env file:");
  console.log(`PRIVACY_BIOMETRIC_CONTRACT_ADDRESS=${contractAddress}`);

  console.log("\n=== Next Steps ===");
  console.log("1. Update your .env file with the contract address");
  console.log("2. Run 'npm run interact' to test contract functions");
  console.log("3. Register biometric templates using the interaction script");
  console.log("4. Test biometric verification functionality");

  return {
    privacyBiometric: contractAddress
  };
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error("Deployment failed:");
      console.error(error);
      process.exit(1);
    });
}

module.exports = main;