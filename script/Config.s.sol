// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract Config is Script {
    struct NetworkConfig {
        uint256 entranceFee;
        address vrfCoordinatorAddress;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        bytes32 gasLane;
        uint256 lengthOfRaffle;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getSepoliaConfig() private pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                vrfCoordinatorAddress: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                subscriptionId: 415,
                callbackGasLimit: 500000,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                lengthOfRaffle: 30
            });
    }

    function getAnvilConfig() private returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinatorAddress != address(0)) {
            return activeNetworkConfig;
        }
        uint96 baseFee = 0.25 ether; // LINK
        uint96 gasPriceLink = 1e9; // 1 qwei of LINK
        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        vm.stopBroadcast();
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                vrfCoordinatorAddress: address(vrfCoordinator),
                subscriptionId: 0,
                callbackGasLimit: 500000,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                lengthOfRaffle: 30
            });
    }
}
