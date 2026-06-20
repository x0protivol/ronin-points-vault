const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Ronin Points Vault...");
  console.log("Network:", network.name);

  const [deployer] = await ethers.getSigners();
  console.log("Deployer address:", deployer.address);
  console.log(
    "Deployer balance:",
    ethers.formatEther(await ethers.provider.getBalance(deployer.address)),
    "RON"
  );

  // ---- 1. Deploy PointsVault ----
  const feeRecipient = process.env.FEE_RECIPIENT_ADDRESS || deployer.address;
  console.log("\nDeploying PointsVault...");
  const PointsVault = await ethers.getContractFactory("PointsVault");
  const vault = await PointsVault.deploy(feeRecipient);
  await vault.waitForDeployment();
  const vaultAddress = await vault.getAddress();
  console.log("PointsVault deployed to:", vaultAddress);

  // ---- 2. Print summary ----
  console.log("\n=== DEPLOYMENT SUMMARY ===");
  console.log("Network:          ", network.name);
  console.log("Deployer:         ", deployer.address);
  console.log("PointsVault:      ", vaultAddress);
  console.log("Fee Recipient:    ", feeRecipient);
  console.log("");
  console.log("Next steps:");
  console.log("1. Update POINTS_VAULT_ADDRESS in your .env file");
  console.log("2. Deploy game adapters and register them with registerGame()");
  console.log("3. Update frontend NEXT_PUBLIC_POINTS_VAULT_ADDRESS");
  console.log("4. Apply for Ronin Ecosystem Grant at:");
  console.log("   https://blog.roninchain.com/p/introducing-ronin-ecosystem-grants");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
