// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./libraries/BigNumbers.sol";

library PietrzakVDF1 {
    function verifyRecursiveHalvingProofAlgorithm2(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) internal view returns (bool) {
        uint256 i;
        uint256 tau = log2(T);
        uint256 iMax = tau - delta;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        uint256 twoPowerOfDelta;
        unchecked {
            twoPowerOfDelta = 1 << delta;
        }
        bytes memory twoPowerOfDeltaBytes = new bytes(32);
        assembly ("memory-safe") {
            mstore(add(twoPowerOfDeltaBytes, 32), twoPowerOfDelta)
        }

        if (
            !BigNumbers.eq(
                y,
                BigNumbers.modexp(
                    x,
                    BigNumbers.modexp(
                        _two,
                        BigNumbers.init(twoPowerOfDeltaBytes),
                        BigNumbers._powModulus(_two, twoPowerOfDelta)
                    ),
                    n
                )
            )
        ) return false;
        return true;
    }

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        uint256 exp;
        unchecked {
            exp = 128 * toUint(value > (1 << 128) - 1);
            value >>= exp;
            result += exp;

            exp = 64 * toUint(value > (1 << 64) - 1);
            value >>= exp;
            result += exp;

            exp = 32 * toUint(value > (1 << 32) - 1);
            value >>= exp;
            result += exp;

            exp = 16 * toUint(value > (1 << 16) - 1);
            value >>= exp;
            result += exp;

            exp = 8 * toUint(value > (1 << 8) - 1);
            value >>= exp;
            result += exp;

            exp = 4 * toUint(value > (1 << 4) - 1);
            value >>= exp;
            result += exp;

            exp = 2 * toUint(value > (1 << 2) - 1);
            value >>= exp;
            result += exp;

            result += toUint(value > 1);
        }
        return result;
    }

    function toUint(bool b) internal pure returns (uint256 u) {
        /// @solidity memory-safe-assembly
        assembly {
            u := iszero(iszero(b))
        }
    }

    function _hash128(
        bytes memory a,
        bytes memory b,
        bytes memory c
    ) internal view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(bytes.concat(a, b, c)) >> 128));
    }
}

library PietrzakVDF1Halving {
    function verifyRecursiveHalvingProofAlgorithm2(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) internal returns (bool) {
        uint256 start = gasleft();
        uint256 i;
        uint256 tau = log2(T);
        uint256 iMax = tau - delta;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        emit gasUsed1(start - gasleft());
        uint256 twoPowerOfDelta;
        unchecked {
            twoPowerOfDelta = 1 << delta;
        }
        bytes memory twoPowerOfDeltaBytes = new bytes(32);
        assembly ("memory-safe") {
            mstore(add(twoPowerOfDeltaBytes, 32), twoPowerOfDelta)
        }

        if (
            !BigNumbers.eq(
                y,
                BigNumbers.modexp(
                    x,
                    BigNumbers.modexp(
                        _two,
                        BigNumbers.init(twoPowerOfDeltaBytes),
                        BigNumbers._powModulus(_two, twoPowerOfDelta)
                    ),
                    n
                )
            )
        ) return false;
        return true;
    }

    event gasUsed1(uint256);

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        uint256 exp;
        unchecked {
            exp = 128 * toUint(value > (1 << 128) - 1);
            value >>= exp;
            result += exp;

            exp = 64 * toUint(value > (1 << 64) - 1);
            value >>= exp;
            result += exp;

            exp = 32 * toUint(value > (1 << 32) - 1);
            value >>= exp;
            result += exp;

            exp = 16 * toUint(value > (1 << 16) - 1);
            value >>= exp;
            result += exp;

            exp = 8 * toUint(value > (1 << 8) - 1);
            value >>= exp;
            result += exp;

            exp = 4 * toUint(value > (1 << 4) - 1);
            value >>= exp;
            result += exp;

            exp = 2 * toUint(value > (1 << 2) - 1);
            value >>= exp;
            result += exp;

            result += toUint(value > 1);
        }
        return result;
    }

    function toUint(bool b) internal pure returns (uint256 u) {
        /// @solidity memory-safe-assembly
        assembly {
            u := iszero(iszero(b))
        }
    }

    function _hash128(
        bytes memory a,
        bytes memory b,
        bytes memory c
    ) internal view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(bytes.concat(a, b, c)) >> 128));
    }
}

