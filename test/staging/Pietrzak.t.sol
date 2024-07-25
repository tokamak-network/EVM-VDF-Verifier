// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../shared/BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";
import "../../src/test/MinimalPietrzak.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../../src/libraries/BigNumbers.sol";
import {GasHelpers} from "../shared/Utils.t.sol";
import {GasSnapshot} from "forge-gas-snapshot/GasSnapshot.sol";

contract MinimalPietrzakTest is BaseTest, GasHelpers, GasSnapshot {
    struct JsonBigNumber {
        uint256 bitlen;
        bytes val;
    }
    IMinimalPietrzak[12] public mPs;

    function setUp() public override {
        BaseTest.setUp();
        mPs[0] = IMinimalPietrzak(address(new MinimalPietrzak204820()));
        mPs[1] = IMinimalPietrzak(address(new MinimalPietrzak204821()));
        mPs[2] = IMinimalPietrzak(address(new MinimalPietrzak204822()));
        mPs[3] = IMinimalPietrzak(address(new MinimalPietrzak204823()));
        mPs[4] = IMinimalPietrzak(address(new MinimalPietrzak204824()));
        mPs[5] = IMinimalPietrzak(address(new MinimalPietrzak204825()));
        mPs[6] = IMinimalPietrzak(address(new MinimalPietrzak307220()));
        mPs[7] = IMinimalPietrzak(address(new MinimalPietrzak307221()));
        mPs[8] = IMinimalPietrzak(address(new MinimalPietrzak307222()));
        mPs[9] = IMinimalPietrzak(address(new MinimalPietrzak307223()));
        mPs[10] = IMinimalPietrzak(address(new MinimalPietrzak307224()));
        mPs[11] = IMinimalPietrzak(address(new MinimalPietrzak307225()));
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

    function testPietrzakAllTestCases() public view {
        BigNumber[] memory v;
        BigNumber memory x;
        BigNumber memory y;
        BigNumber memory n;
        uint256 delta;
        uint256 T;
        uint256 numOfEachTestCase = 5;
        uint256[6] memory taus = [uint256(20), 21, 22, 23, 24, 25];
        uint256[2] memory bits = [uint256(2048), 3072];
        for (uint256 i = 0; i < bits.length; i++) {
            for (uint256 j = 0; j < taus.length; j++) {
                for (uint256 k = 1; k <= numOfEachTestCase; k++) {
                    IMinimalPietrzak minimalPietrzak = mPs[i * 6 + j];
                    (v, x, y, n, delta, T) = returnParsed(bits[i], k, taus[j]);
                    bool result = minimalPietrzak.verifyPietrzak(
                        v,
                        x,
                        y,
                        n,
                        delta,
                        T
                    );
                    assertTrue(result);
                }
            }
        }
    }
}
