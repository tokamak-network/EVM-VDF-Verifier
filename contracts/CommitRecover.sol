// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./libraries/Pietrzak_VDF.sol";
import "hardhat/console.sol";

/* Errors */
error AlreadyCommitted();
error GreaterOrEqualThanOrder();
error AlreadyRevealed();
error NotCommittedParticipant();
error CommitRevealDurationLessThanCommitDuration();
error ANotMatchCommit();
error FunctionInvalidAtThisStage();
error StageNotFinished();
error AllFinished();
error OmegaAlreadyCompleted();

/**
 * @title Bicorn-RX Commit-Reveal-Recover
 * @author Justin G
 * @notice This contract is for generating random number
 *    1. Commit: participants commit their value
 *    2. Reveal: participants reveal their value
 *    3. Finished: Calculate or recover the random number
 *    4. go to 1
 */
contract CommitRecover {
    /* Type declaration */
    /**
     * @notice Stages of the contract
     * @notice Recover can be performed in the Reveal and Finished stages.
     */
    enum Stages {
        Commit,
        Reveal,
        Finished
    }
    struct Omega {
        uint256 omega; // the random number
        bytes32 bStar; //hash of commitsString
        uint256 numOfParticipants; // number of participants
        mapping(uint256 => CommitRevealValue) commitRevealValues; // 0 => CommitRevealValue(c, a, participantAddress), 1 => CommitRevealValue(c, a, participantAddress), ...
        bool isCompleted; // omega is finalized when this is true
        bool isCalculated; // omega is calculated when this is true
    }
    struct CommitRevealValue {
        uint256 c;
        uint256 a;
        address participantAddress;
    }
    struct UserAtRound {
        uint256 index; // index of the dynamic arrays(c_s, a_s) in Omega struct
        bool committed; // true if committed
        bool revealed; // true if revealed
    }
    struct StartParams {
        uint256 commitDuration;
        uint256 commitRevealDuration;
        uint256 h;
        Pietrzak_VDF.VDFClaim[] proofs;
    }

    /* State variables */
    uint256 public startTime;
    uint256 public commitDuration;
    uint256 public commitRevealDuration; //commit + reveal period, commitRevealDuration - commitDuration => revealDuration
    uint256 public immutable N; // modulor
    uint256 public immutable G; // a value generated from the generator list
    uint256 public h; // a value generated from the VDF(g)
    uint256 public count; //This variable is used to keep track of the number of commitments and reveals, and to check if anything has been committed when moving to the reveal stage.
    uint256 public round; //first round is 1, second round is 2, ...
    string public commitsString; //concatenated string of commits
    Stages public stage;
    //bool public isHAndBStarSet;

    mapping(uint256 round => Omega omega) public valuesAtRound; // 1 => Omega(omega, isCompleted, ...), 2 => Omega(omega, isCompleted, ...), ...
    mapping(address owner => mapping(uint256 round => UserAtRound user)) public userInfos;

    /* Events */
    event CommitC(
        address participant,
        uint256 commit,
        string commitsString,
        uint256 commitCount,
        uint256 commitTimestamp
    );
    event RevealA(address participant, uint256 a, uint256 revealLeftCount, uint256 revealTimestamp);
    event Recovered(
        address msgSender,
        uint256 vdfInput,
        uint256 recov,
        uint256 omega,
        uint256 recoveredTimestamp
    );
    event Start(
        address msgSender,
        uint256 startTime,
        uint256 commitDuration,
        uint256 commitRevealDuration,
        uint256 N,
        uint256 g,
        uint256 round
    );
    event CalculatedOmega(
        uint256 round,
        uint256 omega,
        uint256 calculatedTimestamp,
        bool isCompleted
    );

    modifier shouldBeLessThanN(uint256 _value) {
        if (_value >= N) revert GreaterOrEqualThanOrder();
        _;
    }

    /* Functions */
    /**
     * @param params start parameters
     * @notice CommitRecover constructor
     * @notice The constructor is called when the contract is deployed and commit starts right away
     *
     */
    constructor(StartParams memory params, uint256 _g, uint256 _n) {
        if (_g >= _n) revert GreaterOrEqualThanOrder();
        if (params.commitDuration >= params.commitRevealDuration)
            revert CommitRevealDurationLessThanCommitDuration();
        //verify
        Pietrzak_VDF.verifyRecursiveHalvingProof(params.proofs);
        stage = Stages.Commit;
        startTime = block.timestamp;
        commitDuration = params.commitDuration;
        commitRevealDuration = params.commitRevealDuration;
        N = _n;
        G = _g;
        h = params.h;
        round = 1;
    }

    /**
     * @param _commit participant's commit value
     * @notice Commit function
     * @notice The participant's commit value must be less than the modulor
     * @notice The participant can only commit once
     * @notice check period, update stage if needed, revert if not currently at commit stage
     */
    function commit(uint256 _commit) public shouldBeLessThanN(_commit) {
        if (userInfos[msg.sender][round].committed) {
            revert AlreadyCommitted();
        }
        checkStage(Stages.Commit);
        uint256 _count = count;
        string memory _commitsString = commitsString;
        _commitsString = string.concat(_commitsString, Pietrzak_VDF.toString(_commit));
        userInfos[msg.sender][round] = UserAtRound(_count, true, false);
        valuesAtRound[round].commitRevealValues[_count] = CommitRevealValue(_commit, 0, msg.sender); //index starts from 0, so _count -1
        commitsString = _commitsString;
        count = ++_count;
        emit CommitC(msg.sender, _commit, _commitsString, _count, block.timestamp);
    }

    /**
     * @param _a participant's reveal value
     * @notice Reveal function
     * @notice h must be set before reveal
     * @notice participant must have committed
     * @notice participant must not have revealed
     * @notice The participant's reveal value must match the commit value
     * @notice The participant's reveal value must be less than the modulor
     * @notice check period, update stage if needed, revert if not currently at reveal stage
     * @notice update omega, count
     * @notice if count == 0, update valuesAtRound, stage
     * @notice update userInfos
     */
    function reveal(uint256 _a) public shouldBeLessThanN(_a) {
        UserAtRound memory _user = userInfos[msg.sender][round];
        if (!_user.committed) {
            revert NotCommittedParticipant();
        }
        if (_user.revealed) {
            revert AlreadyRevealed();
        }
        if (
            Pietrzak_VDF.powerModOrder(G, _a, N) !=
            valuesAtRound[round].commitRevealValues[_user.index].c
        ) {
            revert ANotMatchCommit();
        }
        checkStage(Stages.Reveal);
        uint256 _count = --count;
        valuesAtRound[round].commitRevealValues[_user.index].a = _a;
        if (_count == 0) stage = Stages.Finished;
        userInfos[msg.sender][round].revealed = true;
        emit RevealA(msg.sender, _a, _count, block.timestamp);
    }

    function calculateOmega() public returns (uint256) {
        uint256 _round = round;
        if (valuesAtRound[_round].isCompleted) revert OmegaAlreadyCompleted();
        checkStage(Stages.Finished);
        uint256 _numOfParticipants = valuesAtRound[_round].numOfParticipants;
        uint256 _omega = 1;
        bytes32 _bStar = valuesAtRound[_round].bStar;
        uint256 _h = h;
        uint256 _n = N;
        bool _isCompleted = true;
        for (uint256 i = 0; i < _numOfParticipants; i++) {
            if (
                userInfos[valuesAtRound[_round].commitRevealValues[i].participantAddress][_round]
                    .revealed == false
            ) {
                _isCompleted = false;
                continue;
            }
            _omega = mulmod(
                _omega,
                Pietrzak_VDF.powerModOrder(
                    Pietrzak_VDF.powerModOrder(
                        _h,
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    valuesAtRound[_round].commitRevealValues[i].c,
                                    _bStar
                                )
                            )
                        ),
                        _n
                    ),
                    valuesAtRound[_round].commitRevealValues[i].a,
                    _n
                ),
                _n
            );
        }
        valuesAtRound[_round].omega = _omega;
        valuesAtRound[_round].isCompleted = _isCompleted; //false when not all participants have revealed
        valuesAtRound[_round].isCalculated = true;
        emit CalculatedOmega(_round, _omega, block.timestamp, _isCompleted);
        return _omega;
    }

    /**
     * @param recov the recovered value
     * @notice Recover function
     * @notice The recovered value must be less than the modulor
     * @notice revert if currently at commit stage
     * @notice revert if count == 0 meaning no one has committed
     * @notice calculate and finalize omega
     */
    function recover(
        uint256 vdfInput,
        uint256 recov,
        Pietrzak_VDF.VDFClaim[] calldata proofs
    ) public shouldBeLessThanN(recov) {
        uint256 _omega;
        if (stage == Stages.Commit) {
            revert FunctionInvalidAtThisStage();
        }
        if (valuesAtRound[round].isCompleted) revert OmegaAlreadyCompleted();
        if (!valuesAtRound[round].isCalculated) _omega = calculateOmega();
        else _omega = valuesAtRound[round].omega;
        //verify
        Pietrzak_VDF.verifyRecursiveHalvingProof(proofs);
        valuesAtRound[round].isCompleted = true;
        valuesAtRound[round].omega = mulmod(_omega, recov, N);
        emit Recovered(msg.sender, vdfInput, recov, _omega, block.timestamp);
    }

    /**
     *
     * @param params start parameters
     * @notice Start function
     * @notice The contract must be in the Finished stage
     * @notice The commit period must be less than the commit + reveal period
     * @notice The g value must be less than the modulor
     * @notice reset count, commitsString, isHAndBStarSet, stage, startTime, commitDuration, commitRevealDuration, N, g, omega
     * @notice increase round
     */
    function start(StartParams calldata params) public {
        uint256 g = G;
        if (stage != Stages.Finished) {
            revert StageNotFinished();
        }
        if (g >= N) revert GreaterOrEqualThanOrder();
        if (params.commitDuration >= params.commitRevealDuration)
            revert CommitRevealDurationLessThanCommitDuration();
        stage = Stages.Commit;
        startTime = block.timestamp;
        commitDuration = params.commitDuration;
        commitRevealDuration = params.commitRevealDuration;
        h = params.h;
        round += 1;
        count = 0;
        commitsString = "";
        emit Start(msg.sender, startTime, commitDuration, commitRevealDuration, N, g, round);
    }

    /**
     * @param _stage the stage to check
     * @notice checkStage function
     * @notice revert if the current stage is not the given stage
     * @notice this function is used to check if the current stage is the given stage
     * @notice it will update the stage to the next stage if needed
     */
    function checkStage(Stages _stage) internal {
        Stages _currentStage = stage;
        uint256 _startTime = startTime;
        if (_currentStage == Stages.Commit && block.timestamp >= _startTime + commitDuration) {
            if (count != 0) {
                nextStage();
                valuesAtRound[round].numOfParticipants = count;
                bytes32 _bStar = keccak256(abi.encodePacked(commitsString));
                valuesAtRound[round].bStar = _bStar;
            } else {
                //only one participant
                stage = Stages.Finished;
            }
        }
        if (
            _currentStage == Stages.Reveal &&
            (block.timestamp >= _startTime + commitRevealDuration || count == 0)
        ) {
            nextStage();
        }
        if (stage != _stage) revert FunctionInvalidAtThisStage();
    }

    /**
     * @notice NextStage function
     * @notice update stage to the next stage
     * @notice revert if the current stage is Finished
     */
    function nextStage() internal {
        if (stage == Stages.Finished) revert AllFinished();
        stage = Stages(addmod(uint256(stage), 1, 3));
    }
}
