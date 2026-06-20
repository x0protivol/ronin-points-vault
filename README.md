# Ronin Points Vault

> Cross-game points aggregator & tradeable yield vault on the Ronin blockchain
> **Ronin Ecosystem Grant MVP — Builder Grant Application ($50K–$150K)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Chain: Ronin](https://img.shields.io/badge/Chain-Ronin%20L2-blue)](https://roninchain.com)
[![Status: MVP](https://img.shields.io/badge/Status-MVP%20Build-green)](#)

---

## Problem

Ronin has 2M+ daily active users across games like Axie Infinity, Pixels, and Wild Forest. Every game runs its own siloed points/reward system. Players have no unified way to:
- View all their cross-game points in one place
- Earn yield on idle points while waiting for TGE or redemptions
- Trade or transfer points as liquid ERC-20 assets
- Use points as collateral for other DeFi activities

This is dead capital sitting across millions of wallets on Ronin with zero financial utility.

---

## Solution — Ronin Points Vault

A cross-game points aggregation protocol that:
1. **Aggregates** in-game points from all major Ronin games into one dashboard
2. **Wraps** points into tradeable ERC-20 receipt tokens (`rpXXX` format)
3. **Vaults** wrapped points to generate yield via Katana DEX liquidity
4. **Integrates** Ronin Waypoint for gasless social login onboarding

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ USER (Ronin Waypoint / Wallet) │
└──────────────┬──────────────────────────────────────┘
 │
 ▼
┌─────────────────────────────────────────────────────┐
│ FRONTEND (Next.js + Viem) │
│ - Points Dashboard │
│ - Vault Deposit / Withdraw │
│ - Yield tracker │
└──────────────┬──────────────────────────────────────┘
 │
 ▼
┌─────────────────────────────────────────────────────┐
│ BACKEND INDEXER (Node.js + Express) │
│ - Ronin RPC event listener │
│ - Game API adapters (Pixels, Axie, Wild Forest) │
│ - Points balance aggregator │
└──────────────┬──────────────────────────────────────┘
 │
 ▼
┌─────────────────────────────────────────────────────┐
│ SMART CONTRACTS (Solidity / Hardhat) │
│ - PointsVault.sol (deposit, withdraw, yield) │
│ - PointsReceipt.sol (ERC-20 wrapper token) │
│ - IGamePoints.sol (interface for game adapters) │
│ - VaultStrategy.sol (Katana LP yield routing) │
└─────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
ronin-points-vault/
├── contracts/ # Solidity smart contracts
│ ├── PointsVault.sol
│ ├── PointsReceipt.sol
│ ├── VaultStrategy.sol
│ └── interfaces/
│ └── IGamePoints.sol
├── scripts/ # Hardhat deploy scripts
│ ├── deploy.js
│ └── verify.js
├── test/ # Contract tests
│ ├── PointsVault.test.js
│ └── PointsReceipt.test.js
├── frontend/ # Next.js app
│ ├── pages/
│ │ ├── index.tsx (Dashboard)
│ │ ├── vault.tsx (Deposit/Withdraw)
│ │ └── leaderboard.tsx
│ ├── components/
│ │ ├── PointsCard.tsx
│ │ ├── VaultWidget.tsx
│ │ └── WaypointLogin.tsx
│ └── hooks/
│ ├── usePointsBalance.ts
│ └── useVault.ts
├── indexer/ # Backend indexer
│ ├── server.js
│ ├── adapters/
│ │ ├── axieAdapter.js
│ │ ├── pixelsAdapter.js
│ │ └── wildForestAdapter.js
│ └── listeners/
│ └── onchainListener.js
├── hardhat.config.js
├── package.json
└── .env.example
```

---

## Smart Contracts

### PointsVault.sol
- Accept wrapped ERC-20 points tokens
- Track per-user vault balances
- Route idle capital to Katana DEX for LP yield
- Emit events for indexer

### PointsReceipt.sol (ERC-20)
- `rpAXS` — Axie Infinity wrapped points
- `rpPXL` — Pixels wrapped points
- `rpWF` — Wild Forest wrapped points
- 1:1 redeemable against source game points
- Freely transferable and tradeable on Katana DEX

### VaultStrategy.sol
- Deposits LP tokens into Katana pools
- Auto-compounds yield
- Configurable strategy per token pair

---

## Ronin Waypoint Integration

All user-facing actions support **gasless onboarding** via Ronin Waypoint:
- Social login (Google / Apple)
- No seed phrase required
- Gas sponsorship via Waypoint Gas Grant ($20K additional grant)

---

## Grant Strategy

| Grant Program | Amount | Application |  
|---|---|---|
| Ronin Builder Grant | $50K–$150K RON | [Apply here](https://blog.roninchain.com/p/introducing-ronin-ecosystem-grants) |
| Ronin Waypoint Gas Grant | $20K RON | Same application |
| **Total target** | **$70K–$170K** | |

**Evaluation criteria met:**
- Solves real user pain point (dead capital, fragmented points)
- Introduces new utility not on Ronin (yield on game points)
- Brings new DeFi users to Ronin ecosystem
- Integrates Ronin Waypoint for mass onboarding

---

## Tech Stack

| Layer | Technology |
|---|---|
| Blockchain | Ronin L2 (OP Stack + EigenDA) |
| Smart Contracts | Solidity 0.8.x + Hardhat |
| Frontend | Next.js 14 + TypeScript + Viem |
| Wallet | Ronin Waypoint SDK |
| Backend Indexer | Node.js + Express + Prisma |
| Database | PostgreSQL (Supabase) |
| Yield Source | Katana DEX LP |

---

## Roadmap

### V1 — MVP (6 weeks)
- [ ] Deploy PointsReceipt ERC-20 for top 3 Ronin games
- [ ] PointsVault.sol with basic deposit/withdraw
- [ ] Frontend dashboard with Waypoint login
- [ ] Backend indexer for Axie + Pixels
- [ ] Ronin testnet deployment
- [ ] Grant application submission

### V2 — Growth (weeks 7–12)
- [ ] Katana DEX LP yield integration
- [ ] Auto-compound vault strategies
- [ ] Points leaderboard + social sharing
- [ ] Mobile-responsive UI
- [ ] Mainnet deployment

### V3 — Expansion
- [ ] Points-backed lending (collateral layer)
- [ ] Cross-game points swap market
- [ ] DAO governance for vault strategies
- [ ] SDK for new games to plug in

---

## Getting Started

```bash
# Clone repo
git clone https://github.com/x0protivol/ronin-points-vault
cd ronin-points-vault

# Install dependencies
npm install

# Copy env
cp .env.example .env
# Fill in your RPC URL, private key, etc.

# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to Ronin testnet
npx hardhat run scripts/deploy.js --network ronin-testnet

# Start frontend
cd frontend && npm run dev

# Start indexer
cd indexer && node server.js
```

---

## Contributing

PRs welcome. This is an open-source MVP built for the Ronin ecosystem.

---

## License

MIT — see [LICENSE](LICENSE)
