// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Script, console2} from "forge-std/Script.sol";
import {ConsumerExample} from "../src/consumers/ConsumerExample.sol";

contract DeployConsumerExample is Script {
    error RNGCoordinatorPoFNotDeployed();

    function run() external returns (ConsumerExample consumerExample) {
        address rNGCoordinatorPoFAddress = DevOpsTools
            .get_most_recent_deployment("RNGCoordinatorPoF", block.chainid);
        console2.log("rNGCoordinatorPoFAddress: ", rNGCoordinatorPoFAddress);
        vm.startBroadcast();
        consumerExample = new ConsumerExample(rNGCoordinatorPoFAddress);
        vm.stopBroadcast();
    }
}
