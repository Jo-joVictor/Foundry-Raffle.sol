# Provably Random Raffle Contracts

## About

This code is to create a proveably random smart contract lottery.

## What we want it to do?

1. Users can enter by paying for a ticket
    1. The ticket fees are going to go to the winner during the draw
2. After X period of time, the lottery will automatically draw a winner
    1. And this will be done programatically
3. Using Chainlink VRF & Chainlink Automation
    1. Chainlink VRF => Randomness
    2. Chainlink Automation => Time based trigger
 

 # Provably Fair Raffle

A decentralized raffle using Chainlink VRF for randomness and Automation for execution.

**Live Contract:** `0xaC48b201E9D3f27076Da1Bb518E194B88B5288fe` (Sepolia)

## Features
-  Provably fair randomness
-  Automated winner selection  
-  Gas optimized
-  Comprehensive tests

## Usage
```bash
forge test                    # Run tests
forge script script/DeployRaffle.s.sol --broadcast  # Deploy