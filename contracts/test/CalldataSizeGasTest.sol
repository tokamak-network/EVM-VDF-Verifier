// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract Calldata {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

    function verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory expDelta,
        uint256 T
    ) external {}
}

contract Calldata2 {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

    function verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external {}
}

contract A {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

    // Function Dispatching 2^22, 2048 bit delta 9일때, 11000
    // 700

    // *** Intrinsic Gas = 21000 + calldataGasCost

    // *** execution cost = ( Function Dispatching(= function selection + parameter memory loading) + 반복문 + 비교문)

    // *** 3072 데이터 보충

    function verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory twoPowerOfDeltaBytes,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {
        //반복문
        //비교문
    }
}

contract AA {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

    // 550
    function verifyRecursiveHalvingProof(
        BigNumber[] calldata v,
        BigNumber calldata x,
        BigNumber calldata y,
        BigNumber calldata n,
        bytes calldata bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {
        assembly {
            calldatacopy(0, 0, calldatasize())
        }
    }
}

// contract AAA {
//     struct BigNumber {
//         bytes val;
//         uint256 bitlen;
//     }

//     function verifyRecursiveHalvingProof(
//         BigNumber[] memory v,
//         BigNumber memory x,
//         BigNumber memory y,
//         BigNumber memory n,
//         bytes memory bigNumTwoPowerOfDelta,
//         uint256 twoPowerOfDelta,
//         uint256 T
//     ) external pure returns (uint256 m) {
//         assembly {
//             m := msize()
//         }
//     }
// }

contract B {
    function verifyRecursiveHalvingProof() external {}
}

contract C {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

    function verifyRecursiveHalvingProof(BigNumber memory v) external {}
}

contract D {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

    function verifyRecursiveHalvingProof(BigNumber calldata v) external {}
}

contract E {
    function verifyRecursiveHalvingProof(bytes memory v) external {}
}

contract F {
    function verifyRecursiveHalvingProof(bytes calldata v) external {}
}
