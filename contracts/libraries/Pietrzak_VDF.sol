// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./BigNumbers.sol";
import "hardhat/console.sol";

library Pietrzak_VDF {
    using BigNumbers for *;
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    bytes private constant MODFORHASH = hex"0000000000000000000000000000000100000000000000000000000000000000";

    struct VDFClaim {
        uint256 T;
        BigNumber n;
        BigNumber x;
        BigNumber y;
        BigNumber v;
    }

    struct SingHalvProofOutput {
        bool verified;
        bool calculated;
        BigNumber x_prime;
        BigNumber y_prime;
        uint256 T_half;
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
        VDFClaim calldata vdfClaim
    ) internal view returns (SingHalvProofOutput memory) {
        BigNumber memory _zero = BigNumbers.zero();
        BigNumber memory _two = BigNumbers.two();
        if (vdfClaim.T == 1) {
            //if (vdfClaim.y == powerModN(vdfClaim.x, 2, vdfClaim.n)) {
            //if (equal(vdfClaim.y, powerModN(vdfClaim.x, vdfClaim.v, vdfClaim.n))) {
            if (vdfClaim.y.eq(vdfClaim.x.modexp(_two, vdfClaim.n))) {
                return SingHalvProofOutput(true, false, _zero, _zero, 0);
            } else {
                return SingHalvProofOutput(false, false, _zero, _zero, 0);
            }
        }
        uint256 tHalf;
        BigNumber memory y = vdfClaim.y;
        BigNumber memory r = modHash(vdfClaim.x, bytes.concat(vdfClaim.y.val, vdfClaim.v.val)).mod(BigNumber(MODFORHASH, 129));
        if (vdfClaim.T & 1 == 0) {
            tHalf = vdfClaim.T / 2;
        } else {
            tHalf = (vdfClaim.T + 1) / 2;
            y = y.modexp(_two, vdfClaim.n);
        }
        return
            SingHalvProofOutput(
                true,
                true,
                (vdfClaim.x.modexp(r, vdfClaim.n)).modmul(vdfClaim.v, vdfClaim.n),
                (vdfClaim.v.modexp(r, vdfClaim.n)).modmul(y, vdfClaim.n),
                tHalf
            );
    }

    function verifyRecursiveHalvingProof(
        VDFClaim[] calldata proofList
    ) internal view returns (bool) {
        uint256 proofSize = proofList.length;
        for (uint256 i = 0; i < proofSize; i++) {
            SingHalvProofOutput memory output = processSingleHalvingProof(proofList[i]);
            if (!output.verified) {
                return false;
            } else {
                if (!output.calculated) {
                    return true;
                } else if (!output.x_prime.eq(proofList[i + 1].x)) {
                    return false;
                } else if (!output.y_prime.eq(proofList[i + 1].y)) {
                    return false;
                } else if (output.T_half != proofList[i + 1].T) {
                    return false;
                }
            }
        }
        return true;
    }
}
