// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "../libraries/BigNumbers.sol";

interface IExponentiation {
    function exponentiation(
        BigNumber memory x,
        BigNumber memory t,
        BigNumber memory n
    ) external view returns (BigNumber memory);

    function precompileExponentiation(
        bytes memory _b,
        bytes memory _e,
        bytes memory _m
    ) external view returns (bytes memory);
}

interface IMultiExponentiation {
    function multiExponentiation(
        BigNumber calldata a,
        BigNumber calldata x,
        BigNumber calldata y,
        BigNumber calldata n
    ) external view returns (BigNumber memory);
}

contract PrecompileMultiExp {
    function multiExponentiation(
        BigNumber calldata a,
        BigNumber calldata x,
        BigNumber calldata y,
        BigNumber calldata n
    ) external view returns (BigNumber memory) {
        return
            BigNumbers.modmul(
                BigNumbers.modexp(x, a, n),
                BigNumbers.modexp(
                    y,
                    BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                    n
                ),
                n
            );
    }
}

contract DimitrovMultiExp {
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

    function multiExponentiation(
        BigNumber memory a,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n
    ) external view returns (BigNumber memory _z) {
        _z = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
        BigNumber memory _b = BigNumber(
            BigNumbers.BYTESTWO,
            BigNumbers.UINTTWO
        );
        BigNumber memory _q = BigNumbers.modmul(x, y, n);
        uint256 firstByteIndex = 31 - (((a.bitlen - 1) % 256) >> 3);
        bytes1 aValByte1 = a.val[firstByteIndex];
        bool _aBool;
        uint256 j = 7 - ((a.bitlen - 1) % 8);
        while (j < 6) {
            _z = BigNumbers.modexp(_z, _b, n);
            _aBool = (aValByte1 & MASKS[j]) != 0;
            if (_aBool) _z = BigNumbers.modmul(_z, x, n);
            unchecked {
                ++j;
            }
        }
        if (j == 6) {
            _z = BigNumbers.modexp(_z, _b, n);
            _aBool = (aValByte1 & MASKS[j]) != 0;
            bool _bBool = a.val.length - firstByteIndex == 1;
            if (_aBool && _bBool) {
                _z = BigNumbers.modmul(_z, _q, n);
            } else if (_aBool) {
                _z = BigNumbers.modmul(_z, x, n);
            } else if (_bBool) {
                _z = BigNumbers.modmul(_z, y, n);
            }
            unchecked {
                ++j;
            }
        }
        _z = BigNumbers.modexp(_z, _b, n);
        _aBool = (aValByte1 & MASKS[j]) != 0;
        if (_aBool) _z = BigNumbers.modmul(_z, x, n);
        uint256 iMax = a.bitlen / 8 + 1 + firstByteIndex;
        uint256 i = 1 + firstByteIndex;
        for (; i < iMax - 1; i = unchecked_increment(i)) {
            aValByte1 = a.val[i];
            j = 0;
            do {
                _z = BigNumbers.modexp(_z, _b, n);
                _aBool = (aValByte1 & MASKS[j]) != 0;
                if (_aBool) _z = BigNumbers.modmul(_z, x, n);
                unchecked {
                    ++j;
                }
            } while (j < 8);
        }
        if (i == iMax - 1) {
            aValByte1 = a.val[i];
            j = 0;
            do {
                _z = BigNumbers.modexp(_z, _b, n);
                _aBool = (aValByte1 & MASKS[j]) != 0;
                if (_aBool) _z = BigNumbers.modmul(_z, x, n);
                unchecked {
                    ++j;
                }
            } while (j < 6);
            _z = BigNumbers.modexp(_z, _b, n);
            _aBool = (aValByte1 & MASKS[j]) != 0;
            if (_aBool) _z = BigNumbers.modmul(_z, _q, n);
            else _z = BigNumbers.modmul(_z, y, n);
            unchecked {
                ++j;
            }
            _z = BigNumbers.modexp(_z, _b, n);
            _aBool = (aValByte1 & MASKS[j]) != 0;
            if (_aBool) _z = BigNumbers.modmul(_z, x, n);
        }
    }

    function unchecked_increment(uint256 a) public pure returns (uint256) {
        unchecked {
            return a + 1;
        }
    }
}

