// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./BigNumbers.sol";

library Pietrzak_VDF {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    using BigNumbers for *;

    struct VDFClaim {
        uint256 T;
        BigNumber n;
        BigNumber x;
        BigNumber y;
        BigNumber v;
    }

    struct SingHalvProofOutput {
        bool verified;
        bool calculated;
        BigNumber x_prime;
        BigNumber y_prime;
        uint256 T_half;
    }

    function modHash(
        BigNumber memory n,
        bytes memory _strings
    ) internal view returns (BigNumber memory) {
        //return uint256(keccak256(abi.encodePacked(strings))) % n;
        //return powerModN(abi.encodePacked(keccak256(_strings)), _one, n);
        return abi.encodePacked(keccak256(_strings)).init(false).mod(n);
    }

    function processSingleHalvingProof(
        VDFClaim calldata vdfClaim
    ) internal view returns (SingHalvProofOutput memory) {
        BigNumber memory _zero = BigNumbers.zero();
        BigNumber memory _two = BigNumbers.two();
        if (vdfClaim.T == 1) {
            //if (vdfClaim.y == powerModN(vdfClaim.x, 2, vdfClaim.n)) {
            //if (equal(vdfClaim.y, powerModN(vdfClaim.x, vdfClaim.v, vdfClaim.n))) {
            if (vdfClaim.y.eq(vdfClaim.x.modexp(vdfClaim.v, vdfClaim.n))) {
                return SingHalvProofOutput(true, false, _zero, _zero, 0);
            } else {
                return SingHalvProofOutput(false, false, _zero, _zero, 0);
            }
        } else {
            uint256 tHalf;
            BigNumber memory y = vdfClaim.y;
            BigNumber memory r = modHash(vdfClaim.x, bytes.concat(vdfClaim.y.val, vdfClaim.v.val));

            if (vdfClaim.T & 1 == 0) {
                tHalf = vdfClaim.T / 2;
            } else {
                tHalf = (vdfClaim.T + 1) / 2;
                y = y.modexp(_two, vdfClaim.n);
            }
            return
                SingHalvProofOutput(
                    true,
                    true,
                    vdfClaim.x.modexp(r, vdfClaim.n).modexp(vdfClaim.v, vdfClaim.n),
                    vdfClaim.v.modexp(r, vdfClaim.n).modexp(y, vdfClaim.n),
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
                else if (!output.x_prime.eq(proofList[i + 1].x)) return false;
                else if (!output.y_prime.eq(proofList[i + 1].y)) return false;
                else if (output.T_half != proofList[i + 1].T) return false;
            }
        }
        return true;
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
