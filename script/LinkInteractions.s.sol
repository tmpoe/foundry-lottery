// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Config} from "./Config.s.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.m.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract CreateVrfSubscription is Script {
    function run() external returns (uint64) {
        return createSubscriptionByConfig();
    }

    function createSubscriptionByConfig() public returns (uint64) {
        Config config = new Config();
        (
            ,
            address vrfCoordinatorAddress,
            ,
            ,
            ,
            ,
            ,
            uint256 deployerKey
        ) = config.activeNetworkConfig();
        return createSubscription(vrfCoordinatorAddress, deployerKey);
    }

    function createSubscription(
        address vrfCoordinatorAddress,
        uint256 deployerKey
    ) public returns (uint64) {
        VRFCoordinatorV2Mock vrfCoordinator = VRFCoordinatorV2Mock(
            vrfCoordinatorAddress
        );
        console.log("Creating sub from ", deployerKey);
        vm.startBroadcast(deployerKey);
        uint64 subId = vrfCoordinator.createSubscription();
        vm.stopBroadcast();
        return subId;
    }
}

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionByConfig() public {
        Config config = new Config();
        (
            ,
            address vrfCoordinatorAddress,
            uint64 subId,
            ,
            ,
            ,
            address linkTokenAddress,
            uint256 deployerKey
        ) = config.activeNetworkConfig();
        fundSubscription(
            vrfCoordinatorAddress,
            subId,
            linkTokenAddress,
            deployerKey
        );
    }

    function fundSubscription(
        address vrfCoordinatorAddress,
        uint64 subId,
        address linkTokenAddress,
        uint256 deployerKey
    ) public {
        console.log("Funding sub from ", deployerKey);

        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinatorAddress).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkTokenAddress).transferAndCall(
                vrfCoordinatorAddress,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionByConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerByConfig() public {
        Config config = new Config();
        (
            ,
            address vrfCoordinatorAddress,
            uint64 subId,
            ,
            ,
            ,
            ,
            uint256 deployerKey
        ) = config.activeNetworkConfig();
        address raffleAddress = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumer(vrfCoordinatorAddress, subId, raffleAddress, deployerKey);
    }

    function addConsumer(
        address vrfCoordinatorAddress,
        uint64 subId,
        address raffleAddress,
        uint256 deployerKey
    ) public {
        console.log("Adding consumer from ", deployerKey);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinatorAddress).addConsumer(
            subId,
            raffleAddress
        );
        vm.stopBroadcast();
    }

    function run() external {
        addConsumerByConfig();
    }
}
