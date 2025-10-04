# Raffle Smart Contract

A provably fair, automated lottery system built with Solidity and Foundry that uses Chainlink VRF for verifiable randomness and Chainlink Automation for trustless upkeep execution.

## Features

- **Provably fair randomness**: Chainlink VRF V2 ensures tamper-proof winner selection
- **Automated upkeep**: Chainlink Automation triggers lottery draws automatically
- **Time-based intervals**: Configurable lottery duration with automated resets
- **Gas optimized**: Uses immutable variables, custom errors, and efficient storage patterns
- **Player limit protection**: Maximum 1000 players per round to prevent DoS attacks
- **Event-driven transparency**: All critical actions emit events for tracking
- **Multi-network support**: Deployable on Ethereum Sepolia and local Anvil networks
- **Comprehensive testing**: Unit tests, staging tests, and fuzz tests included

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- Chainlink VRF V2 Subscription (for testnet/mainnet)

### Installation

```bash
git clone <your-repo-url>
cd raffle-lottery
forge install
```

### Environment Setup

Create a `.env` file:
```bash
SEPOLIA_RPC_URL=your_sepolia_rpc_url
PRIVATE_KEY=your_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Usage

### Deploy

```bash
# Deploy to local anvil
forge script script/DeployRaffle.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to Sepolia testnet
forge script script/DeployRaffle.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

### Create and Fund VRF Subscription

```bash
# Create subscription
forge script script/Interactions.s.sol:CreateSubscription --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast

# Fund subscription with LINK
forge script script/Interactions.s.sol:FundSubscription --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Add Consumer to Subscription

```bash
forge script script/Interactions.s.sol:AddConsumer --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Enter Raffle

```bash
cast send <RAFFLE_ADDRESS> "enterRaffle()" --value 0.01ether --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Manually Trigger Upkeep (Testing)

```bash
forge script script/Interactions.s.sol:PerformUpkeep --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Check Raffle Status

```bash
# Check entrance fee
cast call <RAFFLE_ADDRESS> "getEntranceFee()(uint256)" --rpc-url $SEPOLIA_RPC_URL

# Check number of players
cast call <RAFFLE_ADDRESS> "getNumPlayers()(uint256)" --rpc-url $SEPOLIA_RPC_URL

# Check raffle state (0=OPEN, 1=CALCULATING)
cast call <RAFFLE_ADDRESS> "getRaffleState()(uint8)" --rpc-url $SEPOLIA_RPC_URL

# Check recent winner
cast call <RAFFLE_ADDRESS> "getRecentWinner()(address)" --rpc-url $SEPOLIA_RPC_URL
```

## Contract Architecture

### Core Contract

- **Raffle.sol**: Main lottery contract implementing VRF and Automation

### Key Components

#### Raffle States

```solidity
enum RaffleState {
    OPEN,
    CALCULATING
}
```

- **OPEN**: Players can enter the raffle
- **CALCULATING**: Waiting for VRF to return random number

#### Core Functions

- `enterRaffle()`: Players pay entrance fee to join the lottery
- `checkUpkeep()`: Chainlink Automation calls this to check if upkeep is needed
- `performUpkeep()`: Triggers VRF request when conditions are met
- `fulfillRandomWords()`: VRF callback that selects winner and transfers prize

#### Getter Functions

- `getEntranceFee()`: Returns required entrance fee in wei
- `getPlayer(uint256)`: Returns player address at given index
- `getRecentWinner()`: Returns address of most recent winner
- `getRaffleState()`: Returns current raffle state
- `getNumPlayers()`: Returns total number of current players
- `getLastTimeStamp()`: Returns timestamp of last lottery draw
- `getInterval()`: Returns configured lottery interval

### Deployment Scripts

- **DeployRaffle.s.sol**: Main deployment script with subscription setup
- **HelperConfig.s.sol**: Network configuration for Sepolia and Anvil
- **Interactions.s.sol**: Scripts for subscription management and upkeep

## Testing

Run the complete test suite:

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test file
forge test --match-path test/unit/RaffleTest.t.sol

