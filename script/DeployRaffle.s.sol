// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {Config} from "./Config.s.sol";

contract DeployRaffle is Script {
    function run() external returns (Raffle) {
        Config config = new Config();
        (
            uint256 entraceFee,
            address vrfCoordinatorAddress,
            uint64 subscriptionId,
            uint32 callbackGasLimit,
            bytes32 gasLane,
            uint256 lengthOfRaffle
        ) = config.activeNetworkConfig();
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            entraceFee,
            vrfCoordinatorAddress,
            subscriptionId,
            callbackGasLimit,
            gasLane,
            lengthOfRaffle
        );
        vm.stopBroadcast();
        return raffle;
    }
}
