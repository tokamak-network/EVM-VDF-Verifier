// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.22;
// import "./BigNumbers.sol";

// library Pietrzak_VDF {
//     using BigNumbers for *;
//     bytes private constant MODFORHASH =
//         hex"0000000000000000000000000000000100000000000000000000000000000000";
//     uint256 private constant MODFORHASH_LEN = 129;

//     struct VDFClaim {
//         uint256 T;
//         BigNumber x;
//         BigNumber y;
//         BigNumber v;
//     }

//     function modHash(
//         BigNumber memory _n,
//         bytes memory _strings
//     ) internal view returns (BigNumber memory) {
//         return abi.encodePacked(keccak256(_strings)).init().mod(_n);
//     }

//     function verifyRecursiveHalvingProof(
//         VDFClaim[] calldata proofList,
//         BigNumber memory _n
//     ) internal view returns (bool) {
//         uint256 proofSize = proofList.length;
//         BigNumber memory _two = BigNumbers.two();
//         for (uint256 i = 0; i < proofSize; i++) {
//             if (proofList[i].T == 1) {
//                 if (proofList[i].y.eq(proofList[i].x.modexp(_two, _n))) {
//                     return true;
//                 } else {
//                     return false;
//                 }
//             }
//             BigNumber memory y = proofList[i].y;
//             BigNumber memory r = modHash(
//                 proofList[i].x,
//                 bytes.concat(proofList[i].y.val, proofList[i].v.val)
//             ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
//             if (proofList[i].T & 1 == 1) y = y.modexp(_two, _n);
//             BigNumber memory _xPrime = proofList[i].x.modexp(r, _n).modmul(proofList[i].v, _n);
//             if (!_xPrime.eq(proofList[i + 1].x)) return false;
//             BigNumber memory _yPrime = proofList[i].v.modexp(r, _n);
//             if (!_yPrime.modmul(y, _n).eq(proofList[i + 1].y)) return false;
//         }
//         return true;
//     }
// }
