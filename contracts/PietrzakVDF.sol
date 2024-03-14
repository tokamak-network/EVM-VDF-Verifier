// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./libraries/BigNumbers.sol";
import "hardhat/console.sol";

contract PietrzakVDF {
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
    uint256 private constant DELTA = 1;
    uint256 private constant POW2POW2DELTA = 4;
    uint256 private immutable i_proofLastIndex;
    uint256 private constant PROOFLASTINDEXOPTIMIZED = 20;
    uint256 private constant PROOFOPTIMIZEDLENGTH = 21;

    constructor(uint256 proofLastIndex) {
        i_proofLastIndex = proofLastIndex;
    }

    function verifyRecursiveHalvingAppliedDeltaRepeat(
        VDFClaimXYV[] memory proofList,
        BigNumber memory n,
        uint256 twoPowerOfDelta,
        uint256 delta,
        uint256 T
    ) internal view returns (bool) {
        uint i;
        uint256 iMax = i_proofLastIndex - delta;
        do {
            BigNumber memory _r = _modHashMod128(
                bytes.concat(proofList[i].y.val, proofList[i].v.val),
                proofList[i].x
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
        if (!BigNumbers.eq(proofList[i_proofLastIndex - delta].y, BigNumbers.init(_x)))
            return false;
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
        uint256 iMax = i_proofLastIndex;
        BigNumber memory _r;
        do {
            _r = _modHashMod128(bytes.concat(y.val, v[i].val), x);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0)
                y = BigNumbers.modexp(y, BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO), n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < iMax);
        if (
            !BigNumbers.eq(
                y,
                BigNumbers.modexp(x, BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO), n)
            )
        ) return false;
        return true;
    }

    function verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta,
        uint256 T
    ) internal view returns (bool) {
        uint i;
        uint256 iMax = i_proofLastIndex - delta;
        BigNumber memory _r;
        do {
            _r = _modHashMod128(bytes.concat(y.val, v[i].val), x);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            if (T & 1 != 0)
                y = BigNumbers.modexp(y, BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO), n);
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
                            BigNumbers
                                ._powModulus(
                                    BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                                    2 ** delta
                                )
                                .val
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
        uint256 delta
    ) internal view returns (bool) {
        uint i;
        uint256 iMax = i_proofLastIndex - delta;
        BigNumber memory _r;
        do {
            _r = _modHashMod128(
                bytes.concat(proofList[i].y.val, proofList[i].v.val),
                proofList[i].x
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
        uint256 twoPowerOfDelta = 2 ** delta;
        while (i < twoPowerOfDelta) {
            _x = BigNumbers._modexp(_x, BigNumbers.BYTESTWO, nVal);
            unchecked {
                ++i;
            }
        }
        if (!BigNumbers.eq(proofList[i_proofLastIndex - delta].y, BigNumbers.init(_x)))
            return false;
        return true;
    }

    function verifyRecursiveHalvingProofNTXYVDeltaApplied(
        VDFClaimTXYVN[] memory proofList,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta
    ) internal view returns (bool) {
        uint i;
        uint256 iMax = i_proofLastIndex - delta;
        BigNumber memory _r;
        do {
            _r = _modHashMod128(
                bytes.concat(proofList[i].y.val, proofList[i].v.val),
                proofList[i].x
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
        if (
            !BigNumbers.eq(
                proofList[i].y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        proofList[i].x.val,
                        BigNumbers._modexp(
                            BigNumbers.BYTESTWO,
                            bigNumTwoPowerOfDelta,
                            BigNumbers
                                ._powModulus(
                                    BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                                    2 ** delta
                                )
                                .val
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
        BigNumber memory _r;
        do {
            _r = _modHashMod128(bytes.concat(y.val, proofList[i].v.val), x);
            x = BigNumbers.modmul(
                BigNumbers.modexp(x, _r, proofList[i].n),
                proofList[i].v,
                proofList[i].n
            );
            if (T & 1 != 0)
                y = BigNumbers.modexp(
                    y,
                    BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                    proofList[i].n
                );
            y = BigNumbers.modmul(
                BigNumbers.modexp(proofList[i].v, _r, proofList[i].n),
                y,
                proofList[i].n
            );
            unchecked {
                ++i;
                T = T >> 1;
            }
        } while (i < i_proofLastIndex);
        if (
            !BigNumbers.eq(
                y,
                BigNumbers.modexp(
                    x,
                    BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                    proofList[i].n
                )
            )
        ) return false;
        return true;
    }

    function verifyRecursiveHalvingProofSkippingN(
        BigNumber memory n,
        VDFClaimTXYV[] memory proofList
    ) internal view returns (bool) {
        uint i;
        BigNumber memory _r;
        do {
            _r = _modHashMod128(
                bytes.concat(proofList[i].y.val, proofList[i].v.val),
                proofList[i].x
            );
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) return false;
            if (proofList[i].T & 1 == 1)
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
            }
        } while (i < i_proofLastIndex);
        if (
            !BigNumbers.eq(
                proofList[i].y,
                BigNumbers.modexp(
                    proofList[i].x,
                    BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                    n
                )
            )
        ) return false;
        return true;
    }

    function verifyRecursiveHalvingProofNTXYVInProof(
        VDFClaimTXYVN[] memory proofList
    ) internal view returns (bool) {
        uint i;
        BigNumber memory _r;
        do {
            _r = _modHashMod128(
                bytes.concat(proofList[i].y.val, proofList[i].v.val),
                proofList[i].x
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
        } while (i < i_proofLastIndex);
        if (
            !BigNumbers.eq(
                proofList[i].y,
                BigNumbers.modexp(
                    proofList[i].x,
                    BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                    proofList[i].n
                )
            )
        ) return false;
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
    ) external view {
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

    function _modHashMod128(
        bytes memory strings,
        BigNumber memory n
    ) private view returns (BigNumber memory) {
        return
            BigNumbers.init(
                abi.encodePacked(
                    (bytes32(
                        BigNumbers.mod(BigNumbers.init(abi.encodePacked(keccak256(strings))), n).val
                    ) >> 128)
                )
            );
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
