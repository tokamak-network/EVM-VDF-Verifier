// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {RNGConsumerBase} from "./RNGConsumerBase.sol";
import {ICRRRNGServiceWrapper} from "./interfaces/ICRRRNGServiceWrapper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CryptoDice is RNGConsumerBase, Ownable {
    /* Type declaration */
    using SafeERC20 for IERC20;
    struct RoundStatus {
        uint256 requestId;
        uint256 totalPrizeAmount;
        uint256 prizeAmountForEachWinner;
        bool registrationStarted;
        bool randNumRequested;
        bool randNumfulfilled;
    }

    uint32 private constant CALLBACK_GAS_LIMIT = 100000;
    /* Immutable state variables */
    IERC20 private immutable i_airdropToken;

    /* Storage state variables */
    mapping(address participantAddress => uint256[] diceRounds) private s_participatedRounds;
    mapping(address participantAddress => uint256[] withdrawedRounds) private s_withdrawedRounds;
    mapping(address participantAddress => mapping(uint256 diceRound => uint256 diceNum))
        private s_diceNumAtRound;
    mapping(address participantAddress => mapping(uint256 diceRound => bool isWithdrawn))
        private s_withdrawn;
    mapping(uint256 diceRound => uint256 registeredCount) private s_registeredCount;
    mapping(uint256 diceRound => RoundStatus) private s_roundStatus;
    mapping(uint256 requestId => uint256 diceRound) private s_requestIdToRound;
    mapping(uint256 diceRound => uint256 hashedOmegaVal) private s_randomNum;
    mapping(uint256 diceRound => uint256 diceNum) private s_winningDiceNum;
    mapping(uint256 diceRound => uint256[7] diceNumCount) private s_diceNumCount;
    uint256 private s_nextDiceRound;
    uint256 private s_startRegistrationTime;
    uint256 private s_registrationDuration;

    /* Errors */
    error RegistrationInProgress();
    error RegistrationNotStarted();
    error RegistrationFinished();
    error InvalidDiceNum();
    error AlreadyRegistered();
    error InvalidBlackListLength();
    error RNGRequested();
    error NoneParticipated();
    error InsufficientBalance();
    error NotParticipatedOrBlackListed();
    error RandNumNotFulfilled();
    error YouAreNotWinner();
    error AlreadyWithdrawn();
    error AlreadyFulfilled();

    /* Events */
    event RegistrationStarted(uint256 diceRound);
    event Registered(uint256 diceRound, address participant, uint256 diceNum);

    constructor(
        address rngCoordinator,
        address airdropToken
    ) RNGConsumerBase(rngCoordinator) Ownable(msg.sender) {
        require(rngCoordinator != address(0));
        require(airdropToken != address(0));
        i_airdropToken = IERC20(airdropToken);
    }

    function startRegistration(
        uint256 registrationDuration,
        uint256 totalPrizeAmount
    ) external onlyOwner {
        uint256 _nextDiceRound = s_nextDiceRound;
        if (_nextDiceRound > 0) {
            if (block.timestamp <= s_startRegistrationTime + s_registrationDuration)
                revert RegistrationInProgress();
            if (s_registeredCount[_nextDiceRound - 1] == 0) {
                unchecked {
                    _nextDiceRound = --s_nextDiceRound;
                }
            }
        }
        s_startRegistrationTime = block.timestamp;
        s_registrationDuration = registrationDuration;
        s_roundStatus[_nextDiceRound].registrationStarted = true;
        s_roundStatus[_nextDiceRound].totalPrizeAmount = totalPrizeAmount;
        emit RegistrationStarted(s_nextDiceRound++);
    }

    function register(uint256 diceNum) external {
        uint256 _round = s_nextDiceRound - 1;
        // diceNum should be in the range of 1 to 6
        if (diceNum < 1 || diceNum > 6) revert InvalidDiceNum();
        if (!s_roundStatus[_round].registrationStarted) revert RegistrationNotStarted();
        if (block.timestamp > s_startRegistrationTime + s_registrationDuration)
            revert RegistrationFinished();
        if (s_diceNumAtRound[msg.sender][_round] != 0) revert AlreadyRegistered();
        s_diceNumAtRound[msg.sender][_round] = diceNum;
        s_participatedRounds[msg.sender].push(_round);
        unchecked {
            ++s_registeredCount[_round];
            ++s_diceNumCount[_round][diceNum];
        }
        emit Registered(_round, msg.sender, diceNum);
    }

    function blackList(uint256 diceRound, address[] calldata addresses) external onlyOwner {
        uint256 _participantsLength = s_registeredCount[diceRound];
        uint256 _blackListLength = addresses.length;
        //check
        if (_participantsLength < _blackListLength) revert InvalidBlackListLength();
        if (_participantsLength == 0) revert NoneParticipated();
        if (!s_roundStatus[diceRound].registrationStarted) revert RegistrationNotStarted();
        if (block.timestamp <= s_startRegistrationTime + s_registrationDuration)
            revert RegistrationInProgress();
        if (s_roundStatus[diceRound].randNumRequested) revert RNGRequested();
        //effect
        uint256[7] memory _diceNumCount = s_diceNumCount[diceRound];
        uint256 i;
        do {
            uint256 _diceNum = s_diceNumAtRound[addresses[i]][diceRound];
            if (_diceNum == 0) revert NotParticipatedOrBlackListed();
            --_diceNumCount[_diceNum];
            s_diceNumAtRound[addresses[i]][diceRound] = 0;
            unchecked {
                ++i;
            }
        } while (i < _blackListLength);
        s_diceNumCount[diceRound] = _diceNumCount;
        unchecked {
            s_registeredCount[diceRound] -= _blackListLength;
        }
    }

    function requestRandomWord(uint256 round) external payable onlyOwner {
        //check
        if (i_airdropToken.balanceOf(address(this)) < s_roundStatus[round].totalPrizeAmount)
            revert InsufficientBalance();
        if (s_registeredCount[round] == 0) revert NoneParticipated();
        if (!s_roundStatus[round].registrationStarted) revert RegistrationNotStarted();
        if (block.timestamp <= s_startRegistrationTime + s_registrationDuration)
            revert RegistrationInProgress();
        if (s_roundStatus[round].randNumRequested) revert RNGRequested();
        //effect
        s_roundStatus[round].randNumRequested = true;
        // interaction
        (uint256 _requestId, ) = requestRandomness(CALLBACK_GAS_LIMIT);
        s_requestIdToRound[_requestId] = round;
        s_roundStatus[round].requestId = _requestId;
    }

    function withdrawAirdropTokenOnlyOwner() external onlyOwner {
        uint256 _balance = i_airdropToken.balanceOf(address(this));
        i_airdropToken.safeTransfer(owner(), _balance);
    }

    function withdrawAirdropToken(uint256 round) external {
        // check
        uint256 _diceNum = s_diceNumAtRound[msg.sender][round];
        if (_diceNum == 0) revert NotParticipatedOrBlackListed();
        if (!s_roundStatus[round].randNumfulfilled) revert RandNumNotFulfilled();
        if (s_withdrawn[msg.sender][round]) revert AlreadyWithdrawn();
        if (_diceNum != s_winningDiceNum[round]) revert YouAreNotWinner();
        uint256 _prizeAmount = s_roundStatus[round].prizeAmountForEachWinner;
        // effect
        s_withdrawn[msg.sender][round] = true;
        s_withdrawedRounds[msg.sender].push(round);
        // interaction
        i_airdropToken.safeTransfer(msg.sender, _prizeAmount);
    }

    // *** getter functions ***

    function getWithdrawedRounds(address participant) external view returns (uint256[] memory) {
        return s_withdrawedRounds[participant];
    }

    function getDiceNumAtRound(uint256 round, address participant) external view returns (uint256) {
        return s_diceNumAtRound[participant][round];
    }

    function getParticipatedRounds(address participant) external view returns (uint256[] memory) {
        return s_participatedRounds[participant];
    }

    function getRoundStatus(uint256 round) external view returns (RoundStatus memory) {
        return s_roundStatus[round];
    }

    function getRNGCoordinator() external view returns (address) {
        return address(i_rngCoordinator);
    }

    function getAirdropTokenAddress() external view returns (address) {
        return address(i_airdropToken);
    }

    function getRegistrationTimeAndDuration() external view returns (uint256, uint256) {
        return (s_startRegistrationTime, s_registrationDuration);
    }

    function getNextCryptoDiceRound() external view returns (uint256) {
        return s_nextDiceRound;
    }

    function getRegisteredCount(uint256 round) external view returns (uint256) {
        return s_registeredCount[round];
    }

    function getRandNum(uint256 round) external view returns (uint256) {
        return s_randomNum[round];
    }

    function getWinningDiceNum(uint256 round) external view returns (uint256) {
        return s_winningDiceNum[round];
    }

    function getPrizeAmountForEachWinner(uint256 round) external view returns (uint256) {
        return s_roundStatus[round].prizeAmountForEachWinner;
    }

    function getDiceNumCount(uint256 round, uint256 diceNum) external view returns (uint256) {
        return s_diceNumCount[round][diceNum];
    }

    function fulfillRandomWords(uint256 requestId, uint256 hashedOmegaVal) internal override {
        //check
        uint256 _round = s_requestIdToRound[requestId];
        if (s_roundStatus[_round].randNumfulfilled) revert AlreadyFulfilled();
        // effect
        s_randomNum[_round] = hashedOmegaVal;
        s_roundStatus[_round].randNumfulfilled = true;
        uint256 winningDiceNum = (hashedOmegaVal % 6) + 1;
        s_winningDiceNum[_round] = winningDiceNum;
        uint256 _diceNumCount = s_diceNumCount[_round][winningDiceNum];
        if (_diceNumCount != 0)
            s_roundStatus[_round].prizeAmountForEachWinner =
                s_roundStatus[_round].totalPrizeAmount /
                s_diceNumCount[_round][winningDiceNum];
    }
}
