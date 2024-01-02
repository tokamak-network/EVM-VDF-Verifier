// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
import "./libraries/Pietrzak_VDF.sol";

/**
 * @title Bicorn-RX Commit-Reveal-Recover
 * @author Justin g
 * @notice This contract is for generating random number
 *    1. Finished: Not SetUped | Calculate or recover the random number
 *    2. Commit: participants commit their value
 *    3. Reveal: participants reveal their value
 */
contract CommitRecover {
    using BigNumbers for BigNumber;
    using Pietrzak_VDF for *;
    /* Type declaration */
    /**
     * @notice Stages of the contract
     * @notice Recover can be performed in the Reveal and Finished stages.
     */
    enum Stages {
        Finished,
        Commit,
        Reveal
    }
    struct SetUpValueAtRound {
        uint256 setUpTime; //setUp time of the round
        uint256 commitDuration; // commit period
        uint256 commitRevealDuration; // commit + reveal period, commitRevealDuration - commitDuration => revealDuration
        uint256 T;
        BigNumber n;
        BigNumber g; // a value generated from the generator list
        BigNumber h; // a value generated from the VDF(g)
    }
    struct ValueAtRound {
        uint256 numOfParticipants; // number of participants
        uint256 count; //This variable is used to keep track of the number of commitments and reveals, and to check if anything has been committed when moving to the reveal stage.
        bytes bStar; // hash of commitsString
        bytes commitsString; // concatenated string of commits
        BigNumber omega; // the random number
        Stages stage; // stage of the contract
        bool isCompleted; // omega is finialized when this is true
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
    uint256 public nextRound;
    mapping(uint256 round => SetUpValueAtRound) public setUpValuesAtRound;
    mapping(uint256 round => ValueAtRound) public valuesAtRound;
    mapping(uint256 round => mapping(uint256 index => CommitRevealValue)) public commitRevealValues;
    mapping(address owner => mapping(uint256 round => UserAtRound)) public userInfosAtRound;

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
    event SetUp(
        address msgSender,
        uint256 setUpTime,
        uint256 commitDuration,
        uint256 commitRevealDuration,
        BigNumber n,
        BigNumber g,
        BigNumber h,
        uint256 T,
        uint256 round
    );
    event CalculatedOmega(uint256 round, BigNumber omega, uint256 calculatedTimestamp);

    /* Errors */
    error AlreadyCommitted();
    error NotCommittedParticipant();
    error AlreadyRevealed();
    error ModExpRevealNotMatchCommit();
    error NotAllRevealed();
    error OmegaAlreadyCompleted();
    error FunctionInvalidAtThisStage();
    error NotVerified();
    error RecovNotMatchX();
    error StageNotFinished();
    error CommitRevealDurationLessThanCommitDuration();
    error AllFinished();
    error NoneParticipated();
    error ShouldNotBeZero();

    /* Functions */
    /**
     * @param _c participant's commit value
     * @notice Commit function
     * @notice The participant's commit value must be less than the modulor
     * @notice The participant can only commit once
     * @notice check period, update stage if needed, revert if not currently at commit stage
     */
    function commit(uint256 _round, BigNumber memory _c) public {
        if (_c.isZero()) revert ShouldNotBeZero();
        if (userInfosAtRound[msg.sender][_round].committed) revert AlreadyCommitted();
        checkStage(_round);
        equalStage(_round, Stages.Commit);
        uint256 _count = valuesAtRound[_round].count;
        bytes memory _commitsString = valuesAtRound[_round].commitsString;
        _commitsString = bytes.concat(_commitsString, _c.val);
        userInfosAtRound[msg.sender][_round] = UserAtRound(_count, true, false);
        commitRevealValues[_round][_count] = CommitRevealValue(_c, BigNumbers.zero(), msg.sender); //index setUps from 0, so _count -1
        valuesAtRound[_round].commitsString = _commitsString;
        valuesAtRound[_round].count = ++_count;
        emit CommitC(msg.sender, _c, _commitsString, _count, block.timestamp);
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
    function reveal(uint256 _round, BigNumber calldata _a) public {
        UserAtRound memory _user = userInfosAtRound[msg.sender][_round];
        if (!_user.committed) revert NotCommittedParticipant();
        if (_user.revealed) revert AlreadyRevealed();
        if (
            !(setUpValuesAtRound[_round].g.modexp(_a, setUpValuesAtRound[_round].n)).eq(
                commitRevealValues[_round][_user.index].c
            )
        ) revert ModExpRevealNotMatchCommit();
        checkStage(_round);
        equalStage(_round, Stages.Reveal);
        //uint256 _count = --count;
        uint256 _count = valuesAtRound[_round].count -= 1;
        commitRevealValues[_round][_user.index].a = _a;
        if (_count == 0) {
            valuesAtRound[_round].stage = Stages.Finished;
            valuesAtRound[_round].isAllRevealed = true;
        }
        userInfosAtRound[msg.sender][_round].revealed = true;
        emit RevealA(msg.sender, _a, _count, block.timestamp);
    }

    function calculateOmega(uint256 _round) public returns (BigNumber memory) {
        if (!valuesAtRound[_round].isAllRevealed) revert NotAllRevealed();
        if (valuesAtRound[_round].isCompleted) return valuesAtRound[_round].omega;
        checkStage(_round);
        equalStage(_round, Stages.Finished);
        uint256 _numOfParticipants = valuesAtRound[_round].numOfParticipants;
        BigNumber memory _omega = BigNumbers.one();
        bytes memory _bStar = valuesAtRound[_round].bStar;
        BigNumber memory _h = setUpValuesAtRound[_round].h;
        BigNumber memory _n = setUpValuesAtRound[_round].n;
        for (uint256 i = 0; i < _numOfParticipants; i = unchecked_inc(i)) {
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
        valuesAtRound[_round].isCompleted = true; //false when not all participants have revealed
        valuesAtRound[_round].stage = Stages.Finished;
        emit CalculatedOmega(_round, _omega, block.timestamp);
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
        BigNumber memory _n = setUpValuesAtRound[_round].n;
        checkStage(_round);
        if (valuesAtRound[_round].stage == Stages.Commit) revert FunctionInvalidAtThisStage();
        if (
            valuesAtRound[_round].stage == Stages.Finished &&
            valuesAtRound[_round].numOfParticipants == 0
        ) revert NoneParticipated();
        bytes memory _bStar = valuesAtRound[_round].bStar;
        if (valuesAtRound[_round].isCompleted) revert OmegaAlreadyCompleted();
        if (!Pietrzak_VDF.verifyRecursiveHalvingProof(proofs, _n, setUpValuesAtRound[_round].T))
            revert NotVerified();
        for (uint256 i = 0; i < valuesAtRound[_round].numOfParticipants; i = unchecked_inc(i)) {
            BigNumber memory _c = commitRevealValues[_round][i].c;
            BigNumber memory temp = _c.modexp(_n.modHash(bytes.concat(_c.val, _bStar)), _n);
            //recov = mulmod(recov, temp, _n);
            recov = recov.modmul(temp, _n);
        }
        if (!recov.eq(proofs[0].x)) revert RecovNotMatchX();
        valuesAtRound[_round].isCompleted = true;
        valuesAtRound[_round].omega = proofs[0].y;
        valuesAtRound[_round].stage = Stages.Finished;
        emit Recovered(msg.sender, recov, proofs[0].y, block.timestamp);
    }

    /**
     * @notice SetUp function
     * @notice The contract must be in the Finished stage
     * @notice The commit period must be less than the commit + reveal period
     * @notice The g value must be less than the modulor
     * @notice reset count, commitsString, isHAndBStarSet, stage, setUpTime, commitDuration, commitRevealDuration, n, g, omega
     * @notice increase round
     */
    function setUp(
        uint256 _commitDuration,
        uint256 _commitRevealDuration,
        uint256 _T,
        BigNumber calldata _n,
        Pietrzak_VDF.VDFClaim[] calldata _proofs
    ) public returns (uint256 _round) {
        _round = nextRound++;
        //if (valuesAtRound[_round].stage != Stages.Finished) revert StageNotFinished();
        if (_commitDuration >= _commitRevealDuration)
            revert CommitRevealDurationLessThanCommitDuration();
        if (!Pietrzak_VDF.verifyRecursiveHalvingProof(_proofs, _n, _T)) revert NotVerified();
        valuesAtRound[_round].stage = Stages.Commit;
        setUpValuesAtRound[_round].setUpTime = block.timestamp;
        setUpValuesAtRound[_round].commitDuration = _commitDuration;
        setUpValuesAtRound[_round].commitRevealDuration = _commitRevealDuration;
        setUpValuesAtRound[_round].T = _T;
        setUpValuesAtRound[_round].g = _proofs[0].x;
        setUpValuesAtRound[_round].h = _proofs[0].y;
        setUpValuesAtRound[_round].n = _n;
        valuesAtRound[_round].count = 0;
        valuesAtRound[_round].commitsString = "";
        emit SetUp(
            msg.sender,
            block.timestamp,
            _commitDuration,
            _commitRevealDuration,
            _n,
            _proofs[0].x,
            _proofs[0].y,
            _T,
            _round
        );
    }

    /**
     * @notice checkStage function
     * @notice revert if the current stage is not the given stage
     * @notice this function is used to check if the current stage is the given stage
     * @notice it will update the stage to the next stage if needed
     */
    function checkStage(uint256 _round) public {
        uint256 _setUpTime = setUpValuesAtRound[_round].setUpTime;
        if (
            valuesAtRound[_round].stage == Stages.Commit &&
            block.timestamp >= _setUpTime + setUpValuesAtRound[_round].commitDuration
        ) {
            if (valuesAtRound[_round].count != 0) {
                nextStage(_round);
                valuesAtRound[_round].numOfParticipants = valuesAtRound[_round].count;
                // uint256 _bStar = uint256(keccak256(abi.encodePacked(commitsString))) %
                //     valuesAtRound[round].n;
                bytes memory _bStar = setUpValuesAtRound[_round]
                    .n
                    .modHash(valuesAtRound[_round].commitsString)
                    .val;
                valuesAtRound[_round].bStar = _bStar;
            } else {
                valuesAtRound[_round].stage = Stages.Finished;
            }
        }
        if (
            valuesAtRound[_round].stage == Stages.Reveal &&
            (block.timestamp >= _setUpTime + setUpValuesAtRound[_round].commitRevealDuration ||
                valuesAtRound[_round].count == 0)
        ) {
            nextStage(_round);
        }
    }

    function equalStage(uint256 _round, Stages _stage) internal view {
        if (valuesAtRound[_round].stage != _stage) revert FunctionInvalidAtThisStage();
    }

    /**
     * @notice NextStage function
     * @notice update stage to the next stage
     * @notice revert if the current stage is Finished
     */
    function nextStage(uint256 _round) internal {
        Stages _stage = valuesAtRound[_round].stage;
        if (_stage == Stages.Finished) revert AllFinished();
        valuesAtRound[_round].stage = Stages(addmod(uint256(_stage), 1, 3));
    }

    function unchecked_inc(uint256 i) private pure returns (uint) {
        unchecked {
            return i + 1;
        }
    }
}
