// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract RaffleStagingTest is Test {
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed player);

    Raffle public raffle;
    HelperConfig public helperConfig;
    uint256 public entranceFee;
    uint256 public interval;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
            _;
        }
    }

    modifier onlyFork() {
        if (block.chainid == 31337) {
            return;
            _;
        }
        _;
    }

    function setUp() external {
        if (block.chainid == 31337) {
            return;
        }

        raffle = Raffle(DevOpsTools.get_most_recent_deployment("Raffle", block.chainid));
        helperConfig = new HelperConfig();
        (, entranceFee, , , , interval, ,) = helperConfig.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testCanPickWinnerOnTestnet() public onlyFork {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        uint256 startingTimeStamp = raffle.getLastTimeStamp();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        assert(uint256(requestId) > 0);
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
        
        console.log("Request ID:", uint256(requestId));
        console.log("Waiting for Chainlink VRF to fulfill randomness...");
    }

    function testUsersCanEnterRaffleOnTestnet() public onlyFork {
        uint256 initialNumPlayers = raffle.getNumPlayers();
        
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        assert(raffle.getNumPlayers() == initialNumPlayers + 1);
        assert(raffle.getPlayer(initialNumPlayers) == PLAYER);
    }

    function testCheckUpkeepWorksOnTestnet() public onlyFork {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
        
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (upkeepNeeded,) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function testRaffleStateChangesOnTestnet() public onlyFork {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    function testMultiplePlayersCanEnterOnTestnet() public onlyFork {
        uint256 numPlayers = 3;
        uint256 initialNumPlayers = raffle.getNumPlayers();
        
        for (uint256 i = 1; i <= numPlayers; i++) {
            address player = address(uint160(i + 1000));
            hoax(player, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        
        assert(raffle.getNumPlayers() == initialNumPlayers + numPlayers);
        assert(address(raffle).balance >= numPlayers * entranceFee);
    }

    function testGettersWorkOnTestnet() public onlyFork {
        assert(raffle.getEntranceFee() == entranceFee);
        assert(raffle.getInterval() == interval);
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        
        console.log("Entrance Fee:", raffle.getEntranceFee());
        console.log("Interval:", raffle.getInterval());
        console.log("Current Players:", raffle.getNumPlayers());
    }

    function testRaffleIsAlive() public onlyFork {
        assert(address(raffle) != address(0));
        assert(raffle.getEntranceFee() > 0);
        assert(raffle.getInterval() > 0);
        console.log("Raffle is deployed and functional on testnet");
    }

    function testFuzz_StagingEntranceFee(uint256 _payAmount) public onlyFork {
        vm.assume(_payAmount > 0 && _payAmount <= 10 ether);
        
        hoax(PLAYER, 20 ether);
        
        if (_payAmount < entranceFee) {
            vm.expectRevert();
            raffle.enterRaffle{value: _payAmount}();
        } else {
            uint256 initialPlayers = raffle.getNumPlayers();
            raffle.enterRaffle{value: _payAmount}();
            assert(raffle.getNumPlayers() == initialPlayers + 1);
        }
    }
}