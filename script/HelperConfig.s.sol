// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {TonToken} from "../src/test/TonToken.sol";

contract HelperConfig is Script {
    // *** Types ***
    struct NetworkConfig {
        address tonToken;
    }

    // *** State Variables ***
    NetworkConfig public activeNetworkConfig;

    // *** Functions ***
    constructor() {
        uint256 chainId = block.chainid;
        if (chainId == 55007) activeNetworkConfig = getTitanConfig();
        else activeNetworkConfig = getOrCreateTestnetConfig();
    }

    function getTitanConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                tonToken: 0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2
            });
    }

    function getOrCreateTestnetConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.tonToken != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        TonToken ton = new TonToken(); // 1000000000000000000000000000
        vm.stopBroadcast();
        return NetworkConfig({tonToken: address(ton)});
    }
}
