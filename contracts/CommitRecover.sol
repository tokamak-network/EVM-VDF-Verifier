// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./libraries/Pietrzak_VDF.sol";

/**
 * @title Bicorn-RX Commit-Reveal-Recover
 * @author Justin g
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
    struct ValueAtRound {
        uint256 omega; // the random number
        uint256 bStar; //hash of commitsString
        uint256 numOfParticipants; // number of participants
        uint256 g; // a value generated from the generator list
        uint256 h; // a value generated from the VDF(g)
        uint256 n; // modulor
        uint256 T;
        bool isCompleted; // omega is finalized when this is true
        bool isAllRevealed; // true when all participants have revealed
    }
    struct CommitRevealValue {
        uint256 c;
        uint256 a;
        address participantAddress;
    }
    struct UserAtRound {
        uint256 index; // index of the commitRevealValues
        bool committed; // true if committed
        bool revealed; // true if revealed
    }
    struct StartParams {
        uint256 commitDuration;
        uint256 commitRevealDuration;
        uint256 n;
        Pietrzak_VDF.VDFClaim[] proofs;
    }

    /* State variables */
    uint256 public startTime;
    uint256 public commitDuration;
    uint256 public commitRevealDuration; //commit + reveal period, commitRevealDuration - commitDuration => revealDuration
    uint256 public count; //This variable is used to keep track of the number of commitments and reveals, and to check if anything has been committed when moving to the reveal stage.
    uint256 public round; //first round is 1, second round is 2, ...
    string public commitsString; //concatenated string of commits
    Stages public stage;
    //bool public isHAndBStarSet;
    mapping(uint256 round => mapping(uint256 index => CommitRevealValue)) public commitRevealValues; //
    mapping(uint256 round => ValueAtRound omega) public valuesAtRound; // 1 => ValueAtRound(omega, isCompleted, ...), 2 => ValueAtRound(omega, isCompleted, ...), ...
    mapping(address owner => mapping(uint256 round => UserAtRound user)) public userInfosAtRound;

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
        uint256 recov,
        uint256 omegaRecov,
        uint256 recoveredTimestamp
    );
    event Start(
        address msgSender,
        uint256 startTime,
        uint256 commitDuration,
        uint256 commitRevealDuration,
        uint256 n,
        uint256 g,
        uint256 h,
        uint256 T,
        uint256 round
    );
    event CalculatedOmega(
        uint256 round,
        uint256 omega,
        uint256 calculatedTimestamp,
        bool isCompleted
    );

    modifier shouldBeLessThanN(uint256 _value) {
        require(_value < valuesAtRound[round].n, "GreaterOrEqualThanN");
        _;
    }

    /* Functions */
    /**
     */
    constructor() {
        stage = Stages.Finished;
    }

    /**
     * @param _commit participant's commit value
     * @notice Commit function
     * @notice The participant's commit value must be less than the modulor
     * @notice The participant can only commit once
     * @notice check period, update stage if needed, revert if not currently at commit stage
     */
    function commit(uint256 _commit) public shouldBeLessThanN(_commit) {
        require(!userInfosAtRound[msg.sender][round].committed, "AlreadyCommitted");
        checkStage(Stages.Commit);
        uint256 _count = count;
        string memory _commitsString = commitsString;
        _commitsString = string.concat(_commitsString, Pietrzak_VDF.toString(_commit));
        userInfosAtRound[msg.sender][round] = UserAtRound(_count, true, false);
        commitRevealValues[round][_count] = CommitRevealValue(_commit, 0, msg.sender); //index starts from 0, so _count -1
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
     * @notice update userInfosAtRound
     */
    function reveal(uint256 _a) public shouldBeLessThanN(_a) {
        uint256 _round = round;
        UserAtRound memory _user = userInfosAtRound[msg.sender][_round];
        require(_user.committed, "NotCommittedParticipant");
        require(!_user.revealed, "AlreadyRevealed");
        require(
            Pietrzak_VDF.powerModN(valuesAtRound[_round].g, _a, valuesAtRound[_round].n) ==
                commitRevealValues[_round][_user.index].c,
            "ANotMatchCommit"
        );
        checkStage(Stages.Reveal);
        uint256 _count = --count;
        commitRevealValues[_round][_user.index].a = _a;
        if (_count == 0) {
            stage = Stages.Finished;
            valuesAtRound[_round].isAllRevealed = true;
        }
        userInfosAtRound[msg.sender][_round].revealed = true;
        emit RevealA(msg.sender, _a, _count, block.timestamp);
    }

    function calculateOmega() public returns (uint256) {
        uint256 _round = round;
        require(valuesAtRound[_round].isAllRevealed, "NotAllRevealed");
        require(!valuesAtRound[_round].isCompleted, "OmegaAlreadyCompleted");
        checkStage(Stages.Finished);
        uint256 _numOfParticipants = valuesAtRound[_round].numOfParticipants;
        uint256 _omega = 1;
        uint256 _bStar = valuesAtRound[_round].bStar;
        uint256 _h = valuesAtRound[round].h;
        uint256 _n = valuesAtRound[round].n;
        bool _isCompleted = true;
        for (uint256 i = 0; i < _numOfParticipants; i++) {
            _omega = mulmod(
                _omega,
                Pietrzak_VDF.powerModN(
                    Pietrzak_VDF.powerModN(
                        _h,
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    Pietrzak_VDF.toString(commitRevealValues[_round][i].c),
                                    Pietrzak_VDF.toString(_bStar)
                                )
                            )
                        ) % _n,
                        _n
                    ),
                    commitRevealValues[_round][i].a,
                    _n
                ),
                _n
            );
        }
        valuesAtRound[_round].omega = _omega;
        valuesAtRound[_round].isCompleted = _isCompleted; //false when not all participants have revealed
        stage = Stages.Finished;
        emit CalculatedOmega(_round, _omega, block.timestamp, _isCompleted);
        return _omega;
    }

    /**
     * @param proofs the proof of the recovered value
     * @notice Recover function
     * @notice The recovered value must be less than the modulor
     * @notice revert if currently at commit stage
     * @notice revert if count == 0 meaning no one has committed
     * @notice calculate and finalize omega
     */
    function recover(
        uint256 _round,
        Pietrzak_VDF.VDFClaim[] calldata proofs
    ) public shouldBeLessThanN(proofs[0].y) {
        uint256 recov = 1;
        uint256 _n = valuesAtRound[_round].n;
        uint256 _bStar = valuesAtRound[_round].bStar;
        require(stage != Stages.Commit, "FunctionInvalidAtThisStage");
        require(!valuesAtRound[_round].isCompleted, "OmegaAlreadyCompleted");
        require(valuesAtRound[_round].T == proofs[0].T, "TNotMatched");
        Pietrzak_VDF.verifyRecursiveHalvingProof(proofs);
        for (uint256 i = 0; i < valuesAtRound[_round].numOfParticipants; i++) {
            uint256 _c = commitRevealValues[_round][i].c;
            uint256 temp = Pietrzak_VDF.powerModN(
                _c,
                uint256(
                    keccak256(
                        abi.encodePacked(Pietrzak_VDF.toString(_c), Pietrzak_VDF.toString(_bStar))
                    )
                ) % _n,
                _n
            );
            recov = mulmod(recov, temp, _n);
        }
        require(recov == proofs[0].x, "RecovNotMatchX");
        valuesAtRound[_round].isCompleted = true;
        valuesAtRound[_round].omega = proofs[0].y;
        stage = Stages.Finished;
        emit Recovered(msg.sender, recov, proofs[0].y, block.timestamp);
    }

    /**
     *
     * @param params start parameters
     * @notice Start function
     * @notice The contract must be in the Finished stage
     * @notice The commit period must be less than the commit + reveal period
     * @notice The g value must be less than the modulor
     * @notice reset count, commitsString, isHAndBStarSet, stage, startTime, commitDuration, commitRevealDuration, n, g, omega
     * @notice increase round
     */
    function start(StartParams calldata params) public {
        require(params.proofs[0].x < params.n, "GreaterOrEqualThanN");
        require(
            params.commitDuration < params.commitRevealDuration,
            "CommitRevealDurationLessThanCommitDuration"
        );
        require(stage == Stages.Finished, "StageNotFinished");
        Pietrzak_VDF.verifyRecursiveHalvingProof(params.proofs);
        round += 1;
        stage = Stages.Commit;
        startTime = block.timestamp;
        commitDuration = params.commitDuration;
        commitRevealDuration = params.commitRevealDuration;
        valuesAtRound[round].T = params.proofs[0].T;
        valuesAtRound[round].g = params.proofs[0].x;
        valuesAtRound[round].h = params.proofs[0].y;
        valuesAtRound[round].n = params.n;
        count = 0;
        commitsString = "";
        emit Start(
            msg.sender,
            block.timestamp,
            params.commitDuration,
            params.commitRevealDuration,
            params.n,
            params.proofs[0].x,
            params.proofs[0].y,
            params.proofs[0].T,
            round
        );
    }

    /**
     * @param _stage the stage to check
     * @notice checkStage function
     * @notice revert if the current stage is not the given stage
     * @notice this function is used to check if the current stage is the given stage
     * @notice it will update the stage to the next stage if needed
     */
    function checkStage(Stages _stage) public {
        uint256 _startTime = startTime;
        if (stage == Stages.Commit && block.timestamp >= _startTime + commitDuration) {
            if (count != 0) {
                nextStage();
                valuesAtRound[round].numOfParticipants = count;
                uint256 _bStar = uint256(keccak256(abi.encodePacked(commitsString))) %
                    valuesAtRound[round].n;
                valuesAtRound[round].bStar = _bStar;
            } else {
                stage = Stages.Finished;
            }
        }
        if (
            stage == Stages.Reveal &&
            (block.timestamp >= _startTime + commitRevealDuration || count == 0)
        ) {
            nextStage();
        }
        require(stage == _stage, "FunctionInvalidAtThisStage");
    }

    /**
     * @notice NextStage function
     * @notice update stage to the next stage
     * @notice revert if the current stage is Finished
     */
    function nextStage() internal {
        require(stage != Stages.Finished, "AllFinished");
        stage = Stages(addmod(uint256(stage), 1, 3));
    }
}
