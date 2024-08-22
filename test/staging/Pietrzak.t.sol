// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "../shared/BaseTest.t.sol";
import {console2, Vm} from "forge-std/Test.sol";
import "../../src/test/MinimalPietrzak.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/libraries/BigNumbers.sol";
import {DecodeJsonBigNumber} from "../shared/DecodeJsonBigNumber.sol";

contract MinimalPietrzakTest is BaseTest, DecodeJsonBigNumber {
    IMinimalPietrzak public minimalPietrzak;

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
        minimalPietrzak = IMinimalPietrzak(address(new MinimalPietrzak()));
    }

    function returnParsed(
        uint256 bits,
        uint256 i,
        uint256 tau,
        uint256 delta
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

    uint256 constant DELTA2048 = 15;

    function test1PietrzakForManuscriptTable2048() public view {
        BigNumber[] memory v;
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        uint256 T;
        uint256 numOfEachTestCase = 5;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256 bit = 2048;
        console2.log("-----------------");
        console2.log("bit size", bit);
        uint256[4][6][DELTA2048] memory results;
        for (uint256 j = 0; j < taus.length; j++) {
            for (uint256 delta; delta < DELTA2048; delta++) {
                uint256[] memory gasUseds = new uint256[](numOfEachTestCase);
                uint256[] memory calldataSizes = new uint256[](
                    numOfEachTestCase
                );
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (v, x, y, n, T) = returnParsed(bit, k, taus[j], delta);
                    bool result = minimalPietrzak.verifyPietrzak(
                        v,
                        x,
                        y,
                        n,
                        delta,
                        T
                    );
                    gasUseds[k - 1] = vm.lastCallGas().gasTotalUsed;
                    calldataSizes[k - 1] = abi
                        .encodeWithSelector(
                            minimalPietrzak.verifyPietrzak.selector,
                            v,
                            x,
                            y,
                            n,
                            delta,
                            T
                        )
                        .length;
                    assertTrue(result);
                }
                uint256 averageGasUsed = getAverage(gasUseds);
                uint256 averageCalldataSize = getAverage(calldataSizes);
                results[delta][j] = [
                    delta,
                    taus[j],
                    averageGasUsed,
                    averageCalldataSize
                ];
            }
        }
        console2.log("delta", "tau", "gas used", "calldata size");
        for (uint256 k = 0; k < DELTA2048; k++) {
            for (uint256 j = 0; j < taus.length; j++) {
                console2.log(
                    results[k][j][0],
                    results[k][j][1],
                    results[k][j][2],
                    results[k][j][3]
                );
            }
        }
    }

    uint256 constant DELTA3072 = 15;

    function test1PietrzakForManuscriptTable3072() public view {
        BigNumber[] memory v;
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        uint256 T;
        uint256 numOfEachTestCase = 4;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256 bit = 3072;
        console2.log("bit size", bit);
        uint256[3][6][DELTA3072] memory results;
        for (uint256 j = 0; j < taus.length; j++) {
            for (uint256 delta; delta < DELTA3072; delta++) {
                uint256[] memory gasUseds = new uint256[](numOfEachTestCase);
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (v, x, y, n, T) = returnParsed(bit, k, taus[j], delta);
                    bool result = minimalPietrzak.verifyPietrzak(
                        v,
                        x,
                        y,
                        n,
                        delta,
                        T
                    );
                    gasUseds[k - 1] = vm.lastCallGas().gasTotalUsed;
                    assertTrue(result);
                }
                uint256 averageGasUsed = getAverage(gasUseds);
                results[delta][j] = [delta, taus[j], averageGasUsed];
            }
        }
        console2.log("delta", "tau", "gas used", "calldata size");
        for (uint256 k = 0; k < DELTA3072; k++) {
            for (uint256 j = 0; j < taus.length; j++) {
                console2.log(
                    results[k][j][0],
                    results[k][j][1],
                    results[k][j][2]
                );
            }
        }
    }

    function test2PietrzakForManuscriptTable() public view {
        BigNumber[] memory v;
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        uint256 T;
        uint256 numOfEachTestCase = 5;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256[2] memory bits = [uint256(2048), 3072];
        for (uint256 i = 0; i < bits.length; i++) {
            console2.log("-----------------");
            console2.log("bit size", bits[i]);
            uint256[4][4][6] memory results;
            for (uint256 delta = 16; delta < 20; delta++) {
                for (uint256 j = 0; j < taus.length; j++) {
                    uint256[] memory gasUseds = new uint256[](
                        numOfEachTestCase
                    );
                    uint256[] memory calldataSizes = new uint256[](
                        numOfEachTestCase
                    );
                    for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                        (v, x, y, n, T) = returnParsed(
                            bits[i],
                            k,
                            taus[j],
                            delta
                        );
                        bool result = minimalPietrzak.verifyPietrzak(
                            v,
                            x,
                            y,
                            n,
                            delta,
                            T
                        );
                        gasUseds[k - 1] = vm.lastCallGas().gasTotalUsed;
                        bytes memory calldataBytes = abi.encodeWithSelector(
                            minimalPietrzak.verifyPietrzak.selector,
                            v,
                            x,
                            y,
                            n,
                            delta,
                            T
                        );
                        calldataSizes[k - 1] = calldataBytes.length;
                        assertTrue(result);
                    }
                    uint256 averageGasUsed = getAverage(gasUseds);
                    uint256 averageCalldataSize = getAverage(calldataSizes);
                    results[j][delta] = [
                        taus[j],
                        averageGasUsed,
                        averageCalldataSize,
                        (averageCalldataSize * 10000) / 1024
                    ];
                }
            }
            console2.log(
                "tau",
                "gas used",
                "calldata size",
                "calldata size(KB) * 10000"
            );
            for (uint256 j = 0; j < taus.length; j++) {
                for (uint256 k = 0; k < 4; k++) {
                    console2.log(
                        results[j][k][0],
                        results[j][k][1],
                        results[j][k][2],
                        results[j][k][3]
                    );
                }
            }
        }
    }

    function getAverage(uint256[] memory array) private pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < array.length; i++) {
            sum += array[i];
        }
        return sum / array.length;
    }

    function testCalldataCost() public {
        BigNumber[] memory v;
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        uint256 T;
        uint256 numOfEachTestCase = 5;
        uint256 tau = 25;
        uint256[2] memory bits = [uint256(2048), 3072];
        Calldata calldataContract = new Calldata();
        for (uint256 bitIndex = 0; bitIndex < bits.length; bitIndex++) {
            console2.log("-----------------");
            console2.log("bit size", bits[bitIndex]);
            uint256[4][26] memory results1;
            uint256[2][26] memory results2;
            for (uint256 delta = 0; delta < 26; delta++) {
                uint256[] memory intrinsicGass = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory calldataLengths = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory gasOfFuncDispatchs = new uint256[](
                    numOfEachTestCase
                );
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (v, x, y, n, T) = returnParsed(
                        bits[bitIndex],
                        k,
                        tau,
                        delta
                    );
                    bytes memory calldataBytes = abi.encodeWithSelector(
                        minimalPietrzak.verifyPietrzak.selector,
                        v,
                        x,
                        y,
                        n,
                        delta,
                        T
                    );
                    calldataLengths[k - 1] = calldataBytes.length;
                    intrinsicGass[k - 1] = getIntrinsicGas(calldataBytes);
                    calldataContract.verify(v, x, y, n, delta, T);
                    gasOfFuncDispatchs[k - 1] =
                        vm.lastCallGas().gasTotalUsed -
                        intrinsicGass[k - 1];
                }
                uint256 averageIntrinsicGas = getAverage(intrinsicGass);
                uint256 averageCalldataLength = getAverage(calldataLengths);
                uint256 averageGasOfFuncDispatch = getAverage(
                    gasOfFuncDispatchs
                );
                results1[delta] = [
                    delta,
                    tau - delta,
                    averageCalldataLength,
                    averageIntrinsicGas
                ];
                results2[delta] = [
                    averageGasOfFuncDispatch,
                    averageGasOfFuncDispatch + averageIntrinsicGas
                ];
            }
            console2.log(
                "delta",
                "proof length",
                "calldata length",
                "intrinsic gas"
            );
            for (uint256 i = 0; i < 26; i++) {
                console2.log(
                    results1[i][0],
                    results1[i][1],
                    results1[i][2],
                    results1[i][3]
                );
            }
            console2.log("func dispatch", "func dispatch + intrinsic gas");
            for (uint256 i = 0; i < 26; i++) {
                console2.log(results2[i][0], " ", results2[i][1]);
            }
        }
    }
}

