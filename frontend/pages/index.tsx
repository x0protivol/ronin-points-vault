/**
 * Ronin Points Vault - Main Dashboard Page
 * Shows aggregated cross-game points + vault actions
 */

import { useState, useEffect } from "react";

const INDEXER_URL = process.env.NEXT_PUBLIC_INDEXER_URL || "http://localhost:3001";

interface GameBalances {
  axie: number;
  pixels: number;
  wildForest: number;
}

interface PointsData {
  address: string;
  games: GameBalances;
  total: number;
  timestamp: string;
}

export default function Dashboard() {
  const [address, setAddress] = useState("");
  const [pointsData, setPointsData] = useState<PointsData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const fetchPoints = async () => {
    if (!address || address.length < 10) {
      setError("Please enter a valid Ronin wallet address");
      return;
    }

    setLoading(true);
    setError("");

    try {
      const response = await fetch(`${INDEXER_URL}/api/points/${address}`);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      setPointsData(data);
    } catch (err: any) {
      setError("Failed to fetch points. Is the indexer running?");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ fontFamily: "sans-serif", maxWidth: 800, margin: "0 auto", padding: 32 }}>
      {/* Header */}
      <div style={{ marginBottom: 32 }}>
        <h1 style={{ fontSize: 32, fontWeight: "bold", color: "#1a1a2e" }}>
          Ronin Points Vault
        </h1>
        <p style={{ color: "#666", fontSize: 16 }}>
          Cross-game points aggregator on Ronin L2 | Ronin Ecosystem Grant MVP
        </p>
      </div>

      {/* Wallet Input */}
      <div style={{ marginBottom: 24 }}>
        <label style={{ display: "block", marginBottom: 8, fontWeight: 600 }}>
          Ronin Wallet Address
        </label>
        <div style={{ display: "flex", gap: 8 }}>
          <input
            type="text"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder="0x..."
            style={{
              flex: 1,
              padding: "10px 14px",
              border: "1px solid #ddd",
              borderRadius: 8,
              fontSize: 14,
            }}
          />
          <button
            onClick={fetchPoints}
            disabled={loading}
            style={{
              padding: "10px 20px",
              background: "#2563eb",
              color: "white",
              border: "none",
              borderRadius: 8,
              cursor: loading ? "not-allowed" : "pointer",
              fontSize: 14,
              fontWeight: 600,
            }}
          >
            {loading ? "Loading..." : "Check Points"}
          </button>
        </div>
        {error && <p style={{ color: "red", marginTop: 8 }}>{error}</p>}
      </div>

      {/* Points Cards */}
      {pointsData && (
        <div>
          {/* Total */}
          <div
            style={{
              background: "linear-gradient(135deg, #2563eb, #7c3aed)",
              color: "white",
              borderRadius: 12,
              padding: 24,
              marginBottom: 24,
              textAlign: "center",
            }}
          >
            <p style={{ margin: 0, opacity: 0.8, fontSize: 14 }}>Total Points (All Games)</p>
            <p style={{ margin: "8px 0 0", fontSize: 48, fontWeight: "bold" }}>
              {pointsData.total.toLocaleString()}
            </p>
          </div>

          {/* Per Game */}
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 16 }}>
            <GameCard game="Axie Infinity" points={pointsData.games.axie} color="#60a5fa" />
            <GameCard game="Pixels" points={pointsData.games.pixels} color="#34d399" />
            <GameCard game="Wild Forest" points={pointsData.games.wildForest} color="#f59e0b" />
          </div>

          {/* CTA */}
          <div style={{ marginTop: 32, textAlign: "center" }}>
            <button
              style={{
                padding: "14px 32px",
                background: "#16a34a",
                color: "white",
                border: "none",
                borderRadius: 8,
                fontSize: 16,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              Deposit Points to Vault (Coming Soon)
            </button>
            <p style={{ color: "#888", marginTop: 8, fontSize: 12 }}>
              Vault smart contract deployment in progress
            </p>
          </div>
        </div>
      )}
    </div>
  );
}

function GameCard({ game, points, color }: { game: string; points: number; color: string }) {
  return (
    <div
      style={{
        background: "white",
        border: `2px solid ${color}`,
        borderRadius: 12,
        padding: 20,
        textAlign: "center",
        boxShadow: "0 2px 8px rgba(0,0,0,0.06)",
      }}
    >
      <p style={{ margin: 0, fontSize: 12, color: "#888", textTransform: "uppercase", letterSpacing: 1 }}>
        {game}
      </p>
      <p style={{ margin: "8px 0 0", fontSize: 28, fontWeight: "bold", color }}>
        {points.toLocaleString()}
      </p>
      <p style={{ margin: "4px 0 0", fontSize: 11, color: "#aaa" }}>points</p>
    </div>
  );
}
