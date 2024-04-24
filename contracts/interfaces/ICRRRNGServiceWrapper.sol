// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface ICRRRNGServiceWrapper {
    error InsufficientAmount();
    error SendFailed();
    error DisputePeriodNotEnded();
    error AlreadyLeader();

    /**
     * @notice SetUp function
     * @notice The contract must be in the Finished stage
     * @notice The commit period must be less than the commit + reveal period
     * @notice The g value must be less than the modulor
     * @notice reset count, commitsString, isHAndBStarSet, stage, setUpTime, commitDuration, commitRevealDuration, n, g, omega
     * @notice increase round
     */
    function requestRandomWordDirectFunding(
        uint32 _callbackGasLimit
    ) external payable returns (uint256);

    function calculateDirectFundingPrice(uint32 _callbackGasLimit) external view returns (uint256);
}
