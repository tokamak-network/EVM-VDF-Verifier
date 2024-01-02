// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "./BigNumbers.sol";

library Pietrzak_VDF {
    using BigNumbers for *;
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";

    struct VDFClaim {
        uint256 T;
        BigNumber x;
        BigNumber y;
        BigNumber v;
    }

    struct SingHalvProofOutput {
        bool verified;
        bool calculated;
        BigNumber x_prime;
        BigNumber y_prime;
    }

    function modHash(
        BigNumber memory _n,
        bytes memory _strings
    ) internal view returns (BigNumber memory) {
        //return uint256(keccak256(abi.encodePacked(strings))) % n;
        //return powerModN(abi.encodePacked(keccak256(_strings)), _one, n);

        return abi.encodePacked(keccak256(_strings)).init().mod(_n);
    }

    function processSingleHalvingProof(
        VDFClaim calldata vdfClaim,
        BigNumber memory _n
    ) internal view returns (SingHalvProofOutput memory) {
        BigNumber memory _zero = BigNumbers.zero();
        BigNumber memory _two = BigNumbers.two();
        if (vdfClaim.T == 1) {
            if (vdfClaim.y.eq(vdfClaim.x.modexp(_two, _n))) {
                return SingHalvProofOutput(true, false, _zero, _zero);
            } else {
                return SingHalvProofOutput(false, false, _zero, _zero);
            }
        }
        BigNumber memory y = vdfClaim.y;
        BigNumber memory r = modHash(vdfClaim.x, bytes.concat(vdfClaim.y.val, vdfClaim.v.val)).mod(
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
        VDFClaim[] calldata proofList,
        BigNumber memory _n
    ) internal view returns (bool) {
        uint256 proofSize = proofList.length;
        for (uint256 i = 0; i < proofSize; i++) {
            SingHalvProofOutput memory output = processSingleHalvingProof(proofList[i], _n);
            if (!output.verified) {
                return false;
            } else {
                if (!output.calculated) {
                    return true;
                } else if (!output.x_prime.eq(proofList[i + 1].x)) {
                    return false;
                } else if (!output.y_prime.eq(proofList[i + 1].y)) {
                    return false;
                }
            }
        }
        return true;
    }
}
