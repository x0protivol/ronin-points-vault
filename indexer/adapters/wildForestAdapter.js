/**
 * Wild Forest Game Points Adapter
 * Fetches in-game resource and unit balances from Wild Forest API
 */

const axios = require("axios");

const WILD_FOREST_API_BASE = "https://api.wildforest.gg/v1";
const API_KEY = process.env.WILD_FOREST_API_KEY || "";

async function getBalance(address) {
  if (!API_KEY) {
    console.warn("WILD_FOREST_API_KEY not set - returning mock data");
    return getMockBalance(address);
  }

  try {
    const response = await axios.get(
      `${WILD_FOREST_API_BASE}/players/${address}/balance`,
      {
        headers: { "x-api-key": API_KEY },
        timeout: 5000,
      }
    );

    const gold = response.data?.gold || 0;
    const wood = response.data?.wood || 0;

    return gold + wood;
  } catch (err) {
    console.error("Wild Forest API error:", err.message);
    return 0;
  }
}

function getMockBalance(address) {
  const hash = address.toLowerCase().split("").reduce((acc, c) => acc + c.charCodeAt(0), 0);
  return (hash % 3000) + 25;
}

module.exports = { getBalance };
