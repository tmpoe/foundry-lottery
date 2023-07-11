// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Config} from "./Config.s.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract CreateVrfSubscription is Script {
    function run() external returns (uint64) {
        return createSubscriptionByConfig();
    }

    function createSubscriptionByConfig() public returns (uint64) {
        address vrfCoordinatorAddress = getVrfCoordinatorAddress();
        return createSubscription(vrfCoordinatorAddress);
    }

    function createSubscription(
        address vrfCoordinatorAddress
    ) public returns (uint64) {
        VRFCoordinatorV2Mock vrfCoordinator = VRFCoordinatorV2Mock(
            vrfCoordinatorAddress
        );

        vm.startBroadcast();
        uint64 subId = vrfCoordinator.createSubscription();
        vm.stopBroadcast();
        return subId;
    }

    function getVrfCoordinatorAddress() internal returns (address) {
        Config config = new Config();
        (, address vrfCoordinatorAddress, , , , ) = config
            .activeNetworkConfig();
        return vrfCoordinatorAddress;
    }
}
