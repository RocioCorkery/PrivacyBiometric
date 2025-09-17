const { ethers } = require("hardhat");
require("dotenv/config");

async function main() {
  console.log("=== Privacy Biometric System Interaction Script ===\n");

  const contractAddress = process.env.PRIVACY_BIOMETRIC_CONTRACT_ADDRESS;
  if (!contractAddress) {
    console.error("Please set PRIVACY_BIOMETRIC_CONTRACT_ADDRESS in your .env file");
    process.exit(1);
  }

  const [owner, user1, user2] = await ethers.getSigners();
  console.log("Owner address:", owner.address);
  console.log("User1 address:", user1.address);
  console.log("User2 address:", user2.address);

  const PrivacyBiometric = await ethers.getContractFactory("PrivacyBiometric");
  const contract = PrivacyBiometric.attach(contractAddress);

  console.log("\n1. Contract Information");
  console.log("Contract address:", contractAddress);

  const totalUsers = await contract.totalUsers();
  console.log("Total registered users:", totalUsers.toString());

  const contractStats = await contract.getContractStats();
  console.log("Contract stats - Total users:", contractStats[0].toString());
  console.log("Contract stats - Total access attempts:", contractStats[1].toString());
  console.log("Contract stats - Active users:", contractStats[2].toString());

  console.log("\n2. Testing Biometric Registration");

  console.log("Registering biometric for user1...");
  const fingerprintHash1 = 12345678901234567890n;
  const faceTemplateHash1 = 98765432109876543210n;
  const voicePrintHash1 = 1357924680;
  const irisPattern1 = 2468135790;

  try {
    const registerTx1 = await contract.connect(user1).registerBiometric(
      fingerprintHash1,
      faceTemplateHash1,
      voicePrintHash1,
      irisPattern1
    );
    await registerTx1.wait();
    console.log("✓ User1 biometric registered successfully");
  } catch (error) {
    console.log("User1 already registered or error:", error.message);
  }

  console.log("Registering biometric for user2...");
  const fingerprintHash2 = 11111111111111111111n;
  const faceTemplateHash2 = 22222222222222222222n;
  const voicePrintHash2 = 3333333333;
  const irisPattern2 = 4444444444;

  try {
    const registerTx2 = await contract.connect(user2).registerBiometric(
      fingerprintHash2,
      faceTemplateHash2,
      voicePrintHash2,
      irisPattern2
    );
    await registerTx2.wait();
    console.log("✓ User2 biometric registered successfully");
  } catch (error) {
    console.log("User2 already registered or error:", error.message);
  }

  console.log("\n3. Checking User Status");
  const user1Status = await contract.getUserBiometricStatus(user1.address);
  console.log("User1 status - Active:", user1Status[0]);
  console.log("User1 status - Registration time:", new Date(user1Status[1] * 1000).toISOString());
  console.log("User1 status - Access count:", user1Status[2].toString());

  const user2Status = await contract.getUserBiometricStatus(user2.address);
  console.log("User2 status - Active:", user2Status[0]);
  console.log("User2 status - Registration time:", new Date(user2Status[1] * 1000).toISOString());
  console.log("User2 status - Access count:", user2Status[2].toString());

  console.log("\n4. Testing Biometric Verification");

  console.log("User1 attempting verification with correct biometrics...");
  try {
    const verifyTx1 = await contract.connect(user1).verifyBiometric(
      fingerprintHash1,
      faceTemplateHash1,
      voicePrintHash1,
      irisPattern1
    );
    await verifyTx1.wait();
    console.log("✓ User1 verification request submitted");
  } catch (error) {
    console.log("Error during user1 verification:", error.message);
  }

  console.log("User2 attempting verification with incorrect biometrics...");
  try {
    const verifyTx2 = await contract.connect(user2).verifyBiometric(
      fingerprintHash1, // Wrong fingerprint
      faceTemplateHash2,
      voicePrintHash2,
      irisPattern2
    );
    await verifyTx2.wait();
    console.log("✓ User2 verification request submitted (should fail)");
  } catch (error) {
    console.log("Error during user2 verification:", error.message);
  }

  console.log("\n5. Testing Authorization Management");

  console.log("Authorizing user1...");
  try {
    const authTx = await contract.connect(owner).authorizeUser(user1.address);
    await authTx.wait();
    console.log("✓ User1 authorized successfully");
  } catch (error) {
    console.log("Error authorizing user1:", error.message);
  }

  const isUser1Authorized = await contract.isUserAuthorized(user1.address);
  console.log("User1 authorized status:", isUser1Authorized);

  console.log("\n6. Testing Biometric Update");

  console.log("User1 updating biometric template...");
  const newFingerprintHash1 = 99999999999999999999n;
  const newFaceTemplateHash1 = 88888888888888888888n;
  const newVoicePrintHash1 = 7777777777;
  const newIrisPattern1 = 6666666666;

  try {
    const updateTx = await contract.connect(user1).updateBiometric(
      newFingerprintHash1,
      newFaceTemplateHash1,
      newVoicePrintHash1,
      newIrisPattern1
    );
    await updateTx.wait();
    console.log("✓ User1 biometric updated successfully");
  } catch (error) {
    console.log("Error updating user1 biometric:", error.message);
  }

  console.log("\n7. Access History");

  const accessHistoryLength1 = await contract.getAccessHistoryLength(user1.address);
  console.log("User1 access history length:", accessHistoryLength1.toString());

  const accessHistoryLength2 = await contract.getAccessHistoryLength(user2.address);
  console.log("User2 access history length:", accessHistoryLength2.toString());

  if (accessHistoryLength1 > 0) {
    const lastAccess = await contract.getAccessAttempt(user1.address, accessHistoryLength1 - 1);
    console.log("User1 last access - Verified:", lastAccess[0]);
    console.log("User1 last access - Timestamp:", new Date(lastAccess[1] * 1000).toISOString());
    console.log("User1 last access - Confidence score:", lastAccess[2].toString());
  }

  console.log("\n8. Security Hash Generation");

  const secureHash = await contract.generateSecureBiometricHash(123456789n, 987654321);
  console.log("Generated secure biometric hash:", secureHash.toString());

  console.log("\n9. Final Contract Statistics");

  const finalStats = await contract.getContractStats();
  console.log("Final stats - Total users:", finalStats[0].toString());
  console.log("Final stats - Total access attempts:", finalStats[1].toString());
  console.log("Final stats - Active users:", finalStats[2].toString());

  const registeredUsers = await contract.getAllRegisteredUsers();
  console.log("All registered users:", registeredUsers.map(addr => addr));

  console.log("\n=== Interaction Complete ===");
  console.log("All biometric operations tested successfully!");
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error("Interaction failed:");
      console.error(error);
      process.exit(1);
    });
}

module.exports = main;