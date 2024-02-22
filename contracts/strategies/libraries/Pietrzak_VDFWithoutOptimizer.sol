// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "./BigNumbersWithoutOptimizer.sol";
import "../interfaces/ICRRWithNTInProofVerifyAndProcessSeparateFileSeparateWithoutOptimizer.sol";

library Pietrzak_VDF {
    using BigNumbersWithoutOptimizer for *;
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";
    error XPrimeNotEqualAtIndex(uint256 index);
    error YPrimeNotEqualAtIndex(uint256 index);

    error NotVerified();
    error NotCalculated();

    function modHash(
        bytes memory _strings,
        BigNumber memory _n
    ) internal view returns (BigNumber memory) {
        return abi.encodePacked(keccak256(_strings)).init().mod(_n);
    }

    struct SingHalvProofOutput {
        bool verified;
        bool calculated;
        BigNumber x_prime;
        BigNumber y_prime;
    }

    function processSingleHalvingProof(
        ICRRWithNTInProofVerifyAndProcessSeparateFileSeparateWithoutOptimizer.VDFClaim
            calldata vdfClaim,
        BigNumber memory _n
    ) internal view returns (SingHalvProofOutput memory) {
        BigNumber memory _zero = BigNumber(
            BigNumbersWithoutOptimizer.BYTESZERO,
            BigNumbersWithoutOptimizer.UINTZERO
        );
        BigNumber memory _two = BigNumber(
            BigNumbersWithoutOptimizer.BYTESTWO,
            BigNumbersWithoutOptimizer.UINTTWO
        );
        if (vdfClaim.T == 1) {
            if (vdfClaim.y.eq(vdfClaim.x.modexp(_two, _n))) {
                return SingHalvProofOutput(true, false, _zero, _zero);
            } else {
                return SingHalvProofOutput(false, false, _zero, _zero);
            }
        }
        BigNumber memory y = vdfClaim.y;
        BigNumber memory r = modHash(bytes.concat(vdfClaim.y.val, vdfClaim.v.val), vdfClaim.x).mod(
            BigNumber(MODFORHASH, 129)
        );
        if (vdfClaim.T & 1 == 1) y = y.modexp(_two, _n);
        return
            SingHalvProofOutput(
                true,
                true,
                vdfClaim.x.modexp(r, _n).modmul(vdfClaim.v, _n),
                vdfClaim.v.modexp(r, _n).modmul(y, _n)
            );
    }

    function verifyRecursiveHalvingProof(
        ICRRWithNTInProofVerifyAndProcessSeparateFileSeparateWithoutOptimizer.VDFClaim[]
            calldata _proofList,
        BigNumber memory _n,
        uint256 _proofsSize
    ) internal view {
        uint256 i;
        for (; i < _proofsSize; i++) {
            SingHalvProofOutput memory output = processSingleHalvingProof(_proofList[i], _n);
            if (!output.verified) {
                revert NotVerified();
            } else {
                if (!output.calculated) {
                    return;
                } else if (!output.x_prime.eq(_proofList[i + 1].x)) {
                    revert XPrimeNotEqualAtIndex(i);
                } else if (!output.y_prime.eq(_proofList[i + 1].y)) {
                    revert YPrimeNotEqualAtIndex(i);
                }
            }
        }
        if (i != _proofsSize || _proofList[i - 1].T != 1) revert YPrimeNotEqualAtIndex(i);
    }
}
