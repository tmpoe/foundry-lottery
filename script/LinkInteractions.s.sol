// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Config} from "./Config.s.sol";
import {console} from "forge-std/console.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.m.sol";

contract CreateVrfSubscription is Script {
    function run() external returns (uint64) {
        return createSubscriptionByConfig();
    }

    function createSubscriptionByConfig() public returns (uint64) {
        Config config = new Config();
        (, address vrfCoordinatorAddress, , , , , ) = config
            .activeNetworkConfig();
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
            address linkTokenAddress
        ) = config.activeNetworkConfig();
        fundSubscription(vrfCoordinatorAddress, subId, linkTokenAddress);
    }

    function fundSubscription(
        address vrfCoordinatorAddress,
        uint64 subId,
        address linkTokenAddress
    ) public {
        if (block.chainid == 31337) {
            VRFCoordinatorV2Mock(vrfCoordinatorAddress).fundSubscription(
                subId,
                FUND_AMOUNT
            );
        } else {
            LinkToken(linkTokenAddress).transferAndCall(
                vrfCoordinatorAddress,
                FUND_AMOUNT,
                abi.encode(subId)
            );
        }
    }

    function run() external {
        fundSubscriptionByConfig();
    }
}
