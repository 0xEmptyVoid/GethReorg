<div align="center">

# ⛓️ Geth Reorg Simulator

**Simulate Ethereum Chain Reorganizations in a Controlled 3-Node Private Network**

[![Geth](https://img.shields.io/badge/Geth-v1.13.5--stable-3C3C3D?style=for-the-badge&logo=ethereum&logoColor=white)](https://geth.ethereum.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

<br>

_Understand how blockchain forks happen and how they resolve — by making them happen yourself._

<br>

</div>

---

## 🧬 What Is This?

A hands-on simulation tool that spins up a **3-node Clique PoA Ethereum network** and lets you trigger **real chain reorganizations** through controlled network partitions. Perfect for:

- 🔬 **Researchers** studying fork behavior and consensus edge cases
- 🛡️ **Security engineers** testing reorg-resilient smart contracts
- 🏗️ **DApp developers** validating transaction finality assumptions
- 📚 **Students** learning how Ethereum consensus actually works under the hood

---

## 🏗️ Architecture

```
           ┌─────────────────────────────────────┐
           │         GETH REORG SIMULATOR        │
           │       Interactive CLI Dashboard     │
           └───────────────────┬─────────────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
    ┌─────▼──────┐       ┌─────▼──────┐       ┌─────▼──────┐
    │  NODE  A   │       │  NODE  B   │       │  NODE  C   │
    │  Passive   │◄─────►│  Miner     │◄─────►│  Passive   │
    │  :8545     │       │  :8547     │       │  :8549     │
    │  :30305    │       │  :30306    │       │  :30307    │
    └────────────┘       └────────────┘       └────────────┘
          │                                          │
          └──────────────────────────────────────────┘
                     Full Mesh Topology

   --- During Reorg ---
   Node A isolates -> mines private fork -> reconnects -> REORG!
```

| Node  | Role                  | HTTP RPC |   WS   | P2P Port |
| :---: | :-------------------- | :------: | :----: | :------: |
| **A** | Passive (Reorg Actor) |  `8545`  | `8546` | `30305`  |
| **B** | Primary Miner         |  `8547`  | `8548` | `30306`  |
| **C** | Passive Observer      |  `8549`  | `8550` | `30307`  |

---

## ✨ Features

|     | Feature                        | Description                                                          |
| :-: | ------------------------------ | -------------------------------------------------------------------- |
| 🖥️  | **Premium CLI Dashboard**      | ASCII art banner, colored output, categorized menu system            |
| ⛏️  | **3-Node Clique PoA**          | Pre-configured genesis with sealed authority accounts                |
| 🔀  | **Realistic Reorg Simulation** | Network partition, private mining, reconnection, chain reorg         |
| 💧  | **Built-in Faucet**            | Send ETH to any address from the pre-funded signer account           |
| 🐳  | **Docker & Windows**           | Separate optimized scripts for containerized and native environments |
| 🔌  | **Geth Console Access**        | Attach directly to any node's IPC/named-pipe for raw JS commands     |
| 📊  | **Live Monitoring**            | Check block numbers, peer lists, and enode URIs per node             |

---

## 🚀 Quick Start

### Option A — Docker (Recommended)

```bash
# 1. Clone the repository
git clone https://github.com/0xEmptyVoid/GethReorg.git
cd GethReorg

# 2. Build and start the container
docker compose build && docker compose up -d

# 3. Attach to the interactive simulator
docker attach geth-reorg-sim
```

### Option B — Windows (Native)

> [!NOTE]
> **Prerequisites:** [Geth v1.13.5](https://geth.ethereum.org/downloads) installed and available in PATH, [Git Bash](https://gitforwindows.org/) or MSYS2.

```bash
# Run the Windows-optimized script
bash reorg_sim_win.sh
```

---

## 📋 Menu Reference

```
  ════════════════════════════════════════════════════════════════

  [ NETWORK MANAGEMENT ]
   1) Run All Nodes           (Start A, B, C)
   2) Init Genesis Block      (Required once)
   3) Faucet                  (Send ETH to address)

  [ MONITORING ]
   4) Show Block Number       (A/B/C)
   5) List Peers              (A/B/C)
   6) View Enode              (A/B/C)

  [ FORK & MINING ]
   7) Simulate REORG          (Partition & Mine A)
   8) Stop Mining             (A/B/C)
   9) Start Mining            (A/B/C)

  [ TOOLS ]
   10) Attach Geth Console    (A/B/C)
   11) Clean All Data         (Wipe chain)
    c) Clear Logs             (Console cleanup)
    h) Show Menu              (Help)
    0) Exit

  ════════════════════════════════════════════════════════════════
```

---

## 🔀 How Reorg Simulation Works

The simulator executes a **5-phase reorg sequence**:

```
Phase 1            Phase 2           Phase 3           Phase 4           Phase 5
---------          ---------         ---------         ---------         ---------
PARTITION          HANDICAP          FORK              REJOIN            REORG!

 A --X-- B,C       A waits...       A mines alone     A --- B,C         Longest chain
                   B,C mine ahead   B,C keep mining   Compare chains    wins & replaces
```

1. **Partition** — Node A disconnects from B and C
2. **Handicap** — Node A intentionally waits `N` blocks while B/C mine ahead (configurable)
3. **Private Fork** — Node A starts mining its own chain in isolation
4. **Rejoin** — Node A reconnects to the network
5. **Resolution** — Geth's consensus picks the **longest valid chain**, triggering a reorg on the shorter side

> [!TIP]
> Set a small handicap (1-2 blocks) but mine many blocks on A to guarantee Node A wins the fork and forces B/C to reorg.

---

## 💧 Faucet

Send test ETH from the pre-funded signer account (`0x573Df0Eb...1dd7`) to any address:

```
Select option: 3
Target Node (A/B/C) [default: A]: A
Enter receiver address: 0xYourAddressHere
Enter amount in ETH [default 10]: 100
```

The signer account is initialized with a massive balance in `genesis.json`, making it an unlimited faucet for testing purposes.

---

## 📁 Project Structure

```
GethReorg/
├── Dockerfile              # Ubuntu 22.04 + Geth 1.13.5
├── docker-compose.yml      # One-command container orchestration
├── reorg_sim.sh            # Main script (Docker / Linux)
├── reorg_sim_win.sh        # Windows-native variant (named pipes)
├── README.md
├── template/
│   ├── genesis.json        # Clique PoA genesis (chainId: 1, period: 5s)
│   ├── password.txt        # Keystore unlock password
│   └── keystore/           # Pre-generated signer account
└── data/                   # Runtime chain data (gitignored)
    ├── A/                  # Node A data directory
    ├── B/                  # Node B data directory
    └── C/                  # Node C data directory
```

---

## ⚙️ Genesis Configuration

| Parameter    | Value                                        |
| :----------- | :------------------------------------------- |
| Chain ID     | `1`                                          |
| Consensus    | Clique PoA                                   |
| Block Period | `5 seconds`                                  |
| Epoch        | `30000` blocks                               |
| Gas Limit    | `8,000,000`                                  |
| Signer       | `0x573Df0Eb2F042bf92a897A5C37c144F717Ed1dd7` |

### Pre-funded Accounts

| Address           | Balance                      |
| :---------------- | :--------------------------- |
| `0x573Df0...1dd7` | ~10^31 ETH (Signer / Faucet) |
| `0xE299f6...5904` | 100M ETH                     |
| `0xF1dC4D...d42E` | 100M ETH                     |
| `0x902B5b...110B` | 200 ETH                      |
| `0x03748A...06C3` | 50 ETH                       |

---

## 🔧 Ports & Endpoints

| Service   |      Node A      |      Node B      |      Node C      |
| :-------- | :--------------: | :--------------: | :--------------: |
| HTTP RPC  | `localhost:8545` | `localhost:8547` | `localhost:8549` |
| WebSocket | `localhost:8546` | `localhost:8548` | `localhost:8550` |
| P2P       |     `30305`      |     `30306`      |     `30307`      |
| Auth RPC  |      `8552`      |      `8553`      |      `8554`      |

### Connect via MetaMask / Web3

```
RPC URL:     http://localhost:8545
Chain ID:    1
Currency:    ETH
```

---

## ⚠️ Notes

- The simulation uses **host network mode** in Docker for seamless inter-node communication
- Ensure ports `8545-8554` and `30305-30307` are not occupied by other services
- All nodes share the same signer key — this is intentional for simplified PoA testing
- Chain data persists in `./data/` via Docker volume mount
- Use option `11` to wipe all chain data and start fresh

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to open an issue or submit a PR.

---

<div align="center">

**Built with ⛏️ for the Ethereum research community**

</div>
