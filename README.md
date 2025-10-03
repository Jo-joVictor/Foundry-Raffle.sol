# Raffle Lottery Smart Contract

## Overview
This project is a decentralized raffle (lottery) smart contract built with Solidity.  
It uses Chainlink VRF v2.5 for provably fair randomness and Chainlink Automation to automatically trigger winner selection at fixed time intervals.

Players enter by paying a set entrance fee. After the interval has passed, a random winner is selected, and all ETH in the contract is transferred to the winner. The contract then resets for the next round.

---

## Features
- Secure state machine using `enum` for raffle state.
- Gas-optimized custom errors.
- Events for transparency (`RaffleEnter`, `RequestedRaffleWinner`, `WinnerPicked`).
- Follows the CEI (Checks-Effects-Interactions) pattern.
- Includes unit and staging tests.

---

## How It Works
1. Players call `enterRaffle()` with at least the entrance fee.
2. Chainlink Automation checks conditions:
   - Time interval has passed.
   - Raffle is open.
   - At least one player entered.
   - Contract holds ETH.
3. If true, `performUpkeep()` requests randomness from Chainlink VRF.
4. `fulfillRandomWords()` selects a random winner and transfers the prize.
5. The raffle resets.

---

## Configuration
Replace the placeholder values with actual values before deployment:

```solidity
address constant VRF_COORDINATOR = 0x...; // Network VRF Coordinator
bytes32 constant GAS_LANE = 0x...;        // KeyHash
uint64 constant SUBSCRIPTION_ID = 1234;   // Your Chainlink subscription ID
uint32 constant CALLBACK_GAS_LIMIT = 500000;
uint256 constant ENTRANCE_FEE = 0.01 ether;
uint256 constant INTERVAL = 604800;       // 1 week

**Live Contract:** `0xaC48b201E9D3f27076Da1Bb518E194B88B5288fe` (Sepolia)

forge script script/DeployRaffle.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast

flowchart TD
    A[Players Enter Raffle] --> B[Wait for Interval]
    B --> C[Automation Triggers Upkeep]
    C --> D[VRF Randomness Request]
    D --> E[VRF Returns Random Number]
    E --> F[Winner Selected]
    F --> G[ETH Transferred to Winner]
    G --> H[Raffle Resets]
