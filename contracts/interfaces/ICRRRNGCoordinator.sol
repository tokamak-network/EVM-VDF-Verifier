// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Commit-Reveal-Recover
 * @author Justin g
 * @notice This contract is for generating random number
 *    1. Finished: Not SetUped | Calculate or recover the random number
 *    2. Commit: participants commit their value
 *    3. Reveal: participants reveal their value
 */
interface ICRRRNGCoordinator {
    function requestRandomWordDirectFunding(
        uint32 _callbackGasLimit
    ) external payable returns (uint256);

    function calculateDirectFundingPrice(uint32 _callbackGasLimit) external view returns (uint256);
}
