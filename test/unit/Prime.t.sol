// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../shared/BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {WesolowskiFixedWitness, WesolowskiPseudoRandomWitness} from "../../src/test/MinimalWesolowski.sol";
import {PrimeNumbers} from "../shared/PrimeNumbers.sol";
import {BailliePSW} from "../../src/utils/BailliePSW.sol";

contract PrimeTest is BaseTest, PrimeNumbers {
    WesolowskiFixedWitness public wesolowskiFixedWitness;
    WesolowskiPseudoRandomWitness public wesolowskiPseudoRandomWitness;
    BailliePSW public bailliePSW;
    uint256 msb = 1 << 255;

    function setUp() public override {
        BaseTest.setUp();
        wesolowskiFixedWitness = new WesolowskiFixedWitness();
        wesolowskiPseudoRandomWitness = new WesolowskiPseudoRandomWitness();
        bailliePSW = new BailliePSW();
    }

    function testMillerRabinFixedWitnessTest() public view {
        for (uint256 i = 0; i < fixturePrimeNumber.length; i++) {
            bool isPrimeNumber = wesolowskiFixedWitness.millerRanbinTest(
                fixturePrimeNumber[i]
            );
            if (!isPrimeNumber) {
                console2.log("miller rabin failed", fixturePrimeNumber[i]);
            }
            assertTrue(isPrimeNumber, "Should be a prime number");
        }
    }

    function testMillerRanbinPseudoRandomWitnessTest() public view {
        for (uint256 i = 0; i < fixturePrimeNumber.length; i++) {
            bool isPrimeNumber = wesolowskiPseudoRandomWitness.millerRanbinTest(
                fixturePrimeNumber[i]
            );
            if (!isPrimeNumber) {
                console2.log("miller rabin failed", fixturePrimeNumber[i]);
            }
            assertTrue(isPrimeNumber, "Should be a prime number");
        }
    }

    function testBailliePSW() public view {
        for (uint256 i = 0; i < fixturePrimeNumber.length; i++) {
            bool isPrimeNumber = bailliePSW.bailliePSW(fixturePrimeNumber[i]);
            if (!isPrimeNumber) {
                console2.log("miller rabin failed", fixturePrimeNumber[i]);
            }
            assertTrue(isPrimeNumber, "Should be a prime number");
        }
    }

    function testMillerRanbinFixedWitnessExpectToFailTest() public view {
        uint256 length = fixturePrimeNumber.length - 1;
        for (uint256 i = 0; i < length; i++) {
            uint256 notPrimeNumber = fixturePrimeNumber[i] + 2;
            if (notPrimeNumber == fixturePrimeNumber[i + 1]) continue;
            bool isPrimeNumber = wesolowskiFixedWitness.millerRanbinTest(
                notPrimeNumber
            );
            if (isPrimeNumber) {
                console2.log("miller rabin failed", notPrimeNumber);
            }
            assertFalse(isPrimeNumber, "Should not be a prime number");
        }
    }

    function testMillerRanbinPseudoRandomWitnessExpectToFailTest() public view {
        uint256 length = fixturePrimeNumber.length - 1;
        for (uint256 i = 0; i < length; i++) {
            uint256 notPrimeNumber = fixturePrimeNumber[i] + 2;
            if (notPrimeNumber == fixturePrimeNumber[i + 1]) continue;
            bool isPrimeNumber = wesolowskiPseudoRandomWitness.millerRanbinTest(
                notPrimeNumber
            );
            if (isPrimeNumber) {
                console2.log("miller rabin failed", notPrimeNumber);
            }
            assertFalse(isPrimeNumber, "Should not be a prime number");
        }
    }

    function testBailliePSWTestExpectToFail() public view {
        uint256 length = fixturePrimeNumber.length - 1;
        for (uint256 i = 0; i < length; i++) {
            uint256 notPrimeNumber = fixturePrimeNumber[i] + 2;
            if (notPrimeNumber == fixturePrimeNumber[i + 1]) continue;
            bool isPrimeNumber = bailliePSW.bailliePSW(notPrimeNumber);
            if (isPrimeNumber) {
                console2.log("miller rabin failed", notPrimeNumber);
            }
            assertFalse(isPrimeNumber, "Should not be a prime number");
        }
    }
}
