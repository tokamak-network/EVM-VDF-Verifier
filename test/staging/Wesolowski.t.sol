// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../shared/BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";
import "../../src/test/MinimalWesolowski.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/libraries/BigNumbers.sol";
import "../shared/Utils.t.sol";
import {DecodeJsonBigNumber} from "../shared/DecodeJsonBigNumber.sol";

import {LibUint1024Test, BigNumberLibraryTest} from "../../src/test/ArithmeticLibraryCompare.sol";

contract MinimalWesolowskiTest is BaseTest, GasHelpers, DecodeJsonBigNumber {
    struct SmallJsonBigNumber {
        uint256 bitlen;
        bytes32 val;
    }
    IMinimalWesolowski public minimalWesolowski;
    WesolowskiCalldata public wesolowskiCalldata;

    function setUp() public override {
        BaseTest.setUp();
        minimalWesolowski = IMinimalWesolowski(
            address(new MinimalWesolowski())
        );
        wesolowskiCalldata = new WesolowskiCalldata();
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

    function decodeShortBigNumber(
        bytes memory jsonBytes
    ) public pure returns (BigNumber memory) {
        SmallJsonBigNumber memory xJsonBigNumber = abi.decode(
            jsonBytes,
            (SmallJsonBigNumber)
        );
        BigNumber memory x = BigNumber(
            abi.encode(xJsonBigNumber.val),
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
            BigNumber memory x,
            BigNumber memory y,
            BigNumber memory n,
            BigNumber memory t,
            BigNumber memory pi,
            BigNumber memory l
        )
    {
        string memory root = vm.projectRoot();
        string memory path = string(
            abi.encodePacked(
                root,
                "/test/shared/wesolowskiTestCases/",
                Strings.toString(bits),
                "/T",
                Strings.toString(tau),
                "/",
                Strings.toString(i),
                ".json"
            )
        );
        string memory json = vm.readFile(path);
        t = decodeShortBigNumber(vm.parseJson(json, ".T"));
        l = decodeShortBigNumber(vm.parseJson(json, ".l"));
        x = decodeBigNumber(vm.parseJson(json, ".x"));
        y = decodeBigNumber(vm.parseJson(json, ".y"));
        n = decodeBigNumber(vm.parseJson(json, ".n"));
        pi = decodeBigNumber(vm.parseJson(json, ".pi"));
    }

    function getAverage(uint256[] memory array) private pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < array.length; i++) {
            sum += array[i];
        }
        return sum / array.length;
    }

    function testWesolowskiAllTestCases2048() public view {
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        BigNumber memory T;
        BigNumber memory pi;
        BigNumber memory l;
        uint256 numOfEachTestCase = 5;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256[1] memory bits = [uint256(2048)];
        for (uint256 i = 0; i < bits.length; i++) {
            console2.log("Bits: ", bits[i]);
            uint256[2][6] memory results;
            for (uint256 j = 0; j < taus.length; j++) {
                uint256[] memory gasUseds = new uint256[](numOfEachTestCase);
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (x, y, n, T, pi, l) = returnParsed(bits[i], k, taus[j]);
                    bool result = minimalWesolowski.verifyWesolowski(
                        x,
                        n,
                        T,
                        pi,
                        l
                    );
                    gasUseds[k - 1] = vm.lastCallGas().gasTotalUsed;
                    assertTrue(result);
                }
                uint256 averageGasUsed = getAverage(gasUseds);
                results[j] = [taus[j], averageGasUsed];
            }
            console2.log("tau, averageGasUsed");
            for (uint256 j = 0; j < taus.length; j++) {
                console2.log(results[j][0], results[j][1]);
            }
        }
    }

    function testWesolowskiAllTestCases3072() public view {
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        BigNumber memory T;
        BigNumber memory pi;
        BigNumber memory l;
        uint256 numOfEachTestCase = 5;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256[1] memory bits = [uint256(3072)];
        for (uint256 i = 0; i < bits.length; i++) {
            console2.log("Bits: ", bits[i]);
            uint256[2][6] memory results;
            for (uint256 j = 0; j < taus.length; j++) {
                uint256[] memory gasUseds = new uint256[](numOfEachTestCase);
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (x, y, n, T, pi, l) = returnParsed(bits[i], k, taus[j]);
                    bool result = minimalWesolowski.verifyWesolowski(
                        x,
                        n,
                        T,
                        pi,
                        l
                    );
                    gasUseds[k - 1] = vm.lastCallGas().gasTotalUsed;
                    assertTrue(result);
                }
                uint256 averageGasUsed = getAverage(gasUseds);
                results[j] = [taus[j], averageGasUsed];
            }
            console2.log("tau, averageGasUsed");
            for (uint256 j = 0; j < taus.length; j++) {
                console2.log(results[j][0], results[j][1]);
            }
        }
    }

    function testWesolowskiAllTestCasesCalldata() public {
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        BigNumber memory T;
        BigNumber memory pi;
        BigNumber memory l;
        uint256 numOfEachTestCase = 5;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256[2] memory bits = [uint256(2048), 3072];
        for (uint256 i = 0; i < bits.length; i++) {
            console2.log("Bits: ", bits[i]);
            uint256[4][6] memory results;
            for (uint256 j = 0; j < taus.length; j++) {
                uint256[] memory calldataSizes = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory intrinsicGas = new uint256[](
                    numOfEachTestCase
                );
                uint256[] memory gasOfFuncDispatchs = new uint256[](
                    numOfEachTestCase
                );
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (x, y, n, T, pi, l) = returnParsed(bits[i], k, taus[j]);
                    wesolowskiCalldata.verifyWesolowski(x, n, T, pi, l);
                    console2.log(vm.lastCallGas().gasTotalUsed);
                    bytes memory calldataBytes = abi.encodeWithSelector(
                        minimalWesolowski.verifyWesolowski.selector,
                        x,
                        n,
                        T,
                        pi,
                        l
                    );
                    calldataSizes[k - 1] = calldataBytes.length;
                    intrinsicGas[k - 1] = getIntrinsicGas(calldataBytes);
                    if (vm.lastCallGas().gasTotalUsed > intrinsicGas[k - 1]) {
                        gasOfFuncDispatchs[k - 1] =
                            vm.lastCallGas().gasTotalUsed -
                            intrinsicGas[k - 1];
                    } else {
                        gasOfFuncDispatchs[k - 1] = 0;
                    }
                }
                uint256 averageCalldataSize = getAverage(calldataSizes);
                uint256 averageIntrinsicGas = getAverage(intrinsicGas);
                uint256 averageGasOfFuncDispatch = getAverage(
                    gasOfFuncDispatchs
                );
                results[j] = [
                    taus[j],
                    averageCalldataSize,
                    averageIntrinsicGas,
                    averageGasOfFuncDispatch
                ];
            }
            console2.log("calldataSize", "IntrinsicGas", "GasOfFuncDispatch");
            uint256[] memory calldataSizesForAvg = new uint256[](taus.length);
            uint256[] memory intrinsicGasForAvg = new uint256[](taus.length);
            uint256[] memory gasOfFuncDispatchsForAvg = new uint256[](
                taus.length
            );
            for (uint256 j = 0; j < taus.length; j++) {
                calldataSizesForAvg[j] = results[j][1];
                intrinsicGasForAvg[j] = results[j][2];
                gasOfFuncDispatchsForAvg[j] = results[j][3];
            }
            console2.log(
                getAverage(calldataSizesForAvg),
                getAverage(intrinsicGasForAvg),
                getAverage(gasOfFuncDispatchsForAvg)
            );
        }
    }

    function testWesolowski1024() public {
        BigNumberLibraryTest bigNumberLibraryTest = new BigNumberLibraryTest();
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        BigNumber memory T;
        BigNumber memory pi;
        BigNumber memory l;
        uint256 numOfEachTestCase = 1;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256[1] memory bits = [uint256(1024)];
        for (uint256 i = 0; i < bits.length; i++) {
            console2.log("Bits: ", bits[i]);
            uint256[2][6] memory results;
            for (uint256 j = 0; j < taus.length; j++) {
                uint256[] memory gasUseds = new uint256[](numOfEachTestCase);
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (x, y, n, T, pi, l) = returnParsed(bits[i], k, taus[j]);
                    bigNumberLibraryTest.verify(x, n, T, pi, l);
                    gasUseds[k - 1] = vm.lastCallGas().gasTotalUsed;
                }
                uint256 averageGasUsed = getAverage(gasUseds);
                results[j] = [taus[j], averageGasUsed];
            }
            console2.log("tau, averageGasUsed");
            for (uint256 j = 0; j < taus.length; j++) {
                console2.log(results[j][0], results[j][1]);
            }
        }
    }
}

