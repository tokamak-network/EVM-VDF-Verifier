// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {DRBCoordinatorMock} from "../../src/DRBCoordinatorMock.sol";

contract DeployDRBCoordinatorMock is Script {
    uint256 public avgL2GasUsed = 2100000;
    uint256 public premiumPercentage = 0;
    uint256 public flatFee = 0.001 ether;
    /// @dev calldataSize Bytes for 2 commits, 2 reveals, 1 calculateOmegaAndFulfill
    uint256 public calldataSizeBytes = 2071;

    function run() external returns (DRBCoordinatorMock drbCoordinatorMock) {
        vm.startBroadcast();
        drbCoordinatorMock = new DRBCoordinatorMock(
            avgL2GasUsed,
            premiumPercentage,
            flatFee,
            calldataSizeBytes
        );
        vm.stopBroadcast();
    }
}
