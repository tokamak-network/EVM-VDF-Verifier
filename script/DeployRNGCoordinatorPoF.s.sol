// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {RNGCoordinatorPoF} from "../src/RNGCoordinatorPoF.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../src/libraries/BigNumbers.sol";

contract DeployRNGCoordinatorPoF is Script {
    struct JsonBigNumber {
        uint256 bitlen;
        bytes val;
    }
    struct DefaultRNGConfig {
        uint256 disputePeriod;
        uint256 minimumDepositAmount;
        uint256 avgL2GasUsed;
        uint256 avgL1GasUsed;
        uint256 premiumPercentage;
        uint256 penaltyPercentage;
        uint256 flatFee;
    }
    uint256 public constant PROOFLENGTH = 13;
    DefaultRNGConfig public defaultRNGConfig =
        DefaultRNGConfig({
            disputePeriod: 120,
            minimumDepositAmount: 0.005 ether,
            avgL2GasUsed: 2101449,
            avgL1GasUsed: 27824,
            premiumPercentage: 0,
            penaltyPercentage: 20,
            flatFee: 0.001 ether
        });

    function run()
        external
        returns (RNGCoordinatorPoF rng, bool isInitialized)
    {
        vm.startBroadcast();
        rng = new RNGCoordinatorPoF(
            defaultRNGConfig.disputePeriod,
            defaultRNGConfig.minimumDepositAmount,
            defaultRNGConfig.avgL2GasUsed,
            defaultRNGConfig.avgL1GasUsed,
            defaultRNGConfig.premiumPercentage,
            defaultRNGConfig.penaltyPercentage,
            defaultRNGConfig.flatFee
        );
        vm.stopBroadcast();
        isInitialized = initialize(rng);
    }

    function decodeBigNumber(
        bytes memory jsonBytes
    ) public pure returns (BigNumber memory) {
        JsonBigNumber memory xJsonBigNumber = abi.decode(
            jsonBytes,
            (JsonBigNumber)
        );
        BigNumber memory x = BigNumber(
            xJsonBigNumber.val,
            xJsonBigNumber.bitlen
        );
        return x;
    }

    function initialize(RNGCoordinatorPoF rng) public returns (bool) {
        // *** Get the setup proofs from the current test case
        string memory root = vm.projectRoot();
        string memory path = string(
            abi.encodePacked(root, "/test/shared/currentTestCase.json")
        );
        string memory json = vm.readFile(path);
        BigNumber memory x = decodeBigNumber(
            vm.parseJson(json, ".setupProofs[0].x")
        );
        BigNumber memory y = decodeBigNumber(
            vm.parseJson(json, ".setupProofs[0].y")
        );
        BigNumber[] memory vs = new BigNumber[](PROOFLENGTH);
        for (uint256 i; i < PROOFLENGTH; i++) {
            vs[i] = (
                decodeBigNumber(
                    vm.parseJson(
                        json,
                        string.concat(
                            ".setupProofs[",
                            Strings.toString(i),
                            "].v"
                        )
                    )
                )
            );
        }
        // *** broadcast ***
        vm.startBroadcast();
        rng.initialize(vs, x, y);
        vm.stopBroadcast();
        return rng.isInitialized();
    }
}
