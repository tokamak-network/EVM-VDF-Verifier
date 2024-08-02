// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "../../src/libraries/BigNumbers.sol";
import {Test} from "forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DecodeJsonBigNumber} from "./DecodeJsonBigNumber.sol";

contract ExpTestNumbers is Test, DecodeJsonBigNumber {
    BigNumber[16] public base2048s;
    BigNumber[16] public n2048s;
    BigNumber[16] public y2048s;
    BigNumber[16] public base3072s;
    BigNumber[16] public n3072s;
    BigNumber[16] public y3072s;

    bool private s_expTestNumbersInitialized;

    function setUp() public virtual {
        if (s_expTestNumbersInitialized) return;
        s_expTestNumbersInitialized = true;
        string memory root = vm.projectRoot();

        // ** 2048
        string memory path = string(
            abi.encodePacked(
                root,
                "/test/shared/pietrzakTestCases/2048/T23/1.json"
            )
        );
        string memory json = vm.readFile(path);
        for (uint256 i = 0; i < 16; i++) {
            base2048s[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(".setupProofs[", Strings.toString(i), "].v")
                )
            );
        }
        for (uint256 i = 0; i < 8; i++) {
            n2048s[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(
                        ".setupProofs[",
                        Strings.toString(i + 16),
                        "].n"
                    )
                )
            );
        }
        for (uint256 i = 0; i < 8; i++) {
            n2048s[i + 8] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(
                        ".recoveryProofs[",
                        Strings.toString(i),
                        "].n"
                    )
                )
            );
        }
        for (uint256 i = 0; i < 16; i++) {
            y2048s[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(
                        ".recoveryProofs[",
                        Strings.toString(i + 8),
                        "].y"
                    )
                )
            );
        }

        // ** 3072
        path = string(
            abi.encodePacked(
                root,
                "/test/shared/pietrzakTestCases/3072/T23/1.json"
            )
        );
        json = vm.readFile(path);
        for (uint256 i = 0; i < 16; i++) {
            base3072s[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(".setupProofs[", Strings.toString(i), "].v")
                )
            );
        }
        for (uint256 i = 0; i < 8; i++) {
            n3072s[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(
                        ".setupProofs[",
                        Strings.toString(i + 16),
                        "].n"
                    )
                )
            );
        }
        for (uint256 i = 0; i < 8; i++) {
            n3072s[i + 8] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(
                        ".recoveryProofs[",
                        Strings.toString(i),
                        "].n"
                    )
                )
            );
        }
        for (uint256 i = 0; i < 16; i++) {
            y3072s[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(
                        ".recoveryProofs[",
                        Strings.toString(i + 8),
                        "].y"
                    )
                )
            );
        }
    }
}
