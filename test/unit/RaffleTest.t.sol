// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {console} from "forge-std/console.sol";
import {Config} from "../../script/Config.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract RaffleTest is Test {
    Raffle raffle;
    Config config;
    uint256 lengthOfRaffle;
    uint256 subId;
    address vrfCoordinatorAddress;

    address USER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    event Entered(address indexed participant, uint256 raffleNumber);
    event Winner(address indexed winner, uint256 raffleNumber);
    event IdleRaffleReset(uint256 raffleNumber);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, config) = deployRaffle.run();

        (, vrfCoordinatorAddress, subId, , , lengthOfRaffle, , ) = config
            .activeNetworkConfig();

        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testCanEnter() public prankUser(USER) {
        assert(address(raffle).balance == 0);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit Entered(USER, 0);
        raffle.enter{value: 10000000000000000}();
        assert(raffle.getNumberOfParticipants() == 1);
        assert(raffle.getParticipant(0) == USER);
        assert(address(raffle).balance > 0);
    }

    function testCantEnterWithoutEnoughEth() public prankUser(USER) {
        assert(address(raffle).balance == 0);
        vm.expectRevert(Raffle.Raffle__NotEnoughEthToEnter.selector);
        raffle.enter{value: 100}();
        assert(address(raffle).balance == 0);
    }

    function testCantEnterWhenNotOpen() public {
        enterUser(USER);
        performValidUpdate();
        vm.expectRevert(Raffle.Raffle__RaffleIsNotOpen.selector);
        raffle.enter{value: 10000000000000000}();
    }

    function testCheckUpkeep_notNeededIfNotOpen() public {
        enterUser(USER);
        performValidUpdate();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function testWinnerIsPicked() public skipOnFork {
        for (uint256 i = 1; i < 10; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether);
            raffle.enter{value: 10000000000000000}();
        }
        bytes32 requestId = performValidUpdate();

        vm.warp(block.timestamp + lengthOfRaffle + 1);
        vm.roll(block.number + 3);

        assert(address(raffle).balance != 0);
        uint256 originalStartOfRaffle = raffle.getStartOfRaffle();

        vm.recordLogs();
        VRFCoordinatorV2Mock(vrfCoordinatorAddress).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );
        Vm.Log[] memory entries = vm.getRecordedLogs();

        address winner = address(uint160(uint256(entries[0].topics[1])));

        uint256 postWinUserBalance = winner.balance;
        assert(postWinUserBalance > 1 ether);
        assert(address(raffle).balance == 0);

        uint256 newStartOfRaffle = raffle.getStartOfRaffle();
        assert(newStartOfRaffle > originalStartOfRaffle);
    }

    function testRestartRaffleOnIdle() public {
        vm.warp(block.timestamp + lengthOfRaffle + 1);
        vm.roll(block.number + 1);

        uint256 originalStartOfRaffle = raffle.getStartOfRaffle();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == true);

        vm.expectEmit(false, false, false, true, address(raffle));
        emit IdleRaffleReset(0);
        raffle.performUpkeep("");
        uint256 newStartOfRaffle = raffle.getStartOfRaffle();
        assert(newStartOfRaffle > originalStartOfRaffle);
    }

    function enterUser(address user) internal {
        vm.startPrank(user);
        raffle.enter{value: 10000000000000000}();
        vm.stopPrank();
    }

    function performValidUpdate() internal returns (bytes32 requestId) {
        vm.warp(block.timestamp + lengthOfRaffle + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        raffle.performUpkeep("");

        Vm.Log[] memory entries = vm.getRecordedLogs();

        requestId = entries[1].topics[1];
        console.log("requestId: %s", uint256(requestId));

        assert(raffle.getState() == uint256(Raffle.RaffleState.CLOSED));
        return requestId;
    }

    modifier prankUser(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }

    modifier skipOnFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }
}
