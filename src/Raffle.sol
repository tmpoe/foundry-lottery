// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughEthToEnter();
    error Raffle__RaffleIsNotOpen();
    error Raffle__NotEnoughTimePassed();
    error Raffle__WinnerTransferFailed();

    enum RaffleState {
        OPEN,
        CLOSED
    }

    uint32 private constant NUM_RANDOM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;

    uint256 private immutable i_entranceFee;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_lengthOfRaffle;

    address payable[] private s_participants;
    uint256 private s_currentRaffleNumber = 0;
    uint256 private s_startOfRaffle = block.timestamp;
    RaffleState private s_raffleState = RaffleState.OPEN;

    event Entered(address indexed participant, uint256 raffleNumber);
    event Winner(address indexed winner, uint256 raffleNumber);

    constructor(
        uint256 entranceFee,
        address vrfCoordinator,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        bytes32 gasLane,
        uint256 lengthOfRaffle
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_gasLane = gasLane;
        i_lengthOfRaffle = lengthOfRaffle;
    }

    function enter() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEthToEnter();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleIsNotOpen();
        }

        s_participants.push(payable(msg.sender));
        emit Entered(msg.sender, s_currentRaffleNumber);
    }

    function pickWinner() public {
        if (block.timestamp - s_startOfRaffle < i_lengthOfRaffle) {
            revert Raffle__NotEnoughTimePassed();
        }
        s_raffleState = RaffleState.CLOSED;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_RANDOM_WORDS
        );
    } // only owner? only chainlink?

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 indexOfWinner = randomWords[0] % s_participants.length;
        address payable winner = s_participants[indexOfWinner];
        emit Winner(winner, s_currentRaffleNumber++);
        delete s_participants;
        s_startOfRaffle = block.timestamp;
        s_raffleState = RaffleState.OPEN;

        // call will not run out of gas, transfer could and I would not want to have the funds get stuck
        (bool success, ) = payable(winner).call{value: address(this).balance}(
            ""
        );
        if (!success) {
            revert Raffle__WinnerTransferFailed();
        }
    }

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
