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
    uint256 entraceFee;
    address vrfCoordinatorAddress;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    bytes32 gasLane;
    uint256 lengthOfRaffle;

    address USER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, config) = deployRaffle.run();

        (
            entraceFee,
            vrfCoordinatorAddress,
            subscriptionId,
            callbackGasLimit,
            gasLane,
            lengthOfRaffle
        ) = config.activeNetworkConfig();

        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testStateAtStart() public {
        assert(raffle.getState() == 0);
    }
}
