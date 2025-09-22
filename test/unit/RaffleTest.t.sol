// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    Raffle public raffle;
    HelperConfig public helperConfig;
    
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        vm.deal(PLAYER, STARTING_USER_BALANCE);

        (vrfCoordinator, entranceFee, gasLane, subscriptionId, callbackGasLimit, interval, , ) = helperConfig.activeNetworkConfig();
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert();
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayer() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == PLAYER);
    }

    function testEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEnter(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCantEnterWhenRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        vm.expectRevert();
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpkeepReturnsFalseIfNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTime() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
    }

    function testPerformUpkeepRunsIfCheckUpkeepTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepFalse() public {
        vm.expectRevert();
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        assert(uint256(requestId) > 0);
        assert(uint256(raffle.getRaffleState()) == 1);
    }

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep() public {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(0, address(raffle));
    }

    function testFulfillRandomWordsPicksWinnerResetsAndSendsMoney() public {
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        address recentWinner = raffle.getRecentWinner();
        assert(recentWinner != address(0));
        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getLastTimeStamp() > startingTimeStamp);
    }

    // Fuzz Tests
    function testFuzz_EntranceFeeValidation(uint256 _paymentAmount) public {
        vm.assume(_paymentAmount < entranceFee && _paymentAmount > 0);
        vm.prank(PLAYER);
        vm.expectRevert();
        raffle.enterRaffle{value: _paymentAmount}();
    }

    function testFuzz_MultiplePlayersCanEnter(uint8 _numPlayers) public {
        vm.assume(_numPlayers > 0 && _numPlayers <= 50);
        
        for (uint256 i = 1; i <= _numPlayers; i++) {
            address player = address(uint160(i));
            hoax(player, 10 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        
        assert(raffle.getNumPlayers() == _numPlayers);
    }

    function testFuzz_RandomWinnerSelection(uint256 _randomSeed) public {
        uint256 numPlayers = 10;
        for (uint256 i = 1; i <= numPlayers; i++) {
            address player = address(uint160(i));
            hoax(player, 10 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));
        
        address winner = raffle.getRecentWinner();
        bool isValidWinner = false;
        for (uint256 i = 1; i <= numPlayers; i++) {
            if (winner == address(uint160(i))) {
                isValidWinner = true;
                break;
            }
        }
        assert(isValidWinner);
    }

    function testFuzz_ValidEntranceFeeAmounts(uint256 _paymentAmount) public {
        vm.assume(_paymentAmount >= entranceFee && _paymentAmount <= 100 ether);
        hoax(PLAYER, 200 ether);
        raffle.enterRaffle{value: _paymentAmount}();
        assert(raffle.getPlayer(0) == PLAYER);
    }

    // Getter Tests
    function testGetters() public view {
        assert(raffle.getEntranceFee() == entranceFee);
        assert(raffle.getInterval() == interval);
        assert(raffle.getNumPlayers() == 0);
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }
}