# Run staging tests (Sepolia only)
forge test --match-path test/staging/RaffleStagingTest.t.sol --fork-url $SEPOLIA_RPC_URL
```

### Test Coverage

#### Unit Tests

- **Initialization**: Raffle starts in OPEN state
- **Entry Requirements**: Reverts when payment is insufficient
- **Player Tracking**: Records players correctly
- **Event Emission**: Emits RaffleEnter event on entry
- **State Transitions**: Cannot enter during CALCULATING state
- **Upkeep Conditions**: Validates all checkUpkeep requirements
- **Random Winner Selection**: Winner selection and prize distribution
- **Fuzz Tests**: Entrance fee validation, multiple players, random selection

#### Staging Tests (Testnet)

- **Live Entry**: Users can enter raffle on testnet
- **Upkeep Execution**: CheckUpkeep works correctly on testnet
- **State Changes**: Raffle state transitions properly
- **Multiple Players**: Multiple users can participate
- **Getter Functions**: All view functions return correct values
- **Contract Health**: Verifies deployment and functionality

## Security Features

- **Chainlink VRF**: Tamper-proof randomness prevents manipulation
- **Automated Execution**: Chainlink Automation removes need for trusted operators
- **Player Limit**: Maximum 1000 players prevents gas limit DoS attacks
- **State Machine**: Raffle state prevents entries during winner calculation
- **Custom Errors**: Gas-efficient error handling with descriptive messages
- **Immutable Variables**: Critical parameters cannot be changed post-deployment
- **Safe Transfers**: Uses low-level call for ETH transfers with failure handling

## Gas Optimization

- Custom errors instead of require strings
- Immutable variables for constant values
- Efficient storage with dynamic arrays
- Event emission for off-chain data tracking
- Enum for state management
- Constants for fixed values

## Upkeep Conditions

Chainlink Automation triggers `performUpkeep` when all conditions are met:

1. **Raffle is OPEN**: Not currently calculating a winner
2. **Time has passed**: Current time exceeds last timestamp plus interval
3. **Has players**: At least one player has entered
4. **Has balance**: Contract holds ETH from entry fees

## Chainlink Integration

### VRF V2 Configuration

- **Request Confirmations**: 3 blocks
- **Number of Random Words**: 1
- **Callback Gas Limit**: Configurable (default 500,000)
- **Gas Lane**: Network-specific key hash

### Automation Configuration

The contract implements `AutomationCompatibleInterface` for automated lottery draws based on time intervals.

## Network Configuration

### Sepolia Testnet

- **VRF Coordinator**: `0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B`
- **LINK Token**: `0x779877A7B0D9E8603169DdbD7836e478b4624789`
- **Gas Lane**: `0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c`
- **Entrance Fee**: 0.01 ETH
- **Interval**: 30 seconds (configurable)

### Local Anvil

- **Mock VRF Coordinator**: Deployed automatically
- **Mock LINK Token**: Deployed automatically
- **Entrance Fee**: 0.01 ETH
- **Interval**: 30 seconds

## Lottery Mechanics

### Entry Process

1. Player calls `enterRaffle()` with minimum entrance fee
2. Contract validates payment and raffle state
3. Player address added to players array
4. RaffleEnter event emitted

### Winner Selection Process

1. Time interval passes and conditions are met
2. Chainlink Automation calls `performUpkeep()`
3. Raffle state changes to CALCULATING
4. VRF request is made for random number
5. Chainlink VRF calls `fulfillRandomWords()` with randomness
6. Winner is selected using modulo operation
7. Prize transferred to winner
8. Players array reset and raffle reopens
9. WinnerPicked event emitted

## Error Handling

- `Raffle__NotEnoughETH`: Sent value below entrance fee
- `Raffle__TransferFailed`: ETH transfer to winner failed
- `Raffle__NotOpen`: Attempted entry during CALCULATING state
- `Raffle__UpkeepNotNeeded`: Upkeep conditions not met
- `Raffle__MaxPlayersReached`: Player limit exceeded

## Events

- `RaffleEnter(address indexed player)`: Emitted when player enters
- `RequestedRaffleWinner(uint256 indexed requestId)`: Emitted when VRF request made
- `WinnerPicked(address indexed winner)`: Emitted when winner selected and paid

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [Chainlink VRF Documentation](https://docs.chain.link/vrf/v2/introduction)
- [Chainlink Automation Documentation](https://docs.chain.link/chainlink-automation/introduction)
- [Solidity Documentation](https://docs.soliditylang.org/)
