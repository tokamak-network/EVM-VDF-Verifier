// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract Exp {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
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

    function precompileMultiExp(BigNumber calldata a, BigNumber calldata b, BigNumber calldata x, BigNumber calldata y, BigNumber calldata n) external view returns (BigNumber memory) {
        return modmul(modexp(x, a, n), modexp(y, b, n), n);
    }

    //output x^a*y^2 mod n
    function precompileMultiExpFixedB2(BigNumber calldata a, BigNumber calldata x, BigNumber calldata y, BigNumber calldata n) external view returns (BigNumber memory){
        return modmul(modexp(x, a, n), modexp(y, BigNumber(BYTESTWO, UINTTWO), n), n);
    }
    function uncheckedIncrement32(uint256 a) internal pure returns (uint256) {
        unchecked {
            return a + 32;
        }
    }

    //output x^a*y^b mod n
    function dimitrovMultiExp(BigNumber memory a, BigNumber memory b, BigNumber memory x, BigNumber memory y, BigNumber memory n) external view returns (BigNumber memory _z) {
        uint256 firstByteIndex;
        uint256 iMax;
        uint256 i;
        if(a.bitlen < b.bitlen) {
            if(a.val.length < b.val.length){
                uint256 diff = b.val.length - a.val.length;
                for(; i < diff;i = uncheckedIncrement32(i)){
                    a.val = bytes.concat(BYTESZERO, a.val);
                }
            }
            firstByteIndex = 31 - (((b.bitlen - UINTONE) % 256)>> 3);
            iMax = b.bitlen / 8 + 1 + firstByteIndex;
            i = 7 - (b.bitlen - UINTONE) % 8;
        } else {
            if(a.val.length > b.val.length){
                uint256 diff = a.val.length - b.val.length;
                for(; i < diff;i = uncheckedIncrement32(i)){
                    b.val = bytes.concat(BYTESZERO, b.val);
                }
            }
            firstByteIndex = 31 - (((a.bitlen - UINTONE) % 256)>> 3);
            iMax = a.bitlen / 8 + 1 + firstByteIndex;
            i = 7 - (a.bitlen - UINTONE) % 8;
        }
        _z = BigNumber(BYTESONE, UINTONE);
        BigNumber memory _b = BigNumber(BYTESTWO, UINTTWO);
        BigNumber memory _q = modmul(x,y,n);
        bytes1 aValByte1 = a.val[firstByteIndex];
        bytes1 bValByte1 = b.val[firstByteIndex];
        for (;i<8; i = unchecked_increment(i)) {
            _z = modexp(_z, _b, n);
            bool _aBool = (aValByte1 & MASKS[i]) != 0;
            bool _bBool = (bValByte1 & MASKS[i]) != 0;
            if (_aBool && _bBool) {
                _z = modmul(_z, _q, n);
            } else if (_aBool) {
                _z = modmul(_z, x, n);
            } else if (_bBool) {
                _z = modmul(_z, y, n);
            }
        }
        for (i = 1 + firstByteIndex; i < iMax; i = unchecked_increment(i)) {
            aValByte1 = a.val[i];
            bValByte1 = b.val[i];
            uint256 j;
            do {
                _z = modexp(_z, _b, n);
                bool _aBool = (aValByte1 & MASKS[j]) != 0;
                bool _bBool = (bValByte1 & MASKS[j]) != 0;
                if (_aBool && _bBool) {
                    _z = modmul(_z, _q, n);
                } else if (_aBool) {
                    _z = modmul(_z, x, n);
                } else if (_bBool) {
                    _z = modmul(_z, y, n);
                }   
                unchecked {
                    ++j;
                }
            } while (j < 8);
        }
    }
    

    //output x^a*y^2 mod n
    function dimitrovMultiExpFixedB2(BigNumber memory a, BigNumber memory x, BigNumber memory y, BigNumber memory n) external view returns (BigNumber memory _z) {
        _z = BigNumber(BYTESONE, UINTONE);
        BigNumber memory _b = BigNumber(BYTESTWO, UINTTWO);
        BigNumber memory _q = modmul(x,y,n);
        uint256 firstByteIndex = 31 - (((a.bitlen - 1) % 256)>> 3);
        bytes1 aValByte1 = a.val[firstByteIndex];
        bool _aBool;
        uint256 j = 7 - (a.bitlen - 1) % 8;
        while (j < 6) {
            _z = modexp(_z, _b, n);
             _aBool = (aValByte1 & MASKS[j]) != 0;
             if(_aBool ) _z = modmul(_z, x, n);
            unchecked{
                ++j;
            }
        }
        if (j==6){
            _z = modexp(_z, _b, n);
            _aBool = (aValByte1 & MASKS[j]) != 0;
            bool _bBool = a.val.length - firstByteIndex == 1;
            if (_aBool && _bBool) {
                _z = modmul(_z, _q, n);
            } else if (_aBool) {
                _z = modmul(_z, x, n);
            } else if (_bBool) {
                _z = modmul(_z, y, n);
            }
            unchecked {
                ++j;
            }
        }
        _z = modexp(_z, _b, n);
        _aBool = (aValByte1 & MASKS[j]) != 0;
        if (_aBool) _z = modmul(_z, x, n);
        uint256 iMax = a.bitlen / 8 + 1 + firstByteIndex;
        uint256 i = 1 + firstByteIndex;
        for(; i < iMax - 1; i= unchecked_increment(i)) {
            aValByte1 = a.val[i];
            j = 0;
            do {
                _z = modexp(_z, _b, n);
                _aBool = (aValByte1 & MASKS[j]) != 0;
                if (_aBool) _z = modmul(_z, x, n);
                unchecked {
                    ++j;
                }
            } while (j < 8);
        }
        if(i == iMax - 1){
            aValByte1 = a.val[i];
            j = 0;
            do {
                _z = modexp(_z, _b, n);
                _aBool = (aValByte1 & MASKS[j]) != 0;
                if(_aBool ) _z = modmul(_z, x, n);
                unchecked{
                    ++j;
                }
            } while (j < 6);
            _z = modexp(_z, _b, n);
            _aBool = (aValByte1 & MASKS[j]) != 0;
            if (_aBool) _z = modmul(_z, _q, n);
            else _z = modmul(_z, y, n);
            unchecked {
                ++j;
            }
            _z = modexp(_z, _b, n);
            _aBool = (aValByte1 & MASKS[j]) != 0;
            if (_aBool) _z = modmul(_z, x, n);
        }
    }

    

        //output x^a*y^2 mod n
    function dimitrovMultiExpVer1(BigNumber memory a, BigNumber memory x, BigNumber memory y, BigNumber memory n) external view returns (BigNumber memory _z) {
        _z = BigNumber(BYTESONE, UINTONE);
        BigNumber memory _b = BigNumber(BYTESTWO, UINTTWO);
        BigNumber memory _q = modmul(x,y,n);
        uint256 firstByteIndex = 31 - (((a.bitlen - 1) % 256)>> 3);
        bytes1 aValByte1 = a.val[firstByteIndex];
        bytes1 bValByte1 = _b.val[firstByteIndex];
        bool _aBool;
         bool _bBool;
        uint256 i = 7 - (a.bitlen - 1) % 8;
        do {
            _z = modexp(_z, _b, n);
             _aBool = (aValByte1 & MASKS[i]) != 0;
             _bBool = _bBool && i == 6;
            if (_aBool && _bBool) {
                _z = modmul(_z, _q, n);
            } else if (_aBool) {
                _z = modmul(_z, x, n);
            } else if (_bBool) {
                _z = modmul(_z, y, n);
            }
            unchecked {
                ++i;
            }
        } while(i < 8);
        uint256 iMax = a.bitlen / 8 + 1 + firstByteIndex;
        for(i=1 + firstByteIndex; i < iMax; i= unchecked_increment(i)) {
            aValByte1 = a.val[i];
            bValByte1 = _b.val[i];
            _bBool = i == iMax - 1;
            uint256 j;
            do {
                _z = modexp(_z, _b, n);
                _aBool = (aValByte1 & MASKS[j]) != 0;
                _bBool = (bValByte1 & MASKS[j]) != 0;
                if (_aBool && _bBool) {
                    _z = modmul(_z, _q, n);
                } else if (_aBool) {
                    _z = modmul(_z, x, n);
                } else if (_bBool) {
                    _z = modmul(_z, y, n);
                }
                unchecked {
                    ++j;
                }
            } while (j < 8);
        }
    }

    function unchecked_increment(uint256 a) public pure returns (uint256) {
        unchecked {
            return a + 1;
        }
    }


    function exp_by_squaring_iterative(uint256 x, uint256 n) public pure returns (uint256) {
        if (n == 0) return 1;
        if (n == 1) return x;
        uint256 y = 1;
        do {
            if (n % 2 == 1) {
                y = x * y;
                unchecked {
                    --n;
                }
            }
            x = x * x;
            n = n / 2;
        } while (n > 1);

        return x * y;
    }

    function bigNumber_exp_by_squaring_iterative(BigNumber memory x, BigNumber memory n) public view returns (BigNumber memory) {
        if (n.bitlen == 0) return BigNumber(BYTESONE, UINTONE);
        if (n.bitlen == 1) return x;
        BigNumber memory y = BigNumber(BYTESONE, UINTONE);
        BigNumber memory one = BigNumber(BYTESONE, UINTONE);
        do {
            if (isOdd(n)) {
                y = mul(x, y);
                //n = sub(n, one);
            }
            x = mul(x, x);
            n = _shr(n, 1);
        } while (gt(n, one));
        return mul(x, y);
    }

    function bigNumber_exp_by_squaring_and_multiply_mod(BigNumber memory x, BigNumber memory t, BigNumber memory n) external view returns (BigNumber memory) {
        if(t.bitlen == 0) return BigNumber(BYTESONE, UINTONE);
        if(t.bitlen == 1) return x;
        uint256 firstByteIndex = 31 - (((t.bitlen - 1) % 256) >> 3);
        uint256 j = 8 - (t.bitlen - 1) % 8;
        BigNumber memory _two = BigNumber(BYTESTWO, UINTTWO);
        BigNumber memory _originalX = x;
        bytes1 tValByte1 = t.val[firstByteIndex];
        while (j < 8) {
            x = modexp(x, _two, n);
            if ((tValByte1 & MASKS[j]) != 0) {
                x = modmul(x, _originalX, n);
            }
            unchecked {
                ++j;
            }
        }
        uint256 iMax = t.bitlen / 8 + 1 + firstByteIndex;
        for (uint256 i = 1 + firstByteIndex; i < iMax; i = unchecked_increment(i)) {
            tValByte1 = t.val[i];
            j = 0;
            do {
                x = modexp(x, _two, n);
                if ((tValByte1 & MASKS[j]) != 0) {
                    x = modmul(x, _originalX, n);
                }
                unchecked {
                    ++j;
                }
            } while (j < 8);
        }
        return x;
    }
    

    function bigNumber_exp_by_squaring_iterative_mod(BigNumber memory x, BigNumber memory t, BigNumber memory n) external view returns (BigNumber memory) {
        if (t.bitlen == 0) return BigNumber(BYTESONE, UINTONE);
        if (t.bitlen == 1) return x;
        BigNumber memory y = BigNumber(BYTESONE, UINTONE);
        BigNumber memory one = BigNumber(BYTESONE, UINTONE);
        do {
            if (isOdd(t)) {
                y = modmul(x, y, n);
                //t = sub(t, one);
            }
            x = modexp(x, BigNumber(BYTESTWO, UINTTWO), n);
            t = _shr(t, 1);
        } while (gt(t, one));
        return modmul(x, y, n);
    }


    /** @notice BigNumber odd number check
     * @dev isOdd: returns 1 if BigNumber value is an odd number and 0 otherwise.
     *
     * @param a BigNumber
     * @return r Boolean result
     */
    function isOdd(BigNumber memory a) internal pure returns (bool r) {
        assembly ("memory-safe") {
            let a_ptr := add(mload(a), mload(mload(a))) // go to least significant word
            r := mod(mload(a_ptr), 2) // mod it with 2 (returns 0 or 1)
        }
    }

        error BigNumbers__ShouldNotBeZero();
    
    /// @notice the value for number 0 of a BigNumber instance.
    bytes constant internal BYTESZERO = hex"0000000000000000000000000000000000000000000000000000000000000000";
    /// @notice the value for number 1 of a BigNumber instance.
    bytes constant internal  BYTESONE = hex"0000000000000000000000000000000000000000000000000000000000000001";
    /// @notice the value for number 2 of a BigNumber instance.
    bytes constant internal  BYTESTWO = hex"0000000000000000000000000000000000000000000000000000000000000002";
    uint256 constant internal UINTZERO = 0;
    uint256 constant internal UINTONE = 1;
    uint256 constant internal UINTTWO = 2;
    uint256 constant internal UINT32 = 32;
    int256 constant internal INTZERO = 0;
    int256 constant internal INTONE = 1;
    int256 constant internal INTMINUSONE = -1;

    // ***************** BEGIN EXPOSED MANAGEMENT FUNCTIONS ******************
