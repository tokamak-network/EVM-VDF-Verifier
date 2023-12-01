// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./libraries/Pietrzak_VDF.sol";

import "hardhat/console.sol";

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
    using BigNumbers for *;
    using Pietrzak_VDF for *;
    enum Stages {
        Commit,
        Reveal,
        Finished
    }
    struct ValueAtRound {
        BigNumber omega; // the random number
        bytes bStar; //hash of commitsString
        uint256 numOfParticipants; // number of participants
        BigNumber g; // a value generated from the generator list
        BigNumber h; // a value generated from the VDF(g)
        BigNumber n; // modulor
        uint256 T;
        bool isCompleted; // omega is finalized when this is true
        bool isAllRevealed; // true when all participants have revealed
    }
    struct CommitRevealValue {
        BigNumber c;
        BigNumber a;
        address participantAddress;
    }
    struct UserAtRound {
        uint256 index; // index of the commitRevealValues
        bool committed; // true if committed
        bool revealed; // true if revealed
    }

    /* State variables */
    uint256 public startTime;
    uint256 public commitDuration;
    uint256 public commitRevealDuration; //commit + reveal period, commitRevealDuration - commitDuration => revealDuration
    uint256 public count; //This variable is used to keep track of the number of commitments and reveals, and to check if anything has been committed when moving to the reveal stage.
    uint256 public round; //first round is 1, second round is 2, ...
    bytes public commitsString; //concatenated string of commits
    Stages public stage;
    //bool public isHAndBStarSet;
    mapping(uint256 round => mapping(uint256 index => CommitRevealValue)) public commitRevealValues; //
    mapping(uint256 round => ValueAtRound omega) public valuesAtRound; // 1 => ValueAtRound(omega, isCompleted, ...), 2 => ValueAtRound(omega, isCompleted, ...), ...
    mapping(address owner => mapping(uint256 round => UserAtRound user)) public userInfosAtRound;

    /* Events */
    event CommitC(
        address participant,
        BigNumber commit,
        bytes commitsString,
        uint256 commitCount,
        uint256 commitTimestamp
    );
    event RevealA(
        address participant,
        BigNumber a,
        uint256 revealLeftCount,
        uint256 revealTimestamp
    );
    event Recovered(
        address msgSender,
        BigNumber recov,
        BigNumber omegaRecov,
        uint256 recoveredTimestamp
    );
    event Start(
        address msgSender,
        uint256 startTime,
        uint256 commitDuration,
        uint256 commitRevealDuration,
        BigNumber n,
        BigNumber g,
        BigNumber h,
        uint256 T,
        uint256 round
    );
    event CalculatedOmega(
        uint256 round,
        BigNumber omega,
        uint256 calculatedTimestamp,
        bool isCompleted
    );

    // modifier shouldBeLessThanN(uint256 _value) {
    //     require(_value < valuesAtRound[round].n, "GreaterOrEqualThanN");
    //     _;
    // }

    /* Functions */
    /**
     */
    constructor() {
        stage = Stages.Finished;
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

    function reveal(BigNumber calldata _a) public {
        uint256 _round = round;
        UserAtRound memory _user = userInfosAtRound[msg.sender][_round];
        require(_user.committed, "NotCommittedParticipant");
        require(!_user.revealed, "AlreadyRevealed");
        // console.log("reveal contract-----!");
        // console.logBytes(commitRevealValues[_round][_user.index].c.val);
        // console.logBytes(valuesAtRound[_round].g.modexp(_a, valuesAtRound[_round].n).val);
        // console.log(commitRevealValues[_round][_user.index].c.bitlen);
        // console.log(valuesAtRound[_round].g.modexp(_a, valuesAtRound[_round].n).bitlen);
        // console.log(commitRevealValues[_round][_user.index].c.neg);
        // console.log(valuesAtRound[_round].g.modexp(_a, valuesAtRound[_round].n).neg);
        require(
            (valuesAtRound[_round].g.modexp(_a, valuesAtRound[_round].n)).eq(
                commitRevealValues[_round][_user.index].c
            ),
            "ANotMatchCommit"
        );
        checkStage();
        equalStage(Stages.Reveal);
        uint256 _count = --count;
        commitRevealValues[_round][_user.index].a = _a;
        if (_count == 0) {
            stage = Stages.Finished;
            valuesAtRound[_round].isAllRevealed = true;
        }
        userInfosAtRound[msg.sender][_round].revealed = true;
        emit RevealA(msg.sender, _a, _count, block.timestamp);
    }

    function calculateOmega() public returns (BigNumber memory) {
        uint256 _round = round;
        require(valuesAtRound[_round].isAllRevealed, "NotAllRevealed");
        require(!valuesAtRound[_round].isCompleted, "OmegaAlreadyCompleted");
        checkStage();
        equalStage(Stages.Finished);
        uint256 _numOfParticipants = valuesAtRound[_round].numOfParticipants;
        BigNumber memory _omega = BigNumbers.one();
        bytes memory _bStar = valuesAtRound[_round].bStar;
        BigNumber memory _h = valuesAtRound[round].h;
        BigNumber memory _n = valuesAtRound[round].n;
        bool _isCompleted = true;
        for (uint256 i = 0; i < _numOfParticipants; i++) {
            _omega = _omega.modmul(
                _h
                    .modexp(
                        // Pietrzak_VDF.modHash(_n, bytes.concat(commitRevealValues[_round][i].c, _bStar)),
                        _n.modHash(bytes.concat(commitRevealValues[_round][i].c.val, _bStar)),
                        _n
                    )
                    .modexp(commitRevealValues[_round][i].a, _n),
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
    function recover(uint256 _round, Pietrzak_VDF.VDFClaim[] calldata proofs) public {
        BigNumber memory recov = BigNumbers.one();
        BigNumber memory _n = valuesAtRound[_round].n;
        //require(stage != Stages.Commit, "FunctionInvalidAtThisStage");
        checkStage();
        overStage(Stages.Commit);
        bytes memory _bStar = valuesAtRound[_round].bStar;
        require(!valuesAtRound[_round].isCompleted, "OmegaAlreadyCompleted");
        require(valuesAtRound[_round].T == proofs[0].T, "TNotMatched");
        require(Pietrzak_VDF.verifyRecursiveHalvingProof(proofs), "not verified");
        for (uint256 i = 0; i < valuesAtRound[_round].numOfParticipants; i++) {
            BigNumber memory _c = commitRevealValues[_round][i].c;
            BigNumber memory temp = _c.modexp(_n.modHash(bytes.concat(_c.val, _bStar)), _n);
            //recov = mulmod(recov, temp, _n);
            recov = recov.modmul(temp, _n);
        }
        //require(recov == proofs[0].x, "RecovNotMatchX");
        require(recov.eq(proofs[0].x), "RecovNotMatchX");
        valuesAtRound[_round].isCompleted = true;
        valuesAtRound[_round].omega = proofs[0].y;
        stage = Stages.Finished;
        emit Recovered(msg.sender, recov, proofs[0].y, block.timestamp);
    }

    /**
     *
     * @notice Start function
     * @notice The contract must be in the Finished stage
     * @notice The commit period must be less than the commit + reveal period
     * @notice The g value must be less than the modulor
     * @notice reset count, commitsString, isHAndBStarSet, stage, startTime, commitDuration, commitRevealDuration, n, g, omega
     * @notice increase round
     */
    function start(
        uint256 _commitDuration,
        uint256 _commitRevealDuration,
        BigNumber calldata _n,
        Pietrzak_VDF.VDFClaim[] calldata _proofs
    ) public {
        //require(_proofs[0].x < _n, "GreaterOrEqualThanN");

        require(
            _commitDuration < _commitRevealDuration,
            "CommitRevealDurationLessThanCommitDuration"
        );
        require(stage == Stages.Finished, "StageNotFinished");
        require(Pietrzak_VDF.verifyRecursiveHalvingProof(_proofs), "not verified");
        round += 1;
        stage = Stages.Commit;
        startTime = block.timestamp;
        commitDuration = _commitDuration;
        commitRevealDuration = _commitRevealDuration;
        valuesAtRound[round].T = _proofs[0].T;
        valuesAtRound[round].g = _proofs[0].x;
        valuesAtRound[round].h = _proofs[0].y;
        valuesAtRound[round].n = _n;
        count = 0;
        commitsString = "";
        emit Start(
            msg.sender,
            block.timestamp,
            _commitDuration,
            _commitRevealDuration,
            _n,
            _proofs[0].x,
            _proofs[0].y,
            _proofs[0].T,
            round
        );
    }

    /**
     * @notice checkStage function
     * @notice revert if the current stage is not the given stage
     * @notice this function is used to check if the current stage is the given stage
     * @notice it will update the stage to the next stage if needed
     */
    function checkStage() public {
        uint256 _startTime = startTime;
        if (stage == Stages.Commit && block.timestamp >= _startTime + commitDuration) {
            if (count != 0) {
                nextStage();
                valuesAtRound[round].numOfParticipants = count;
                // uint256 _bStar = uint256(keccak256(abi.encodePacked(commitsString))) %
                //     valuesAtRound[round].n;
                bytes memory _bStar = valuesAtRound[round].n.modHash(commitsString).val;
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
    }

    /**
     * @param _commit participant's commit value
     * @notice Commit function
     * @notice The participant's commit value must be less than the modulor
     * @notice The participant can only commit once
     * @notice check period, update stage if needed, revert if not currently at commit stage
     */
    function commit(BigNumber memory _commit) public {
        require(!userInfosAtRound[msg.sender][round].committed, "AlreadyCommitted");
        checkStage();
        equalStage(Stages.Commit);
        uint256 _count = count;
        bytes memory _commitsString = commitsString;
        _commitsString = bytes.concat(_commitsString, _commit.val);
        userInfosAtRound[msg.sender][round] = UserAtRound(_count, true, false);
        commitRevealValues[round][_count] = CommitRevealValue(
            _commit,
            BigNumbers.one(),
            msg.sender
        ); //index starts from 0, so _count -1
        commitsString = _commitsString;
        count = ++_count;
        emit CommitC(msg.sender, _commit, _commitsString, _count, block.timestamp);
    }

    function equalStage(Stages _stage) internal view {
        require(stage == _stage, "FunctionInvalidAtThisStage");
    }

    function overStage(Stages _stage) internal view {
        require(stage > _stage, "FunctionInvalidAtThisStage");
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