library PietrzakVDF1ModExp {
    function verifyRecursiveHalvingProofAlgorithm2(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) internal returns (bool) {
        uint256 i;
        uint256 tau = log2(T);
        uint256 iMax = tau - delta;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        uint256 start = gasleft();
        uint256 twoPowerOfDelta;
        unchecked {
            twoPowerOfDelta = 1 << delta;
        }
        bytes memory twoPowerOfDeltaBytes = new bytes(32);
        assembly ("memory-safe") {
            mstore(add(twoPowerOfDeltaBytes, 32), twoPowerOfDelta)
        }
        if (
            !BigNumbers.eq(
                y,
                BigNumbers.modexp(
                    x,
                    BigNumbers.modexp(
                        _two,
                        BigNumbers.init(twoPowerOfDeltaBytes),
                        BigNumbers._powModulus(_two, twoPowerOfDelta)
                    ),
                    n
                )
            )
        ) return false;
        emit gasUsed1(start - gasleft());
        return true;
    }

    event gasUsed1(uint256);

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        uint256 exp;
        unchecked {
            exp = 128 * toUint(value > (1 << 128) - 1);
            value >>= exp;
            result += exp;

            exp = 64 * toUint(value > (1 << 64) - 1);
            value >>= exp;
            result += exp;

            exp = 32 * toUint(value > (1 << 32) - 1);
            value >>= exp;
            result += exp;

            exp = 16 * toUint(value > (1 << 16) - 1);
            value >>= exp;
            result += exp;

            exp = 8 * toUint(value > (1 << 8) - 1);
            value >>= exp;
            result += exp;

            exp = 4 * toUint(value > (1 << 4) - 1);
            value >>= exp;
            result += exp;

            exp = 2 * toUint(value > (1 << 2) - 1);
            value >>= exp;
            result += exp;

            result += toUint(value > 1);
        }
        return result;
    }

    function toUint(bool b) internal pure returns (uint256 u) {
        /// @solidity memory-safe-assembly
        assembly {
            u := iszero(iszero(b))
        }
    }

    function _hash128(
        bytes memory a,
        bytes memory b,
        bytes memory c
    ) internal view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(bytes.concat(a, b, c)) >> 128));
    }
}

