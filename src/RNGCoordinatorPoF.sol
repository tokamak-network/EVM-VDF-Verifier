// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRNGCoordinator} from "./interfaces/IRNGCoordinator.sol";
import {VDFPoF} from "./VDFPoF.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Proof of Fraud, Random Number Generator Coordinator
/// @author Justin G
/// @notice This contract is for generating random numbers and is not audited.
/// @dev Implements the IRNGCoordinator interface and inherits from Ownable and VDFRNGPoF.
contract RNGCoordinatorPoF is IRNGCoordinator, Ownable, VDFPoF {
    // *** State variables
    // * private
    uint256 private s_avgL2GasUsed;
    uint256 private s_premiumPercentage;
    uint256 private s_flatFee;

    /// @notice Constructor to initialize the RNGCoordinatorPoF contract.
    /// @param disputePeriod The dispute period for the contract.
    /// @param minimumDepositAmount The minimum deposit amount required from operators.
    /// @param avgL2GasUsed The average L2 gas used. 3 commits + 1 recover + 1 fulfill gasUsed
    /// @param avgL1GasUsed The average L1 gas used. 3 commits + 1 recover + 1 fulfill calldata gas
    /// @param premiumPercentage The premium percentage to be applied.
    /// @param penaltyPercentage The penalty percentage to be applied.
    /// @param flatFee The flat fee to be charged.
    constructor(
        uint256 disputePeriod,
        uint256 minimumDepositAmount,
        uint256 avgL2GasUsed,
        uint256 avgL1GasUsed,
        uint256 premiumPercentage,
        uint256 penaltyPercentage,
        uint256 flatFee
    ) Ownable(msg.sender) {
        s_avgL2GasUsed = avgL2GasUsed;
        s_minimumDepositAmount = minimumDepositAmount;
        s_premiumPercentage = premiumPercentage;
        s_disputePeriod = disputePeriod;
        s_penaltyPercentage = penaltyPercentage;
        s_avgL1GasUsed = avgL1GasUsed;
        s_l1GasUsedTitan = avgL1GasUsed + 20000;
        s_flatFee = flatFee;
    }

    function setSettingVariables(
        uint256 disputePeriod,
        uint256 minimumDepositAmount,
        uint256 avgL2GasUsed,
        uint256 avgL1GasUsed,
        uint256 premiumPercentage,
        uint256 penaltyPercentage,
        uint256 flatFee
    ) external onlyOwner {
        s_avgL2GasUsed = avgL2GasUsed;
        s_minimumDepositAmount = minimumDepositAmount;
        s_premiumPercentage = premiumPercentage;
        s_disputePeriod = disputePeriod;
        s_penaltyPercentage = penaltyPercentage;
        s_avgL1GasUsed = avgL1GasUsed;
        s_l1GasUsedTitan = avgL1GasUsed + 20000;
        s_flatFee = flatFee;
    }

    /// @notice Requests a random word with direct funding.
    /// @param callbackGasLimit The gas limit for the callback function.
    /// @return round The round number of the request.
    function requestRandomWordDirectFunding(
        uint32 callbackGasLimit
    ) external payable nonReentrant returns (uint256 round) {
        if (!s_initialized) revert NotVerified();
        if (s_operatorCount < 2) revert NotEnoughOperators();
        uint256 cost = _calculateDirectFundingPrice(
            callbackGasLimit,
            tx.gasprice
        );
        if (msg.value < cost) revert InsufficientAmount();
        round = s_nextRound++;
        s_valuesAtRound[round].consumer = msg.sender;
        s_valuesAtRound[round].requestedTime = block.timestamp;
        s_cost[round] = msg.value;
        s_callbackGasLimit[round] = callbackGasLimit;
        emit RandomWordsRequested(round);
    }

    /// @notice Re-requests a random word at a specific round.
    /// @param round The round number for which to re-request the random word.
    function reRequestRandomWordAtRound(
        uint256 round
    ) external startedRound(round) nonReentrant {
        // check
        if (s_operatorCount < 2) revert NotEnoughOperators();
        if (s_valuesAtRound[round].commitEndTime == 0)
            revert CommitNotStarted();
        if (block.timestamp < s_valuesAtRound[round].commitEndTime)
            revert StillInCommitPhase();
        uint256 count = s_commitValues[round].length - s_ignoredCounts[round];
        if (count > 1) revert TwoOrMoreCommittedPleaseRecover();
        if (count == 1) {
            unchecked {
                ++s_ignoredCounts[round];
            }
        }
        s_valuesAtRound[round].commitEndTime = 0;
        emit RandomWordsRequested(round);
    }

    /// @notice Refunds at a specific round.
    /// @param round The round number for which to process the refund.
    function refundAtRound(
        uint256 round
    ) external startedRound(round) nonReentrant {
        // check
        if (s_valuesAtRound[round].consumer != msg.sender) revert NotConsumer();
        uint256 count = s_commitValues[round].length - s_ignoredCounts[round];
        if (
            s_valuesAtRound[round].requestedTime + 180 < block.timestamp &&
            count == 0
        ) _refund(round);
        else {
            if (block.timestamp < s_valuesAtRound[round].commitEndTime)
                revert StillInCommitPhase();
            if (count < 2) _refund(round);
        }
    }

    /// @notice Allows operators to deposit funds. or to become an operator.
    function operatorDeposit() external payable {
        uint256 sumAmount = s_depositedAmount[msg.sender] + msg.value;
        if (sumAmount < s_minimumDepositAmount)
            revert InsufficientDepositAmount();
        if (!s_isOperators[msg.sender]) {
            s_isOperators[msg.sender] = true;
            emit OperatorNumberChanged(++s_operatorCount, msg.sender, true);
        }
        s_depositedAmount[msg.sender] = sumAmount;
    }

    /// @notice Allows operators to withdraw funds.
    /// @param amount The amount to withdraw.
    function operatorWithdraw(uint256 amount) external nonReentrant {
        uint256 depositAmount = s_depositedAmount[msg.sender];
        if (s_disputeEndTimeForOperator[msg.sender] > block.timestamp)
            revert DisputePeriodNotEnded();
        if (depositAmount < amount) revert InsufficientDepositAmount();
        if (
            depositAmount - amount < s_minimumDepositAmount &&
            s_isOperators[msg.sender]
        ) {
            s_isOperators[msg.sender] = false;
            emit OperatorNumberChanged(--s_operatorCount, msg.sender, false);
        }
        s_depositedAmount[msg.sender] -= amount;
        bool success = _send(msg.sender, gasleft(), amount);
        if (!success) revert SendFailed();
    }

    /// @notice Estimates the direct funding price.
    /// @param _callbackGasLimit The gas limit for the callback function.
    /// @param gasPrice The gas price to be used for the estimation.
    /// @return The estimated direct funding price.
    function estimateDirectFundingPrice(
        uint32 _callbackGasLimit,
        uint256 gasPrice
    ) external view returns (uint256) {
        return _calculateDirectFundingPrice(_callbackGasLimit, gasPrice);
    }

    // @notice Calculates the direct funding price.
    /// @param _callbackGasLimit The gas limit for the callback function.
    /// @return The calculated direct funding price.
    function calculateDirectFundingPrice(
        uint32 _callbackGasLimit
    ) external view override returns (uint256) {
        return _calculateDirectFundingPrice(_callbackGasLimit, tx.gasprice);
    }

    function getDisputeEndTimeOfOperator(
        address operator
    ) external view returns (uint256) {
        return s_disputeEndTimeForOperator[operator];
    }

    function getCostAtRound(uint256 round) external view returns (uint256) {
        return s_cost[round];
    }

    function getCommitCountAtRound(
        uint256 round
    ) external view returns (uint256) {
        return s_commitValues[round].length;
    }

    function getValidCommitCountAtRound(
        uint256 round
    ) external view returns (uint256) {
        return s_commitValues[round].length - s_ignoredCounts[round];
    }

    function getDepositAmount(
        address operator
    ) external view returns (uint256) {
        return s_depositedAmount[operator];
    }

    function getOperatorCount() external view returns (uint256) {
        return s_operatorCount;
    }

    function getMinimumDepositAmount() external view returns (uint256) {
        return s_minimumDepositAmount;
    }

    function getNextRound() external view returns (uint256) {
        return s_nextRound;
    }

    function getFeeSettings()
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        return (
            s_minimumDepositAmount,
            s_avgL2GasUsed,
            s_avgL1GasUsed,
            s_premiumPercentage,
            s_flatFee
        );
    }

    function getDisputePeriod() external view returns (uint256) {
        return s_disputePeriod;
    }

    function getValuesAtRound(
        uint256 _round
    ) external view returns (ValueAtRound memory) {
        return s_valuesAtRound[_round];
    }

    function getConsumerAtRound(uint256 round) external view returns (address) {
        return s_valuesAtRound[round].consumer;
    }

    function isOperator(address operator) external view returns (bool) {
        return s_isOperators[operator];
    }

    function isInitialized() external view returns (bool) {
        return s_initialized;
    }

    function _calculateDirectFundingPrice(
        uint32 _callbackGasLimit,
        uint256 gasPrice
    ) private view returns (uint256) {
        return
            (((gasPrice * (_callbackGasLimit + s_avgL2GasUsed)) *
                (s_premiumPercentage + 100)) / 100) +
            s_flatFee +
            _getCurrentTxL1GasFee();
    }

    function _calculateRecoveryGasPrice(
        uint256 gasPrice
    ) private view returns (uint256) {
        return
            (gasPrice * s_avgL2GasUsed * (s_premiumPercentage + 100)) /
            100 +
            _getCurrentTxL1GasFee();
    }

    function _calculateCallbackGasLimitPrice(
        uint32 _callbackGasLimit,
        uint256 gasPrice
    ) private view returns (uint256) {
        return
            ((gasPrice * _callbackGasLimit * (s_premiumPercentage + 100)) /
                100) + s_flatFee;
    }

    function _refund(uint256 round) private {
        s_valuesAtRound[round].commitEndTime = 0;
        // interaction
        uint256 refundAmount = s_cost[round];
        bool success = _send(msg.sender, gasleft(), refundAmount);
        if (!success) revert SendFailed();
    }

    /// @notice Performs a low level call without copying any returndata.
    /// @notice Passes no calldata to the call context.
    /// @param _target   Address to call
    /// @param _gas      Amount of gas to pass to the call
    /// @param _value    Amount of value to pass to the call
    function _send(
        address _target,
        uint256 _gas,
        uint256 _value
    ) private returns (bool) {
        bool _success;
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                0, // inloc
                0, // inlen
                0, // outloc
                0 // outlen
            )
        }
        return _success;
    }
}
