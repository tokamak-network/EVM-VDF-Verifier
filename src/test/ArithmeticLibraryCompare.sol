// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../libraries/BigNumbers.sol";
import {LibUint1024} from "../libraries/LibUint1024.sol";

contract LibUint1024Test {
    function verify(
        uint256[4] memory x,
        uint256[4] memory n,
        uint256 T,
        uint256[4] memory pi,
        uint256 l
    ) external view {
        uint256 r = _expMod(2, T, l);
        uint256[4] memory y = LibUint1024.mulMod(
            LibUint1024.expMod(pi, l, n),
            LibUint1024.expMod(x, r, n),
            n
        );
    }

    // Computes (base ** exponent) % modulus
    function _expMod(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) private view returns (uint256 result) {
        assembly ("memory-safe") {
            // Get free memory pointer
            let p := mload(0x40)
            // Store parameters for the EXPMOD (0x05) precompile
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), exponent) // Exponent
            mstore(add(p, 0xa0), modulus) // Modulus
            // Call 0x05 (EXPMOD) precompile
            if iszero(staticcall(gas(), 0x05, p, 0xc0, 0, 0x20)) {
                revert(0, 0)
            }
            result := mload(0)
            // Update free memory pointer
            mstore(0x40, add(p, 0xc0))
        }
    }
}

contract BigNumberLibraryTest {
    function verify(
        BigNumber memory x,
        BigNumber memory n,
        BigNumber memory T,
        BigNumber memory pi,
        BigNumber memory l
    ) external view {
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
    }
}
