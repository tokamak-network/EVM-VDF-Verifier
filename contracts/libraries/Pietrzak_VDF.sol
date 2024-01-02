// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
import "./BigNumbers.sol";

library Pietrzak_VDF {
    using BigNumbers for *;
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";

    struct VDFClaim {
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
        BigNumber memory _n,
        uint256 _T
    ) internal view returns (SingHalvProofOutput memory, uint256) {
        BigNumber memory _zero = BigNumbers.zero();
        BigNumber memory _two = BigNumbers.two();
        if (_T == 1) {
            if (vdfClaim.y.eq(vdfClaim.x.modexp(_two, _n))) {
                return (SingHalvProofOutput(true, false, _zero, _zero), 0);
            } else {
                return (SingHalvProofOutput(false, false, _zero, _zero), 0);
            }
        }
        BigNumber memory y = vdfClaim.y;
        BigNumber memory r = modHash(vdfClaim.x, bytes.concat(y.val, vdfClaim.v.val)).mod(
            BigNumber(MODFORHASH, 129)
        );
        if (_T & 1 == 0) {
            _T = _T / 2;
        } else {
            _T = (_T + 1) / 2;
            y = y.modexp(_two, _n);
        }
        BigNumber memory _x_prime = vdfClaim.x.modexp(r, _n).modmul(vdfClaim.v, _n);
        BigNumber memory _y_prime = vdfClaim.v.modexp(r, _n); // to avoid stack too deep error
        return (SingHalvProofOutput(true, true, _x_prime, _y_prime.modmul(y, _n)), _T);
    }

    function verifyRecursiveHalvingProof(
        VDFClaim[] calldata proofList,
        BigNumber memory _n,
        uint256 _T
    ) internal view returns (bool) {
        uint256 proofSize = proofList.length;
        for (uint256 i = 0; i < proofSize; i++) {
            SingHalvProofOutput memory output;
            (output, _T) = processSingleHalvingProof(proofList[i], _n, _T);
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
