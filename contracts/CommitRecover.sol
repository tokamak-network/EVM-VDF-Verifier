// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./libraries/Strings.sol";

/* Errors */
error AlreadyCommitted();
error GreaterOrEqualThanOrder();
error AlreadyRevealed();
error NotCommittedParticipant();
error CommitRevealDurationLessThanCommitDuration();
error ANotMatchCommit();
error FunctionInvalidAtThisStage();
error StageNotFinished();
error HNotSet();
error AllFinished();
error OmegaAlreadyCompleted();

/**
 * @title Bicorn-RX Commit-Reveal-Recover
 * @author Justin G
 * @notice This contract is for generating random number
 *    1. Commit: participants commit their value
 *    2. Reveal: participants reveal their value
 *    3. Recover: someone recovers the random number
 *    4. Start: start a new round
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
    struct Commit {
        uint256 c; // commit value
        uint256 a; // reveal value
        bool committed;
        bool revealed;
    }
    struct Omega {
        uint256 omega;
        bool isCompleted; // omega is finalized when this is true
        bytes32 bStar; //hash of commitsString
    }

    /* State variables */
    uint256 public startTime;
    uint256 public commitDuration;
    uint256 public commitRevealDuration; //commit + reveal period, commitRevealDuration - commitDuration => revealDuration
    uint256 public order; // modulor
    uint256 public g; // a value generated from the generator list
    uint256 public h; // a value generated from the VDF(g)
    uint256 public omega; // the random number
    uint256 public count; //This variable is used to keep track of the number of commitments and reveals, and to check if anything has been committed when moving to the reveal stage.
    uint256 public round; //first round is 1, second round is 2, ...
    string public commitsString; //concatenated string of commits
    Stages public stage;
    bool public isHAndBStarSet;

    mapping(uint256 round => Omega omega) public omegaAtRound; // 1 => Omega(omega, isCompleted), 2 => Omega(omega, isCompleted), ...
    mapping(address owner => mapping(uint256 round => Commit commit)) public commitsInfos;

    /* Events */
    event CommitC(
        address participant,
        uint256 commit,
        string commitsString,
        uint256 commitCount,
        uint256 commitTimestamp
    );
    event RevealA(
        address participant,
        uint256 a,
        uint256 omega,
        uint256 revealLeftCount,
        uint256 revealTimestamp
    );
    event SetHAndBStar(address msgSender, uint256 h, uint256 setHTimestamp);
    event Recovered(address msgSender, uint256 recov, uint256 omega, uint256 recoveredTimestamp);

    modifier shouldNotBeGreaterOrEqualThanOrder(uint256 _value) {
        if (_value >= order) revert GreaterOrEqualThanOrder();
        _;
    }

    /* Functions */
    /**
     *
     * @param _commitDuration commit period
     * @param _commitRevealDuration commit + reveal period
     * @param _order modulor
     * @param _g a value generated from the generator list
     * @notice The constructor is called when the contract is deployed and commit starts right away
     *
     */
    constructor(
        uint256 _commitDuration,
        uint256 _commitRevealDuration,
        uint256 _order,
        uint256 _g
    ) {
        if (_g >= _order) revert GreaterOrEqualThanOrder();
        if (_commitDuration >= _commitRevealDuration)
            revert CommitRevealDurationLessThanCommitDuration();
        checkIfPrimeNumber(_order);
        stage = Stages.Commit;
        startTime = block.timestamp;
        commitDuration = _commitDuration;
        commitRevealDuration = _commitRevealDuration;
        order = _order;
        g = _g;
        omega = 1;
        round = 1;
    }

    /**
     * @param _commit participant's commit value
     * @notice Commit function
     * @notice The participant's commit value must be less than the modulor
     * @notice The participant can only commit once
     * @notice check period, update stage if needed, revert if not currently at commit stage
     */
    function commit(uint256 _commit) public shouldNotBeGreaterOrEqualThanOrder(_commit) {
        string memory _commitsString = commitsString;
        if (commitsInfos[msg.sender][round].committed) {
            revert AlreadyCommitted();
        }
        updateStage(Stages.Commit);
        _commitsString = string.concat(_commitsString, Strings.toString(_commit));
        commitsInfos[msg.sender][round] = Commit(_commit, 0, true, false);
        count += 1;
        commitsString = _commitsString;
        emit CommitC(msg.sender, _commit, _commitsString, count, block.timestamp);
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
     * @notice if count == 0, update omegaAtRound, stage
     * @notice update commitsInfos
     */
    function reveal(uint256 _a) public shouldNotBeGreaterOrEqualThanOrder(_a) {
        uint256 _omega = omega;
        if (!isHAndBStarSet) revert HNotSet();
        Commit memory _commit = commitsInfos[msg.sender][round];
        if (!_commit.committed) {
            revert NotCommittedParticipant();
        }
        if (_commit.revealed) {
            revert AlreadyRevealed();
        }
        if (powerModOrder(g, _a) != _commit.c) {
            revert ANotMatchCommit();
        }
        updateStage(Stages.Reveal);
        _omega =
            (_omega *
                powerModOrder(
                    powerModOrder(
                        h,
                        uint256(keccak256(abi.encodePacked(_commit.c, omegaAtRound[round].bStar)))
                    ),
                    _a
                )) %
            order;

        count -= 1;
        if (count == 0) {
            finalizeOmega(_omega);
        } else {
            omega = _omega;
        }
        commitsInfos[msg.sender][round].a = _a;
        commitsInfos[msg.sender][round].revealed = true;
        emit RevealA(msg.sender, _a, _omega, count, block.timestamp);
    }

    /**
     * @param recov the recovered value
     * @notice Recover function
     * @notice The recovered value must be less than the modulor
     * @notice revert if currently at commit stage
     * @notice revert if count == 0 meaning no one has committed
     * @notice calculate and finalize omega
     */
    function recover(uint256 recov) public shouldNotBeGreaterOrEqualThanOrder(recov) {
        uint256 _omega = omega;
        if (stage == Stages.Commit) {
            revert FunctionInvalidAtThisStage();
        }
        if (count == 0) {
            revert OmegaAlreadyCompleted();
        }
        /**
         * need to verify recov
         */
        _omega = mulmod(_omega, recov, order);
        finalizeOmega(_omega);
        emit Recovered(msg.sender, recov, _omega, block.timestamp);
    }

    /**
     *
     * @param _commitDuration commit period
     * @param _commitRevealDuration commit + reveal period, commitRevealDuration - commitDuration => revealDuration
     * @param _order modulor
     * @param _g a value generated from the generator list
     * @notice Start function
     * @notice The contract must be in the Finished stage
     * @notice The commit period must be less than the commit + reveal period
     * @notice The g value must be less than the modulor
     * @notice reset count, commitsString, isHAndBStarSet, stage, startTime, commitDuration, commitRevealDuration, order, g, omega
     * @notice increase round
     */
    function start(
        uint256 _commitDuration,
        uint256 _commitRevealDuration,
        uint256 _order,
        uint256 _g
    ) public {
        if (stage != Stages.Finished) {
            revert StageNotFinished();
        }
        if (_g >= _order) revert GreaterOrEqualThanOrder();
        if (_commitDuration >= _commitRevealDuration)
            revert CommitRevealDurationLessThanCommitDuration();
        checkIfPrimeNumber(order);
        stage = Stages.Commit;
        startTime = block.timestamp;
        commitDuration = _commitDuration;
        commitRevealDuration = _commitRevealDuration;
        order = _order;
        g = _g;
        omega = 1;
        round += 1;
        count = 0;
        commitsString = "";
        isHAndBStarSet = false;
    }

    /**
     * @param _h a value generated from the VDF(g)
     * @notice SetHAndBStar function
     * @notice The contract must not be in the Commit stage
     * @notice The h value must be less than the modulor
     * @notice The h value must be verified
     * @notice set isHAndBStarSet to true
     */
    function setHAndBStar(uint256 _h) public shouldNotBeGreaterOrEqualThanOrder(_h) {
        /**
         * need to verify _h
         */
        if (stage == Stages.Commit) {
            revert FunctionInvalidAtThisStage();
        }
        if (omegaAtRound[round].bStar == 0) {
            omegaAtRound[round].bStar = keccak256(abi.encodePacked(commitsString));
        }
        verifyVDFResult(g, _h);
        isHAndBStarSet = true;
        h = _h;
        emit SetHAndBStar(msg.sender, _h, block.timestamp);
    }

    /**
     * @param _stage the stage to update to
     * @notice UpdateStage function
     * @notice update stage if needed and check if the stage is the same as the input stage
     * @notice if the current stage is Commit and the commit period is over,
     * and if there are commitments, update stage to Reveal stage, else update stage to Finished stage
     * @notice if the current stage is Reveal and the reveal period is over, update stage to Finished stage
     * @notice revert if the stage is not the same as the input stage
     */
    function updateStage(Stages _stage) public {
        Stages _currentStage = stage;
        uint256 _startTime = startTime;
        if (_currentStage == Stages.Commit && block.timestamp >= _startTime + commitDuration) {
            if (count != 0) {
                nextStage();
            } else {
                stage = Stages.Finished;
            }
        }
        if (
            _currentStage == Stages.Reveal && block.timestamp >= _startTime + commitRevealDuration
        ) {
            nextStage();
        }
        if (stage != _stage) revert FunctionInvalidAtThisStage();
    }

    /**
     * @param _omega omega that should be finalized
     * @notice FinalizeOmega function
     * @notice update omegaAtRound, stage
     * @notice revert if the omega is already finalized
     * @notice set isCompleted to true
     * @notice set stage to Finished
     */
    function finalizeOmega(uint256 _omega) internal {
        if (omegaAtRound[round].isCompleted) revert OmegaAlreadyCompleted();
        omegaAtRound[round].omega = _omega;
        omegaAtRound[round].isCompleted = true;
        stage = Stages.Finished;
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

    /**
     *
     * @param _input input value of VDF
     * @param _result result of VDF
     * @return true if the result is correct, false otherwise
     * @notice verifyVDFResult function
     * @notice need to verify _result is generated from _input
     * @notice need to verify _result is less than the modulor
     */
    function verifyVDFResult(
        uint256 _input,
        uint256 _result
    ) internal view shouldNotBeGreaterOrEqualThanOrder(_result) returns (bool) {
        /**
         * need to verify
         */
        return true;
    }

    /**
     *
     * @param a base value
     * @param b exponent value
     * @return result of a^b mod order
     * @notice powerModOrder function
     * @notice calculate a^b mod order
     * @notice O(log b) complexity
     */
    function powerModOrder(uint256 a, uint256 b) internal view returns (uint256) {
        uint256 _order = order;
        uint256 result = 1;
        while (b > 0) {
            if (b & 1 == 1) {
                result = mulmod(result, a, _order);
            }
            a = mulmod(a, a, _order);
            b = b / 2;
        }
        return result;
    }

    /**
     * @param _number the number to check
     * @return true if the number is prime, false otherwise
     * @notice checkIfPrimeNumber function
     * @notice O(sqrt(n)) complexity
     */
    function checkIfPrimeNumber(uint256 _number) internal pure returns (bool) {
        if (_number < 2) {
            return false;
        }
        uint256 i = 2;
        while (i <= sqrt(_number)) {
            if (_number % i == 0) {
                return false;
            }
            i++;
        }
        return true;
    }

    /**
     * @notice sqrt function
     * @notice Calculates the square root of x, rounding down.
     * @notice from prb-math
     * @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
     * @param x The uint256 number for which to calculate the square root.
     * @return result The result as an uint256.
     *
     */
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Calculate the square root of the perfect square of a power of two that is the closest to x.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}
