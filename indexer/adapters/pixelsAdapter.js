/**
 * Pixels Game Points Adapter
 * Fetches BERRY and in-game resource balances from Pixels API
 * API Docs: https://pixels.xyz/developers
 */

const axios = require("axios");

const PIXELS_API_BASE = "https://api.pixels.xyz/v1";
const API_KEY = process.env.PIXELS_API_KEY || "";

async function getBalance(address) {
  if (!API_KEY) {
    console.warn("PIXELS_API_KEY not set - returning mock data");
    return getMockBalance(address);
  }

  try {
    const response = await axios.get(
      `${PIXELS_API_BASE}/players/${address}/resources`,
      {
        headers: { "x-api-key": API_KEY },
        timeout: 5000,
      }
    );

    const resources = response.data?.resources || [];
    const berry = resources.find((r) => r.name === "BERRY");
    const coins = resources.find((r) => r.name === "PIXEL_COIN");

    return (berry?.amount || 0) + (coins?.amount || 0);
  } catch (err) {
    console.error("Pixels API error:", err.message);
    return 0;
  }
}

function getMockBalance(address) {
  const hash = address.toLowerCase().split("").reduce((acc, c) => acc + c.charCodeAt(0), 0);
  return (hash % 5000) + 50;
}

module.exports = { getBalance };
