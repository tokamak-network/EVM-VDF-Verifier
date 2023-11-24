// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract WrapperForEIP198 {
    function modExp(
        bytes memory _base,
        bytes memory _exp,
        bytes memory _mod
    ) public view returns (bytes memory result) {
        assembly {
            let bl := mload(_base)
            let el := mload(_exp)
            let ml := mload(_mod)
            let fmp := mload(0x40)

            mstore(fmp, bl)
            mstore(add(fmp, 32), el)
            mstore(add(fmp, 64), ml)
            if iszero(staticcall(gas(), 0x4, add(_base, 32), bl, add(fmp, 96), bl)) {
                revert(0, 0)
            }
            let offset := add(96, bl)
            if iszero(staticcall(gas(), 0x4, add(_exp, 32), el, add(fmp, offset), el)) {
                revert(0, 0)
            }
            offset := add(offset, el)
            if iszero(staticcall(gas(), 0x4, add(_mod, 32), ml, add(fmp, offset), ml)) {
                revert(0, 0)
            }
            offset := add(offset, ml)
            if iszero(staticcall(gas(), 0x5, fmp, offset, add(fmp, 96), ml)) {
                revert(0, 0)
            }
            // point to the location of the return value (length, bits)

            //result := add(fmp, 64)
            let length := ml
            let ptr := add(fmp, 96)
            /// the following code removes any leading words containing all zeros in the result.
            for {

            } eq(eq(length, 32), 0) {

            } {
                switch eq(mload(ptr), 0)
                case 1 {
                    ptr := add(ptr, 32)
                }
                default {
                    break
                }
                length := sub(length, 32)
            }
            result := sub(ptr, 32)
            mstore(result, length)

            mstore(0x40, add(add(fmp, 96), ml))
        }
    }
}
