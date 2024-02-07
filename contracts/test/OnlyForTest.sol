// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "hardhat/console.sol";
import "./../libraries/BigNumbers.sol";

contract OnlyForTest {
    using BigNumbers for *;
    /* Errors */
    error AlreadyCommitted();
    error NotCommittedParticipant();
    error AlreadyRevealed();
    error ModExpRevealNotMatchCommit();
    error NotAllRevealed();
    error OmegaAlreadyCompleted();
    error FunctionInvalidAtThisStage();
    error TNotMatched();
    error NotVerifiedAtTOne();
    error RecovNotMatchX();
    error StageNotFinished();
    error CommitRevealDurationLessThanCommitDuration();
    error AllFinished();
    error NoneParticipated();
    error ShouldNotBeZero();
    error TOneNotAtLast();
    error iNotMatchProofSize();
    error XPrimeNotEqualAtIndex(uint256 index);
    error YPrimeNotEqualAtIndex(uint256 index);
    uint256 aa;
    struct VDFClaimWithN {
        uint256 T;
        BigNumber x;
        BigNumber y;
        BigNumber v;
        BigNumber n;
    }
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";
    uint256 private constant MODFORHASH_LEN = 129;
    uint256 private constant ZERO = 0;
    uint256 private constant ONE = 1;

    function recover(
        uint256 round,
        VDFClaimWithN[] calldata _proofs
    ) external returns (string memory) {
        aa = 1;
        return "test";
    }

    struct VDFClaim {
        uint256 T;
        BigNumber x;
        BigNumber y;
        BigNumber v;
    }

    function verifyRecursiveHalvingProof(
        VDFClaim[] calldata _proofList,
        BigNumber memory _n,
        uint256 _proofsLastIndex
    ) public {
        BigNumber memory _two = BigNumbers.two();
        uint256 i;
        for (; i < _proofsLastIndex; i = unchecked_inc(i)) {
            if (_proofList[i].T == ONE) {
                if (!_proofList[i].y.eq(_proofList[i].x.modexp(_two, _n)))
                    revert NotVerifiedAtTOne();
                if (i + ONE != _proofsLastIndex) revert TOneNotAtLast();
                return;
            }
            BigNumber memory _y = _proofList[i].y;
            BigNumber memory _r = modHash(
                bytes.concat(_proofList[i].y.val, _proofList[i].v.val),
                _proofList[i].x
            ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
            if (_proofList[i].T & ONE == ONE) _y = _y.modexp(_two, _n);
            BigNumber memory _xPrime = _proofList[i].x.modexp(_r, _n).modmul(_proofList[i].v, _n);
            if (!_xPrime.eq(_proofList[unchecked_inc(i)].x)) revert XPrimeNotEqualAtIndex(i);
            BigNumber memory _yPrime = _proofList[i].v.modexp(_r, _n);
            if (!_yPrime.modmul(_y, _n).eq(_proofList[unchecked_inc(i)].y))
                revert YPrimeNotEqualAtIndex(i);
        }
        if (i != _proofsLastIndex) revert iNotMatchProofSize();
    }

    struct VDFClaimWithoutT {
        BigNumber x;
        BigNumber y;
        BigNumber v;
    }

    function verifyRecursiveHalvingProofWithoutT(
        VDFClaimWithoutT[] calldata _proofList,
        BigNumber memory _n,
        uint256 _proofsLastIndex,
        uint256 _T
    ) public {
        _proofsLastIndex -= 1;
        BigNumber memory _two = BigNumbers.two();
        uint256 i;
        for (; i < _proofsLastIndex; i = unchecked_inc(i)) {
            BigNumber memory _y = _proofList[i].y;
            BigNumber memory _r = modHash(
                bytes.concat(_proofList[i].y.val, _proofList[i].v.val),
                _proofList[i].x
            ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
            if (_T & ONE == ONE) {
                _T += 1;
                _y = _y.modexp(_two, _n);
            }
            BigNumber memory _xPrime = _proofList[i].x.modexp(_r, _n).modmul(_proofList[i].v, _n);
            if (!_xPrime.eq(_proofList[unchecked_inc(i)].x)) revert XPrimeNotEqualAtIndex(i);
            BigNumber memory _yPrime = _proofList[i].v.modexp(_r, _n);
            if (!_yPrime.modmul(_y, _n).eq(_proofList[unchecked_inc(i)].y))
                revert YPrimeNotEqualAtIndex(i);
            _T >>= 1;
        }
        if (!_proofList[i].y.eq(_proofList[i].x.modexp(_two, _n))) revert NotVerifiedAtTOne();
        if (i != _proofsLastIndex || _T != ONE) revert TOneNotAtLast();
        return;
    }

    function modHash(
        bytes memory _strings,
        BigNumber memory _n
    ) private view returns (BigNumber memory) {
        return abi.encodePacked(keccak256(_strings)).init().mod(_n);
    }

    function unchecked_inc(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    bytes1 constant ZEROBYTE1 = hex"00";
    bytes1 constant ONEMASK = hex"01";
    bytes1 constant TWOMASK = hex"02";
    bytes1 constant THREEMASK = hex"04";
    bytes1 constant FOURMASK = hex"08";
    bytes1 constant FIVEMASK = hex"10";
    bytes1 constant SIXMASK = hex"20";
    bytes1 constant SEVENMASK = hex"40";
    bytes1 constant EIGHTMASK = hex"80";

    bytes constant MASKS =
        abi.encodePacked(
            EIGHTMASK,
            SEVENMASK,
            SIXMASK,
            FIVEMASK,
            FOURMASK,
            THREEMASK,
            TWOMASK,
            ONEMASK
        );

    function dimitrovMultiExp(
        BigNumber memory _a,
        BigNumber memory _x,
        BigNumber memory _y,
        BigNumber memory _n
    ) external returns (BigNumber memory) {
        BigNumber memory _z = BigNumbers.one();
        BigNumber memory _b = BigNumbers.two();
        BigNumber memory _q = _x.modmul(_y, _n);

        uint256 _pad = (_a.bitlen / 8) % 32;
        _pad = _pad % 2 == 0 ? _pad : _pad + 1;
        bytes1 tempA = _a.val[_pad];
        bytes1 tempB = _b.val[_pad];
        bool _aBool;
        bool _bBool;

        for (uint256 j = 8 - (((_a.bitlen - 1) % 8) + 1); j < 8; j = unchecked_inc(j)) {
            // first 1 byte
            _z = _z.modmul(_z, _n);
            _aBool = tempA & MASKS[j] > ZEROBYTE1;
            _bBool = tempB & MASKS[j] > ZEROBYTE1;
            if (_aBool && _bBool) {
                _z = _z.modmul(_q, _n);
            } else if (_aBool) {
                _z = _z.modmul(_x, _n);
            } else if (_bBool) {
                _z = _z.modmul(_y, _n);
            }
        }
        uint iMax = ((_a.bitlen + 7) / 8) + _pad;
        for (uint256 i = 1 + _pad; i < iMax; i = unchecked_inc(i)) {
            tempA = _a.val[i];
            tempB = _b.val[i];
            for (uint256 j; j < 8; j = unchecked_inc(j)) {
                _z = _z.modmul(_z, _n);
                _aBool = tempA & MASKS[j] > ZEROBYTE1;
                _bBool = tempB & MASKS[j] > ZEROBYTE1;
                if (_aBool && _bBool) {
                    _z = _z.modmul(_q, _n);
                } else if (_aBool) {
                    _z = _z.modmul(_x, _n);
                } else if (_bBool) {
                    _z = _z.modmul(_y, _n);
                }
            }
        }
        return _z;
    }

    function dimitrovMultiExpView(
        BigNumber memory _a,
        BigNumber memory _x,
        BigNumber memory _y,
        BigNumber memory _n
    ) external view returns (BigNumber memory) {
        BigNumber memory _z = BigNumbers.one();
        BigNumber memory _b = BigNumbers.two();
        BigNumber memory _q = _x.modmul(_y, _n);

        uint256 _pad = (_a.bitlen / 8) % 32;
        _pad = _pad % 2 == 0 ? _pad : _pad + 1;
        bytes1 tempA = _a.val[_pad];
        bytes1 tempB = _b.val[_pad];
        bool _aBool;
        bool _bBool;

        for (uint256 j = 8 - (((_a.bitlen - 1) % 8) + 1); j < 8; j = unchecked_inc(j)) {
            // first 1 byte
            _z = _z.modmul(_z, _n);
            _aBool = tempA & MASKS[j] > ZEROBYTE1;
            _bBool = tempB & MASKS[j] > ZEROBYTE1;
            if (_aBool && _bBool) {
                _z = _z.modmul(_q, _n);
            } else if (_aBool) {
                _z = _z.modmul(_x, _n);
            } else if (_bBool) {
                _z = _z.modmul(_y, _n);
            }
        }
        uint iMax = ((_a.bitlen + 7) / 8) + _pad;
        for (uint256 i = 1 + _pad; i < iMax; i = unchecked_inc(i)) {
            tempA = _a.val[i];
            tempB = _b.val[i];
            for (uint256 j; j < 8; j = unchecked_inc(j)) {
                _z = _z.modmul(_z, _n);
                _aBool = tempA & MASKS[j] > ZEROBYTE1;
                _bBool = tempB & MASKS[j] > ZEROBYTE1;
                if (_aBool && _bBool) {
                    _z = _z.modmul(_q, _n);
                } else if (_aBool) {
                    _z = _z.modmul(_x, _n);
                } else if (_bBool) {
                    _z = _z.modmul(_y, _n);
                }
            }
        }
        return _z;
    }

    function dimitrovMultiExpViewForLoopCount(
        BigNumber memory _a,
        BigNumber memory _x,
        BigNumber memory _y,
        BigNumber memory _n
    ) external view returns (BigNumber memory) {
        BigNumber memory _z = BigNumbers.one();
        uint256 _pad = (_a.bitlen / 8) % 32;
        _pad = _pad % 2 == 0 ? _pad : _pad + 1;
        uint256 count;
        console.log(8 - (((_a.bitlen - 1) % 8) + 1));
        for (uint256 j = 8 - (((_a.bitlen - 1) % 8) + 1); j < 8; j++) {
            // first 1 byte
            count++;
        }
        uint iMax = ((_a.bitlen + 7) / 8) + _pad;
        for (uint256 i = 1 + _pad; i < iMax; i = unchecked_inc(i)) {
            for (uint256 j; j < 8; j = unchecked_inc(j)) {
                count++;
            }
        }
        console.log("count:", count);
        return _z;
    }

    function multiExp(
        BigNumber memory _a,
        BigNumber memory _b,
        BigNumber memory _x,
        BigNumber memory _y,
        BigNumber memory _n
    ) external returns (BigNumber memory) {
        return _x.modexp(_a, _n).modmul(_y.modexp(_b, _n), _n);
    }

    function multiExpView(
        BigNumber memory _a,
        BigNumber memory _b,
        BigNumber memory _x,
        BigNumber memory _y,
        BigNumber memory _n
    ) external view returns (BigNumber memory) {
        return _x.modexp(_a, _n).modmul(_y.modexp(_b, _n), _n);
    }

    function multiExpGas(
        BigNumber memory _a,
        BigNumber memory _b,
        BigNumber memory _x,
        BigNumber memory _y,
        BigNumber memory _n
    ) external returns (BigNumber memory) {
        uint256 startGas = gasleft();
        _x.modexp(_a, _n);
        console.log("gas used for modexp _x^_a %_n:", startGas - gasleft());
        startGas = gasleft();
        _x.modexp(_y, _n);
        console.log("gas used for modexp _x^_y %_n:", startGas - gasleft());
        startGas = gasleft();
        _x.modmul(_a, _n);
        console.log("gas used for modmul _x*_a %_n:", startGas - gasleft());
        startGas = gasleft();
        _x.modmul(_y, _n);
        console.log("gas used for modmul _x*_y%_n:", startGas - gasleft());
        return _x.modexp(_a, _n).modmul(_y.modexp(_b, _n), _n);
    }
}
