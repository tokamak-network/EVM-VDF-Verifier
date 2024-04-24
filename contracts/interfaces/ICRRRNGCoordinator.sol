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
interface ICRRRNGCoordinator {
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
    struct ValueAtRound {
        uint256 startTime;
        uint256 numOfPariticipants;
        uint256 count; //This variable is used to keep track of the number of commitments and reveals, and to check if anything has been committed when moving to the reveal stage.
        address consumer;
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
    event CommitC(uint256 commitCount, bytes commitVal);
    event RevealA(uint256 revealLeftCount, bytes aVal);
    event Recovered(uint256 round, bytes recov, bytes omega, bool success);
    event RandomWordsRequested(uint256 round, address sender);
    event CalculateOmega(uint256 round, bytes omega);

    /* Errors */
    error ReentrancyGuard();
    error AlreadyVerified();
    error AlreadyCommitted();
    error NotCommittedParticipant();
    error AlreadyRevealed();
    error ModExpRevealNotMatchCommit();
    error NotAllRevealed();
    error OmegaAlreadyCompleted();
    error FunctionInvalidAtThisStage();
    error NotVerifiedAtTOne();
    error RecovNotMatchX();
    error NoneParticipated();
    error ShouldNotBeZero();
    error TOneNotAtLast();
    error InvalidProofsLength();
    error TwoOrMoreCommittedPleaseRecover();
    error NotStartedRound();
    error NotVerified();
    error StillInCommitStage();
    error InsufficientDepositAmount();
    error NotOperator();
    error OmegaNotCompleted();
    error NotLeader();
    error DisputePeriodEnded();
    error XPrimeNotEqualAtIndex(uint256 index);
    error YPrimeNotEqualAtIndex(uint256 index);

    /* Functions */
    // external
    /**
     * @param c participant's commit value
     * @notice Commit function
     * @notice The participant's commit value must be less than the modulor
     * @notice The participant can only commit once
     * @notice check period, update stage if needed, revert if not currently at commit stage
     */
    function commit(uint256 round, BigNumber calldata c) external;

    /**
     * @param a participant's reveal value
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
    function reveal(uint256 round, BigNumber calldata a) external;

    function calculateOmega(uint256 round) external;

    /**
     * @notice Recover function
     * @notice The recovered value must be less than the modulor
     * @notice revert if currently at commit stage
     * @notice revert if count == 0 meaning no one has committed
     * @notice calculate and finalize omega
     */
    function recover(
        uint256 round,
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta
    ) external;

    // getter functions

    function getSetUpValues()
        external
        view
        returns (uint256, uint256, uint256, uint256, bytes memory, bytes memory, bytes memory);

    function getNextRound() external view returns (uint256);

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
