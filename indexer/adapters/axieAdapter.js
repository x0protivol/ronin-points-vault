/**
 * Axie Infinity Points Adapter
 * 
 * Fetches player's SLP (Smooth Love Potion) and AXP (Axie XP) balances
 * from the Axie Infinity API and Ronin chain
 * 
 * TODO: Replace mock data with real Axie Infinity API calls
 * API Docs: https://developers.skymavis.com/api/rns
 */

const axios = require("axios");

const AXIE_API_BASE = "https://api-gateway.skymavis.com/origin";
const API_KEY = process.env.AXIE_API_KEY || "";

/**
 * Get Axie-related points balance for a wallet address
 * Returns combined SLP balance + AXP points
 * @param {string} address - Ronin wallet address
 * @returns {Promise<number>} - Total points balance
 */
async function getBalance(address) {
  if (!API_KEY) {
    // Return mock data for development
    console.warn("AXIE_API_KEY not set - returning mock data");
    return getMockBalance(address);
  }

  try {
    const response = await axios.get(
      `${AXIE_API_BASE}/v2/players/${address}/items`,
      {
        headers: {
          "x-api-key": API_KEY,
          "Content-Type": "application/json",
        },
        timeout: 5000,
      }
    );

    // Extract SLP and AXP from response
    const items = response.data?.result?.items || [];
    const slp = items.find((i) => i.itemId === "smooth-love-potion");
    const axp = items.find((i) => i.itemId === "axie-experience-point");

    return (slp?.quantity || 0) + (axp?.quantity || 0);
  } catch (err) {
    console.error("Axie API error:", err.message);
    return 0;
  }
}

/**
 * Mock balance for development/testing
 */
function getMockBalance(address) {
  // Deterministic mock based on address
  const hash = address.toLowerCase().split("").reduce((acc, c) => acc + c.charCodeAt(0), 0);
  return (hash % 10000) + 100;
}

module.exports = { getBalance };
