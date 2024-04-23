// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract A {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

    function verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory twoPowerOfDeltaBytes,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}
}

contract AA {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

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
