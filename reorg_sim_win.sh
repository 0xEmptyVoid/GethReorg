#!/bin/bash
# reorg_sim_win.sh - Geth Reorg Simulation for Windows (Host)
# Optimized with Premium Dashboard UI
#
# Copyright (c) 2026 0xEmptyVoid
# Licensed under the MIT License. See LICENSE file in the project root for details.

# ================= CONFIG =================
GETH_BIN="geth"
BASE_DIR=$(cd "$(dirname "$0")" && pwd)
DATA_DIR="$BASE_DIR/data"
TEMPLATE_DIR="$BASE_DIR/template"
PASSWORD_FILE="$TEMPLATE_DIR/password.txt"

# IPC Paths (Windows Named Pipe Format - using relative structure for Geth compatibility)
# This avoids the 'colon in path' error on Windows Geth
IPC_A='\\.\pipe\data\A\geth.ipc'
IPC_B='\\.\pipe\data\B\geth.ipc'
IPC_C='\\.\pipe\data\C\geth.ipc'

# Block time from genesis.json (clique.period = 5)
BLOCK_TIME=5

# Colors & Styles
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
MAGENTA="\033[0;35m"
WHITE="\033[1;37m"
BOLD="\033[1m"
DIM="\033[2m"
NC="\033[0m"

