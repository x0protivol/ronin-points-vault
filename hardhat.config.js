require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    // Ronin Testnet (Saigon)
    "ronin-testnet": {
      url: process.env.RONIN_TESTNET_RPC || "https://saigon-testnet.roninchain.com/rpc",
      accounts: process.env.DEPLOYER_PRIVATE_KEY ? [process.env.DEPLOYER_PRIVATE_KEY] : [],
      chainId: 2021,
      gasPrice: 20000000000, // 20 gwei
    },

    // Ronin Mainnet
    "ronin-mainnet": {
      url: process.env.RONIN_MAINNET_RPC || "https://api.roninchain.com/rpc",
      accounts: process.env.DEPLOYER_PRIVATE_KEY ? [process.env.DEPLOYER_PRIVATE_KEY] : [],
      chainId: 2020,
      gasPrice: 20000000000,
    },

    // Local Hardhat node for testing
    hardhat: {
      chainId: 31337,
    },
  },

  etherscan: {
    apiKey: {
      // Ronin uses its own explorer - placeholder for future verification
      "ronin-mainnet": process.env.RONIN_EXPLORER_API_KEY || "",
    },
    customChains: [
      {
        network: "ronin-mainnet",
        chainId: 2020,
        urls: {
          apiURL: "https://app.roninchain.com/api",
          browserURL: "https://app.roninchain.com",
        },
      },
    ],
  },

  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },

  mocha: {
    timeout: 60000,
  },
};
