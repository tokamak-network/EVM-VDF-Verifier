// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

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
    IMinimalWesolowski[12] public mWs;

    function setUp() public override {
        BaseTest.setUp();
        mWs[0] = IMinimalWesolowski(address(new MinimalWesolowski204820()));
        mWs[1] = IMinimalWesolowski(address(new MinimalWesolowski204821()));
        mWs[2] = IMinimalWesolowski(address(new MinimalWesolowski204822()));
        mWs[3] = IMinimalWesolowski(address(new MinimalWesolowski204823()));
        mWs[4] = IMinimalWesolowski(address(new MinimalWesolowski204824()));
        mWs[5] = IMinimalWesolowski(address(new MinimalWesolowski204825()));
        mWs[6] = IMinimalWesolowski(address(new MinimalWesolowski307220()));
        mWs[7] = IMinimalWesolowski(address(new MinimalWesolowski307221()));
        mWs[8] = IMinimalWesolowski(address(new MinimalWesolowski307222()));
        mWs[9] = IMinimalWesolowski(address(new MinimalWesolowski307223()));
        mWs[10] = IMinimalWesolowski(address(new MinimalWesolowski307224()));
        mWs[11] = IMinimalWesolowski(address(new MinimalWesolowski307225()));
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
            for (uint256 j = 0; j < taus.length; j++) {
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    IMinimalWesolowski minimalWesolowski = mWs[i * 6 + j];
                    (x, y, n, T, pi, l) = returnParsed(bits[i], k, taus[j]);
                    bool result = minimalWesolowski.verifyWesolowski(
                        x,
                        y,
                        n,
                        T,
                        pi,
                        l
                    );
                    assertTrue(result);
                }
            }
        }
    }
}