log_info()    { echo -e "${BLUE}${BOLD}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; }

section () {
  echo -e "${CYAN}┌──────────────────────────────────────┐${NC}"
  echo -e "${CYAN}│ $(printf '%-36s' "$1") │${NC}"
  echo -e "${CYAN}└──────────────────────────────────────┘${NC}"
}

get_status() {
    if tasklist //FI "IMAGENAME eq geth.exe" 2>/dev/null | grep -i "geth.exe" > /dev/null; then
        echo -e "${GREEN}${BOLD}● ACTIVE${NC}"
    else
        echo -e "${RED}${BOLD}○ INACTIVE${NC}"
    fi
}

# ---------- Node Management ----------

init_genesis() {
    section "Initializing Genesis Block for all nodes"
    # Ensure nodes are stopped before initialization to avoid file locks
    stop_nodes
    sleep 2
    
    mkdir -p "data/A" "data/B" "data/C"
    
    log_info "Initializing genesis for Node A..."
    $GETH_BIN init --datadir "./data/A" "$TEMPLATE_DIR/genesis.json"
    log_info "Initializing genesis for Node B..."
    $GETH_BIN init --datadir "./data/B" "$TEMPLATE_DIR/genesis.json"
    log_info "Initializing genesis for Node C..."
    $GETH_BIN init --datadir "./data/C" "$TEMPLATE_DIR/genesis.json"
    
    log_info "Copying keystore to nodes..."
    cp -r "$TEMPLATE_DIR/keystore" "./data/A/"
    cp -r "$TEMPLATE_DIR/keystore" "./data/B/"
    cp -r "$TEMPLATE_DIR/keystore" "./data/C/"
    
    log_success "Genesis block initialized and keystore copied for Node A, B, and C"
}

clean_nodes() {
    section "Cleaning Data for all nodes"
    log_info "Stopping nodes before cleaning..."
    stop_nodes
    log_info "Removing data directories..."
    rm -rf "./data/A" "./data/B" "./data/C"
    log_success "Data for Node A, B, and C have been removed"
}

start_nodes() {
    section "Starting 3 Geth Nodes (Windows Mode)"
    
    # Cleanup any old processes (using taskkill)
    taskkill //F //IM geth.exe //T 2>/dev/null || true
    
    # Node A (Passive, starts mining only during reorg)
    log_info "Starting Node A (Passive)..."
    $GETH_BIN --datadir "./data/A" --networkid 1 --port 30305 --authrpc.port 8552 \
      --nat none --nodiscover --netrestrict 127.0.0.1/32 \
      --ipcpath "$IPC_A" \
      --http --http.addr 0.0.0.0 --http.port 8545 --http.api "eth,net,web3,personal,miner,admin" \
      --http.corsdomain="*" --http.vhosts="*" \
      --ws --ws.addr "0.0.0.0" --ws.port 8546 --ws.api eth,web3 --ws.origins "*" \
      --allow-insecure-unlock \
      --miner.etherbase "0x573Df0Eb2F042bf92a897A5C37c144F717Ed1dd7" \
      --unlock "0x573Df0Eb2F042bf92a897A5C37c144F717Ed1dd7" --password "$PASSWORD_FILE" \
      --syncmode full --gcmode archive --verbosity 3 > "./data/A/nodeA.log" 2>&1 &
    
    # Node B (Always Mining)
    log_info "Starting Node B (Mining)..."
    $GETH_BIN --datadir "./data/B" --networkid 1 --port 30306 --authrpc.port 8553 \
      --nat none --nodiscover --netrestrict 127.0.0.1/32 \
      --ipcpath "$IPC_B" \
      --http --http.addr 0.0.0.0 --http.port 8547 --http.api "eth,net,web3,personal,miner,admin" \
      --http.corsdomain="*" --http.vhosts="*" \
      --ws --ws.addr 0.0.0.0 --ws.port 8548 --ws.api eth,web3 --ws.origins "*" \
      --allow-insecure-unlock --mine --miner.etherbase "0x573Df0Eb2F042bf92a897A5C37c144F717Ed1dd7" \
      --unlock "0x573Df0Eb2F042bf92a897A5C37c144F717Ed1dd7" --password "$PASSWORD_FILE" \
      --syncmode full --gcmode archive --verbosity 3 > "./data/B/nodeB.log" 2>&1 &
    
    # Node C (Passive)
    log_info "Starting Node C (Passive)..."
    $GETH_BIN --datadir "./data/C" --networkid 1 --port 30307 --authrpc.port 8554 \
      --nat none --nodiscover --netrestrict 127.0.0.1/32 \
      --ipcpath "$IPC_C" \
      --http --http.addr 0.0.0.0 --http.port 8549 --http.api "eth,net,web3,personal,miner,admin" \
      --http.corsdomain="*" --http.vhosts="*" \
      --ws --ws.addr 0.0.0.0 --ws.port 8550 --ws.api eth,web3 --ws.origins "*" \
      --allow-insecure-unlock \
      --unlock "0x573Df0Eb2F042bf92a897A5C37c144F717Ed1dd7" --password "$PASSWORD_FILE" \
      --syncmode full --gcmode archive --verbosity 3 > "./data/C/nodeC.log" 2>&1 &

    log_info "Waiting for nodes to initialize..."
    sleep 10
    
    # Connect Peers
    connect_initial_peers
}

connect_initial_peers() {
    section "Establishing Network Topology"
    
    log_info "Fetching enode from Node B (Pipe: $IPC_B)..."
    ENODE_B=$($GETH_BIN attach --exec "admin.nodeInfo.enode" "$IPC_B" 2>/dev/null | tr -d '"\r' | sed 's/\\//g')
    
    log_info "Fetching enode from Node C (Pipe: $IPC_C)..."
    ENODE_C=$($GETH_BIN attach --exec "admin.nodeInfo.enode" "$IPC_C" 2>/dev/null | tr -d '"\r' | sed 's/\\//g')
    
    if [[ -z "$ENODE_B" || "$ENODE_B" == "" || "$ENODE_B" == "null" ]]; then
        log_error "Failed to retrieve Node B enode. Check ./data/B/nodeB.log"
        return
    fi
    if [[ -z "$ENODE_C" || "$ENODE_C" == "" || "$ENODE_C" == "null" ]]; then
        log_error "Failed to retrieve Node C enode. Check ./data/C/nodeC.log"
        return
    fi

    # 1. Node A adds Node B and Node C
    log_info "Node A: Adding Peer B ($ENODE_B)..."
    $GETH_BIN attach --exec "admin.addPeer(\"$ENODE_B\")" "$IPC_A" > /dev/null 2>&1
    
    log_info "Node A: Adding Peer C ($ENODE_C)..."
    $GETH_BIN attach --exec "admin.addPeer(\"$ENODE_C\")" "$IPC_A" > /dev/null 2>&1
    
    # 2. Node B adds Node C (Core chain connectivity)
    log_info "Node B: Adding Peer C..."
    $GETH_BIN attach --exec "admin.addPeer(\"$ENODE_C\")" "$IPC_B" > /dev/null 2>&1
    
    log_success "Topology defined: Node A -> [B, C], Node B -> [C]"
    log_warn "If commands fail, try option 1 again after few seconds."
}


stop_nodes() {
    log_info "Stopping all nodes..."
    # Force stop any running geth.exe processes on Windows
    taskkill //F //IM geth.exe //T 2>/dev/null || true
    log_success "All nodes stopped"
}

# ---------- helpers ----------
run_js () {
  local target_ipc="${2:-$IPC_A}"
  $GETH_BIN attach --exec "$1" "$target_ipc" >/dev/null
}

run_js_out () {
  local target_ipc="${2:-$IPC_A}"
  $GETH_BIN attach --exec "$1" "$target_ipc"
}

get_target_ipc() {
  read -p "Target Node (A/B/C) [default: A]: " node_input
  node_input=$(echo "$node_input" | tr '[:lower:]' '[:upper:]')
  case "$node_input" in
    B) TARGET_IPC="$IPC_B"; TARGET_NAME="B" ;;
    C) TARGET_IPC="$IPC_C"; TARGET_NAME="C" ;;
    *) TARGET_IPC="$IPC_A"; TARGET_NAME="A" ;;
  esac
}

