// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./libraries/BigNumbers.sol";
import "hardhat/console.sol";

contract OptimizedPietrzak {
    error XPrimeNotEqualAtIndex(uint256 index);
    error YPrimeNotEqualAtIndex(uint256 index);
    error NotVerifiedAtTOne();
    error TOneNotAtLast();
    error NotVerified();

    struct VDFClaim {
        BigNumber x;
        BigNumber y;
        BigNumber v;
    }

    bytes internal constant BYTESFOUR =
        hex"0000000000000000000000000000000000000000000000000000000000000004";
    uint256 private constant UINTFOUR = 4;
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";
    uint256 private constant MODFORHASH_LEN = 129;
    uint256 private constant ZERO = 0;
    uint256 private constant ONE = 1;
    uint256 private constant T = 4194304; // 2^22\
    uint256 private constant DELTA = 1;
    uint256 private constant POW2POW2DELTA = 4;
    uint256 private constant PROOFLASTINDEX = 22;
    uint256 private constant PROOFLASTINDEXOPTIMIZED = 20;
    uint256 private constant PROOFOPTIMIZEDLENGTH = 21;

    function compareGasModLeftAndRight(VDFClaim[] calldata proofList) external view {
        bytes32 s = keccak256("any string");
        console.logBytes32(s);
        BigNumber memory _r;
        uint256 start = gasleft();
        _r = _modHash(bytes.concat(proofList[0].y.val, proofList[0].v.val), proofList[0].x);
        console.log(start - gasleft());
        start = gasleft();
        _r = _hashMod128(bytes.concat(proofList[0].x.val, proofList[0].y.val, proofList[0].v.val));
        console.log(start - gasleft());
        start = gasleft();
        BigNumber memory a = BigNumbers.mod(
            BigNumbers.init(abi.encodePacked(s)),
            BigNumber(MODFORHASH, MODFORHASH_LEN)
        );
        console.log(start - gasleft());
        start = gasleft();
        BigNumber memory c = BigNumbers.init(abi.encodePacked(s >> 128));
        console.log(start - gasleft());
        start = gasleft();
        BigNumber memory b = BigNumbers.init(abi.encodePacked(bytes16(s)));
        console.log(start - gasleft());
        start = gasleft();
        BigNumber memory d = BigNumbers.init(abi.encodePacked(s << 128));
        console.log(start - gasleft());
        console.logBytes(a.val);
        console.logBytes(b.val);
        console.logBytes(c.val);
        console.logBytes(d.val);
        console.log(a.bitlen);
        console.log(b.bitlen);
        console.log(c.bitlen);
        console.log(d.bitlen);
    }

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

    function verifyRecursiveHalvingProofBytes(
        VDFClaim[] memory proofList,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 delta
    ) external view {
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        uint i;
        BigNumber memory _r;
        do {
            _r = _modHash(bytes.concat(proofList[i].y.val, proofList[i].v.val), proofList[i].x);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) revert XPrimeNotEqualAtIndex(i);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) revert YPrimeNotEqualAtIndex(i);
            i = _unchecked_inc(i);
        } while (i < PROOFLASTINDEX - delta);
        // x^2
        // if (!BigNumbers.eq(proofList[i].y, BigNumbers.modexp(proofList[i].x, _two, n)))
        //     revert NotVerifiedAtTOne();
        // x^2^2^delta  NotVerifiedAtTOne

        // BigNumbers._modexp(
        //     proofList[i].x.val,
        //     BigNumbers._modexp(
        //         _two.val,
        //         bigNumTwoPowerOfDelta,
        //         BigNumbers._powModulus(_two, twoPowerOfDelta).val
        //     ),
        //     n.val
        // );

        if (
            !BigNumbers.eq(
                proofList[i].y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        proofList[i].x.val,
                        BigNumbers._modexp(
                            _two.val,
                            bigNumTwoPowerOfDelta,
                            BigNumbers._powModulus(_two, twoPowerOfDelta).val
                        ),
                        n.val
                    )
                )
            )
        ) revert NotVerifiedAtTOne();
    }

    function verifyRecursiveHalvingProofBytes1(
        VDFClaim[] memory proofList,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta
    ) external view {
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        uint i;
        BigNumber memory _r;
        do {
            _r = _modHash(bytes.concat(proofList[i].y.val, proofList[i].v.val), proofList[i].x);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) revert XPrimeNotEqualAtIndex(i);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) revert YPrimeNotEqualAtIndex(i);
            i = _unchecked_inc(i);
        } while (i < PROOFLASTINDEX - delta);
        if (
            !BigNumbers.eq(
                proofList[i].y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        proofList[i].x.val,
                        BigNumbers._modexp(
                            _two.val,
                            bigNumTwoPowerOfDelta,
                            BigNumbers._powModulus(_two, 2 ** delta).val
                        ),
                        n.val
                    )
                )
            )
        ) revert NotVerifiedAtTOne();
    }

    function verifyRecursiveHalvingProof(
        VDFClaim[] memory proofList,
        BigNumber memory n,
        BigNumber memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 delta
    ) external view {
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        uint i;
        BigNumber memory _r;
        do {
            _r = _modHash(bytes.concat(proofList[i].y.val, proofList[i].v.val), proofList[i].x);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) revert XPrimeNotEqualAtIndex(i);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) revert YPrimeNotEqualAtIndex(i);
            i = _unchecked_inc(i);
        } while (i < PROOFLASTINDEX - delta);
        // x^2
        // if (!BigNumbers.eq(proofList[i].y, BigNumbers.modexp(proofList[i].x, _two, n)))
        //     revert NotVerifiedAtTOne();
        // x^2^2^delta  NotVerifiedAtTOne
        if (
            !BigNumbers.eq(
                proofList[i].y,
                BigNumbers.modexp(
                    proofList[i].x,
                    BigNumbers.modexp(
                        _two,
                        bigNumTwoPowerOfDelta,
                        BigNumbers._powModulus(_two, twoPowerOfDelta)
                    ),
                    n
                )
            )
        ) revert NotVerifiedAtTOne();
    }

    function verifyRecursiveHalvingProofRepeated(
        VDFClaim[] memory proofList,
        BigNumber memory n,
        uint256 twoPowerOfDelta,
        uint256 delta
    ) external view {
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        uint i;
        BigNumber memory _r;
        do {
            _r = _modHash(bytes.concat(proofList[i].y.val, proofList[i].v.val), proofList[i].x);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) revert XPrimeNotEqualAtIndex(i);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) revert YPrimeNotEqualAtIndex(i);
            i = _unchecked_inc(i);
        } while (i < PROOFLASTINDEX - delta);
        // if (!BigNumbers.eq(proofList[i].y, BigNumbers.modexp(proofList[i].x, _two, n)))
        _r = BigNumbers.modexp(proofList[i].x, _two, n);
        i = 1;
        while (i < twoPowerOfDelta) {
            _r = BigNumbers.modexp(_r, _two, n);
            unchecked {
                ++i;
            }
        }
        if (!BigNumbers.eq(proofList[PROOFLASTINDEX - delta].y, _r)) revert NotVerifiedAtTOne();
    }

    function verifyRecursiveHalvingProofRepeatedBytes(
        VDFClaim[] memory proofList,
        BigNumber memory n,
        uint256 twoPowerOfDelta,
        uint256 delta
    ) external view {
        uint i;
        BigNumber memory _r;
        do {
            _r = _modHash(bytes.concat(proofList[i].y.val, proofList[i].v.val), proofList[i].x);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) revert XPrimeNotEqualAtIndex(i);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) revert YPrimeNotEqualAtIndex(i);
            i = _unchecked_inc(i);
        } while (i < PROOFLASTINDEX - delta);
        // if (!BigNumbers.eq(proofList[i].y, BigNumbers.modexp(proofList[i].x, _two, n)))
        bytes memory _x = BigNumbers._modexp(proofList[i].x.val, BigNumbers.BYTESTWO, n.val);
        i = 1;
        while (i < twoPowerOfDelta) {
            _x = BigNumbers._modexp(_x, BigNumbers.BYTESTWO, n.val);
            unchecked {
                ++i;
            }
        }
        if (!BigNumbers.eq(proofList[PROOFLASTINDEX - delta].y, BigNumbers.init(_x)))
            revert NotVerifiedAtTOne();
    }

    function verifyRecursiveHalvingProof1(
        VDFClaim[] memory proofList,
        BigNumber memory n
    ) external view {
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        uint i;
        BigNumber memory _r;
        do {
            _r = _modHash(bytes.concat(proofList[i].y.val, proofList[i].v.val), proofList[i].x);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) revert XPrimeNotEqualAtIndex(i);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) revert YPrimeNotEqualAtIndex(i);
            i = _unchecked_inc(i);
        } while (i < PROOFLASTINDEX);
        // x^2
        if (!BigNumbers.eq(proofList[i].y, BigNumbers.modexp(proofList[i].x, _two, n)))
            revert NotVerifiedAtTOne();
    }

    function verifyRecursiveHalvingProof2(
        VDFClaim[] memory proofList,
        BigNumber memory n,
        BigNumber memory bigNumDelta,
        uint256 delta
    ) external view {
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        uint i;
        BigNumber memory _r;
        do {
            _r = _modHash(bytes.concat(proofList[i].y.val, proofList[i].v.val), proofList[i].x);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) revert XPrimeNotEqualAtIndex(i);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) revert YPrimeNotEqualAtIndex(i);
            i = _unchecked_inc(i);
        } while (i < PROOFLASTINDEX - delta);
        // x^2
        // if (!BigNumbers.eq(proofList[i].y, BigNumbers.modexp(proofList[i].x, _two, n)))
        //     revert NotVerifiedAtTOne();
        // x^2^2^delta  NotVerifiedAtTOne
        _r = BigNumbers.modexp(_two, bigNumDelta, BigNumbers._powModulus(_two, delta));
        if (
            !BigNumbers.eq(
                proofList[i].y,
                BigNumbers.modexp(
                    proofList[i].x,
                    BigNumbers.modexp(
                        _two,
                        _r,
                        BigNumbers._powModulus(_two, uint256(bytes32(_r.val)))
                    ),
                    n
                )
            )
        ) revert NotVerifiedAtTOne();
    }

    function _modHash(
        bytes memory strings,
        BigNumber memory n
    ) private view returns (BigNumber memory) {
        return BigNumbers.mod(BigNumbers.init(abi.encodePacked(keccak256(strings) >> 128)), n);
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
