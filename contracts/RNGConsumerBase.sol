// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

abstract contract RNGConsumerBase {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address internal immutable i_rngCoordinator;

    /**
     * @param rngCoordinator The address of the RNGCoordinator contract
     */
    constructor(address rngCoordinator) {
        i_rngCoordinator = rngCoordinator;
    }

    function fulfillRandomWords(uint256 round, uint256 hashedOmegaVal) internal virtual;

    function rawFulfillRandomWords(uint256 round, uint256 hashedOmegaVal) external {
        if (msg.sender != i_rngCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, i_rngCoordinator);
        }
        fulfillRandomWords(round, hashedOmegaVal);
    }
}
