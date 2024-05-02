// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;
import "../libraries/BigNumbers.sol";
import "hardhat/console.sol";

contract MontgomeryExp {
    function mont(
        BigNumber memory u,
        BigNumber memory v,
        BigNumber memory n,
        BigNumber memory R,
        BigNumber memory nInv
    ) internal view returns (BigNumber memory) {
        u = BigNumbers.modmul(u, v, n);
        BigNumber memory t = BigNumbers.modmul(u, nInv, R);
        uint256 k = R.bitlen - 1;
        u = BigNumbers._shr(BigNumbers.add(u, BigNumbers.mul(t, n)), k);
        if (BigNumbers.cmp(u, n) >= 0) {
            u = BigNumbers.sub(u, n);
        }
        return u;
    }

    function montgomeryExponentation(
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory R,
        BigNumber memory RInv,
        BigNumber memory nInv
    ) external view returns (BigNumber memory) {
        require(BigNumbers.modinvVerify(R, n, RInv), "R and n are not coprime");
        require(BigNumbers.modinvVerify(n, R, nInv), "n and R are not coprime");
        BigNumber memory base = mont(
            x,
            BigNumbers.modexp(
                R,
                BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO),
                BigNumbers._powModulus(R, BigNumbers.UINTTWO)
            ),
            n,
            R,
            nInv
        );
        BigNumber memory result = BigNumbers.mod(R, n);
        while (BigNumbers.isZero(y) == false) {
            if (BigNumbers.isOdd(y)) {
                result = mont(result, base, n, R, nInv);
            }
            base = mont(base, base, n, R, nInv);
            y = BigNumbers._shr(y, 1);
        }
        return BigNumbers.modmul(result, RInv, n);
    }
}
