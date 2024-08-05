// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../shared/BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";
import "../../src/test/MinimalWesolowski.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/libraries/BigNumbers.sol";
import "../shared/Utils.t.sol";
import {DecodeJsonBigNumber} from "../shared/DecodeJsonBigNumber.sol";

contract MinimalWesolowskiTest is BaseTest, GasHelpers, DecodeJsonBigNumber {
    struct SmallJsonBigNumber {
        uint256 bitlen;
        bytes32 val;
    }
    IMinimalWesolowski public minimalWesolowski;

    function setUp() public override {
        BaseTest.setUp();
        minimalWesolowski = IMinimalWesolowski(
            address(new MinimalWesolowski())
        );
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

    function testWesolowskiAllTestCases() public view {
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
            uint256[2][6] memory results;
            for (uint256 j = 0; j < taus.length; j++) {
                uint256[] memory gasUseds = new uint256[](numOfEachTestCase);
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    (x, y, n, T, pi, l) = returnParsed(bits[i], k, taus[j]);
                    bool result = minimalWesolowski.verifyWesolowski(
                        x,
                        y,
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
}