contract MinimalPietrzakHalvingAndModExp is BaseTest, DecodeJsonBigNumber {
    IMinimalPietrzak minimalPietrzak;

    function setUp() public override {
        BaseTest.setUp();
        minimalPietrzak = IMinimalPietrzak(address(new MinimalPietrzak()));
    }

    function returnParsed(
        uint256 bits,
        uint256 i,
        uint256 tau,
        uint256 delta
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

    function getAverage(uint256[] memory array) private pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < array.length; i++) {
            sum += array[i];
        }
        return sum / array.length;
    }

    function testHalvingModExpTotal() public {
        BigNumber[] memory v;
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        uint256 T;
        uint256 maxDelta = 20;
        uint256[2] memory bits = [uint256(2048), 3072];
        uint256 numOfEachTestCase = 5;
        MinimalPietrzakHalvingReturnGas halvingReturnGasContract = new MinimalPietrzakHalvingReturnGas();
        MinimalPietrzakModExpReturnGas modExpReturnGasContract = new MinimalPietrzakModExpReturnGas();
        for (uint256 bitIndex = 0; bitIndex < bits.length; bitIndex++) {
            console2.log("-----------------");
            console2.log("bit size", bits[bitIndex]);
            uint256[4][20] memory results1;
            for (uint256 delta = 0; delta < maxDelta; delta++) {
                uint256[] memory totalGasUseds = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory halvingGasUseds = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory modExpGasUseds = new uint256[](
                    numOfEachTestCase
                );
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (v, x, y, n, T) = returnParsed(
                        bits[bitIndex],
                        k,
                        25,
                        delta
                    );
                    minimalPietrzak.verifyPietrzak(v, x, y, n, delta, T);
                    totalGasUseds[k - 1] = vm.lastCallGas().gasTotalUsed;
                    halvingGasUseds[k - 1] = halvingReturnGasContract
                        .verifyPietrzak(v, x, y, n, delta, T);
                    modExpGasUseds[k - 1] = modExpReturnGasContract
                        .verifyPietrzak(v, x, y, n, delta, T);
                }
                uint256 averageTotalGasUsed = getAverage(totalGasUseds);
                uint256 averageHalvingGasUsed = getAverage(halvingGasUseds);
                uint256 averageModExpGasUsed = getAverage(modExpGasUseds);
                results1[delta] = [
                    delta,
                    averageHalvingGasUsed,
                    averageModExpGasUsed,
                    averageTotalGasUsed
                ];
            }
            console2.log(
                "delta",
                "halving gas used",
                "mod exp gas used",
                "total gas used"
            );
            for (uint256 i = 0; i < maxDelta; i++) {
                console2.log(
                    results1[i][0],
                    results1[i][1],
                    results1[i][2],
                    results1[i][3]
                );
            }
        }
    }
}
