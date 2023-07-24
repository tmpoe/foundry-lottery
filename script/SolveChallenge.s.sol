// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

import {Config} from "./Config.s.sol";
import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {console} from "forge-std/console.sol";

contract SolveChallengeNine {
    error NotSolved(uint256 guess, uint256 solution);
    address constant lessonNineCtr = 0x33e1fD270599188BB1489a169dF1f0be08b83509;

    function solve() public {
        uint256 sol = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.prevrandao, block.timestamp)
            )
        ) % 100000;

        console.log("Solving with ", msg.sender);
        (bool success, bytes memory data) = lessonNineCtr.delegatecall(
            abi.encodeWithSignature(
                "solveChallenge(uint256,string)",
                sol,
                "@its_a_me_TMP"
            )
        );
        require(success);
        uint256 solution = abi.decode(data, (uint256));
        if (sol != solution) {
            revert NotSolved({guess: sol, solution: solution});
        }
    }
}

contract DeployAndRunSolveChallenge is Script {
    SolveChallengeNine solveChallenge;

    function run() external {
        Config config = new Config();
        (, , , , , , , uint256 deployerKey) = config.activeNetworkConfig();

        vm.startBroadcast(deployerKey);

        solveChallenge = new SolveChallengeNine();
        console.log("Solving challenge: ", address(solveChallenge));
        solveChallenge.solve();

        vm.stopBroadcast();
    }
}

contract LessonNineMock {
    function solveChallenge(
        uint256 randomGuess,
        string memory yourTwitterHandle
    ) external {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////// The following are functions needed for the NFT, feel free to ignore. ///////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function description() external pure returns (string memory) {}

    function attribute() external pure returns (string memory) {}

    function specialImage() external pure returns (string memory) {}
}

contract Simulation {
    function getNumber() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.prevrandao,
                        block.timestamp
                    )
                )
            ) % 100000;
    }
}