contract ExponentiationBySquaring {
    function exponentiation(
        BigNumber memory x,
        BigNumber memory t,
        BigNumber memory n
    ) external view returns (BigNumber memory) {
        if (t.bitlen == 0)
            return BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
        if (t.bitlen == 1) return x;
        BigNumber memory y = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
        BigNumber memory one = BigNumber(
            BigNumbers.BYTESONE,
            BigNumbers.UINTONE
        );
        do {
            if (BigNumbers.isOdd(t)) {
                y = BigNumbers.modmul(x, y, n);
                //t = sub(t, one);
            }
            x = BigNumbers.modexp(
                x,
                BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                n
            );
            t = BigNumbers._shr(t, 1);
        } while (gt(t, one));
        return BigNumbers.modmul(x, y, n);
    }

    function gt(
        BigNumber memory a,
        BigNumber memory b
    ) internal pure returns (bool) {
        int256 result = BigNumbers.cmp(a, b);
        return (result == BigNumbers.INTONE) ? true : false;
    }
}

contract SquareAndMultiply {
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

    function exponentiation(
        BigNumber memory x,
        BigNumber memory t,
        BigNumber memory n
    ) external view returns (BigNumber memory) {
        if (t.bitlen == 0)
            return BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
        if (t.bitlen == 1) return x;
        uint256 firstByteIndex = 31 - (((t.bitlen - 1) % 256) >> 3);
        uint256 j = 8 - ((t.bitlen - 1) % 8);
        BigNumber memory _two = BigNumber(
            BigNumbers.BYTESTWO,
            BigNumbers.UINTTWO
        );
        BigNumber memory _originalX = x;
        bytes1 tValByte1 = t.val[firstByteIndex];
        while (j < 8) {
            x = BigNumbers.modexp(x, _two, n);
            if ((tValByte1 & MASKS[j]) != 0) {
                x = BigNumbers.modmul(x, _originalX, n);
            }
            unchecked {
                ++j;
            }
        }
        uint256 iMax = t.bitlen / 8 + 1 + firstByteIndex;
        for (
            uint256 i = 1 + firstByteIndex;
            i < iMax;
            i = unchecked_increment(i)
        ) {
            tValByte1 = t.val[i];
            j = 0;
            do {
                x = BigNumbers.modexp(x, _two, n);
                if ((tValByte1 & MASKS[j]) != 0) {
                    x = BigNumbers.modmul(x, _originalX, n);
                }
                unchecked {
                    ++j;
                }
            } while (j < 8);
        }
        return x;
    }

    function unchecked_increment(uint256 a) public pure returns (uint256) {
        unchecked {
            return a + 1;
        }
    }
}

contract PrecompileModExp {
    function precompileExponentiation(
        bytes memory _b,
        bytes memory _e,
        bytes memory _m
    ) external view returns (bytes memory r) {
        assembly ("memory-safe") {
            let bl := mload(_b)
            let el := mload(_e)
            let ml := mload(_m)

            let freemem := mload(0x40) // Free memory pointer is always stored at 0x40

            mstore(freemem, bl) // arg[0] = base.length @ +0

            mstore(add(freemem, 32), el) // arg[1] = exp.length @ +32

            mstore(add(freemem, 64), ml) // arg[2] = mod.length @ +64

            // arg[3] = base.bits @ + 96
            // Use identity built-in (contract 0x4) as a cheap memcpy
            let success := staticcall(
                450,
                0x4,
                add(_b, 32),
                bl,
                add(freemem, 96),
                bl
            )

            // arg[4] = exp.bits @ +96+base.length
            let size := add(96, bl)
            success := staticcall(
                450,
                0x4,
                add(_e, 32),
                el,
                add(freemem, size),
                el
            )

            // arg[5] = mod.bits @ +96+base.length+exp.length
            size := add(size, el)
            success := staticcall(
                450,
                0x4,
                add(_m, 32),
                ml,
                add(freemem, size),
                ml
            )

            switch success
            case 0 {
                invalid()
            } //fail where we haven't enough gas to make the call

            // Total size of input = 96+base.length+exp.length+mod.length
            size := add(size, ml)
            // Invoke contract 0x5, put return value right after mod.length, @ +96
            success := staticcall(
                sub(gas(), 1350),
                0x5,
                freemem,
                size,
                add(freemem, 0x60),
                ml
            )

            switch success
            case 0 {
                invalid()
            } //fail where we haven't enough gas to make the call

            let length := ml
            let msword_ptr := add(freemem, 0x60)

            ///the following code removes any leading words containing all zeroes in the result.
            for {

            } eq(eq(length, 0x20), 0) {

            } {
                // for(; length!=32; length-=32)
                switch eq(mload(msword_ptr), 0) // if(msword==0):
                case 1 {
                    msword_ptr := add(msword_ptr, 0x20)
                } //     update length pointer
                default {
                    break
                } // else: loop termination. non-zero word found
                length := sub(length, 0x20)
            }
            r := sub(msword_ptr, 0x20)
            mstore(r, length)

            // point to the location of the return value (length, bits)
            //assuming mod length is multiple of 32, return value is already in the right format.
            mstore(0x40, add(add(96, freemem), ml)) //deallocate freemem pointer
        }
    }
}
