// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {ICRRRNGServiceWrapper} from "./interfaces/ICRRRNGServiceWrapper.sol";

abstract contract RNGConsumerBase {
    error OnlyCoordinatorCanFulfill(address have, address want);
    ICRRRNGServiceWrapper internal immutable i_rngCoordinator;

    /**
     * @param rngCoordinator The address of the RNGCoordinator contract
     */
    constructor(address rngCoordinator) {
        i_rngCoordinator = ICRRRNGServiceWrapper(rngCoordinator);
    }

    function requestRandomness(uint32 _callbackGasLimit) internal returns (uint256, uint256) {
        uint256 requestPrice = i_rngCoordinator.calculateDirectFundingPrice(_callbackGasLimit);
        uint256 requestId = i_rngCoordinator.requestRandomWordDirectFunding{value: requestPrice}(
            _callbackGasLimit
        );
        return (requestId, requestPrice);
    }

    function getCalculatedDirectFundingPrice(
        uint32 _callbackGasLimit
    ) external view returns (uint256) {
        return i_rngCoordinator.calculateDirectFundingPrice(_callbackGasLimit);
    }

    function fulfillRandomWords(uint256 round, uint256 hashedOmegaVal) internal virtual;

    function rawFulfillRandomWords(uint256 round, uint256 hashedOmegaVal) external {
        if (msg.sender != address(i_rngCoordinator)) {
            revert OnlyCoordinatorCanFulfill(msg.sender, address(i_rngCoordinator));
        }
        fulfillRandomWords(round, hashedOmegaVal);
    }
}
