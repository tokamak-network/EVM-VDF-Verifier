// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RNGConsumerBase} from "./RNGConsumerBase.sol";
import {ICRRRNGCoordinator} from "./interfaces/ICRRRNGCoordinator.sol";
import "./libraries/BigNumbers.sol";

contract AirdropConsumer is RNGConsumerBase {
    /* Type declaration */
    using BigNumbers for *;
    struct RoundStatus {
        uint256 requestId;
        bool registrationStarted;
        bool randNumRequested;
        bool randNumfulfilled;
    }

    /* State Variables */
    mapping(address participantAddress => uint256[] randomAirdropRounds)
        private s_participatedRounds;
    mapping(address participantAddress => mapping(uint256 randomAirdropRound => uint256 registerIndex))
        private s_registerIndexPlusOneAtRound;
    mapping(uint256 randomAirdropRound => address[] participants) private s_participantsAtRound;
    mapping(uint256 randomAirdropRound => RoundStatus) private s_roundStatus;
    mapping(uint256 requestId => uint256 randomAirdropRound) private s_requestIdToRound;
    mapping(uint256 randomAirdropRound => BigNumber omega) private s_randomNum;
    uint256 private s_nextRandomAirdropRound;
    uint256 private s_startRegistrationTime;
    uint256 private s_registrationDuration;

    error InvalidDuration();
    error RegisterAlreadyStarted();
    error RegistrationInProgress();
    error RegisterNotStarted();
    error RegistrationFinished();
    error AlreadyRegistered();
    error NoneParticipated();
    error AlreadyRequested(uint256 round);
    error AlreadyFulfilled(uint256 round);

    event StartRegistration(uint256 randomAirdropRound);
    event Registered(address participantAddress, uint256 timestamp);

    constructor(address rngCoordinator) RNGConsumerBase(rngCoordinator) {}

    function startRegistration(uint256 registrationDuration) external {
        if (s_nextRandomAirdropRound > 0) {
            uint256 _currentRandomAirdropRound = s_nextRandomAirdropRound - 1;
            if (s_roundStatus[_currentRandomAirdropRound].registrationStarted) {
                if (s_participantsAtRound[_currentRandomAirdropRound].length > 0)
                    revert RegisterAlreadyStarted();
                if (block.timestamp <= s_startRegistrationTime + s_registrationDuration)
                    revert RegistrationInProgress();
            }
        }
        s_startRegistrationTime = block.timestamp;
        s_registrationDuration = registrationDuration;
        s_roundStatus[s_nextRandomAirdropRound].registrationStarted = true;
        ++s_nextRandomAirdropRound;
        emit StartRegistration(s_nextRandomAirdropRound);
    }

    function register() external {
        uint256 _round = s_nextRandomAirdropRound;
        if (!s_roundStatus[_round].registrationStarted) revert RegisterNotStarted();
        if (block.timestamp > s_startRegistrationTime + s_registrationDuration)
            revert RegistrationFinished();
        if (s_registerIndexPlusOneAtRound[msg.sender][_round] != 0) revert AlreadyRegistered();
        s_participantsAtRound[_round].push(msg.sender);
        s_registerIndexPlusOneAtRound[msg.sender][_round] = s_participantsAtRound[_round].length;
        s_participatedRounds[msg.sender].push(_round);
        emit Registered(msg.sender, block.timestamp);
    }

    function requestRandomWord(uint256 round) external {
        //check
        // registration should be finished
        if (!s_roundStatus[round].registrationStarted) revert RegisterNotStarted();
        if (block.timestamp <= s_startRegistrationTime + s_registrationDuration)
            revert RegistrationInProgress();
        if (s_participantsAtRound[round].length == 0) revert NoneParticipated();

        if (s_roundStatus[round].randNumRequested) revert AlreadyRequested(round);
        // effect
        s_roundStatus[round].randNumRequested = true;
        // interaction
        uint256 _requestId = ICRRRNGCoordinator(i_rngCoordinator).requestRandomWord();
        s_roundStatus[round].requestId = _requestId;
        s_requestIdToRound[_requestId] = round;
    }

    function fulfillRandomWords(
        uint256 requestId,
        bytes memory omegaVal,
        uint256 omegaBitLen
    ) internal override {
        //check
        uint256 _round = s_requestIdToRound[requestId];
        if (s_roundStatus[_round].randNumfulfilled) revert AlreadyFulfilled(_round);
        // effect, Do something with the random words
        s_roundStatus[_round].randNumfulfilled = true;
        s_randomNum[_round] = BigNumber(omegaVal, omegaBitLen);
    }
}