contract ArithmeticLibraryComparison is BaseTest {
    struct SmallJsonBigNumber {
        uint256 bitlen;
        bytes32 val;
    }

    function decodeForLib1024Array(
        bytes memory jsonBytes
    ) public pure returns (uint256[4] memory) {
        uint256[4] memory x;
        SmallJsonBigNumber memory xJsonBigNumber = abi.decode(
            jsonBytes,
            (SmallJsonBigNumber)
        );
        bytes memory xBytes = abi.encode(xJsonBigNumber.val);
        assembly ("memory-safe") {
            x := add(xBytes, 0x20)
        }
        return x;
    }

    function decodeForLib1024Uint(
        bytes memory jsonBytes
    ) public pure returns (uint256) {
        SmallJsonBigNumber memory xJsonBigNumber = abi.decode(
            jsonBytes,
            (SmallJsonBigNumber)
        );
        return uint256(xJsonBigNumber.val);
    }

    function returnParsedLib1024(
        uint256 bits,
        uint256 i,
        uint256 tau
    )
        public
        view
        returns (
            uint256[4] memory x,
            uint256[4] memory y,
            uint256[4] memory n,
            uint256 t,
            uint256[4] memory pi,
            uint256 l
        )
    {
        string memory root = vm.projectRoot();
        string memory path = string(
            abi.encodePacked(
                root,
                "/test/shared/wesolowskiTestCases/",
                Strings.toString(bits),
                "/T",
                Strings.toString(tau),
                "/",
                Strings.toString(i),
                ".json"
            )
        );
        string memory json = vm.readFile(path);
        t = decodeForLib1024Uint(vm.parseJson(json, ".T"));
        l = decodeForLib1024Uint(vm.parseJson(json, ".l"));
        x = decodeForLib1024Array(vm.parseJson(json, ".x"));
        y = decodeForLib1024Array(vm.parseJson(json, ".y"));
        n = decodeForLib1024Array(vm.parseJson(json, ".n"));
        pi = decodeForLib1024Array(vm.parseJson(json, ".pi"));
    }

    function getAverage(uint256[] memory array) private pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < array.length; i++) {
            sum += array[i];
        }
        return sum / array.length;
    }

    function testLibUint1024Test() public {
        LibUint1024Test libUint1024Test = new LibUint1024Test();
        uint256[4] memory x;
        uint256[4] memory y;
        uint256[4] memory n;
        uint256 T;
        uint256[4] memory pi;
        uint256 l;
        uint256 numOfEachTestCase = 1;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256[1] memory bits = [uint256(1024)];
        for (uint256 i = 0; i < bits.length; i++) {
            console2.log("Bits: ", bits[i]);
            uint256[2][6] memory results;
            for (uint256 j = 0; j < taus.length; j++) {
                uint256[] memory gasUseds = new uint256[](numOfEachTestCase);
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (x, y, n, T, pi, l) = returnParsedLib1024(
                        bits[i],
                        k,
                        taus[j]
                    );
                    libUint1024Test.verify(x, n, T, pi, l);
                    gasUseds[k - 1] = vm.lastCallGas().gasTotalUsed;
                }
                uint256 averageGasUsed = getAverage(gasUseds);
                results[j] = [taus[j], averageGasUsed];
            }
            console2.log("tau, averageGasUsed");
            for (uint256 j = 0; j < taus.length; j++) {
                console2.log(results[j][0], results[j][1]);
            }
        }
    }
}
