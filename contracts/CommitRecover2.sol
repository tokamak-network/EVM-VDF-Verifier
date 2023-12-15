// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.19;
// import "./libraries/Pietrzak_VDF.sol";

// error AlreadyCommitted();
// error NotCommittedParticipant();
// error AlreadyRevealed();
// error ModExpRevealNotMatchCommit();
// error NotAllRevealed();
// error OmegaAlreadyCompleted();
// error FunctionInvalidAtThisStage();
// error TNotMatched();
// error NotVerified();
// error RecovNotMatchX();
// error StageNotFinished();
// error CommitRevealDurationLessThanCommitDuration();
// error AllFinished();

// /**
//  * @title Bicorn-RX Commit-Reveal-Recover
//  * @author Justin g
//  * @notice This contract is for generating random number
//  *    1. Finished: Not Started | Calculate or recover the random number
//  *    2. Commit: participants commit their value
//  *    3. Reveal: participants reveal their value
//  */

// contract CommitRecover2 {
//     using BigNumbers for BigNumber;
//     using Pietrzak_VDF for *;
//     /* Type declaration */
//     /**
//      * @notice Stages of the contract
//      * @notice Recover can be performed in the Reveal and Finished stages.
//      */
//     enum Stages {
//         Finished,
//         Commit,
//         Reveal
//     }
//     struct StartValueAtRound {
//         uint256 startTime; //start time of the round
//         uint256 commitDuration; // commit period
//         uint256 commitRevealDuration; // commit + reveal period, commitRevealDuration - commitDuration => revealDuration
//         uint256 T;
//         BigNumber n;
//         BigNumber g; // a value generated from the generator list
//         BigNumber h; // a value generated from the VDF(g)
//     }
//     struct ValueAtRound {
//         uint256 numOfParticipants; // number of participants
//         uint256 count; //This variable is used to keep track of the number of commitments and reveals, and to check if anything has been committed when moving to the reveal stage.
//         bytes bStar; // hash of commitsString
//         bytes commitsString; // concatenated string of commits
//         BigNumber omega; // the random number
//         Stages stage; // stage of the contract
//         bool isCompleted; // omega is finialized when this is true
//         bool isAllRevealed; // true when all participants have revealed
//     }
//     struct CommitRevealValue {
//         BigNumber c;
//         BigNumber a;
//     }
//     struct UserAtRound {
//         uint256 index; // index of the commitRevealValues
//         bool committed; // true if committed
//         bool revealed; // true if revealed
//     }
//     /* State variables */
//     uint256 public mostRecentRound;
//     mapping(uint256 round => StartValueAtRound) public startValuesAtRound;
//     mapping(uint256 round => ValueAtRound) public valuesAtRound;
//     mapping(uint256 round => mapping(uint256 index => CommitRevealValue)) public commitRevealValues;
//     mapping(address owner => mapping(uint256 round => UserAtRound)) public userInfosAtRound;

//     /* Events */
//     event CommitC(
//         address participant,
//         BigNumber commit,
//         bytes commitsString,
//         uint256 commitCount,
//         uint256 commitTimestamp
//     );
//     event RevealA(
//         address participant,
//         BigNumber a,
//         uint256 revealLeftCount,
//         uint256 revealTimestamp
//     );
//     event Recovered(
//         address msgSender,
//         BigNumber recov,
//         BigNumber omegaRecov,
//         uint256 recoveredTimestamp
//     );
//     event Start(
//         address msgSender,
//         uint256 startTime,
//         uint256 commitDuration,
//         uint256 commitRevealDuration,
//         BigNumber n,
//         BigNumber g,
//         BigNumber h,
//         uint256 T,
//         uint256 round
//     );
//     event CalculatedOmega(uint256 round, BigNumber omega, uint256 calculatedTimestamp);

//     error AlreadyCommitted();
//     error NotCommittedParticipant();
//     error AlreadyRevealed();
//     error ModExpRevealNotMatchCommit();
//     error NotAllRevealed();
//     error OmegaAlreadyCompleted();
//     error FunctionInvalidAtThisStage();
//     error TNotMatched();
//     error NotVerified();
//     error RecovNotMatchX();
//     error StageNotFinished();
//     error CommitRevealDurationLessThanCommitDuration();
//     error AllFinished();

//     /* Functions */
//     /**
//      * @param _commit participant's commit value
//      * @notice Commit function
//      * @notice The participant's commit value must be less than the modulor
//      * @notice The participant can only commit once
//      * @notice check period, update stage if needed, revert if not currently at commit stage
//      */
//     function commit(uint256 _round, BigNumber memory _commit) public {
//         if (userInfosAtRound[msg.sender][_round].committed) revert AlreadyCommitted();
//         checkStage(_round);
//     }

//     function checkStage(uint256 _round) public {

//     }
// }