/** @notice BigNumber equality
      * @dev eq: returns true if a==b. sign always considered.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
    function eq(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int256 result = cmp(a, b);
        return (result==INTZERO) ? true : false;
    }

    function gt(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(bool){
        int256 result = cmp(a, b);
        return (result==INTONE) ? true : false;
    }
    
    
    /** @notice initialize a BN instance
     *  @dev wrapper function for _init. initializes from bytes value.
     *
     *  @param val BN value. may be of any size.
     *  @return BigNumber instance
     */
    function init(
        bytes memory val
    ) internal view returns(BigNumber memory){
        return _init(val, UINTZERO);
    }

    /** @notice BigNumber full zero check
      * @dev isZero: checks if the BigNumber is in the default zero format for BNs (ie. the result from zero()).
      *             
      * @param a BigNumber
      * @return boolean result.
    */
    function isZero(
        BigNumber memory a
    ) internal pure returns(bool) {
        return isZero(a.val) && a.val.length==UINT32 && a.bitlen == UINTZERO;
    }

    // ***************** BEGIN EXPOSED CORE CALCULATION FUNCTIONS ******************
    /** @notice BigNumber modulus: a % n.
      * @dev mod: takes a BigNumber and modulus BigNumber (a,n), and calculates a % n.
      * modexp precompile is used to achieve a % n; an exponent of value '1' is passed.
      * @param a BigNumber
      * @param n modulus BigNumber
      * @return r result BigNumber
      */
    function mod(
        BigNumber memory a, 
        BigNumber memory n
    ) internal view returns(BigNumber memory){
      return modexp(a,BigNumber(BYTESONE, UINTONE),n);
    }

    function modexpExternal(
        bytes memory _b, 
        bytes memory _e, 
        bytes memory _m
    ) external view returns(bytes memory r) {
        assembly ("memory-safe") {
            
            let bl := mload(_b)
            let el := mload(_e)
            let ml := mload(_m)
            
            
            let freemem := mload(0x40) // Free memory pointer is always stored at 0x40
            
            
            mstore(freemem, bl)         // arg[0] = base.length @ +0
            
            mstore(add(freemem,32), el) // arg[1] = exp.length @ +32
            
            mstore(add(freemem,64), ml) // arg[2] = mod.length @ +64
            
            // arg[3] = base.bits @ + 96
            // Use identity built-in (contract 0x4) as a cheap memcpy
            let success := staticcall(450, 0x4, add(_b,32), bl, add(freemem,96), bl)
            
            // arg[4] = exp.bits @ +96+base.length
            let size := add(96, bl)
            success := staticcall(450, 0x4, add(_e,32), el, add(freemem,size), el)
            
            // arg[5] = mod.bits @ +96+base.length+exp.length
            size := add(size,el)
            success := staticcall(450, 0x4, add(_m,32), ml, add(freemem,size), ml)
            
            switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

            // Total size of input = 96+base.length+exp.length+mod.length
            size := add(size,ml)
            // Invoke contract 0x5, put return value right after mod.length, @ +96
            success := staticcall(sub(gas(), 1350), 0x5, freemem, size, add(freemem, 0x60), ml)

            switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

            let length := ml
            let msword_ptr := add(freemem, 0x60)

            ///the following code removes any leading words containing all zeroes in the result.
            for { } eq ( eq(length, 0x20), 0) { } {                   // for(; length!=32; length-=32)
                switch eq(mload(msword_ptr),0)                        // if(msword==0):
                    case 1 { msword_ptr := add(msword_ptr, 0x20) }    //     update length pointer
                    default { break }                                 // else: loop termination. non-zero word found
                length := sub(length,0x20)                          
            } 
            r := sub(msword_ptr,0x20)
            mstore(r, length)
            
            // point to the location of the return value (length, bits)
            //assuming mod length is multiple of 32, return value is already in the right format.
            mstore(0x40, add(add(96, freemem),ml)) //deallocate freemem pointer
        }        
    }

    /** @notice BigNumber modular exponentiation: a^e mod n.
      * @dev modexp: takes base, exponent, and modulus, internally computes base^exponent % modulus using the precompile at address 0x5, and creates new BigNumber.
      *              this function is overloaded: it assumes the exponent is positive. if not, the other method is used, whereby the inverse of the base is also passed.
      *
      * @param a base BigNumber
      * @param e exponent BigNumber
      * @param n modulus BigNumber
      * @return result BigNumber
      */    
    function modexp(
        BigNumber memory a, 
        BigNumber memory e, 
        BigNumber memory n
    ) internal view returns(BigNumber memory) {
        //if exponent is negative, other method with this same name should be used.
        //if modulus is negative or zero, we cannot perform the operation.
        if(isZero(n.val)) revert BigNumbers__ShouldNotBeZero();

        bytes memory _result = _modexp(a.val,e.val,n.val);
        //get bitlen of result (TODO: optimise. we know bitlen is in the same byte as the modulus bitlen byte)
        uint256 bitlen = bitLength(_result);
        
        // if result is 0, immediately return.
        if(bitlen == UINTZERO) return BigNumber(BYTESZERO, UINTZERO);
        // in any other case we return the positive result.
        return BigNumber(_result, bitlen);
    }
 
    /** @notice modular multiplication: (a*b) % n.
      * @dev modmul: Takes BigNumbers for a, b, and modulus, and computes (a*b) % modulus
      *              We call mul for the two input values, before calling modexp, passing exponent as 1.
      *              Sign is taken care of in sub-functions.
      *
      * @param a BigNumber
      * @param b BigNumber
      * @param n Modulus BigNumber
      * @return result BigNumber
      */
    function modmul(
        BigNumber memory a, 
        BigNumber memory b, 
        BigNumber memory n) internal view returns(BigNumber memory) {       
        return mod(mul(a,b), n);       
    }

    // ***************** END EXPOSED CORE CALCULATION FUNCTIONS ******************




    // ***************** START EXPOSED HELPER FUNCTIONS ******************
        /** @notice BigNumber subtraction: a - b.
      * @dev sub: Initially prepare BigNumbers for subtraction operation; internally calls actual addition/subtraction,
                  depending on inputs.
      *           In order to do correct addition or subtraction we have to handle the sign.
      *           This function discovers the sign of the result based on the inputs, and calls the correct operation.
      *
      * @param a first BN
      * @param b second BN
      * @return r result - subtraction of a and b.
      */  
    function sub(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(BigNumber memory r) {
        if(a.bitlen==UINTZERO && b.bitlen==UINTZERO) return BigNumber(BYTESZERO, UINTZERO);
        bytes memory val;
        int256 compare;
        uint256 bitlen;
        compare = cmp(a,b);

        if(compare == INTONE) {
            (val,bitlen) = _sub(a.val,b.val);
        }
        else if(compare == INTMINUSONE) { 
            (val,bitlen) = _sub(b.val,a.val);
            //r.neg = true;
        }
        else return BigNumber(BYTESZERO, UINTZERO); 
        r.val = val;
        r.bitlen = (bitlen);
    }

    /** @notice BigNumber multiplication: a * b.
      * @dev mul: takes two BigNumbers and multiplys them. Order is irrelevant.
      *              multiplication achieved using modexp precompile:
      *                 (a * b) = ((a + b)**2 - (a - b)**2) / 4
      *
      * @param a first BN
      * @param b second BN
      * @return r result - multiplication of a and b.
      */
    function mul(
        BigNumber memory a, 
        BigNumber memory b
    ) internal view returns(BigNumber memory r){
            
        BigNumber memory lhs = add(a,b);
        BigNumber memory fst = modexp(lhs, BigNumber(BYTESTWO, UINTTWO), _powModulus(lhs, UINTTWO)); // (a+b)^2
        
        // no need to do subtraction part of the equation if a == b; if so, it has no effect on final result.
        if(!eq(a,b)) {
            BigNumber memory rhs = sub(a,b);
            BigNumber memory snd = modexp(rhs, BigNumber(BYTESTWO, UINTTWO), _powModulus(rhs, UINTTWO)); // (a-b)^2
            r = _shr(sub(fst, snd) , UINTTWO); // (a * b) = (((a + b)**2 - (a - b)**2) / 4
        }
        else {
            r = _shr(fst, UINTTWO); // a==b ? (((a + b)**2 / 4
        }
    }
    
    /** @notice BigNumber comparison
      * @dev cmp: Compares BigNumbers a and b. 'signed' parameter indiciates whether to consider the sign of the inputs.
      *           'trigger' is used to decide this - 
      *              if both negative, invert the result; 
      *              if both positive (or signed==false), trigger has no effect;
      *              if differing signs, we return immediately based on input.
      *           returns -1 on a<b, 0 on a==b, 1 on a>b.
      *           
      * @param a BigNumber
      * @param b BigNumber
      * @return int256 result
      */
    function cmp(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(int256){
        int256 trigger = INTONE;

        if(a.bitlen>b.bitlen) return    trigger;   // 1*trigger
        if(b.bitlen>a.bitlen) return INTMINUSONE*trigger;

        uint256 a_ptr;
        uint256 b_ptr;
        uint256 a_word;
        uint256 b_word;

        uint256 len = a.val.length; //bitlen is same so no need to check length.

        assembly ("memory-safe") {
            a_ptr := add(mload(a),0x20) 
            b_ptr := add(mload(b),0x20)
        }

        for(uint256 i; i<len;i+=UINT32){
            assembly ("memory-safe") {
                a_word := mload(add(a_ptr,i))
                b_word := mload(add(b_ptr,i))
            }

            if(a_word>b_word) return    trigger; // 1*trigger
            if(b_word>a_word) return INTMINUSONE*trigger; 

        }

        return INTZERO; //same value.
    }

        /** @notice BigNumber addition: a + b.
      * @dev add: Initially prepare BigNumbers for addition operation; internally calls actual addition/subtraction,
      *           depending on inputs.
      *           In order to do correct addition or subtraction we have to handle the sign.
      *           This function discovers the sign of the result based on the inputs, and calls the correct operation.
      *
      * @param a first BN
      * @param b second BN
      * @return r result  - addition of a and b.
      */
    function add(
        BigNumber memory a, 
        BigNumber memory b
    ) internal pure returns(BigNumber memory r) {
        if(a.bitlen==UINTZERO && b.bitlen==UINTZERO) return BigNumber(BYTESZERO, UINTZERO);
        if(a.bitlen==UINTZERO) return b;
        if(b.bitlen==UINTZERO) return a;
        bytes memory val;
        uint256 bitlen;
        int256 compare = cmp(a,b);
        if(compare>=INTZERO){ // a>=b
            (val, bitlen) = _add(a.val,b.val,a.bitlen);
        }
        else {
            (val, bitlen) = _add(b.val,a.val,b.bitlen);
        }
        r.val = val;
        r.bitlen = (bitlen);
    }

    /** @notice right shift BigNumber memory 'dividend' by 'bits' bits.
      * @dev _shr: Shifts input value in-place, ie. does not create new memory. shr function does this.
      * right shift does not necessarily have to copy into a new memory location. where the user wishes the modify
      * the existing value they have in place, they can use this.  
      * @param bn value to shift
      * @param bits amount of bits to shift by
      * @return r result
      */
    function _shr(BigNumber memory bn, uint256 bits) private view returns(BigNumber memory){
        uint256 length;
        assembly ("memory-safe") { length := mload(mload(bn)) }

        // if bits is >= the bitlength of the value the result is always 0
        if(bits >= bn.bitlen) return BigNumber(BYTESZERO,UINTZERO); 
        
        // set bitlen initially as we will be potentially modifying 'bits'
        bn.bitlen = bn.bitlen-(bits);

        // handle shifts greater than 256:
        // if bits is greater than 256 we can simply remove any trailing words, by altering the BN length. 
        // we also update 'bits' so that it is now in the range 0..256.
        assembly ("memory-safe") {
            if or(gt(bits, 0x100), eq(bits, 0x100)) {
                length := sub(length, mul(div(bits, 0x100), 0x20))
                mstore(mload(bn), length)
                bits := mod(bits, 0x100)
            }

            // if bits is multiple of 8 (byte size), we can simply use identity precompile for cheap memcopy.
            // otherwise we shift each word, starting at the least signifcant word, one-by-one using the mask technique.
            // TODO it is possible to do this without the last two operations, see SHL identity copy.
            let bn_val_ptr := mload(bn)
            switch eq(mod(bits, 8), 0)
              case 1 {  
                  let bytes_shift := div(bits, 8)
                  let in          := mload(bn)
                  let inlength    := mload(in)
                  let insize      := add(inlength, 0x20)
                  let out         := add(in,     bytes_shift)
                  let outsize     := sub(insize, bytes_shift)
                  let success     := staticcall(450, 0x4, in, insize, out, insize)
                  mstore8(add(out, 0x1f), 0) // maintain our BN layout following identity call:
                  mstore(in, inlength)         // set current length byte to 0, and reset old length.
              }
              default {
                  let mask
                  let lsw
                  let mask_shift := sub(0x100, bits)
                  let lsw_ptr := add(bn_val_ptr, length)   
                  for { let i := length } eq(eq(i,0),0) { i := sub(i, 0x20) } { // for(int256 i=max_length; i!=0; i-=32)
                      switch eq(i,0x20)                                         // if i==32:
                          case 1 { mask := 0 }                                  //    - handles lsword: no mask needed.
                          default { mask := mload(sub(lsw_ptr,0x20)) }          //    - else get mask (previous word)
                      lsw := shr(bits, mload(lsw_ptr))                          // right shift current by bits
                      mask := shl(mask_shift, mask)                             // left shift next significant word by mask_shift
                      mstore(lsw_ptr, or(lsw,mask))                             // store OR'd mask and shifted bits in-place
                      lsw_ptr := sub(lsw_ptr, 0x20)                             // point to next bits.
                  }
              }

            // The following removes the leading word containing all zeroes in the result should it exist, 
            // as well as updating lengths and pointers as necessary.
            let msw_ptr := add(bn_val_ptr,0x20)
            switch eq(mload(msw_ptr), 0) 
                case 1 {
                   mstore(msw_ptr, sub(mload(bn_val_ptr), 0x20)) // store new length in new position
                   mstore(bn, msw_ptr)                           // update pointer from bn
                }
                default {}
        }
    

        return bn;
    }


    /** @notice bytes zero check
      * @dev isZero: checks if input bytes value resolves to zero.
      *             
      * @param a bytes value
      * @return boolean result.
      */
    function isZero(
        bytes memory a
    ) private pure returns(bool) {
        uint256 msword;
        uint256 msword_ptr;
        assembly ("memory-safe") {
            msword_ptr := add(a,0x20)
        }
        for(uint256 i; i<a.length; i+=UINT32) {
            assembly ("memory-safe") { msword := mload(msword_ptr) } // get msword of input
            if(msword > 0) return false;
            assembly ("memory-safe") { msword_ptr := add(msword_ptr, 0x20) }
        }
        return true;

    }

    /** @notice bytes bit length
      * @dev bitLength: returns bytes bit length- ie. log2 (most significant bit of value)
      *             
      * @param a bytes value
      * @return r uint256 bit length result.
      */
    function bitLength(
        bytes memory a
    ) private pure returns(uint256 r){
        if(isZero(a)) return UINTZERO;
        uint256 msword; 
        assembly ("memory-safe") {
            msword := mload(add(a,0x20))               // get msword of input
        }
        r = bitLength(msword);                         // get bitlen of msword, add to size of remaining words.
        assembly ("memory-safe") {                                           
            r := add(r, mul(sub(mload(a), 0x20) , 8))  // res += (val.length-32)*8;  
        }
    }

    /** @notice uint256 bit length
        @dev bitLength: get the bit length of a uint256 input - ie. log2 (most significant bit of 256 bit value (one EVM word))
      *                       credit: Tjaden Hess @ ethereum.stackexchange             
      * @param a uint256 value
      * @return r uint256 bit length result.
      */
    function bitLength(
        uint256 a
    ) private pure returns (uint256 r){
        assembly ("memory-safe") {
            switch eq(a, 0)
            case 1 {
                r := 0
            }
            default {
                let arg := a
                a := sub(a,1)
                a := or(a, div(a, 0x02))
                a := or(a, div(a, 0x04))
                a := or(a, div(a, 0x10))
                a := or(a, div(a, 0x100))
                a := or(a, div(a, 0x10000))
                a := or(a, div(a, 0x100000000))
                a := or(a, div(a, 0x10000000000000000))
                a := or(a, div(a, 0x100000000000000000000000000000000))
                a := add(a, 1)
                let m := mload(0x40)
                mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
                mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
                mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
                mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
                mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
                mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
                mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
                mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
                mstore(0x40, add(m, 0x100))
                let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
                let shift := 0x100000000000000000000000000000000000000000000000000000000000000
                let _a := div(mul(a, magic), shift)
                r := div(mload(add(m,sub(255,_a))), shift)
                r := add(r, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
                // where a is a power of two, result needs to be incremented. we use the power of two trick here: if(arg & arg-1 == 0) ++r;
                if eq(and(arg, sub(arg, 1)), 0) {
                    r := add(r, 1) 
                }
            }
        }
    }
    // ***************** END EXPOSED HELPER FUNCTIONS ******************





    // ***************** START PRIVATE MANAGEMENT FUNCTIONS ******************
    /** @notice Create a new BigNumber.
        @dev init: overloading allows caller to obtionally pass bitlen where it is known - as it is cheaper to do off-chain and verify on-chain. 
      *            we assert input is in data structure as defined above, and that bitlen, if passed, is correct.
      *            'copy' parameter indicates whether or not to copy the contents of val to a new location in memory (for example where you pass 
      *            the contents of another variable's value in)
      * @param val bytes - bignum value.
      * @param bitlen uint256 - bit length of value
      * @return r BigNumber initialized value.
      */
    function _init(
        bytes memory val, 
        uint256 bitlen
    ) private view returns(BigNumber memory r){ 
        // use identity at location 0x4 for cheap memcpy.
        // grab contents of val, load starting from memory end, update memory end pointer.
        assembly ("memory-safe") {
            let data := add(val, 0x20)
            let length := mload(val)
            let out
            //let freemem := msize()
            let freemem := mload(0x40) // Free memory pointer is always stored at 0x40
            switch eq(mod(length, 0x20), 0)                       // if(val.length % 32 == 0)
                case 1 {
                    out     := add(freemem, 0x20)                 // freememory location + length word
                    mstore(freemem, length)                       // set new length 
                }
                default { 
                    let offset  := sub(0x20, mod(length, 0x20))   // offset: 32 - (length % 32)
                    out     := add(add(freemem, offset), 0x20)    // freememory location + offset + length word
                    mstore(freemem, add(length, offset))          // set new length 
                }
            pop(staticcall(450, 0x4, data, length, out, length))  // copy into 'out' memory location
            mstore(0x40, add(freemem, add(mload(freemem), 0x20))) // update the free memory pointer
            
            // handle leading zero words. assume freemem is pointer to bytes value
            let bn_length := mload(freemem)
            for { } eq ( eq(bn_length, 0x20), 0) { } {            // for(; length!=32; length-=32)
             switch eq(mload(add(freemem, 0x20)),0)               // if(msword==0):
                    case 1 { freemem := add(freemem, 0x20) }      //     update length pointer
                    default { break }                             // else: loop termination. non-zero word found
                bn_length := sub(bn_length,0x20)                          
            } 
            mstore(freemem, bn_length)                             

            mstore(r, freemem)                                    // store new bytes value in r
        }

        r.bitlen = bitlen == UINTZERO ? bitLength(r.val) : bitlen;
    }
    // ***************** END PRIVATE MANAGEMENT FUNCTIONS ******************





    // ***************** START PRIVATE CORE CALCULATION FUNCTIONS ******************
    /** @notice takes two BigNumber memory values and the bitlen of the max value, and adds them.
      * @dev _add: This function is private and only callable from add: therefore the values may be of different sizes,
      *            in any order of size, and of different signs (handled in add).
      *            As values may be of different sizes, inputs are considered starting from the least significant 
      *            words, working back. 
      *            The function calculates the new bitlen (basically if bitlens are the same for max and min, 
      *            max_bitlen++) and returns a new BigNumber memory value.
      *
      * @param max bytes -  biggest value  (determined from add)
      * @param min bytes -  smallest value (determined from add)
      * @param max_bitlen uint256 - bit length of max value.
      * @return bytes result - max + min.
      * @return uint256 - bit length of result.
      */
    function _add(
        bytes memory max, 
        bytes memory min, 
        uint256 max_bitlen
    ) private pure returns (bytes memory, uint256) {
        bytes memory result;
        assembly ("memory-safe") {

            //let result_start := msize()                                       // Get the highest available block of memory
            let result_start := mload(0x40)                                   // Get the highest available block of memory
            let carry := 0
            let uint_max := sub(0,1)

            let max_ptr := add(max, mload(max))
            let min_ptr := add(min, mload(min))                               // point to last word of each byte array.

            let result_ptr := add(add(result_start,0x20), mload(max))         // set result_ptr end.

            for { let i := mload(max) } eq(eq(i,0),0) { i := sub(i, 0x20) } { // for(int256 i=max_length; i!=0; i-=32)
                let max_val := mload(max_ptr)                                 // get next word for 'max'
                switch gt(i,sub(mload(max),mload(min)))                       // if(i>(max_length-min_length)). while 
                                                                              // 'min' words are still available.
                    case 1{ 
                        let min_val := mload(min_ptr)                         //      get next word for 'min'
                        mstore(result_ptr, add(add(max_val,min_val),carry))   //      result_word = max_word+min_word+carry
                        switch gt(max_val, sub(uint_max,sub(min_val,carry)))  //      this switch block finds whether or
                                                                              //      not to set the carry bit for the
                                                                              //      next iteration.
                            case 1  { carry := 1 }
                            default {
                                switch and(eq(max_val,uint_max),or(gt(carry,0), gt(min_val,0)))
                                case 1 { carry := 1 }
                                default{ carry := 0 }
                            }
                            
                        min_ptr := sub(min_ptr,0x20)                       //       point to next 'min' word
                    }
                    default{                                               // else: remainder after 'min' words are complete.
                        mstore(result_ptr, add(max_val,carry))             //       result_word = max_word+carry
                        
                        switch and( eq(uint_max,max_val), eq(carry,1) )    //       this switch block finds whether or 
                                                                           //       not to set the carry bit for the 
                                                                           //       next iteration.
                            case 1  { carry := 1 }
                            default { carry := 0 }
                    }
                result_ptr := sub(result_ptr,0x20)                         // point to next 'result' word
                max_ptr := sub(max_ptr,0x20)                               // point to next 'max' word
            }

            switch eq(carry,0) 
                case 1{ result_start := add(result_start,0x20) }           // if carry is 0, increment result_start, ie.
                                                                           // length word for result is now one word 
                                                                           // position ahead.
                default { mstore(result_ptr, 1) }                          // else if carry is 1, store 1; overflow has
                                                                           // occured, so length word remains in the 
                                                                           // same position.

            result := result_start                                         // point 'result' bytes value to the correct
                                                                           // address in memory.
            mstore(result,add(mload(max),mul(0x20,carry)))                 // store length of result. we are finished 
                                                                           // with the byte array.
            
            mstore(0x40, add(result,add(mload(result),0x20)))              // Update freemem pointer to point to new 
                                                                           // end of memory.

            // we now calculate the result's bit length.
            // with addition, if we assume that some a is at least equal to some b, then the resulting bit length will
            // be a's bit length or (a's bit length)+1, depending on carry bit.this is cheaper than calling bitLength.
            let msword := mload(add(result,0x20))                             // get most significant word of result
            // if(msword==1 || msword>>(max_bitlen % 256)==1):
            if or( eq(msword, 1), eq(shr(mod(max_bitlen,256),msword),1) ) {
                    max_bitlen := add(max_bitlen, 1)                          // if msword's bit length is 1 greater 
                                                                              // than max_bitlen, OR overflow occured,
                                                                              // new bitlen is max_bitlen+1.
                }
        }
        

        return (result, max_bitlen);
    }

    /** @notice takes two BigNumber memory values and subtracts them.
      * @dev _sub: This function is private and only callable from add: therefore the values may be of different sizes, 
      *            in any order of size, and of different signs (handled in add).
      *            As values may be of different sizes, inputs are considered starting from the least significant words,
      *            working back. 
      *            The function calculates the new bitlen (basically if bitlens are the same for max and min, 
      *            max_bitlen++) and returns a new BigNumber memory value.
      *
      * @param max bytes -  biggest value  (determined from add)
      * @param min bytes -  smallest value (determined from add)
      * @return bytes result - max + min.
      * @return uint256 - bit length of result.
      */
    function _sub(
        bytes memory max, 
        bytes memory min
    ) private pure returns (bytes memory, uint256) {
        bytes memory result;
        uint256 carry = UINTZERO;
        uint256 uint_max = type(uint256).max;
        assembly ("memory-safe") {
                
            //let result_start := msize()                                     // Get the highest available block of 
                                                                            // memory
            let result_start := mload(0x40)                                   // Get the highest available block of memory
        
            let max_len := mload(max)
            let min_len := mload(min)                                       // load lengths of inputs
            
            let len_diff := sub(max_len,min_len)                            // get differences in lengths.
            
            let max_ptr := add(max, max_len)
            let min_ptr := add(min, min_len)                                // go to end of arrays
            let result_ptr := add(result_start, max_len)                    // point to least significant result 
                                                                            // word.
            let memory_end := add(result_ptr,0x20)                          // save memory_end to update free memory
                                                                            // pointer at the end.
            
            for { let i := max_len } eq(eq(i,0),0) { i := sub(i, 0x20) } {  // for(int256 i=max_length; i!=0; i-=32)
                let max_val := mload(max_ptr)                               // get next word for 'max'
                switch gt(i,len_diff)                                       // if(i>(max_length-min_length)). while
                                                                            // 'min' words are still available.
                    case 1{ 
                        let min_val := mload(min_ptr)                       //  get next word for 'min'
        
                        mstore(result_ptr, sub(sub(max_val,min_val),carry)) //  result_word = (max_word-min_word)-carry
                    
                        switch or(lt(max_val, add(min_val,carry)), 
                               and(eq(min_val,uint_max), eq(carry,1)))      //  this switch block finds whether or 
                                                                            //  not to set the carry bit for the next iteration.
                            case 1  { carry := 1 }
                            default { carry := 0 }
                            
                        min_ptr := sub(min_ptr,0x20)                        //  point to next 'result' word
                    }
                    default {                                               // else: remainder after 'min' words are complete.

                        mstore(result_ptr, sub(max_val,carry))              //      result_word = max_word-carry
                    
                        switch and( eq(max_val,0), eq(carry,1) )            //      this switch block finds whether or 
                                                                            //      not to set the carry bit for the 
                                                                            //      next iteration.
                            case 1  { carry := 1 }
                            default { carry := 0 }

                    }
                result_ptr := sub(result_ptr,0x20)                          // point to next 'result' word
                max_ptr    := sub(max_ptr,0x20)                             // point to next 'max' word
            }      

            //the following code removes any leading words containing all zeroes in the result.
            result_ptr := add(result_ptr,0x20)                                                 

            // for(result_ptr+=32;; result==0; result_ptr+=32)
            for { }   eq(mload(result_ptr), 0) { result_ptr := add(result_ptr,0x20) } { 
               result_start := add(result_start, 0x20)                      // push up the start pointer for the result
               max_len := sub(max_len,0x20)                                 // subtract a word (32 bytes) from the 
                                                                            // result length.
            } 

            result := result_start                                          // point 'result' bytes value to 
                                                                            // the correct address in memory
            
            mstore(result,max_len)                                          // store length of result. we 
                                                                            // are finished with the byte array.
            
            mstore(0x40, memory_end)                                        // Update freemem pointer.
        }

        uint256 new_bitlen = bitLength(result);                                // calculate the result's 
                                                                            // bit length.
        
        return (result, new_bitlen);
    }

    /** @notice gets the modulus value necessary for calculating exponetiation.
      * @dev _powModulus: we must pass the minimum modulus value which would return JUST the a^b part of the calculation
      *       in modexp. the rationale here is:
      *       if 'a' has n bits, then a^e has at most n*e bits.
      *       using this modulus in exponetiation will result in simply a^e.
      *       therefore the value may be many words long.
      *       This is done by:
      *         - storing total modulus byte length
      *         - storing first word of modulus with correct bit set
      *         - updating the free memory pointer to come after total length.
      *
      * @param a BigNumber base
      * @param e uint256 exponent
      * @return BigNumber modulus result
      */
    function _powModulus(
        BigNumber memory a, 
        uint256 e
    ) private pure returns(BigNumber memory){
        bytes memory _modulus = BYTESZERO;
        uint256 mod_index;
        assembly ("memory-safe") {
            mod_index := mul(mload(add(a, 0x20)), e)               // a.bitlen * e is the max bitlength of result
            let first_word_modulus := shl(mod(mod_index, 256), 1)  // set bit in first modulus word.
            mstore(_modulus, mul(add(div(mod_index,256),1),0x20))  // store length of modulus
            mstore(add(_modulus,0x20), first_word_modulus)         // set first modulus word
            mstore(0x40, add(_modulus, add(mload(_modulus),0x20))) // update freemem pointer to be modulus index
                                                                   // + length
        }

        //create modulus BigNumber memory for modexp function
        return BigNumber(_modulus, mod_index); 
    }

    /** @notice Modular Exponentiation: Takes bytes values for base, exp, mod and calls precompile for (base^exp)%^mod
      * @dev modexp: Wrapper for built-in modexp (contract 0x5) as described here: 
      *              https://github.com/ethereum/EIPs/pull/198
      *
      * @param _b bytes base
      * @param _e bytes base_inverse 
      * @param _m bytes exponent
      * @param r bytes result.
      */
    function _modexp(
        bytes memory _b, 
        bytes memory _e, 
        bytes memory _m
    ) private view returns(bytes memory r) {
        assembly ("memory-safe") {
            
            let bl := mload(_b)
            let el := mload(_e)
            let ml := mload(_m)
            
            
            let freemem := mload(0x40) // Free memory pointer is always stored at 0x40
            
            
            mstore(freemem, bl)         // arg[0] = base.length @ +0
            
            mstore(add(freemem,32), el) // arg[1] = exp.length @ +32
            
            mstore(add(freemem,64), ml) // arg[2] = mod.length @ +64
            
            // arg[3] = base.bits @ + 96
            // Use identity built-in (contract 0x4) as a cheap memcpy
            let success := staticcall(450, 0x4, add(_b,32), bl, add(freemem,96), bl)
            
            // arg[4] = exp.bits @ +96+base.length
            let size := add(96, bl)
            success := staticcall(450, 0x4, add(_e,32), el, add(freemem,size), el)
            
            // arg[5] = mod.bits @ +96+base.length+exp.length
            size := add(size,el)
            success := staticcall(450, 0x4, add(_m,32), ml, add(freemem,size), ml)
            
            switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

            // Total size of input = 96+base.length+exp.length+mod.length
            size := add(size,ml)
            // Invoke contract 0x5, put return value right after mod.length, @ +96
            success := staticcall(sub(gas(), 1350), 0x5, freemem, size, add(freemem, 0x60), ml)

            switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

            let length := ml
            let msword_ptr := add(freemem, 0x60)

            ///the following code removes any leading words containing all zeroes in the result.
            for { } eq ( eq(length, 0x20), 0) { } {                   // for(; length!=32; length-=32)
                switch eq(mload(msword_ptr),0)                        // if(msword==0):
                    case 1 { msword_ptr := add(msword_ptr, 0x20) }    //     update length pointer
                    default { break }                                 // else: loop termination. non-zero word found
                length := sub(length,0x20)                          
            } 
            r := sub(msword_ptr,0x20)
            mstore(r, length)
            
            // point to the location of the return value (length, bits)
            //assuming mod length is multiple of 32, return value is already in the right format.
            mstore(0x40, add(add(96, freemem),ml)) //deallocate freemem pointer
        }        
    }
}
