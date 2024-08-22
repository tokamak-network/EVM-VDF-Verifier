// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "../shared/BaseTest.t.sol";
import {console2, Vm} from "forge-std/Test.sol";
import "../../src/test/MinimalPietrzak.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/libraries/BigNumbers.sol";
import {DecodeJsonBigNumber} from "../shared/DecodeJsonBigNumber.sol";

contract MinimalPietrzakNoDeltaTest is BaseTest, DecodeJsonBigNumber {
    MinimalPietrzakNoDelta minimalPietrzakNoDelta;
    MinimalPietrzakNoDeltaHalvingReturnGas minimalPietrzakNoDeltaHalvingReturnGas;
    MinimalPietrzakNoDeltaModExpReturnGas minimalPietrzakNoDeltaModExpReturnGas;
    CalldataNoDelta calldataNoDelta;

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

    function setUp() public override {
        BaseTest.setUp();
        minimalPietrzakNoDelta = new MinimalPietrzakNoDelta();
        minimalPietrzakNoDeltaHalvingReturnGas = new MinimalPietrzakNoDeltaHalvingReturnGas();
        minimalPietrzakNoDeltaModExpReturnGas = new MinimalPietrzakNoDeltaModExpReturnGas();
        calldataNoDelta = new CalldataNoDelta();
    }

    function getAverage(uint256[] memory array) private pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < array.length; i++) {
            sum += array[i];
        }
        return sum / array.length;
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
        uint256 proofLength = tau;
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

    function testNoDeltaPietrzakForManuscript() public {
        BigNumber[] memory v;
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        uint256 T;
        uint256 numOfEachTestCase = 5;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256[2] memory bits = [uint256(2048), 3072];
        for (uint256 i; i < bits.length; i++) {
            uint256 bit = bits[i];
            console2.log("------bit", bit);
            for (uint256 j; j < taus.length; j++) {
                uint256 tau = taus[j];
                console2.log("---tau", tau);
                uint256[] memory gasUseds = new uint256[](numOfEachTestCase);
                uint256[] memory calldataSizes = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory intrinsicGass = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory gasOfFuncDispatchs = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory halvingGasUseds = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory modExpGasUseds = new uint256[](
                    numOfEachTestCase
                );
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (v, x, y, n, T) = returnParsed(bit, k, tau);
                    bool result = minimalPietrzakNoDelta.verifyPietrzak(
                        v,
                        x,
                        y,
                        n,
                        T
                    );
                    gasUseds[k - 1] = vm.lastCallGas().gasTotalUsed;
                    assertTrue(result);
                    bytes memory calldataBytes = abi.encodeWithSelector(
                        minimalPietrzakNoDelta.verifyPietrzak.selector,
                        v,
                        x,
                        y,
                        n,
                        T
                    );
                    calldataSizes[k - 1] = calldataBytes.length;
                    intrinsicGass[k - 1] = getIntrinsicGas(calldataBytes);
                    calldataNoDelta.verify(v, x, y, n, T);
                    gasOfFuncDispatchs[k - 1] =
                        vm.lastCallGas().gasTotalUsed -
                        intrinsicGass[k - 1];
                    halvingGasUseds[
                        k - 1
                    ] = minimalPietrzakNoDeltaHalvingReturnGas.verifyPietrzak(
                        v,
                        x,
                        y,
                        n,
                        T
                    );
                    modExpGasUseds[
                        k - 1
                    ] = minimalPietrzakNoDeltaModExpReturnGas.verifyPietrzak(
                        v,
                        x,
                        y,
                        n,
                        T
                    );
                    console2.log("gasUsed", gasUseds[k - 1]);
                }
                uint256 averageCalldataSize = getAverage(calldataSizes);
                uint256 averageIntrinsicGas = getAverage(intrinsicGass);
                uint256 averageGasOfFuncDispatch = getAverage(
                    gasOfFuncDispatchs
                );
                uint256 averageGasUsed = getAverage(gasUseds);
                uint256 averageHalvingGasUsed = getAverage(halvingGasUseds);
                uint256 averageModExpGasUsed = getAverage(modExpGasUseds);
                console2.log("averageGasUsed", averageGasUsed);
                console2.log(
                    "averageCalldataSize in Bytes",
                    averageCalldataSize
                );
                console2.log("averageIntrinsicGas", averageIntrinsicGas);
                console2.log(
                    "averageGasOfFuncDispatch",
                    averageGasOfFuncDispatch
                );
                console2.log("averageHalvingGasUsed", averageHalvingGasUsed);
                console2.log("averageModExpGasUsed", averageModExpGasUsed);
            }
        }
    }
}
