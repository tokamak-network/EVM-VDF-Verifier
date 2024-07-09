// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Test, console2} from "forge-std/Test.sol";

contract Testd is Test {
    function setUp() external pure {
        console2.log("Hello, World!");
    }

    function testTest1() external pure {
        console2.log("Hello, World!");
    }
}
