// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {console} from "forge-std/console.sol";
import {Config} from "../../script/Config.s.sol";

contract RaffleTest is Test {
    Raffle raffle;
    Config config;
    uint256 lengthOfRaffle;

    address USER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    event Entered(address indexed participant, uint256 raffleNumber);
    event Winner(address indexed winner, uint256 raffleNumber);
    event IdleRaffleReset(uint256 raffleNumber);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, config) = deployRaffle.run();

        (, , , , , lengthOfRaffle, , ) = config.activeNetworkConfig();

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

    function testCantEnterWhenNotOpen() public prankUser(USER) {
        makeRaffleClose();
        vm.expectRevert(Raffle.Raffle__RaffleIsNotOpen.selector);
        raffle.enter{value: 10000000000000000}();
    }

    function testCheckUpkeep_notNeededIfNotOpen() public prankUser(USER) {
        makeRaffleClose();

        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded == false);
    }

    function makeRaffleClose() internal {
        raffle.enter{value: 10000000000000000}();
        vm.warp(block.timestamp + lengthOfRaffle + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        assert(raffle.getState() == uint256(Raffle.RaffleState.CLOSED));
    }

    modifier prankUser(address user) {
        vm.startPrank(user);
        _;
        vm.stopPrank();
    }
}
