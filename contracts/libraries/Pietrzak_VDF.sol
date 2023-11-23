// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library Pietrzak_VDF {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    //abi.encodePacked(uint256(1))
    bytes private constant _ONE = abi.encodePacked(uint256(1));
    bytes private constant _TWO = abi.encodePacked(uint256(2));

    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

    struct VDFClaim {
        uint256 T;
        bytes n;
        bytes x;
        bytes y;
        bytes v;
    }

    struct SingHalvProofOutput {
        bool verified;
        bool calculated;
        bytes x_prime;
        bytes y_prime;
        uint256 T_half;
    }

    function modHash(bytes memory n, bytes memory _strings) internal view returns (bytes memory) {
        //return uint256(keccak256(abi.encodePacked(strings))) % n;
        return powerModN(abi.encodePacked(keccak256(_strings)), _ONE, n);
    }

    function processSingleHalvingProof(
        VDFClaim calldata vdfClaim
    ) internal view returns (SingHalvProofOutput memory) {
        if (vdfClaim.T == 1) {
            //if (vdfClaim.y == powerModN(vdfClaim.x, 2, vdfClaim.n)) {
            if (equal(vdfClaim.y, powerModN(vdfClaim.x, vdfClaim.v, vdfClaim.n))) {
                return SingHalvProofOutput(true, false, "", "", 0);
            } else {
                return SingHalvProofOutput(false, false, "", "", 0);
            }
        } else {
            uint256 tHalf;
            bytes memory y = vdfClaim.y;
            bytes memory r = modHash(vdfClaim.x, bytes.concat(vdfClaim.y, vdfClaim.v));

            if (vdfClaim.T & 1 == 0) {
                tHalf = vdfClaim.T / 2;
            } else {
                tHalf = (vdfClaim.T + 1) / 2;
                y = powerModN(y, _TWO, vdfClaim.n);
            }
            return
                SingHalvProofOutput(
                    true,
                    true,
                    powerModN(powerModN(vdfClaim.x, r, vdfClaim.n), vdfClaim.v, vdfClaim.n),
                    powerModN(powerModN(vdfClaim.v, r, vdfClaim.n), y, vdfClaim.n),
                    tHalf
                );
        }
    }

    function verifyRecursiveHalvingProof(
        VDFClaim[] calldata proofList
    ) internal view returns (bool) {
        uint256 proofSize = proofList.length;

        for (uint256 i = 0; i < proofSize; i++) {
            SingHalvProofOutput memory output = processSingleHalvingProof(proofList[i]);
            if (!output.verified) {
                return false;
            } else {
                if (!output.calculated) return true;
                //else if (output.x_prime != proofList[i + 1].x) return false;
                else if (!equal(output.x_prime, proofList[i + 1].x)) return false;
                //else if (output.y_prime != proofList[i + 1].y) return false;
                else if (!equal(output.y_prime, proofList[i + 1].y)) return false;
                else if (output.T_half != proofList[i + 1].T) return false;
            }
        }
        return true;
    }

    // /**
    //  *
    //  * @param a base value
    //  * @param b exponent value
    //  * @return result of a^b mod N
    //  * @notice powerModN function
    //  * @notice calculate a^b mod N
    //  * @notice O(log b) complexity
    //  */
    // function powerModN(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
    //     uint256 result = 1;
    //     while (b > 0) {
    //         if (b & 1 == 1) {
    //             result = mulmod(result, a, n);
    //         }
    //         a = mulmod(a, a, n);
    //         b = b / 2;
    //     }
    //     return result;
    // }

    function powerModN(
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

    // function mul(bytes memory _a, bytes memory _b) internal view returns (bytes memory) {
    //     bytes memory addResult = _add(_a, _b);
    // }

    function init(bytes memory val) internal view returns (BigNumber memory result) {
        return BigNumber(val, val.length * 8);
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}