# ---------- menu functions ----------
show_block () {
  get_target_ipc
  BN=$(run_js_out "eth.blockNumber" "$TARGET_IPC" | tr -d '\r')
  log_info "Node $TARGET_NAME block number: $BN"
}

list_peers () {
  get_target_ipc
  section "Connected Peers (Node $TARGET_NAME)"
  run_js_out "admin.peers.forEach((p, i) => { console.log( '#' + i + ' | ' + p.enode + ' | head=' + p.head ) }) " "$TARGET_IPC" | sed '$d'
}

faucet() {
    section "Geth Faucet"
    get_target_ipc
    
    read -p "Enter receiver address: " RECV_ADDR
    if [[ ! "$RECV_ADDR" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        log_error "Invalid Ethereum address format."
        return
    fi

    read -p "Enter amount in ETH [default 10]: " ETH_AMOUNT
    ETH_AMOUNT=${ETH_AMOUNT:-10}

    log_info "Sending $ETH_AMOUNT ETH from 0x573Df... to $RECV_ADDR on Node $TARGET_NAME..."
    
    TX_HASH=$(run_js_out "eth.sendTransaction({from: '0x573Df0Eb2F042bf92a897A5C37c144F717Ed1dd7', to: '$RECV_ADDR', value: web3.toWei($ETH_AMOUNT, 'ether')})" "$TARGET_IPC" | tr -d '"\r')
    
    if [[ "$TX_HASH" == *"error"* || -z "$TX_HASH" ]]; then
        log_error "Transaction failed: $TX_HASH"
    else
        log_success "Transaction sent! Hash: $TX_HASH"
        log_info "Wait for the next block to confirm (approx $BLOCK_TIME seconds)"
    fi
}


reorg_simulation() {
    section "Realistic Reorg Simulation"
    
    read -p "Target reorg depth (blocks): " TARGET_BLOCKS
    [[ ! "$TARGET_BLOCKS" =~ ^[0-9]+$ || "$TARGET_BLOCKS" -le 0 ]] && { log_error "Invalid input"; return; }

    read -p "Mining handicap (blocks to pause mining, e.g. 1-3): " HANDICAP
    [[ ! "$HANDICAP" =~ ^[0-9]+$ ]] && {
        log_error "Invalid handicap value"
        return
    }

    # 1. Capture and Disconnect Peers
    log_warn "Capturing current peers and simulating network partition..."
    
    SAVED_PEERS=$(run_js_out "admin.peers.map(p => p.enode).join('||')" "$IPC_A" | tr -d '"\r' | sed 's/||/\n/g')

    if [[ -z "$SAVED_PEERS" || "$SAVED_PEERS" == "undefined" || "$SAVED_PEERS" == "" ]]; then
        log_warn "No connected peers found to disconnect."
    else
        echo -e "$SAVED_PEERS" | while IFS= read -r PEER; do
            [[ -z "$PEER" ]] && continue
            log_info "Removing peer: $PEER"
            run_js "admin.removePeer(\"$PEER\")" "$IPC_A"
        done
        log_success "Partition active (Node A isolated)."
    fi

    # 2. Handicap Period (Node A waits while others mine)
    if [[ "$HANDICAP" -gt 0 ]]; then
        H_DELAY=$((HANDICAP * BLOCK_TIME))
        log_warn "Handicap active: Node A waiting $H_DELAY seconds before mining..."
        sleep "$H_DELAY"
    fi

    # 3. Mine Node A while partitioned (Fork start)
    log_info "Node A starting private mining for fork..."
    run_js "miner.start()" "$IPC_A"

    # 4. Wait for fork growth
    FORK_DELAY=$((TARGET_BLOCKS * BLOCK_TIME))
    log_info "Waiting $FORK_DELAY seconds for fork growth..."
    sleep "$FORK_DELAY"

    # 5. Stop mining Node A and reconnect to trigger reorg
    log_info "Stopping Node A mining and rejoining network..."
    run_js "miner.stop()" "$IPC_A"
    
    if [[ -n "$SAVED_PEERS" ]]; then
        echo -e "$SAVED_PEERS" | while IFS= read -r PEER; do
            [[ -z "$PEER" ]] && continue
            log_info "Reconnecting peer: $PEER"
            run_js "admin.addPeer(\"$PEER\")" "$IPC_A"
        done
    fi
    
}

attach_console() {
  get_target_ipc
  section "Attaching to Node $TARGET_NAME Console"
  log_info "Type 'exit' to return to simulator"
  $GETH_BIN attach "$TARGET_IPC"
}

# ---------- Main Loop ----------
menu() {
    echo -e "${BLUE}  ════════════════════════════════════════════════════════════════════════════${NC}"
  
  echo -e "${BOLD}${WHITE}  [ NETWORK MANAGEMENT ]${NC}"
  echo -e "   1) ${GREEN}Run All Nodes${NC}           (Start A, B, C)"
  echo -e "   2) ${YELLOW}Init Genesis Block${NC}      (Required once)"
  echo -e "   3) ${GREEN}${BOLD}Faucet${NC}                  (Send ETH to address)"
  
  echo -e "\n  ${BOLD}${WHITE}  [ MONITORING ]${NC}"
  echo -e "   4) Show Block Number"
  echo -e "   5) List Peers"
  echo -e "   6) View Enode"
  
  echo -e "\n  ${BOLD}${WHITE}  [ FORK & MINING ]${NC}"
  echo -e "   7) ${MAGENTA}${BOLD}Simulate REORG${NC}          (Partition & Mine A)"
  echo -e "   8) Stop Mining"
  echo -e "   9) Start Mining"
  
  echo -e "\n  ${BOLD}${WHITE}  [ TOOLS ]${NC}"
  echo -e "   10) ${CYAN}${BOLD}Attach Geth Console${NC}"
  echo -e "   11) ${RED}Clean All Data${NC}          (Wipe chain)"
  echo -e "   c) Clear Logs              (Console cleanup)"
  echo -e "   h) Show Menu               (Help)"
  echo -e "   0) Exit"
  echo -e "${BLUE}  ════════════════════════════════════════════════════════════════════════════${NC}"
  echo
}

display_menu() {
  echo -e "${CYAN}  ██████╗ ███████╗████████╗██╗  ██╗    ██████╗ ███████╗ ██████╗ ██████╗  ██████╗ ${NC}"
  echo -e "${CYAN} ██╔════╝ ██╔════╝╚══██╔══╝██║  ██║    ██╔══██╗██╔════╝██╔═══██╗██╔══██╗██╔════╝ ${NC}"
  echo -e "${CYAN} ██║  ███╗█████╗     ██║   ███████║    ██████╔╝█████╗  ██║   ██║██████╔╝██║  ███╗${NC}"
  echo -e "${CYAN} ██║   ██║██╔══╝     ██║   ██╔══██║    ██╔══██╗██╔══╝  ██║   ██║██╔══██╗██║   ██║${NC}"
  echo -e "${CYAN} ╚██████╔╝███████╗   ██║   ██║  ██║    ██║  ██║███████╗╚██████╔╝██║  ██║╚██████╔╝${NC}"
  echo -e "${CYAN}  ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ${NC}"
  echo -e "${CYAN}                             [ REACH FORK SIMULATOR v1 ]                       ${NC}"
  echo -e "${CYAN}                                  (WINDOWS HOST MODE)                          ${NC}"
  
  echo -e "\n  ${WHITE}Status: $(get_status)${NC} | ${DIM}Env: Windows Host${NC} | ${DIM}Path: $DATA_DIR${NC}"
  menu
}

# ---------- Main Loop ----------
# Trap Ctrl+C (SIGINT) to prevent accidental exit
trap ":" SIGINT
# Keep EXIT trap for node cleanup
trap stop_nodes EXIT

clear
display_menu

while true; do
  # read returns false on Ctrl+D (EOF)
  if ! read -e -p "Select option: " choice; then
    echo -e "\n  [CTRL+D detected. Exiting...]"
    exit 0
  fi
  
  history -s "$choice" 2>/dev/null # Save to session history

  case "$choice" in
    h|H|help) echo; menu ;;
    1) start_nodes; read -n 1 -s -r -p "[Press any key to continue...]"; clear; display_menu ;;
    2) init_genesis; read -n 1 -s -r -p "[Press any key to continue...]"; clear; display_menu ;;
    3) faucet; echo "" ;;
    4) show_block; echo "" ;;
    5) list_peers; echo "" ;;
    6) get_target_ipc; run_js_out "admin.nodeInfo.enode" "$TARGET_IPC"; echo "" ;;
    7) reorg_simulation; echo "" ;;
    8) get_target_ipc; run_js "miner.stop()" "$TARGET_IPC"; log_success "Mining stopped on Node $TARGET_NAME"; echo "" ;;
    9) get_target_ipc; run_js "miner.start()" "$TARGET_IPC"; log_success "Mining started on Node $TARGET_NAME"; echo "" ;;
    10) attach_console ;;
    11) clean_nodes; read -n 1 -s -r -p "[Press any key to continue...]"; clear; display_menu ;;
    c|C|clear) clear; display_menu ;;
    0) exit 0 ;;
    *) log_warn "Invalid option"; sleep 1 ;;
  esac
done
