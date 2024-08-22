// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract BailliePSW {
    // A bitmask for testing membership in the set of the first 96 odd primes.
    // A bit vector contains elements in [0, 255]. Since all primes (other than 2)
    // are odd, we know the last bit will be 1. So if we first check the parity of
    // the candidate prime, we can drop the last bit and thus check all primes from
    // [3, 511] in this bitvector.
    uint256 private constant PRIMES_BIT_MASK =
        (1 << (3 >> 1)) |
            (1 << (5 >> 1)) |
            (1 << (7 >> 1)) |
            (1 << (11 >> 1)) |
            (1 << (13 >> 1)) |
            (1 << (17 >> 1)) |
            (1 << (19 >> 1)) |
            (1 << (23 >> 1)) |
            (1 << (29 >> 1)) |
            (1 << (31 >> 1)) |
            (1 << (37 >> 1)) |
            (1 << (41 >> 1)) |
            (1 << (43 >> 1)) |
            (1 << (47 >> 1)) |
            (1 << (53 >> 1)) |
            (1 << (59 >> 1)) |
            (1 << (61 >> 1)) |
            (1 << (67 >> 1)) |
            (1 << (71 >> 1)) |
            (1 << (73 >> 1)) |
            (1 << (79 >> 1)) |
            (1 << (83 >> 1)) |
            (1 << (89 >> 1)) |
            (1 << (97 >> 1)) |
            (1 << (101 >> 1)) |
            (1 << (103 >> 1)) |
            (1 << (107 >> 1)) |
            (1 << (109 >> 1)) |
            (1 << (113 >> 1)) |
            (1 << (127 >> 1)) |
            (1 << (131 >> 1)) |
            (1 << (137 >> 1)) |
            (1 << (139 >> 1)) |
            (1 << (149 >> 1)) |
            (1 << (151 >> 1)) |
            (1 << (157 >> 1)) |
            (1 << (163 >> 1)) |
            (1 << (167 >> 1)) |
            (1 << (173 >> 1)) |
            (1 << (179 >> 1)) |
            (1 << (181 >> 1)) |
            (1 << (191 >> 1)) |
            (1 << (193 >> 1)) |
            (1 << (197 >> 1)) |
            (1 << (199 >> 1)) |
            (1 << (211 >> 1)) |
            (1 << (223 >> 1)) |
            (1 << (227 >> 1)) |
            (1 << (229 >> 1)) |
            (1 << (233 >> 1)) |
            (1 << (239 >> 1)) |
            (1 << (241 >> 1)) |
            (1 << (251 >> 1)) |
            (1 << (257 >> 1)) |
            (1 << (263 >> 1)) |
            (1 << (269 >> 1)) |
            (1 << (271 >> 1)) |
            (1 << (277 >> 1)) |
            (1 << (281 >> 1)) |
            (1 << (283 >> 1)) |
            (1 << (293 >> 1)) |
            (1 << (307 >> 1)) |
            (1 << (311 >> 1)) |
            (1 << (313 >> 1)) |
            (1 << (317 >> 1)) |
            (1 << (331 >> 1)) |
            (1 << (337 >> 1)) |
            (1 << (347 >> 1)) |
            (1 << (349 >> 1)) |
            (1 << (353 >> 1)) |
            (1 << (359 >> 1)) |
            (1 << (367 >> 1)) |
            (1 << (373 >> 1)) |
            (1 << (379 >> 1)) |
            (1 << (383 >> 1)) |
            (1 << (389 >> 1)) |
            (1 << (397 >> 1)) |
            (1 << (401 >> 1)) |
            (1 << (409 >> 1)) |
            (1 << (419 >> 1)) |
            (1 << (421 >> 1)) |
            (1 << (431 >> 1)) |
            (1 << (433 >> 1)) |
            (1 << (439 >> 1)) |
            (1 << (443 >> 1)) |
            (1 << (449 >> 1)) |
            (1 << (457 >> 1)) |
            (1 << (461 >> 1)) |
            (1 << (463 >> 1)) |
            (1 << (467 >> 1)) |
            (1 << (479 >> 1)) |
            (1 << (487 >> 1)) |
            (1 << (491 >> 1)) |
            (1 << (499 >> 1)) |
            (1 << (503 >> 1)) |
            (1 << (509 >> 1));

    /// @dev Performs the Baillie-PSW primality test.
    ///      https://en.wikipedia.org/wiki/Baillie%E2%80%93PSW_primality_test
    ///      The Baillie-PSW primality test has no known pseudoprimes (though
    ///      it's conjectured that there are infinitely many).
    /// @param n The number to check the primality of.
    /// @return Returns true if `n` is prime, false if not.
    function bailliePSW(uint256 n) external view returns (bool) {
        return _millerRabinBase2(n) && lucas(n);
    }

    /// @dev Performs the Lucas primality test.
    ///      https://en.wikipedia.org/wiki/Lucas_primality_test
    ///      Based on the Go implementation:
    ///      https://github.com/golang/go/blob/master/src/math/big/prime.go
    /// @param n The number to check the primality of.
    /// @return Returns true if `n` is prime, false if not.
    function lucas(uint256 n) internal pure returns (bool) {
        if (n < 512) {
            return _checkSmallPrimes(n);
        }

        uint256 p = 3;
        uint256 d;
        unchecked {
            while (true) {
                d = p * p - 4;
                int256 j = jacobi(d, n);
                if (j == -1) {
                    break;
                }
                if (j == 0) {
                    return n == p + 2;
                }
                // Omit square check
                p++;
            }
        }

        uint256 s = n + 1;
        uint256 r = trailingZeros(s);
        s >>= r;
        uint256 nm2;
        unchecked {
            nm2 = n - 2;
        }

        uint256 vk = 2;
        uint256 vk1 = p;
        for (uint256 bit = 1 << bitLen(s); bit != 0; bit >>= 1) {
            if (s & bit != 0) {
                // vk = (vk * vk1 + n - p) % n;
                // vk1 = (vk1 * vk1 + nm2) % n;
                assembly ("memory-safe") {
                    vk := mulmod(vk, vk1, n)
                    vk := addmod(vk, sub(n, p), n)
                    vk1 := mulmod(vk1, vk1, n)
                    vk1 := addmod(vk1, nm2, n)
                }
            } else {
                // vk1 = (vk * vk1 + n - p) % n;
                // vk = (vk * vk + nm2) % n;
                assembly ("memory-safe") {
                    vk1 := mulmod(vk, vk1, n)
                    vk1 := addmod(vk1, sub(n, p), n)
                    vk := mulmod(vk, vk, n)
                    vk := addmod(vk, nm2, n)
                }
            }
        }

        if (vk == 2 || vk == nm2) {
            uint256 t1;
            uint256 t2;
            assembly ("memory-safe") {
                t1 := mulmod(vk, p, n)
                t2 := mulmod(vk1, 2, n)
            }
            if (t1 == t2) {
                return true;
            }
        }

        uint256 rLess1;
        unchecked {
            rLess1 = r - 1;
        }
        for (uint256 t = 0; t != rLess1; ++t) {
            if (vk == 0) {
                return true;
            }
            if (vk == 2) {
                return false;
            }
            // vk = (vk * vk + nm2) % n;
            assembly ("memory-safe") {
                vk := mulmod(vk, vk, n)
                vk := addmod(vk, nm2, n)
            }
        }
        return false;
    }

    bytes32 constant HIGHEST_BIT_DE_BRUIJN_TABLE =
        0x010a020b0e16031e0c0f1113171a041f090d151d10121908141c18071b060520;
    uint256 constant HIGHEST_BIT_DE_BRUIJN_SEQUENCE = 130329821;

    /// @dev Computes the minimum number of bits needed to represent `v`.
    ///      Uses a hybrid of the binary search approach and the de Bruijn approach
    ///      described here:
    ///      https://graphics.stanford.edu/~seander/bithacks.html#IntegerLogDeBruijn
    ///      Note that bitlen(x) == log2(x) + 1, so the de Bruijn table values are
    ///      shifted by 1.
    /// @param v The number to compute the bit-length of.
    /// @return r The bit-length of `v`.
    function bitLen(uint256 v) internal pure returns (uint256 r) {
        unchecked {
            assembly ("memory-safe") {
                let f := shl(7, gt(v, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                r := or(r, f)
                v := shr(f, v)

                f := shl(6, gt(v, 0xFFFFFFFFFFFFFFFF))
                r := or(r, f)
                v := shr(f, v)

                f := shl(5, gt(v, 0xFFFFFFFF))
                r := or(r, f)
                v := shr(f, v)

                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))
            }
            uint256 index = uint32(v * HIGHEST_BIT_DE_BRUIJN_SEQUENCE) >> 27;
            assembly ("memory-safe") {
                r := add(r, byte(index, HIGHEST_BIT_DE_BRUIJN_TABLE))
            }
        }
    }

    bytes32 constant LOWEST_BIT_DE_BRUIJN_TABLE =
        0x00011c021d0e18031e16140f191104081f1b0d17151310071a0c12060b050a09;
    uint256 constant LOWEST_BIT_DE_BRUIJN_SEQUENCE = 125613361;

    /// @dev Computes the number of trailing zeros in the (big-endian) bit representation of `v`.
    ///      Uses a hybrid of the binary search approach and the de Bruijn approach
    ///      described here: https://graphics.stanford.edu/~seander/bithacks.html#ZerosOnRightMultLookup
    /// @param v The number to compute the trailing zeros of.
    /// @return r The number of trailing zeros.
    function trailingZeros(uint256 v) internal pure returns (uint256 r) {
        unchecked {
            if (v & 0xffffffffffffffffffffffffffffffff == 0) {
                r = 128;
                v >>= 128;
            }
            if (v & 0xffffffffffffffff == 0) {
                r += 64;
                v >>= 64;
            }
            if (v & 0xffffffff == 0) {
                r += 32;
                v >>= 32;
            }
            int256 negV = -int256(v);
            uint256 index = uint32(
                (v & uint256(negV)) * LOWEST_BIT_DE_BRUIJN_SEQUENCE
            ) >> 27;
            assembly ("memory-safe") {
                r := add(r, byte(index, LOWEST_BIT_DE_BRUIJN_TABLE))
            }
        }
    }

    /// @dev Returns the Jacobi symbol (d / n)
    ///      https://en.wikipedia.org/wiki/Jacobi_symbol
    /// @param d The upper argument of the Jacobi symbol
    /// @param n The lower argument of the Jacobi symbol
    /// @return j The Jacobi symbol (0, 1, or -1).
    function jacobi(uint256 d, uint256 n) internal pure returns (int256 j) {
        assembly ("memory-safe") {
            d := mod(d, n)
            j := 1
            let r := 0
            for {

            } iszero(iszero(d)) {

            } {
                for {

                } iszero(and(d, 1)) {

                } {
                    d := shr(1, d)
                    r := and(n, 7)
                    if or(eq(r, 3), eq(r, 5)) {
                        j := sub(0, j)
                    }
                }
                r := n
                n := d
                d := r
                if and(eq(and(d, 3), 3), eq(and(n, 3), 3)) {
                    j := sub(0, j)
                }
                d := mod(d, n)
            }
            if iszero(eq(n, 1)) {
                j := 0
            }
        }
    }

    function _checkSmallPrimes(uint256 n) private pure returns (bool) {
        if (n == 2) {
            return true;
        } else if (n & 1 == 0) {
            // All other even numbers are composite.
            return false;
        }
        // At this point we know `n` is odd, so we can drop the last bit and
        // check whether `n` is in the first 96 odd primes using our bitmask.
        return (1 << (n >> 1)) & PRIMES_BIT_MASK != 0;
    }

    // Miller-Rabin with a fixed base of 2, used in Baillie-PSW
    function _millerRabinBase2(uint256 n) private view returns (bool) {
        unchecked {
            if (n == 2) {
                return true;
            }

            uint256 d = n - 1;
            uint256 r = 0;

            assembly ("memory-safe") {
                for {

                } iszero(and(d, 1)) {

                } {
                    d := shr(1, d)
                    r := add(r, 1)
                }
            }

            uint256 x;
            assembly ("memory-safe") {
                // Get free memory pointer
                let p := mload(0x40)
                // Store parameters for the EXPMOD precompile
                mstore(p, 0x20) // Length of Base
                mstore(add(p, 0x20), 0x20) // Length of Exponent
                mstore(add(p, 0x40), 0x20) // Length of Modulus
                mstore(add(p, 0x60), 2) // Base
                mstore(add(p, 0x80), d) // Exponent
                mstore(add(p, 0xa0), n) // Modulus
                // Call 0x05 (EXPMOD) precompile
                if iszero(staticcall(gas(), 0x05, p, 0xc0, 0, 0x20)) {
                    revert(0, 0)
                }
                x := mload(0)
                // Update free memory pointer
                mstore(0x40, add(p, 0xc0))
            }

            if (x == 1 || x == n - 1) {
                return true;
            }

            for (uint256 j = 1; j != r; ++j) {
                x = mulmod(x, x, n);
                if (x == n - 1) {
                    return true;
                }
            }
            return false;
        }
    }
}
