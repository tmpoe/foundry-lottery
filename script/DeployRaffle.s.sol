// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {Config} from "./Config.s.sol";
import {CreateVrfSubscription, FundSubscription} from "./LinkInteractions.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle, Config) {
        Config config = new Config();
        (
            uint256 entraceFee,
            address vrfCoordinatorAddress,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            bytes32 gasLane,
            uint256 lengthOfRaffle,
            address linkTokenAddress
        ) = config.activeNetworkConfig();

        if (subscriptionId == 0) {
            CreateVrfSubscription createVrfSubscription = new CreateVrfSubscription();
            subscriptionId = createVrfSubscription.createSubscription(
                vrfCoordinatorAddress
            );
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(
                vrfCoordinatorAddress,
                subscriptionId,
                linkTokenAddress
            );
        }
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entraceFee,
            vrfCoordinatorAddress,
            subscriptionId,
            callbackGasLimit,
            gasLane,
            lengthOfRaffle
        );
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = VRFCoordinatorV2Mock(
            vrfCoordinatorAddress
        );
        vrfCoordinatorV2Mock.addConsumer(subscriptionId, address(raffle));
        vm.stopBroadcast();
        return (raffle, config);
    }
}
