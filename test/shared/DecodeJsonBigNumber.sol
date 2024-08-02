// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {BigNumber} from "../../src/libraries/BigNumbers.sol";

contract DecodeJsonBigNumber {
    struct JsonBigNumber {
        uint256 bitlen;
        bytes val;
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
}
