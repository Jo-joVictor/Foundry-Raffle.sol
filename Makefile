-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil createSubscription addConsumer fundSubscription performUpkeep enterRaffle

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""
	@echo ""
	@echo "  make fund [ARGS=...]\n    example: make fundSubscription ARGS=\"--network sepolia\""
	@echo ""
	@echo "Available commands:"
	@echo "  all              - Clean, install, update, build"
	@echo "  test             - Run all tests"
	@echo "  test-unit        - Run unit tests only"

	@echo "  test-staging     - Run staging tests on testnet"
	@echo "  test-fuzz        - Run fuzz tests only"
	@echo "  deploy           - Deploy Raffle contract"
	@echo "  createSubscription - Create Chainlink VRF subscription"
	@echo "  fundSubscription - Fund VRF subscription with LINK"
	@echo "  addConsumer      - Add contract as VRF consumer"
	@echo "  performUpkeep    - Manually trigger upkeep"
	@echo "  enterRaffle      - Enter the raffle (0.01 ETH)"
	@echo "  anvil            - Start local Anvil node"
	@echo "  format           - Format code"
	@echo "  snapshot         - Create gas snapshot"

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install cyfrin/foundry-devops@0.2.2 && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 && forge install foundry-rs/forge-std@v1.8.2 && forge install transmissions11/solmate@v6 --no-commit

# Update Dependencies
update:; forge update

build:; forge build

# Test commands
test :; forge test 

test-unit:
	@forge test --match-contract RaffleTest -vvv

test-staging:
	@forge test --match-contract RaffleStagingTest --rpc-url $(SEPOLIA_RPC_URL) -vvv

test-fuzz:
	@forge test --match-test testFuzz -vvv

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# Network configuration
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

# Deployment and interaction commands
deploy:
	@forge script script/DeployRaffle.s.sol:DeployRaffle $(NETWORK_ARGS)

createSubscription:
	@forge script script/Interactions.s.sol:CreateSubscription $(NETWORK_ARGS)

addConsumer:
	@forge script script/Interactions.s.sol:AddConsumer $(NETWORK_ARGS)

fundSubscription:
	@forge script script/Interactions.s.sol:FundSubscription $(NETWORK_ARGS)

performUpkeep:
	@forge script script/Interactions.s.sol:PerformUpkeep $(NETWORK_ARGS)

# Contract interaction commands
enterRaffle:
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	@cast send 0xaC48b201E9D3f27076Da1Bb518E194B88B5288fe "enterRaffle()" --value 0.01ether --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY)
else
	@echo "Please specify network: make enterRaffle ARGS=\"--network sepolia\""
endif

# View functions
checkRaffleState:
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	@cast call 0xaC48b201E9D3f27076Da1Bb518E194B88B5288fe "getRaffleState()" --rpc-url $(SEPOLIA_RPC_URL)
else
	@echo "Please specify network: make checkRaffleState ARGS=\"--network sepolia\""
endif

getNumPlayers:
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	@cast call 0xaC48b201E9D3f27076Da1Bb518E194B88B5288fe "getNumPlayers()" --rpc-url $(SEPOLIA_RPC_URL)
else
	@echo "Please specify network: make getNumPlayers ARGS=\"--network sepolia\""
endif

getRecentWinner:
ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	@cast call 0xaC48b201E9D3f27076Da1Bb518E194B88B5288fe "getRecentWinner()" --rpc-url $(SEPOLIA_RPC_URL)
else
	@echo "Please specify network: make getRecentWinner ARGS=\"--network sepolia\""
endif

# Gas reporting
gas-report:
	@forge test --gas-report

# Coverage
coverage:
	@forge coverage --report lcov && genhtml lcov.info --output-directory coverage