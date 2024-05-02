// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "./PietrzakVDF.sol";

//verifyRecursiveHalvingProofAppliedDelta
//verifyRecursiveHalvingProofNotApp liedDelta

contract VerifyRecursiveHalvingProofAlgorithm {
    // function verifyRecursiveHalvingProof(
    //     BigNumber[] memory v,
    //     BigNumber memory x,
    //     BigNumber memory y,
    //     BigNumber memory n,
    //     uint256 delta,
    //     uint256 T
    // ) external view returns (bool) {
    //     return PietrzakVDF.verifyRecursiveHalvingProofAlgorithm(v, x, y, n, delta, T);
    // }
}

contract VerifyRecursiveHalvingProofAlgorithm2 {
    function verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external view returns (bool) {
        return PietrzakVDF1.verifyRecursiveHalvingProofAlgorithm2(v, x, y, n, delta, T);
    }
}

contract VerifyRecursiveHalvingProofAlgorithm2Halving {
    function verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external returns (bool) {
        return PietrzakVDF1Halving.verifyRecursiveHalvingProofAlgorithm2(v, x, y, n, delta, T);
    }
}

contract VerifyRecursiveHalvingProofAlgorithm2ModExp {
    function verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external returns (bool) {
        return PietrzakVDF1ModExp.verifyRecursiveHalvingProofAlgorithm2(v, x, y, n, delta, T);
    }
}

contract VerifyRecursiveHalvingProofDeltaBigNumber {
    function verifyRecursiveHalvingProofExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory expDelta,
        uint256 T
    ) external view returns (bool) {
        return PietrzakVDF.verifyRecursiveHalvingProofDeltaBigNumber(v, x, y, n, expDelta, T);
    }
}

contract VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent {
    function verifyRecursiveHalvingProofDeltaBigNumberHalvingExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory expDelta,
        uint256 T
    ) external returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProofDeltaBigNumberHalving(v, x, y, n, expDelta, T);
    }
}

contract VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent {
    function verifyRecursiveHalvingProofDeltaBigNumberModExpCompareExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory expDelta,
        uint256 T
    ) external returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProofDeltaBigNumberModExpCompare(
                v,
                x,
                y,
                n,
                expDelta,
                T
            );
    }
}

contract VerifyRecursiveHalvingProofExternalContract {
    function verifyRecursiveHalvingProofExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external view returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProof(
                v,
                x,
                y,
                n,
                bigNumTwoPowerOfDelta,
                twoPowerOfDelta,
                T
            );
    }
}

contract VerifyRecursiveHalvingProofExternalGasConsoleHalvingContract {
    function verifyRecursiveHalvingProofExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProofGasConsoleHalving(
                v,
                x,
                y,
                n,
                bigNumTwoPowerOfDelta,
                twoPowerOfDelta,
                T
            );
    }
}

contract VerifyRecursiveHalvingProofExternalGasConsoleMoDExpContract {
    function verifyRecursiveHalvingProofExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProofGasConsoleModExp(
                v,
                x,
                y,
                n,
                bigNumTwoPowerOfDelta,
                twoPowerOfDelta,
                T
            );
    }
}

contract MinimalApplication {
    function verifyRecursiveHalvingProofExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external view returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProof(
                v,
                x,
                y,
                n,
                bigNumTwoPowerOfDelta,
                twoPowerOfDelta,
                T
            );
    }

    function verifyRecursiveHalvingProofExternal3(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external view returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProof(
                v,
                x,
                y,
                n,
                bigNumTwoPowerOfDelta,
                twoPowerOfDelta,
                T
            );
    }

    function verifyRecursiveHalvingProofExternalGasConsoleHalving1(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProofGasConsoleHalving(
                v,
                x,
                y,
                n,
                bigNumTwoPowerOfDelta,
                twoPowerOfDelta,
                T
            );
    }

    function verifyRecursiveHalvingProofExternalGasConsoleModExp(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProofGasConsoleModExp(
                v,
                x,
                y,
                n,
                bigNumTwoPowerOfDelta,
                twoPowerOfDelta,
                T
            );
    }

    function verifyRecursiveHalvingProofSkippingTXYExternal(
        PietrzakVDF.VDFClaimNV[] memory proofList,
        BigNumber memory x,
        BigNumber memory y,
        uint256 T
    ) external view returns (bool) {
        return PietrzakVDF.verifyRecursiveHalvingProofSkippingTXY(proofList, x, y, T);
    }

    function verifyRecursiveHalvingProofNTXYVInProofExternal(
        PietrzakVDF.VDFClaimTXYVN[] memory proofList
    ) external view returns (bool) {
        return PietrzakVDF.verifyRecursiveHalvingProofNTXYVInProof(proofList);
    }

    function verifyRecursiveHalvingProofSkippingNExternal(
        BigNumber memory n,
        PietrzakVDF.VDFClaimTXYV[] memory proofList
    ) external view returns (bool) {
        return PietrzakVDF.verifyRecursiveHalvingProofSkippingN(n, proofList);
    }

    function verifyRecursiveHalvingProofNTXYVDeltaAppliedExternal(
        PietrzakVDF.VDFClaimTXYVN[] memory proofList,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta
    ) external view returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProofNTXYVDeltaApplied(
                proofList,
                bigNumTwoPowerOfDelta,
                twoPowerOfDelta
            );
    }

    function verifyRecursiveHalvingProofNTXYVDeltaRepeatedExternal(
        PietrzakVDF.VDFClaimTXYVN[] memory proofList,
        uint256 twoPowerOfDelta
    ) external view returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProofNTXYVDeltaRepeated(proofList, twoPowerOfDelta);
    }

    function verifyRecursiveHalvingProofWithoutDeltaExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 T
    ) external view returns (bool) {
        return PietrzakVDF.verifyRecursiveHalvingProofWithoutDelta(v, x, y, n, T);
    }

    function verifyRecursiveHalvingProofCorrectExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external view returns (bool) {
        return
            PietrzakVDF.verifyRecursiveHalvingProofCorrect(
                v,
                x,
                y,
                n,
                bigNumTwoPowerOfDelta,
                twoPowerOfDelta,
                T
            );
    }
}

contract ManyMany {
    function a(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}

    function b(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}

    function c(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}

    function d(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}

    function e(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}

    function f(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}

    function g(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}

    function h(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}

    function i(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 T
    ) external {}
}
