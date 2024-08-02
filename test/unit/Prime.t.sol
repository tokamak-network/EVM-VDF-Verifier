// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../shared/BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {Wesolowski} from "../../src/Wesolowski.sol";
import {PrimeNumbers} from "../shared/PrimeNumbers.sol";

contract PrimeTest is BaseTest, PrimeNumbers {
    Wesolowski public wesolowski;
    uint256 msb = 1 << 255;

    function setUp() public override {
        BaseTest.setUp();
        wesolowski = new Wesolowski();
    }

    function testMillerRabinTest() public view {
        for (uint256 i = 0; i < fixturePrimeNumber.length; i++) {
            bool isPrimeNumber = wesolowski.millerRanbinTestExternal(
                fixturePrimeNumber[i]
            );
            if (!isPrimeNumber) {
                console2.log("miller rabin failed", fixturePrimeNumber[i]);
            }
            assertTrue(isPrimeNumber, "Should be a prime number");
        }
    }

    function testMillerRanbinTestExpectToFail() public view {
        uint256 length = fixturePrimeNumber.length - 1;
        for (uint256 i = 0; i < length; i++) {
            uint256 notPrimeNumber = fixturePrimeNumber[i] + 2;
            if (notPrimeNumber == fixturePrimeNumber[i + 1]) continue;
            bool isPrimeNumber = wesolowski.millerRanbinTestExternal(
                notPrimeNumber
            );
            if (isPrimeNumber) {
                console2.log("miller rabin failed", notPrimeNumber);
            }
            assertFalse(isPrimeNumber, "Should not be a prime number");
        }
    }
}
