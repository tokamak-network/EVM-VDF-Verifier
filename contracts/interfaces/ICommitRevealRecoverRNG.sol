// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {BigNumber} from "../libraries/BigNumbers.sol";

/**
 * @title Commit-Reveal-Recover
 * @author Justin g
 * @notice This contract is for generating random number
 *    1. Finished: Not SetUped | Calculate or recover the random number
 *    2. Commit: participants commit their value
 *    3. Reveal: participants reveal their value
 */
interface ICommitRevealRecoverRNG {
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
    struct VDFClaim {
        uint256 T;
        BigNumber x;
        BigNumber y;
        BigNumber v;
    }
    struct SetUpValueAtRound {
        uint256 setUpTime; //setUp time of the round
        uint256 commitDuration; // commit period
        uint256 commitRevealDuration; // commit + reveal period, commitRevealDuration - commitDuration => revealDuration
        uint256 T;
        uint256 proofSize;
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
    error TNotMatched();
    error NotVerifiedAtTOne();
    error RecovNotMatchX();
    error StageNotFinished();
    error CommitRevealDurationLessThanCommitDuration();
    error AllFinished();
    error NoneParticipated();
    error ShouldNotBeZero();
    error TOneNotAtLast();
    error iNotMatchProofSize();
    error XPrimeNotEqualAtIndex(uint256 index);
    error YPrimeNotEqualAtIndex(uint256 index);

    /* Functions */
    /**
     * @param _c participant's commit value
     * @notice Commit function
     * @notice The participant's commit value must be less than the modulor
     * @notice The participant can only commit once
     * @notice check period, update stage if needed, revert if not currently at commit stage
     */
    function commit(uint256 _round, BigNumber memory _c) external;

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
    function reveal(uint256 _round, BigNumber calldata _a) external;

    function calculateOmega(uint256 _round) external returns (BigNumber memory);

    /**
     * @param proofs the proof of the recovered value
     * @notice Recover function
     * @notice The recovered value must be less than the modulor
     * @notice revert if currently at commit stage
     * @notice revert if count == 0 meaning no one has committed
     * @notice calculate and finalize omega
     */
    function recover(uint256 _round, VDFClaim[] calldata proofs) external;

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
        BigNumber calldata _n,
        VDFClaim[] calldata _proofs
    ) external returns (uint256 _round);

    function getNextRound() external view returns (uint256);

    function getSetUpValuesAtRound(uint256 _round) external view returns (SetUpValueAtRound memory);

    function getValuesAtRound(uint256 _round) external view returns (ValueAtRound memory);

    function getCommitRevealValues(
        uint256 _round,
        uint256 _index
    ) external view returns (CommitRevealValue memory);

    function getUserInfosAtRound(
        address _owner,
        uint256 _round
    ) external view returns (UserAtRound memory);
}