library PietrzakVDF {
    error XPrimeNotEqualAtIndex(uint256 index);
    error YPrimeNotEqualAtIndex(uint256 index);
    error NotVerifiedAtTOne();
    error TOneNotAtLast();
    error NotVerified();

    struct VDFClaimXYV {
        BigNumber x;
        BigNumber y;
        BigNumber v;
    }
    struct VDFClaimNV {
        BigNumber n;
        BigNumber v;
    }
    struct VDFClaimXYVN {
        BigNumber x;
        BigNumber y;
        BigNumber v;
        BigNumber n;
    }
    struct VDFClaimTXYV {
        uint256 T;
        BigNumber x;
        BigNumber y;
        BigNumber v;
    }
    struct VDFClaimTXYVN {
        uint256 T;
        BigNumber x;
        BigNumber y;
        BigNumber v;
        BigNumber n;
    }

    bytes internal constant BYTESFOUR =
        hex"0000000000000000000000000000000000000000000000000000000000000004";
    uint256 private constant UINTFOUR = 4;
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";
    uint256 private constant MODFORHASH_LEN = 129;
    uint256 private constant ZERO = 0;
    uint256 private constant ONE = 1;
    //uint256 private constant T = 4194304; // 2^22\
    uint256 private constant PROOFLASTINDEXOPTIMIZED = 20;
    uint256 private constant PROOFOPTIMIZEDLENGTH = 21;

    function verifyRecursiveHalvingAppliedDeltaRepeat(
        VDFClaimXYV[] memory proofList,
        BigNumber memory n,
        uint256 twoPowerOfDelta,
        uint256 T
    ) internal view returns (bool) {
        uint i;
        uint256 iMax;
        unchecked {
            iMax = proofList.length - ONE;
        }
        do {
            BigNumber memory _r = _hash128(
                proofList[i].x.val,
                proofList[i].y.val,
                proofList[i].v.val
            );
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) return false;
            if (T & 1 != 0)
                proofList[i].y = BigNumbers.modexp(
                    proofList[i].y,
                    BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                    n
                );
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) return false;
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        // if (!BigNumbers.eq(proofList[i].y, BigNumbers.modexp(proofList[i].x, _two, n)))
        bytes memory _x = BigNumbers._modexp(proofList[i].x.val, BigNumbers.BYTESTWO, n.val);
        i = 1;
        while (i < twoPowerOfDelta) {
            _x = BigNumbers._modexp(_x, BigNumbers.BYTESTWO, n.val);
            unchecked {
                ++i;
            }
        }
        if (!BigNumbers.eq(proofList[iMax].y, BigNumbers.init(_x))) return false;
        return true;
    }

    function verifyRecursiveHalvingProofWithoutDelta(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 T
    ) internal view returns (bool) {
        uint i;
        uint256 iMax = v.length;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        if (!BigNumbers.eq(y, BigNumbers.modexp(x, _two, n))) return false;
        return true;
    }

    function verifyRecursiveHalvingProofDeltaBigNumberHalving(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory expDelta,
        uint256 T
    ) internal returns (bool) {
        uint256 gasStart = gasleft();
        uint i;
        uint256 iMax = v.length;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        emit gasUsed(gasStart - gasleft());
        if (!BigNumbers.eq(y, BigNumbers.modexp(x, expDelta, n))) return false;
        return true;
    }

    function verifyRecursiveHalvingProofDeltaBigNumberModExpCompare(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory expDelta,
        uint256 T
    ) internal returns (bool) {
        uint i;
        uint256 iMax = v.length;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        uint256 gasStart = gasleft();
        if (!BigNumbers.eq(y, BigNumbers.modexp(x, expDelta, n))) return false;
        emit gasUsed(gasStart - gasleft());
        return true;
    }

    function verifyRecursiveHalvingProofDeltaBigNumber(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory expDelta,
        uint256 T
    ) internal view returns (bool) {
        uint i;
        uint256 iMax = v.length;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        if (!BigNumbers.eq(y, BigNumbers.modexp(x, expDelta, n))) return false;
        return true;
    }

    // function verifyRecursiveHalvingProofAlgorithm(
    //     BigNumber[] memory v,
    //     BigNumber memory x,
    //     BigNumber memory y,
    //     BigNumber memory n,
    //     uint256 delta,
    //     uint256 T
    // ) internal view returns (bool) {
    //     uint256 i;
    //     uint256 tau = log2(T);
    //     uint256 iMax = tau - delta;
    //     BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
    //     do {
    //         BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
    //         x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
    //         if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
    //         y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
    //         unchecked {
    //             ++i;
    //             T = T >> 1;
    //         }
    //     } while (i < iMax);
    //     uint256 twoPowerOfDelta;
    //     unchecked {
    //         twoPowerOfDelta = 1 << delta;
    //     }
    //     bytes memory twoPowerOfDeltaBytes = new bytes(32);
    //     assembly ("memory-safe") {
    //         mstore(add(twoPowerOfDeltaBytes, 32), twoPowerOfDelta)
    //     }
    //     if (
    //         !BigNumbers.eq(
    //             y,
    //             BigNumbers.init(
    //                 BigNumbers._modexp(
    //                     x.val,
    //                     BigNumbers._modexp(
    //                         BigNumbers.BYTESTWO,
    //                         twoPowerOfDeltaBytes,
    //                         BigNumbers._powModulus(_two, twoPowerOfDelta).val
    //                     ),
    //                     n.val
    //                 )
    //             )
    //         )
    //     ) return false;
    //     return true;
    // }

    function verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) internal view returns (bool) {
        uint i;
        uint256 iMax = v.length;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        if (
            !BigNumbers.eq(
                y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        x.val,
                        BigNumbers._modexp(
                            BigNumbers.BYTESTWO,
                            bigNumTwoPowerOfDelta,
                            BigNumbers._powModulus(_two, twoPowerOfDelta).val
                        ),
                        n.val
                    )
                )
            )
        ) return false;
        return true;
    }

    function verifyRecursiveHalvingProofGasConsoleHalving(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) internal returns (bool) {
        uint256 gasStart = gasleft();
        uint i;
        uint256 iMax = v.length;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        emit gasUsed(gasStart - gasleft());
        if (
            !BigNumbers.eq(
                y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        x.val,
                        BigNumbers._modexp(
                            BigNumbers.BYTESTWO,
                            bigNumTwoPowerOfDelta,
                            BigNumbers._powModulus(_two, twoPowerOfDelta).val
                        ),
                        n.val
                    )
                )
            )
        ) return false;
        return true;
    }

    event gasUsed(uint256);

    function verifyRecursiveHalvingProofGasConsoleModExp(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) internal returns (bool) {
        uint i;
        uint256 iMax = v.length;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        uint256 gasStart = gasleft();
        if (
            !BigNumbers.eq(
                y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        x.val,
                        BigNumbers._modexp(
                            BigNumbers.BYTESTWO,
                            bigNumTwoPowerOfDelta,
                            BigNumbers._powModulus(_two, twoPowerOfDelta).val
                        ),
                        n.val
                    )
                )
            )
        ) return false;
        emit gasUsed(gasStart - gasleft());
        return true;
    }

    function verifyRecursiveHalvingProofCorrect(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) internal view returns (bool) {
        uint i;
        uint256 iMax = v.length;
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            //BigNumber memory _r = _hash128(bytes.concat(x.val, y.val, v[i].val));
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        if (
            !BigNumbers.eq(
                y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        x.val,
                        BigNumbers._modexp(
                            BigNumbers.BYTESTWO,
                            bigNumTwoPowerOfDelta,
                            BigNumbers._powModulus(_two, twoPowerOfDelta).val
                        ),
                        n.val
                    )
                )
            )
        ) return false;
        return true;
    }

    function verifyRecursiveHalvingProofNTXYVDeltaRepeated(
        VDFClaimTXYVN[] memory proofList,
        uint256 twoPowerOfDelta
    ) internal view returns (bool) {
        uint i;
        uint256 iMax;
        unchecked {
            iMax = proofList.length - ONE;
        }
        do {
            BigNumber memory _r = _hash128(
                proofList[i].x.val,
                proofList[i].y.val,
                proofList[i].v.val
            );
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(
                        BigNumbers.modexp(proofList[i].x, _r, proofList[i].n),
                        proofList[i].v,
                        proofList[i].n
                    ),
                    proofList[_unchecked_inc(i)].x
                )
            ) return false;
            if (proofList[i].T & 1 == 1)
                proofList[i].y = BigNumbers.modexp(
                    proofList[i].y,
                    BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                    proofList[i].n
                );
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(
                        BigNumbers.modexp(proofList[i].v, _r, proofList[i].n),
                        proofList[i].y,
                        proofList[i].n
                    ),
                    proofList[_unchecked_inc(i)].y
                )
            ) return false;
            unchecked {
                ++i;
            }
        } while (i < iMax);
        bytes memory nVal = proofList[0].n.val;
        bytes memory _x = BigNumbers._modexp(proofList[i].x.val, BigNumbers.BYTESTWO, nVal);
        i = 1;
        while (i < twoPowerOfDelta) {
            _x = BigNumbers._modexp(_x, BigNumbers.BYTESTWO, nVal);
            unchecked {
                ++i;
            }
        }
        if (!BigNumbers.eq(proofList[iMax].y, BigNumbers.init(_x))) return false;
        return true;
    }

    function verifyRecursiveHalvingProofNTXYVDeltaApplied(
        VDFClaimTXYVN[] memory proofList,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta
    ) internal view returns (bool) {
        uint i;
        uint256 iMax;
        unchecked {
            iMax = proofList.length - ONE;
        }
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(
                proofList[i].x.val,
                proofList[i].y.val,
                proofList[i].v.val
            );
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(
                        BigNumbers.modexp(proofList[i].x, _r, proofList[i].n),
                        proofList[i].v,
                        proofList[i].n
                    ),
                    proofList[_unchecked_inc(i)].x
                )
            ) return false;
            if (proofList[i].T & 1 == 1)
                proofList[i].y = BigNumbers.modexp(proofList[i].y, _two, proofList[i].n);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(
                        BigNumbers.modexp(proofList[i].v, _r, proofList[i].n),
                        proofList[i].y,
                        proofList[i].n
                    ),
                    proofList[_unchecked_inc(i)].y
                )
            ) return false;
            unchecked {
                ++i;
            }
        } while (i < iMax);
        if (
            !BigNumbers.eq(
                proofList[i].y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        proofList[i].x.val,
                        BigNumbers._modexp(
                            BigNumbers.BYTESTWO,
                            bigNumTwoPowerOfDelta,
                            BigNumbers._powModulus(_two, twoPowerOfDelta).val
                        ),
                        proofList[i].n.val
                    )
                )
            )
        ) return false;
        return true;
    }

    function verifyRecursiveHalvingProofSkippingTXY(
        VDFClaimNV[] memory proofList,
        BigNumber memory x,
        BigNumber memory y,
        uint256 T
    ) internal view returns (bool) {
        uint i;
        uint256 iMax;
        unchecked {
            iMax = proofList.length - ONE;
        }
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(x.val, y.val, proofList[i].v.val);
            x = BigNumbers.modmul(
                BigNumbers.modexp(x, _r, proofList[i].n),
                proofList[i].v,
                proofList[i].n
            );
            if (T & 1 != 0) y = BigNumbers.modexp(y, _two, proofList[i].n);
            y = BigNumbers.modmul(
                BigNumbers.modexp(proofList[i].v, _r, proofList[i].n),
                y,
                proofList[i].n
            );
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        if (!BigNumbers.eq(y, BigNumbers.modexp(x, _two, proofList[i].n))) return false;
        return true;
    }

    function verifyRecursiveHalvingProofSkippingN(
        BigNumber memory n,
        VDFClaimTXYV[] memory proofList
    ) internal view returns (bool) {
        uint i;
        uint256 iMax;
        unchecked {
            iMax = proofList.length - ONE;
        }
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(
                proofList[i].x.val,
                proofList[i].y.val,
                proofList[i].v.val
            );
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) return false;
            if (proofList[i].T & 1 == 1)
                proofList[i].y = BigNumbers.modexp(proofList[i].y, _two, n);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) return false;
            unchecked {
                ++i;
            }
        } while (i < iMax);
        if (!BigNumbers.eq(proofList[i].y, BigNumbers.modexp(proofList[i].x, _two, n)))
            return false;
        return true;
    }

    function verifyRecursiveHalvingProofNTXYVInProof(
        VDFClaimTXYVN[] memory proofList
    ) internal view returns (bool) {
        uint i;
        uint256 iMax;
        unchecked {
            iMax = proofList.length - ONE;
        }
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        do {
            BigNumber memory _r = _hash128(
                proofList[i].x.val,
                proofList[i].y.val,
                proofList[i].v.val
            );
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(
                        BigNumbers.modexp(proofList[i].x, _r, proofList[i].n),
                        proofList[i].v,
                        proofList[i].n
                    ),
                    proofList[_unchecked_inc(i)].x
                )
            ) return false;
            if (proofList[i].T & 1 == 1)
                proofList[i].y = BigNumbers.modexp(proofList[i].y, _two, proofList[i].n);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(
                        BigNumbers.modexp(proofList[i].v, _r, proofList[i].n),
                        proofList[i].y,
                        proofList[i].n
                    ),
                    proofList[_unchecked_inc(i)].y
                )
            ) return false;
            unchecked {
                ++i;
            }
        } while (i < iMax);
        if (!BigNumbers.eq(proofList[i].y, BigNumbers.modexp(proofList[i].x, _two, proofList[i].n)))
            return false;
        return true;
    }

    /////////////////////////////////////////////////

    // function compareGasModLeftAndRight(VDFClaim[] calldata proofList) external view {
    //     bytes32 s = keccak256("any string");
    //     console.logBytes32(s);
    //     BigNumber memory _r;
    //     uint256 start = gasleft();
    //     _r = _modHashMod128(bytes.concat(proofList[0].y.val, proofList[0].v.val), proofList[0].x);
    //     console.log(start - gasleft());
    //     start = gasleft();
    //     _r = _hashMod128(bytes.concat(proofList[0].x.val, proofList[0].y.val, proofList[0].v.val));
    //     console.log(start - gasleft());
    //     start = gasleft();
    //     BigNumber memory a = BigNumbers.mod(
    //         BigNumbers.init(abi.encodePacked(s)),
    //         BigNumber(MODFORHASH, MODFORHASH_LEN)
    //     );
    //     console.log(start - gasleft());
    //     start = gasleft();
    //     BigNumber memory c = BigNumbers.init(abi.encodePacked(s >> 128));
    //     console.log(start - gasleft());
    //     start = gasleft();
    //     BigNumber memory b = BigNumbers.init(abi.encodePacked(bytes16(s)));
    //     console.log(start - gasleft());
    //     start = gasleft();
    //     BigNumber memory d = BigNumbers.init(abi.encodePacked(s << 128));
    //     console.log(start - gasleft());
    //     console.logBytes(a.val);
    //     console.logBytes(b.val);
    //     console.logBytes(c.val);
    //     console.logBytes(d.val);
    //     console.log(a.bitlen);
    //     console.log(b.bitlen);
    //     console.log(c.bitlen);
    //     console.log(d.bitlen);
    // }

    function verifyOptimizedVersion(
        BigNumber memory x,
        BigNumber memory y,
        BigNumber[PROOFOPTIMIZEDLENGTH] memory pi,
        BigNumber memory n
    ) internal view {
        uint256 i;
        BigNumber memory r;
        do {
            r = _hashMod128(bytes.concat(x.val, y.val, pi[i].val));
            x = BigNumbers.modmul(BigNumbers.modexp(x, r, n), pi[i], n);
            y = BigNumbers.modmul(BigNumbers.modexp(pi[i], r, n), y, n);
            i = _unchecked_inc(i);
        } while (i < PROOFOPTIMIZEDLENGTH);
        if (!BigNumbers.eq(y, BigNumbers.modexp(x, BigNumber(BYTESFOUR, UINTFOUR), n)))
            revert NotVerified();
    }

    function _hash128(
        bytes memory a,
        bytes memory b,
        bytes memory c
    ) private view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(bytes.concat(a, b, c)) >> 128));
    }

    function _hashMod128(bytes memory strings) private view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(strings) >> 128));
    }

    function _unchecked_inc(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + BigNumbers.UINTONE;
        }
    }
}
