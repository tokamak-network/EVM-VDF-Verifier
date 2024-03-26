// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "./PietrzakVDF.sol";

//verifyRecursiveHalvingProofAppliedDelta
//verifyRecursiveHalvingProofNotAppliedDelta
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
