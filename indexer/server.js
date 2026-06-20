/**
 * Ronin Points Vault - Backend Indexer
 * 
 * Listens to on-chain events from PointsVault
 * Aggregates points balances from game APIs
 * Exposes REST API for the frontend dashboard
 */

require("dotenv").config();
const express = require("express");
const cors = require("cors");
const { ethers } = require("ethers");

// Adapters
const axieAdapter = require("./adapters/axieAdapter");
const pixelsAdapter = require("./adapters/pixelsAdapter");
const wildForestAdapter = require("./adapters/wildForestAdapter");

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.INDEXER_PORT || 3001;
const RONIN_RPC = process.env.RONIN_TESTNET_RPC || "https://saigon-testnet.roninchain.com/rpc";
const VAULT_ADDRESS = process.env.POINTS_VAULT_ADDRESS || "";

// Simple in-memory store (replace with DB for production)
const pointsCache = new Map();

// ============ Routes ============

/**
 * GET /health
 * Health check
 */
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

/**
 * GET /api/points/:address
 * Get aggregated points balance for a wallet across all Ronin games
 */
app.get("/api/points/:address", async (req, res) => {
  try {
    const { address } = req.params;

    if (!ethers.isAddress(address)) {
      return res.status(400).json({ error: "Invalid wallet address" });
    }

    // Fetch from all game adapters in parallel
    const [axiePoints, pixelsPoints, wildForestPoints] = await Promise.allSettled([
      axieAdapter.getBalance(address),
      pixelsAdapter.getBalance(address),
      wildForestAdapter.getBalance(address),
    ]);

    const balances = {
      address,
      games: {
        axie: axiePoints.status === "fulfilled" ? axiePoints.value : 0,
        pixels: pixelsPoints.status === "fulfilled" ? pixelsPoints.value : 0,
        wildForest: wildForestPoints.status === "fulfilled" ? wildForestPoints.value : 0,
      },
      total:
        (axiePoints.status === "fulfilled" ? axiePoints.value : 0) +
        (pixelsPoints.status === "fulfilled" ? pixelsPoints.value : 0) +
        (wildForestPoints.status === "fulfilled" ? wildForestPoints.value : 0),
      timestamp: new Date().toISOString(),
    };

    // Cache result
    pointsCache.set(address, balances);

    res.json(balances);
  } catch (err) {
    console.error("Error fetching points:", err);
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * GET /api/vault/stats
 * Get overall vault statistics
 */
app.get("/api/vault/stats", async (req, res) => {
  try {
    // TODO: Query PointsVault contract for TVL, total deposits, active games
    res.json({
      totalValueLocked: "0",
      totalDeposits: "0",
      activeGames: 3,
      supportedGames: ["axie", "pixels", "wildForest"],
      vaultAddress: VAULT_ADDRESS,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(500).json({ error: "Internal server error" });
  }
});

/**
 * GET /api/leaderboard
 * Get top point holders across all games
 */
app.get("/api/leaderboard", async (req, res) => {
  // TODO: Implement from on-chain event logs
  res.json({ leaderboard: [], message: "Coming in V2" });
});

// ============ Start Server ============

app.listen(PORT, () => {
  console.log(`Ronin Points Vault Indexer running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Points API:   http://localhost:${PORT}/api/points/:address`);
  console.log(`Vault stats:  http://localhost:${PORT}/api/vault/stats`);
});

module.exports = app;
