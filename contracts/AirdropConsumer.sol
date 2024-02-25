// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RNGConsumerBase} from "./RNGConsumerBase.sol";
import {ICRRRNGCoordinator} from "./interfaces/ICRRRNGCoordinator.sol";
import "./libraries/BigNumbers.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirdropConsumer is RNGConsumerBase, Ownable {
    /* Type declaration */
    using SafeERC20 for IERC20;
    using BigNumbers for *;
    struct RoundStatus {
        uint256 requestId;
        uint256 totalPrizeAmount;
        uint256 prizeAmountStartingAtFifthPlace;
        bool registrationStarted;
        bool randNumRequested;
        bool randNumfulfilled;
    }

    IERC20 private immutable i_airdropToken;
    uint256 private immutable i_firstPlacePrizeAmount;
    uint256 private immutable i_secondtoFourthPlacePrizeAmount;

    /* State Variables */
    mapping(address participantAddress => uint256[] randomAirdropRounds)
        private s_participatedRounds;
    mapping(address participantAddress => mapping(uint256 randomAirdropRound => uint256 registerIndex))
        private s_registerIndexPlusOneAtRound;
    mapping(address participantAddress => mapping(uint256 randomAirdropRound => bool isWithdrawn))
        private s_withdrawn;
    mapping(uint256 randomAirdropRound => address[] participants) private s_participantsAtRound;
    mapping(uint256 randomAirdropRound => RoundStatus) private s_roundStatus;
    mapping(uint256 requestId => uint256 randomAirdropRound) private s_requestIdToRound;
    mapping(uint256 randomAirdropRound => BigNumber omega) private s_randomNum;
    mapping(uint256 randomAirdropRound => mapping(uint256 winnersIndex => uint256 prizeAmount))
        private s_winnersPrizeAmount;
    mapping(uint256 randomAirdropRound => uint256[4] winnersIndex) private s_winnersIndex;
    uint256 private s_nextRandomAirdropRound;
    uint256 private s_startRegistrationTime;
    uint256 private s_registrationDuration;

    error InvalidDuration();
    error RegisterAlreadyStarted();
    error RegistrationInProgress();
    error RegisterNotStarted();
    error RegistrationFinished();
    error AlreadyRegistered();
    error NotRegisteredMsgSender();
    error NoneParticipated();
    error AlreadyWithdrawn();
    error InsufficientBalance();
    error AlreadyRequested(uint256 round);
    error AlreadyFulfilled(uint256 round);
    error RandNumNotFulfilled(uint256 round);

    event StartRegistration(uint256 randomAirdropRound);
    event Registered(address participantAddress, uint256 timestamp);

    constructor(
        address rngCoordinator,
        address airdropToken,
        uint256 firstPlacePrizeAmount,
        uint256 secondtoFourthPlacePrizeAmount
    ) RNGConsumerBase(rngCoordinator) Ownable(msg.sender) {
        require(rngCoordinator != address(0));
        require(airdropToken != address(0));
        require(firstPlacePrizeAmount > 0);
        require(secondtoFourthPlacePrizeAmount > 0);
        i_airdropToken = IERC20(airdropToken);
        i_firstPlacePrizeAmount = firstPlacePrizeAmount;
        i_secondtoFourthPlacePrizeAmount = secondtoFourthPlacePrizeAmount;
    }

    function startRegistration(
        uint256 registrationDuration,
        uint256 totalPrizeAmount
    ) external onlyOwner {
        if (s_nextRandomAirdropRound > 0) {
            if (block.timestamp <= s_startRegistrationTime + s_registrationDuration)
                revert RegistrationInProgress();
            uint256 _currentRound = s_nextRandomAirdropRound - 1;
            if (s_participantsAtRound[_currentRound].length == 0) {
                unchecked {
                    --s_nextRandomAirdropRound;
                }
            }
        }
        s_startRegistrationTime = block.timestamp;
        s_registrationDuration = registrationDuration;
        s_roundStatus[s_nextRandomAirdropRound].registrationStarted = true;
        s_roundStatus[s_nextRandomAirdropRound].totalPrizeAmount = totalPrizeAmount;
        emit StartRegistration(s_nextRandomAirdropRound++);
    }

    function register() external {
        uint256 _round = s_nextRandomAirdropRound - 1;
        if (!s_roundStatus[_round].registrationStarted) revert RegisterNotStarted();
        if (block.timestamp > s_startRegistrationTime + s_registrationDuration)
            revert RegistrationFinished();
        if (s_registerIndexPlusOneAtRound[msg.sender][_round] != 0) revert AlreadyRegistered();
        s_participantsAtRound[_round].push(msg.sender);
        s_registerIndexPlusOneAtRound[msg.sender][_round] = s_participantsAtRound[_round].length;
        s_participatedRounds[msg.sender].push(_round);
        emit Registered(msg.sender, block.timestamp);
    }

    function requestRandomWord(uint256 round) external onlyOwner {
        //check
        if (i_airdropToken.balanceOf(address(this)) < s_roundStatus[round].totalPrizeAmount)
            revert InsufficientBalance();
        if (!s_roundStatus[round].registrationStarted) revert RegisterNotStarted();
        if (block.timestamp <= s_startRegistrationTime + s_registrationDuration)
            revert RegistrationInProgress();
        if (s_participantsAtRound[round].length == 0) revert NoneParticipated();
        if (s_roundStatus[round].randNumRequested) revert AlreadyRequested(round);
        // effect
        s_roundStatus[round].randNumRequested = true;
        s_roundStatus[round].prizeAmountStartingAtFifthPlace =
            (s_roundStatus[round].totalPrizeAmount -
                i_firstPlacePrizeAmount -
                3 *
                i_secondtoFourthPlacePrizeAmount) /
            (s_participantsAtRound[round].length - 4);
        // interaction
        uint256 _requestId = ICRRRNGCoordinator(i_rngCoordinator).requestRandomWord();
        s_roundStatus[round].requestId = _requestId;
        s_requestIdToRound[_requestId] = round;
    }

    function withdrawAirdropTokenOnlyOwner() external onlyOwner {
        uint256 _balance = i_airdropToken.balanceOf(address(this));
        i_airdropToken.safeTransfer(owner(), _balance);
    }

    function withdrawAirdropToken(uint256 round) external {
        //check
        if (s_withdrawn[msg.sender][round]) revert AlreadyWithdrawn();
        if (!s_roundStatus[round].randNumfulfilled) revert RandNumNotFulfilled(round);
        uint256 _index = s_registerIndexPlusOneAtRound[msg.sender][round];
        if (_index < 1) revert NotRegisteredMsgSender();
        unchecked {
            --_index;
        }
        uint256 _prizeAmount = s_winnersPrizeAmount[round][_index];
        if (_prizeAmount == 0) _prizeAmount = s_roundStatus[round].prizeAmountStartingAtFifthPlace;
        //effect
        s_withdrawn[msg.sender][round] = true;
        //interaction
        i_airdropToken.safeTransfer(msg.sender, _prizeAmount);
    }

    function getIsWithdrawn(uint256 round, address participant) external view returns (bool) {
        return s_withdrawn[participant][round];
    }

    /** getter functions */
    function getPrizeAmountStartingAtFifthPlace(uint256 round) external view returns (uint256) {
        return s_roundStatus[round].prizeAmountStartingAtFifthPlace;
    }

    function getRequestIdAtRound(uint256 round) external view returns (uint256) {
        return s_roundStatus[round].requestId;
    }

    function getRoundAtRequestId(uint256 requestId) external view returns (uint256) {
        return s_requestIdToRound[requestId];
    }

    function getAirdropTokenAddress() external view returns (address) {
        return address(i_airdropToken);
    }

    function getPrizeAmountForFirstAndSecondtoFourthPlace()
        external
        view
        returns (uint256, uint256)
    {
        return (i_firstPlacePrizeAmount, i_secondtoFourthPlacePrizeAmount);
    }

    function getRNGCoordinatorAddress() external view returns (address) {
        return i_rngCoordinator;
    }

    function getRegistrationTimeAndDuration() external view returns (uint256, uint256) {
        return (s_startRegistrationTime, s_registrationDuration);
    }

    function getNextRandomAirdropRound() external view returns (uint256) {
        return s_nextRandomAirdropRound;
    }

    function getNumOfParticipants(uint256 round) external view returns (uint256) {
        return s_participantsAtRound[round].length;
    }

    function getRoundStatus(uint256 round) external view returns (bool, bool, bool) {
        return (
            s_roundStatus[round].registrationStarted,
            s_roundStatus[round].randNumRequested,
            s_roundStatus[round].randNumfulfilled
        );
    }

    function getTotalPrizeAmount(uint256 round) external view returns (uint256) {
        return s_roundStatus[round].totalPrizeAmount;
    }

    function getParticipantsAtRound(uint256 round) external view returns (address[] memory) {
        return s_participantsAtRound[round];
    }

    function getParticipantAtRound(uint256 round, uint256 index) external view returns (address) {
        return s_participantsAtRound[round][index];
    }

    function getRegisterIndexAtRound(
        address participantAddress,
        uint256 round
    ) external view returns (uint256) {
        return s_registerIndexPlusOneAtRound[participantAddress][round] - 1;
    }

    function getParticipatedRounds(
        address participantAddress
    ) external view returns (uint256[] memory) {
        return s_participatedRounds[participantAddress];
    }

    /* end of getter functions */

    function getRandomNumAtRound(uint256 round) external view returns (BigNumber memory) {
        return s_randomNum[round];
    }

    function getWinnersIndexAndAddressAtRound(
        uint256 round
    ) external view returns (uint256[4] memory, address[4] memory) {
        return (
            s_winnersIndex[round],
            [
                s_participantsAtRound[round][s_winnersIndex[round][0]],
                s_participantsAtRound[round][s_winnersIndex[round][1]],
                s_participantsAtRound[round][s_winnersIndex[round][2]],
                s_participantsAtRound[round][s_winnersIndex[round][3]]
            ]
        );
    }

    function getPrizeAmountAtRoundAndIndex(
        uint256 round,
        uint256 index
    ) external view returns (uint256) {
        uint256 _prizeAmount = s_winnersPrizeAmount[round][index];
        return
            _prizeAmount == 0 ? s_roundStatus[round].prizeAmountStartingAtFifthPlace : _prizeAmount;
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
        BigNumber memory _omega = BigNumber(omegaVal, omegaBitLen);
        s_randomNum[_round] = _omega;
        uint256 _participantLength = s_participantsAtRound[_round].length;
        uint256 _firstPlaceIndex = uint256(
            bytes32(_omega.mod(abi.encodePacked(_participantLength).init()).val)
        );
        uint256 _gap = _participantLength / 4;
        uint256 _secondPlaceIndex = addmod(_firstPlaceIndex, _gap, _participantLength);
        uint256 _thirdPlaceIndex = addmod(_secondPlaceIndex, _gap, _participantLength);
        uint256 _fourthPlaceIndex = addmod(_thirdPlaceIndex, _gap, _participantLength);
        s_winnersIndex[_round] = [
            _firstPlaceIndex,
            _secondPlaceIndex,
            _thirdPlaceIndex,
            _fourthPlaceIndex
        ];
        s_winnersPrizeAmount[_round][_firstPlaceIndex] = i_firstPlacePrizeAmount;
        s_winnersPrizeAmount[_round][_secondPlaceIndex] = i_secondtoFourthPlacePrizeAmount;
        s_winnersPrizeAmount[_round][_thirdPlaceIndex] = i_secondtoFourthPlacePrizeAmount;
        s_winnersPrizeAmount[_round][_fourthPlaceIndex] = i_secondtoFourthPlacePrizeAmount;
    }
}
