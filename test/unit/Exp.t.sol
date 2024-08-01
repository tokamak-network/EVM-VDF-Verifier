// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../shared/BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";
import "../../src/libraries/BigNumbers.sol";
import "../../src/test/Exp.sol";
import {ExpTestNumbers} from "../shared/ExpTestNumbers.sol";

contract ExpTest is BaseTest, ExpTestNumbers {
    uint256 public testCaseLength = 16;
    IExponentiation[3] public expContracts;
    IMultiExponentiation[2] public multiExpContracts;
    string[11] public expStrings = [
        "x^2^2",
        "x^2^4",
        "x^2^8",
        "x^2^16",
        "x^2^32",
        "x^2^64",
        "x^2^128",
        "x^2^256",
        "x^2^512",
        "x^2^1024",
        "x^2^2048"
    ];
    uint256[11] public taus = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048];
    BigNumber[] public bigNumTaus;
    BigNumber[] public exps;

    function setUp() public override(BaseTest, ExpTestNumbers) {
        BaseTest.setUp();
        ExpTestNumbers.setUp();
        expContracts[0] = IExponentiation(
            address(new ExponentiationBySquaring())
        );
        expContracts[1] = IExponentiation(address(new SquareAndMultiply()));
        expContracts[2] = IExponentiation(address(new PrecompileModExp()));
        multiExpContracts[0] = IMultiExponentiation(
            address(new DimitrovMultiExp())
        );
        multiExpContracts[1] = IMultiExponentiation(
            address(new PrecompileMultiExp())
        );
        bigNumTaus = new BigNumber[](taus.length);
        exps = new BigNumber[](taus.length);
        for (uint256 i = 0; i < taus.length; i++) {
            bigNumTaus[i] = BigNumbers.init(abi.encodePacked(taus[i]));
            exps[i] = BigNumbers.modexp(
                bigNumTaus[0],
                bigNumTaus[i],
                BigNumbers._powModulus(bigNumTaus[0], taus[i])
            );
        }
    }

    function bitLength(bytes memory a) private pure returns (uint256 r) {
        if (BigNumbers.isZero(a)) return 0;
        uint256 msword;
        assembly ("memory-safe") {
            msword := mload(add(a, 0x20)) // get msword of input
        }
        r = bitLength(msword); // get bitlen of msword, add to size of remaining words.
        assembly ("memory-safe") {
            r := add(r, mul(sub(mload(a), 0x20), 8)) // res += (val.length-32)*8;
        }
    }

    /** @notice uint256 bit length
        @dev bitLength: get the bit length of a uint256 input - ie. log2 (most significant bit of 256 bit value (one EVM word))
      *                       credit: Tjaden Hess @ ethereum.stackexchange             
      * @param a uint256 value
      * @return r uint256 bit length result.
      */
    function bitLength(uint256 a) private pure returns (uint256 r) {
        assembly ("memory-safe") {
            switch eq(a, 0)
            case 1 {
                r := 0
            }
            default {
                let arg := a
                a := sub(a, 1)
                a := or(a, div(a, 0x02))
                a := or(a, div(a, 0x04))
                a := or(a, div(a, 0x10))
                a := or(a, div(a, 0x100))
                a := or(a, div(a, 0x10000))
                a := or(a, div(a, 0x100000000))
                a := or(a, div(a, 0x10000000000000000))
                a := or(a, div(a, 0x100000000000000000000000000000000))
                a := add(a, 1)
                let m := mload(0x40)
                mstore(
                    m,
                    0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd
                )
                mstore(
                    add(m, 0x20),
                    0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe
                )
                mstore(
                    add(m, 0x40),
                    0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616
                )
                mstore(
                    add(m, 0x60),
                    0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff
                )
                mstore(
                    add(m, 0x80),
                    0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e
                )
                mstore(
                    add(m, 0xa0),
                    0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707
                )
                mstore(
                    add(m, 0xc0),
                    0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606
                )
                mstore(
                    add(m, 0xe0),
                    0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100
                )
                mstore(0x40, add(m, 0x100))
                let
                    magic
                := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
                let
                    shift
                := 0x100000000000000000000000000000000000000000000000000000000000000
                let _a := div(mul(a, magic), shift)
                r := div(mload(add(m, sub(255, _a))), shift)
                r := add(
                    r,
                    mul(
                        256,
                        gt(
                            arg,
                            0x8000000000000000000000000000000000000000000000000000000000000000
                        )
                    )
                )
                // where a is a power of two, result needs to be incremented. we use the power of two trick here: if(arg & arg-1 == 0) ++r;
                if eq(and(arg, sub(arg, 1)), 0) {
                    r := add(r, 1)
                }
            }
        }
    }

    function getGasAverage(
        uint256[] memory gasUsed
    ) private pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < gasUsed.length; i++) {
            sum += gasUsed[i];
        }
        return sum / gasUsed.length;
    }

    function testExp2048() public view {
        console2.log("2048 bit exponentiation");
        console2.log(
            "Exponentiation by Squaring",
            "Square and Multiply",
            "Precompile ModExp"
        );
        for (uint256 i = 0; i < exps.length; i++) {
            uint256[] memory gasUsedExpBySquaring = new uint256[](
                testCaseLength
            );
            uint256[] memory gasUsedSquareAndMultiply = new uint256[](
                testCaseLength
            );
            uint256[] memory gasUsedPrecompileModExp = new uint256[](
                testCaseLength
            );
            for (uint256 j = 0; j < testCaseLength; j++) {
                BigNumber memory resultExponentiationBySquaring = expContracts[
                    0
                ].exponentiation(base2048s[j], exps[i], n2048s[j]);
                gasUsedExpBySquaring[j] = vm.lastCallGas().gasTotalUsed;
                BigNumber memory resultSquareAndMultiply = expContracts[1]
                    .exponentiation(base2048s[j], exps[i], n2048s[j]);
                gasUsedSquareAndMultiply[j] = vm.lastCallGas().gasTotalUsed;
                bytes memory resultPrecompileModExp = expContracts[2]
                    .precompileExponentiation(
                        base2048s[j].val,
                        exps[i].val,
                        n2048s[j].val
                    );
                gasUsedPrecompileModExp[j] = vm.lastCallGas().gasTotalUsed;
                uint256 resultPrecompileModExpBitLen = bitLength(
                    resultPrecompileModExp
                );
                assertEq(
                    resultExponentiationBySquaring.val,
                    resultPrecompileModExp
                );
                assertEq(resultPrecompileModExp, resultSquareAndMultiply.val);
                assertEq(
                    resultPrecompileModExpBitLen,
                    resultSquareAndMultiply.bitlen
                );
                assertEq(
                    resultPrecompileModExpBitLen,
                    resultExponentiationBySquaring.bitlen
                );
            }
            console2.log(
                expStrings[i],
                getGasAverage(gasUsedExpBySquaring),
                getGasAverage(gasUsedSquareAndMultiply),
                getGasAverage(gasUsedPrecompileModExp)
            );
        }
        console2.log("--------------------");
    }

    function testExp3072() public view {
        console2.log("3072 bit exponentiation");
        console2.log(
            "Exponentiation by Squaring",
            "Square and Multiply",
            "Precompile ModExp"
        );
        for (uint256 i = 0; i < exps.length; i++) {
            uint256[] memory gasUsedExpBySquaring = new uint256[](
                testCaseLength
            );
            uint256[] memory gasUsedSquareAndMultiply = new uint256[](
                testCaseLength
            );
            uint256[] memory gasUsedPrecompileModExp = new uint256[](
                testCaseLength
            );
            for (uint256 j = 0; j < testCaseLength; j++) {
                BigNumber memory resultExponentiationBySquaring = expContracts[
                    0
                ].exponentiation(base3072s[j], exps[i], n3072s[j]);
                gasUsedExpBySquaring[j] = vm.lastCallGas().gasTotalUsed;
                BigNumber memory resultSquareAndMultiply = expContracts[1]
                    .exponentiation(base3072s[j], exps[i], n3072s[j]);
                gasUsedSquareAndMultiply[j] = vm.lastCallGas().gasTotalUsed;
                bytes memory resultPrecompileModExp = expContracts[2]
                    .precompileExponentiation(
                        base3072s[j].val,
                        exps[i].val,
                        n3072s[j].val
                    );
                gasUsedPrecompileModExp[j] = vm.lastCallGas().gasTotalUsed;
                uint256 resultPrecompileModExpBitLen = bitLength(
                    resultPrecompileModExp
                );
                assertEq(
                    resultExponentiationBySquaring.val,
                    resultPrecompileModExp
                );
                assertEq(resultPrecompileModExp, resultSquareAndMultiply.val);
                assertEq(
                    resultPrecompileModExpBitLen,
                    resultSquareAndMultiply.bitlen
                );
                assertEq(
                    resultPrecompileModExpBitLen,
                    resultExponentiationBySquaring.bitlen
                );
            }
            console2.log(
                expStrings[i],
                getGasAverage(gasUsedExpBySquaring),
                getGasAverage(gasUsedSquareAndMultiply),
                getGasAverage(gasUsedPrecompileModExp)
            );
        }
        console2.log("--------------------");
    }

    function testMultiExp2048() public view {
        console2.log("2048 bit multi exponentiation");
        console2.log("Dimitrov MultiExp", "Precompile MultiExp");
        for (uint256 i = 0; i < exps.length; i++) {
            uint256[] memory gasUsedDimtrovMultiExp = new uint256[](
                testCaseLength
            );
            uint256[] memory gasUsedPrecompileMultiExp = new uint256[](
                testCaseLength
            );
            for (uint256 j = 0; j < testCaseLength; j++) {
                BigNumber memory resultDimitrovMultiExp = multiExpContracts[0]
                    .multiExponentiation(
                        exps[i],
                        base2048s[j],
                        y2048s[j],
                        n2048s[j]
                    );
                gasUsedDimtrovMultiExp[j] = vm.lastCallGas().gasTotalUsed;
                BigNumber memory resultPrecompileMultiExp = multiExpContracts[1]
                    .multiExponentiation(
                        exps[i],
                        base2048s[j],
                        y2048s[j],
                        n2048s[j]
                    );
                gasUsedPrecompileMultiExp[j] = vm.lastCallGas().gasTotalUsed;
                assertEq(
                    resultDimitrovMultiExp.val,
                    resultPrecompileMultiExp.val
                );
                assertEq(
                    resultDimitrovMultiExp.bitlen,
                    resultPrecompileMultiExp.bitlen
                );
            }
            console2.log(
                expStrings[i],
                "* y^(2^1)",
                getGasAverage(gasUsedDimtrovMultiExp),
                getGasAverage(gasUsedPrecompileMultiExp)
            );
        }
        console2.log("--------------------");
    }

    function testMultiExp3072() public view {
        console2.log("3072 bit multi exponentiation");
        console2.log("Dimitrov MultiExp", "Precompile MultiExp");
        for (uint256 i = 0; i < exps.length; i++) {
            uint256[] memory gasUsedDimtrovMultiExp = new uint256[](
                testCaseLength
            );
            uint256[] memory gasUsedPrecompileMultiExp = new uint256[](
                testCaseLength
            );
            for (uint256 j = 0; j < testCaseLength; j++) {
                BigNumber memory resultDimitrovMultiExp = multiExpContracts[0]
                    .multiExponentiation(
                        exps[i],
                        base3072s[j],
                        y3072s[j],
                        n3072s[j]
                    );
                gasUsedDimtrovMultiExp[j] = vm.lastCallGas().gasTotalUsed;
                BigNumber memory resultPrecompileMultiExp = multiExpContracts[1]
                    .multiExponentiation(
                        exps[i],
                        base3072s[j],
                        y3072s[j],
                        n3072s[j]
                    );
                gasUsedPrecompileMultiExp[j] = vm.lastCallGas().gasTotalUsed;
                assertEq(
                    resultDimitrovMultiExp.val,
                    resultPrecompileMultiExp.val
                );
                assertEq(
                    resultDimitrovMultiExp.bitlen,
                    resultPrecompileMultiExp.bitlen
                );
            }
            console2.log(
                expStrings[i],
                "* y^(2^1)",
                getGasAverage(gasUsedDimtrovMultiExp),
                getGasAverage(gasUsedPrecompileMultiExp)
            );
        }
        console2.log("--------------------");
    }
}
