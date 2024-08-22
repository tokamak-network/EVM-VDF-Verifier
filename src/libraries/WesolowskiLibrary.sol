// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import "./BigNumbers.sol";

library WesolowskiLibrary {
    uint256 private constant MILLER_RABIN_CHECKS = 13;

    error ShouldBeGreaterThanThree();
    error InvalidPrime();
    error MSBNotSet();
    error MillarRabinTestFailed();
    error CalculatedYNotEqualY();
    error GapTooLarge();
    //bytes32 private constant primeMask =
    //   hex"7fff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff_E000";
    uint256 private constant jHCadwellMaxGap = 5939;
    bytes32 private constant MSB =
        hex"8000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000";

    // if n < 3,317,044,064,679,887,385,961,981, it is enough to test a = 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, and 41.
    //bytes private constant witness = hex"020305070b0d1113171d1f2529";

    function verify(
        BigNumber memory x,
        BigNumber memory n,
        BigNumber memory T,
        BigNumber memory pi,
        BigNumber memory l
    ) internal view {
        BigNumber memory r = BigNumbers.modexp(
            BigNumber(BigNumbers.BYTESTWO, 2),
            T,
            l
        );
        BigNumber memory y = BigNumbers.modmul(
            BigNumbers.modexp(pi, l, n),
            BigNumbers.modexp(x, r, n),
            n
        );
        _checkHashToPrime(x.val, y.val, l.val, T.val);
    }

    // This function checks if:
    // (1) If h = Hash(input_random, y)
    //      (1a) That h is equal to prime except at the 12 last bits and the most significant bit.abi
    //      (1b) that the prime has msb 1
    // (2) That prime candidate passes the miller rabbin test with 28 round of randomly derived bases [derived from y]
    // TODO - consider adding blockhash to the random base derivation for extra security
    function _checkHashToPrime(
        bytes memory x,
        bytes memory y,
        bytes memory l,
        bytes memory T
    ) internal view {
        // Check p is correct result for hash-to-prime
        uint256 uint256L = uint256(bytes32(l));
        if (
            uint256L - uint256(keccak256(bytes.concat(x, y, T)) | MSB) >
            jHCadwellMaxGap
        ) revert GapTooLarge();
        if (!millerRabinTestFixedWitness(uint256L))
            revert MillarRabinTestFailed();
    }

    function millerRabinTestFixedWitness(
        uint256 n
    ) internal view returns (bool) {
        //if (n < 4) revert ShouldBeGreaterThanThree(); // can be deleted
        if (n & 0x1 == 0) return false;
        uint256 d = n - 1;
        uint256 r;
        assembly {
            for {

            } iszero(and(d, 1)) {

            } {
                d := shr(1, d)
                r := add(r, 1)
            }
        }
        uint256[13] memory witness = [
            uint256(2),
            3,
            5,
            7,
            11,
            13,
            17,
            19,
            23,
            29,
            31,
            37,
            41
        ];
        uint256 memPtr;
        uint256 basePtr;
        assembly {
            // Get free memory pointer
            memPtr := mload(0x40)
            // Store parameters for the EXPMOD precompile
            mstore(memPtr, 0x20) // Length of Base
            mstore(add(memPtr, 0x20), 0x20) // Length of Exponent
            mstore(add(memPtr, 0x40), 0x20) // Length of Modulus
            basePtr := add(memPtr, 0x60) // Base
            mstore(add(memPtr, 0x80), d) // Exponent
            mstore(add(memPtr, 0xa0), n) // Modulus
        }
        uint256 i;
        do {
            uint256 x;
            assembly {
                // pick a witness integer a in the range [2, n − 2]
                let a := mload(add(witness, mul(i, 0x20)))
                mstore(basePtr, a)
                // Call 0x05 (EXPMOD) precompile
                if iszero(
                    staticcall(gas(), 0x05, memPtr, 0xc0, basePtr, 0x20)
                ) {
                    revert(0, 0)
                }
                x := mload(basePtr)
            }
            unchecked {
                ++i;
            }
            if (x == 1 || x == n - 1) {
                continue;
            }
            bool check_passed;
            for (uint256 j = 1; j < r; j++) {
                x = mulmod(x, x, n);
                if (x == n - 1) {
                    check_passed = true;
                    break;
                } else if (x == 1) return false;
            }
            if (!check_passed) {
                return false;
            }
        } while (i < MILLER_RABIN_CHECKS);
        assembly {
            // Update free memory pointer
            mstore(0x40, add(memPtr, 0xc0))
        }
        return true;
    }

    function millerRabinTestPseudoRandomWitness(
        uint256 n
    ) internal view returns (bool) {
        //if (n < 4) revert ShouldBeGreaterThanThree(); // can be deleted
        if (n & 0x1 == 0) return false;
        uint256 d = n - 1;
        uint256 r;
        assembly {
            for {

            } iszero(and(d, 1)) {

            } {
                d := shr(1, d)
                r := add(r, 1)
            }
        }
        uint256 m = n - 3;
        uint256 memPtr;
        uint256 basePtr;
        assembly {
            mstore(0, n)
            //mstore(0x20, blockhash(sub(number(), 1)))
            // Get free memory pointer
            memPtr := mload(0x40)
            // Store parameters for the EXPMOD precompile
            mstore(memPtr, 0x20) // Length of Base
            mstore(add(memPtr, 0x20), 0x20) // Length of Exponent
            mstore(add(memPtr, 0x40), 0x20) // Length of Modulus
            basePtr := add(memPtr, 0x60) // Base
            mstore(add(memPtr, 0x80), d) // Exponent
            mstore(add(memPtr, 0xa0), n) // Modulus
        }
        uint256 i;
        do {
            uint256 x;
            assembly {
                // pick a pseudorandom integer a in the range [2, n − 2]
                mstore(0x20, i)
                let a := add(mod(keccak256(0, 0x40), m), 2)
                mstore(basePtr, a)
                // Call 0x05 (EXPMOD) precompile
                if iszero(
                    staticcall(gas(), 0x05, memPtr, 0xc0, basePtr, 0x20)
                ) {
                    revert(0, 0)
                }
                x := mload(basePtr)
            }
            unchecked {
                ++i;
            }
            if (x == 1 || x == n - 1) {
                continue;
            }
            bool check_passed;
            for (uint256 j = 1; j < r; j++) {
                x = mulmod(x, x, n);
                if (x == n - 1) {
                    check_passed = true;
                    break;
                } else if (x == 1) return false;
            }
            if (!check_passed) {
                return false;
            }
        } while (i < MILLER_RABIN_CHECKS);
        assembly {
            // Update free memory pointer
            mstore(0x40, add(memPtr, 0xc0))
        }
        return true;
    }

    function expmod(
        uint256 base,
        uint256 e,
        uint256 m
    ) private view returns (uint256 o) {
        assembly ("memory-safe") {
            // Get free memory pointer
            let p := mload(0x40)
            // Store parameters for the Expmod (0x05) precompile
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), e) // Exponent
            mstore(add(p, 0xa0), m) // Modulus

            // Call the precompile (0x05, EXPMOD)
            if iszero(staticcall(gas(), 0x05, p, 0xc0, p, 0x20)) {
                revert(0, 0)
            }
            o := mload(p)
            // skip deallocating free memory pointer
        }
    }
}
