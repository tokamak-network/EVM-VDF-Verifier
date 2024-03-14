// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "./PietrzakVDF.sol";

//verifyRecursiveHalvingProofAppliedDelta
//verifyRecursiveHalvingProofNotAppliedDelta
contract MinimalApplication is PietrzakVDF {
    constructor(uint256 proofLastIndex) PietrzakVDF(proofLastIndex) {}

    function verifyRecursiveHalvingProofExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta,
        uint256 T
    ) external view returns (bool) {
        return verifyRecursiveHalvingProof(v, x, y, n, bigNumTwoPowerOfDelta, delta, T);
    }

    function verifyRecursiveHalvingProofSkippingTXYExternal(
        VDFClaimNV[] memory proofList,
        BigNumber memory x,
        BigNumber memory y,
        uint256 T
    ) external view returns (bool) {
        return verifyRecursiveHalvingProofSkippingTXY(proofList, x, y, T);
    }

    function verifyRecursiveHalvingProofNTXYVInProofExternal(
        VDFClaimTXYVN[] memory proofList
    ) external view returns (bool) {
        return verifyRecursiveHalvingProofNTXYVInProof(proofList);
    }

    function verifyRecursiveHalvingProofSkippingNExternal(
        BigNumber memory n,
        VDFClaimTXYV[] memory proofList
    ) external view returns (bool) {
        return verifyRecursiveHalvingProofSkippingN(n, proofList);
    }

    function verifyRecursiveHalvingProofNTXYVDeltaAppliedExternal(
        VDFClaimTXYVN[] memory proofList,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta
    ) external view returns (bool) {
        return
            verifyRecursiveHalvingProofNTXYVDeltaApplied(proofList, bigNumTwoPowerOfDelta, delta);
    }

    function verifyRecursiveHalvingProofNTXYVDeltaRepeatedExternal(
        VDFClaimTXYVN[] memory proofList,
        uint256 delta
    ) external view returns (bool) {
        return verifyRecursiveHalvingProofNTXYVDeltaRepeated(proofList, delta);
    }

    function verifyRecursiveHalvingProofWithoutDeltaExternal(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 T
    ) external view returns (bool) {
        return verifyRecursiveHalvingProofWithoutDelta(v, x, y, n, T);
    }
}
