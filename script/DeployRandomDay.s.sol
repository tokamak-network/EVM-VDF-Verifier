// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Script, console2} from "forge-std/Script.sol";
import {RandomDay} from "../src/consumers/RandomDay.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRandomDay is Script {
    function deployRandomDayUsingConfig(
        address rNGCoordinatorPoFAddress
    ) internal returns (RandomDay randomDay) {
        HelperConfig helperConfig = new HelperConfig();
        address tonTokenAddress = helperConfig.activeNetworkConfig();
        randomDay = deployRandomDay(rNGCoordinatorPoFAddress, tonTokenAddress);
    }

    function deployRandomDay(
        address rNGCoordinatorPoFAddress,
        address tonTokenAddress
    ) internal returns (RandomDay randomDay) {
        vm.startBroadcast();
        randomDay = new RandomDay(rNGCoordinatorPoFAddress, tonTokenAddress);
        vm.stopBroadcast();
    }

    function run() external returns (RandomDay randomDay) {
        address rNGCoordinatorPoFAddress = DevOpsTools
            .get_most_recent_deployment("RNGCoordinatorPoF", block.chainid);
        console2.log("rNGCoordinatorPoFAddress: ", rNGCoordinatorPoFAddress);
        randomDay = deployRandomDayUsingConfig(rNGCoordinatorPoFAddress);
    }
}
