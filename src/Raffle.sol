// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

contract Raffle {
    error Raffle__NotEnoughEthToEnter();

    uint256 private immutable i_entranceFee;

    address[] private s_participants;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enter() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthToEnter();
        }
        s_participants.push(msg.sender);
    }

    function pickWinner() public {} // only owner? only chainlink?

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getParticipant(uint256 index) public view returns (address) {
        return s_participants[index];
    }

    function getNumberOfParticipants() public view returns (uint256) {
        return s_participants.length;
    }
}
