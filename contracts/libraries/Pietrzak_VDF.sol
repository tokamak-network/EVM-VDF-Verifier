// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library Pietrzak_VDF {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    struct VDFClaim {
        uint256 n;
        uint256 x;
        uint256 y;
        uint256 T;
        uint256 v;
    }

    struct SingHalvProofOutput {
        bool verified;
        bool calculated;
        uint256 x_prime;
        uint256 y_prime;
        uint256 T_half;
    }

    function modHash(uint256 n, string memory strings) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(strings))) % n;
    }

    function processSingleHalvingProof(
        VDFClaim memory vdfClaim
    ) internal pure returns (SingHalvProofOutput memory) {
        if (vdfClaim.T == 1) {
            if (vdfClaim.y == powerModOrder(vdfClaim.x, 2, vdfClaim.n)) {
                return SingHalvProofOutput(true, false, 0, 0, 0);
            } else {
                return SingHalvProofOutput(false, false, 0, 0, 0);
            }
        } else {
            uint256 tHalf;
            uint256 y = vdfClaim.y;
            uint256 r = modHash(
                vdfClaim.x,
                string.concat(toString(vdfClaim.y), toString(vdfClaim.v))
            );

            if (vdfClaim.T & 1 == 0) {
                tHalf = vdfClaim.T / 2;
            } else {
                tHalf = (vdfClaim.T + 1) / 2;
                y = (y * y) % vdfClaim.n;
            }
            return
                SingHalvProofOutput(
                    true,
                    true,
                    powerModOrder(powerModOrder(vdfClaim.x, r, vdfClaim.n), vdfClaim.v, vdfClaim.n),
                    powerModOrder(powerModOrder(vdfClaim.v, r, vdfClaim.n), y, vdfClaim.n),
                    tHalf
                );
        }
    }

    function verifyRecursiveHalvingProof(VDFClaim[] memory proofList) internal pure returns (bool) {
        uint256 proofSize = proofList.length;

        for (uint256 i = 0; i < proofSize; i++) {
            SingHalvProofOutput memory output = processSingleHalvingProof(proofList[i]);
            if (!output.verified) {
                return false;
            } else {
                if (!output.calculated) return true;
                else if (output.x_prime != proofList[i + 1].x) return false;
                else if (output.y_prime != proofList[i + 1].y) return false;
                else if (output.T_half != proofList[i + 1].T) return false;
            }
        }
        return true;
    }

    /**
     *
     * @param a base value
     * @param b exponent value
     * @return result of a^b mod N
     * @notice powerModOrder function
     * @notice calculate a^b mod N
     * @notice O(log b) complexity
     */
    function powerModOrder(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        uint256 result = 1;
        while (b > 0) {
            if (b & 1 == 1) {
                result = mulmod(result, a, n);
            }
            a = mulmod(a, a, n);
            b = b / 2;
        }
        return result;
    }

    /**
     * OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * openzeppelin-contracts/contracts/utils/math/Math.sol
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }
}
