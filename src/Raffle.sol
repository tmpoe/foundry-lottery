// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

contract Raffle {
    error Raffle__NotEnoughEthToEnter();

    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enter() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthToEnter();
        }
    }

    function pickWinner() public {} // only owner? only chainlink?
}
