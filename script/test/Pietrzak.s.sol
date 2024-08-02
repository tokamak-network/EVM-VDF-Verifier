// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import "../../src/test/MinimalPietrzak.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract DeployAndTestPietrzak is Script {
    struct JsonBigNumber {
        uint256 bitlen;
        bytes val;
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

    function returnParsed(
        uint256 bits,
        uint256 i,
        uint256 tau
    )
        public
        view
        returns (
            BigNumber[] memory v,
            BigNumber memory x,
            BigNumber memory y,
            BigNumber memory n,
            uint256 delta,
            uint256 T
        )
    {
        string memory root = vm.projectRoot();
        string memory path = string(
            abi.encodePacked(
                root,
                "/test/shared/pietrzakTestCases/",
                Strings.toString(bits),
                "/T",
                Strings.toString(tau),
                "/",
                Strings.toString(i),
                ".json"
            )
        );
        string memory json = vm.readFile(path);
        x = decodeBigNumber(vm.parseJson(json, ".recoveryProofs[0].x"));
        y = decodeBigNumber(vm.parseJson(json, ".recoveryProofs[0].y"));
        delta = 9;
        uint256 proofLength = tau - delta;
        v = new BigNumber[](proofLength);
        for (uint256 j; j < proofLength; j++) {
            v[j] = (
                decodeBigNumber(
                    vm.parseJson(
                        json,
                        string.concat(
                            ".recoveryProofs[",
                            Strings.toString(j),
                            "].v"
                        )
                    )
                )
            );
        }
        n = decodeBigNumber(vm.parseJson(json, ".n"));
        T = uint256(bytes32((vm.parseJson(json, ".T"))));
    }

    function getIntrinsicGas(bytes memory _data) public pure returns (uint256) {
        uint256 total = 21000; //txBase
        for (uint256 i = 0; i < _data.length; i++) {
            if (_data[i] == 0) {
                total += 4;
            } else {
                total += 16;
            }
        }
        return total;
    }

    function run() external {
        BigNumber[] memory v;
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        uint256 delta;
        uint256 T;
        (v, x, y, n, delta, T) = returnParsed(2048, 1, 22);
        MinimalPietrzakExternal minimalPietrzak204822 = MinimalPietrzakExternal(
            DevOpsTools.get_most_recent_deployment(
                "MinimalPietrzakExternal",
                block.chainid
            )
        );
        Calldata calldataContract = Calldata(
            DevOpsTools.get_most_recent_deployment("Calldata", block.chainid)
        );
        vm.startBroadcast();
        //MinimalPietrzakExternal minimalPietrzak204822 = new MinimalPietrzakExternal();
        // bool result = minimalPietrzak204822.verifyPietrzak(
        //     v,
        //     x,
        //     y,
        //     n,
        //     delta,
        //     T
        // );
        calldataContract.verify(v, x, y, n, delta, T);
        vm.stopBroadcast();
        //console2.log("result: ", result);
        console2.log(vm.lastCallGas().gasTotalUsed);
        console2.log(
            getIntrinsicGas(
                abi.encodeWithSelector(
                    calldataContract.verify.selector,
                    v,
                    x,
                    y,
                    n,
                    delta,
                    T
                )
            )
        );
    }
}
