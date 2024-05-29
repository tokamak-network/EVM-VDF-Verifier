// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ICRRRNGCoordinator} from "./interfaces/ICRRRNGCoordinator.sol";
import {VDFCRRNGPoF} from "./VDFCRRNGPoF.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOVM_GasPriceOracle} from "./interfaces/IOVM_GasPriceOracle.sol";

/// @title Commit-Recover Random Number Generator Coordinator
/// @author Justin G
/// @notice This contract is not audited
/// @notice  This contract is for generating random number
contract CRRNGCoordinatorPoF is ICRRRNGCoordinator, Ownable, VDFCRRNGPoF {
    // *** State variables
    // * private
    uint256 private s_avgL2GasUsed;
    uint256 private s_premiumPercentage;
    uint256 private s_flatFee;

    /// @notice The deployer becomes the owner of the contract
    /// @dev no zero checks
    /// @param disputePeriod The dispute period after recovery
    /// @param minimumDepositAmount The minimum deposit amount to become operators
    /// @param avgL2GasUsed The average gas cost for recovery of the random number
    /// @param premiumPercentage The percentage of the premium, will be set to 0
    /// @param flatFee The flat fee for the direct funding
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

    /** @notice Sets the settings for the contract. The owner will be transfer to mini DAO contract in the future.
     *  1. only owner can set the settings<br>
     *  2. no safety checks for values since it is only owner
     * @param disputePeriod The dispute period after recovery
     * @param minimumDepositAmount The minimum deposit amount to become operators
     * @param avgL2GasUsed The average gas cost for recovery of the random number
     * @param premiumPercentage The percentage of the premium, will be set to 0
     * @param flatFee The flat fee for the direct funding
     */
    function setSettings(
        uint256 disputePeriod,
        uint256 minimumDepositAmount,
        uint256 avgL2GasUsed,
        uint256 avgL1GasUsed,
        uint256 premiumPercentage,
        uint256 flatFee
    ) external onlyOwner {
        s_disputePeriod = disputePeriod;
        s_minimumDepositAmount = minimumDepositAmount;
        s_avgL2GasUsed = avgL2GasUsed;
        s_avgL1GasUsed = avgL1GasUsed;
        s_premiumPercentage = premiumPercentage;
        s_flatFee = flatFee;
    }

    /**  @param callbackGasLimit  Test and adjust this limit based on the processing of the callback request in your fulfillRandomWords() function.
     * @return requestId The round ID of the request
     * @notice Consumer requests a random number, the consumer must send the cost of the request. There is refund logic in the contract to refund the excess amount sent by the consumer, so nonReentrant modifier is used to prevent reentrancy attacks.
     * - checks
     * 1. Reverts when reentrancy is detected
     * 2. Reverts when the VDF values are not verified
     * 3. Reverts when the number of operators is less than 2
     * 4. Reverts when the value sent from consumer is less than the _calculateDirectFundingPrice function result
     * - effects
     * 1. Increments the round number
    //  * 2. Sets the start time of the round
     * 3. Sets the stage of the round to Commit, commit starts
     * 4. Sets the msg.sender as the consumer of the round, doesn't check if the consumer is EOA or CA
     * 5. Sets the cost of the round, derived from the _calculateDirectFundingPrice function
     * 6. Emits a RandomWordsRequested(round, msg.sender) event
     * - interactions
     * 1. Refunds the excess amount sent over the result of the _calculateDirectFundingPrice function, reverts if the refund fails
     */
    function requestRandomWordDirectFunding(
        uint32 callbackGasLimit
    ) external payable nonReentrant returns (uint256) {
        if (!s_initialized) revert NotVerified();
        if (s_operatorCount < 2) revert NotEnoughOperators();
        uint256 cost = _calculateDirectFundingPrice(callbackGasLimit, tx.gasprice);
        if (msg.value < cost) revert InsufficientAmount();
        uint256 _round = s_nextRound++;
        s_valuesAtRound[_round].stage = Stages.Commit;
        s_valuesAtRound[_round].consumer = msg.sender;
        s_cost[_round] = cost;
        emit RandomWordsRequested(_round, msg.sender);
        bool success = _send(msg.sender, gasleft(), msg.value - cost);
        if (!success) revert SendFailed();
        return _round;
    }

    /**
     * @param round The round ID of the request
     * @notice This function can be called by anyone to restart the commit stage of the round when commits are less than 2 after the commit stage ends
     * - checks
     * 1. Reverts when the current block timestamp is less than the start time of the round plus the commit duration, meaning the commit stage is still ongoing
     * 2. Reverts when the number of commits is more than 1, because the recovery stage is already started
     * - effects
     * 1. Resets the stage of the round to Commit
     * 2. Resets the start time of the round
     * 3. ReEmits a RandomWordsRequested(round, msg.sender) event
     */
    function reRequestRandomWordAtRound(
        uint256 round
    ) external nonReentrant checkStage(round, Stages.Recover) {
        // check
        if (s_operatorCount < 2) revert NotEnoughOperators();
        if (s_valuesAtRound[round].startTime == 0) revert CommitNotStarted();
        if (block.timestamp < s_valuesAtRound[round].startTime + COMMITDURATION)
            revert StillInCommitStage();
        if (s_valuesAtRound[round].commitCounts > 1) revert TwoOrMoreCommittedPleaseRecover();
        s_valuesAtRound[round].stage = Stages.Commit;
        s_valuesAtRound[round].startTime = block.timestamp;
        emit RandomWordsRequested(round, msg.sender);
    }

    /**
     * @notice This function is for anyone to become an operator by depositing the minimum deposit amount, also for operators to increase their deposit amount
     * - checks
     * 1. Reverts when the deposit amount of the msg.sender plus the value sent is less than the minimum deposit amount
     * - effects
     * 1. Increments the operator count when the msg.sender was not an operator before
     * 2. Sets the operator status of the msg.sender to true
     * 3. Increments the deposit amount of the msg.sender
     */
    function operatorDeposit() external payable {
        uint256 sumAmount = s_depositedAmount[msg.sender] + msg.value;
        if (sumAmount < s_minimumDepositAmount) revert CRRNGCoordinator_InsufficientDepositAmount();
        if (!s_operators[msg.sender]) {
            unchecked {
                ++s_operatorCount;
            }
            s_operators[msg.sender] = true;
        }
        unchecked {
            s_depositedAmount[msg.sender] = sumAmount;
        }
    }

    /**
     * @param amount The amount to withdraw
     * @notice This function is for operators to withdraw their deposit amount, also for operators to decrease their deposit amount
     * - checks
     * 1. Reverts when the dispute end time of the operator is more than the current block timestamp, meaning the operator could be in a dispute
     * 2. Reverts when the parameter amount is more than the deposit amount of the operator
     * - effects
     * 1. If the deposit amount of the operator minus the amount is less than the minimum deposit amount
     * <br>&nbsp;- Sets the operator status of the operator to false
     * <br>&nbsp;- Decrements the operator count
     * 2. Decrements the deposit amount of the operator
     * - interactions
     * 1. Sends the amount to the operator, reverts if the send fails
     */
    function operatorWithdraw(uint256 amount) external onlyOperator nonReentrant {
        uint256 depositAmount = s_depositedAmount[msg.sender];
        if (s_disputeEndTimeForOperator[msg.sender] > block.timestamp)
            revert DisputePeriodNotEnded();
        if (depositAmount < amount) revert CRRNGCoordinator_InsufficientDepositAmount();
        if (depositAmount - amount < s_minimumDepositAmount) {
            s_operators[msg.sender] = false;
            unchecked {
                s_operatorCount--;
            }
        }
        s_depositedAmount[msg.sender] -= amount;
        bool success = _send(msg.sender, gasleft(), amount);
        if (!success) revert SendFailed();
    }

    /**
     * @param _callbackGasLimit The gas limit for the processing of the callback request in consumer's fulfillRandomWords() function.
     * @param gasPrice The expected gas price for the callback transaction.
     * @return calculatedDirectFundingPrice The cost of the direct funding
     * @notice This function is for the consumer to estimate the cost of the direct funding
     * 1. returns cost =  (((gasPrice * (_callbackGasLimit + s_avgL2GasUsed)) * (s_premiumPercentage + 100)) / 100) + s_flatFee;
     */
    function estimateDirectFundingPrice(
        uint32 _callbackGasLimit,
        uint256 gasPrice
    ) external view returns (uint256) {
        return _calculateDirectFundingPrice(_callbackGasLimit, gasPrice);
    }

    /**
     * @param _callbackGasLimit The gas limit for the processing of the callback request in consumer's fulfillRandomWords() function.
     * @return calculatedDirectFundingPrice The cost of the direct funding
     * @notice This function is for the consumer to calculate the cost of the direct funding with the current gas price on-chain
     * 1. returns cost =  (((tx.gasprice * (_callbackGasLimit + s_avgL2GasUsed)) * (s_premiumPercentage + 100)) / 100) + s_flatFee;
     */
    function calculateDirectFundingPrice(
        uint32 _callbackGasLimit
    ) external view override returns (uint256) {
        return _calculateDirectFundingPrice(_callbackGasLimit, tx.gasprice);
    }

    // *** getter functions
    /**
     * @param round The round ID of the request
     * @return disputeEndTimeAtRound The dispute end time of the round
     * @return leaderAtRound The leader of the round
     * @notice This getter function is for anyone to get the dispute end time and the leader of the round
     * - return order
     * 0. dispute end time
     * 1. leader
     */
    function getDisputeEndTimeAndLeaderAtRound(
        uint256 round
    ) external view returns (uint256, address) {
        return (s_disputeEndTimeAtRound[round], s_leaderAtRound[round]);
    }

    /**
     * @param operator The operator address
     * @return s_disputeEndTimeForOperator The dispute end time of the operator
     * @notice This getter function is for anyone to get the dispute end time and all the incentive of the operator
     * - return order
     * 0. dispute end time
     * 1. incentive
     */
    function getDisputeEndTimeOfOperator(address operator) external view returns (uint256) {
        return s_disputeEndTimeForOperator[operator];
    }

    /**
     * @param round The round ID of the request
     * @return costOfRound The cost of the round. The cost includes the _callbackGasLimit, recovery gas cost, premium, and flat fee. premium is set to 0.
     * @notice This getter function is for anyone to get the cost of the round
     */
    function getCostAtRound(uint256 round) external view returns (uint256) {
        return s_cost[round];
    }

    /**
     * @param operator The operator address
     * @return depositAmount The deposit amount of the operator
     * @notice This getter function is for anyone to get the deposit amount of the operator
     */
    function getDepositAmount(address operator) external view returns (uint256) {
        return s_depositedAmount[operator];
    }

    function getFulfillStatusAtRound(uint256 round) external view returns (FulfillStatus memory) {
        return s_fulfillStatus[round];
    }

    function getOperatorCount() external view returns (uint256) {
        return s_operatorCount;
    }

    /**
     * @return minimumDepositAmount The minimum deposit amount to become operators
     * @notice This getter function is for anyone to get the minimum deposit amount to become operators
     */
    function getMinimumDepositAmount() external view returns (uint256) {
        return s_minimumDepositAmount;
    }

    /**
     * @return nextRound The next round ID
     * @notice This getter function is for anyone to get the next round ID
     */
    function getNextRound() external view returns (uint256) {
        return s_nextRound;
    }

    function getFeeSettings() external view returns (uint256, uint256, uint256, uint256, uint256) {
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

    /**
     * @param _round The round ID of the request
     * @return The values of the round that are used for commit and recovery stages. The return value is struct ValueAtRound
     * @notice This getter function is for anyone to get the values of the round that are used for commit and recovery stages
     * - [0]: startTime -> The start time of the round
     * - [1]:numOfPariticipants -> This is the number of operators who have committed to the round. And this is updated on the recovery stage.
     * - [2]: count -> The number of operators who have committed to the round. And this is updated real-time.
     * - [3]: consumer -> The address of the consumer of the round
     * - [4]: bStar -> The bStar value of the round. This is updated on recovery stage.
     * - [5]: commitsString -> The concatenated string of the commits of the operators. This is updated when commit
     * - [6]: omega -> The omega value of the round. This is updated after recovery.
     * - [7]: stage -> The stage of the round. 0 is Recovered or NotStarted, 1 is Commit
     * - [8]: isCompleted -> The flag to check if the round is completed. This is updated after recovery.
     */
    function getValuesAtRound(uint256 _round) external view returns (ValueAtRound memory) {
        return s_valuesAtRound[_round];
    }

    function getConsumerAtRound(uint256 round) external view returns (address) {
        return s_valuesAtRound[round].consumer;
    }

    /**
     * @param _operator The operator address
     * @param _round The round ID of the request
     * @return The status of the operator at the round. The return value is struct UserStatusAtRound
     * @notice This getter function is for anyone to get the status of the operator at the round
     *
     * - [0]: index -> The index of the commitValue array of the operator
     * - [1]: committed -> The flag to check if the operator has committed to the round
     */
    function getUserStatusAtRound(
        address _operator,
        uint256 _round
    ) external view returns (OperatorStatusAtRound memory) {
        return s_operatorStatusAtRound[_round][_operator];
    }

    function isOperator(address operator) external view returns (bool) {
        return s_operators[operator];
    }

    function isInitialized() external view returns (bool) {
        return s_initialized;
    }

    /**
     * @param _round The round ID of the request
     * @return The commit value and the operator address of the round. The return value is struct CommitValue
     * @notice This getter function is for anyone to get the commit value and the operator address of the round
     * - [0]: commit -> The commit value of the operator
     * - [2]: operator -> The operator address
     */
    function getCommitValue(
        uint256 _round,
        uint256 _index
    ) external view returns (CommitValue memory) {
        return s_commitValues[_round][_index];
    }

    /**
     * @param _callbackGasLimit The gas limit for the processing of the callback request in consumer's fulfillRandomWords() function.
     * @param gasPrice The gas price for the callback transaction.
     * @return calculatedDirectFundingPrice The cost of the direct funding
     * @notice This function is for the contract to calculate the cost of the direct funding
     * - returns cost =  (((gasPrice * (_callbackGasLimit + s_avgL2GasUsed)) * (s_premiumPercentage + 100)) / 100) + s_flatFee;
     */
    function _calculateDirectFundingPrice(
        uint32 _callbackGasLimit,
        uint256 gasPrice
    ) private view returns (uint256) {
        return
            (((gasPrice * (_callbackGasLimit + s_avgL2GasUsed)) * (s_premiumPercentage + 100)) /
                100) +
            s_flatFee +
            _getCurrentTxL1GasFee();
    }

    function _calculateRecoveryGasPrice(uint256 gasPrice) private view returns (uint256) {
        return
            (gasPrice * s_avgL2GasUsed * (s_premiumPercentage + 100)) /
            100 +
            _getCurrentTxL1GasFee();
    }

    function _calculateCallbackGasLimitPrice(
        uint32 _callbackGasLimit,
        uint256 gasPrice
    ) private view returns (uint256) {
        return ((gasPrice * _callbackGasLimit * (s_premiumPercentage + 100)) / 100) + s_flatFee;
    }

    /// @notice Performs a low level call without copying any returndata.
    /// @notice Passes no calldata to the call context.
    /// @param _target   Address to call
    /// @param _gas      Amount of gas to pass to the call
    /// @param _value    Amount of value to pass to the call
    function _send(address _target, uint256 _gas, uint256 _value) private returns (bool) {
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
