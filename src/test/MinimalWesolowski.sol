// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../libraries/WesolowskiLibrary.sol";

interface IMinimalWesolowski {
    function verifyWesolowski(
        BigNumber memory x,
        BigNumber memory n,
        BigNumber memory T,
        BigNumber memory pi,
        BigNumber memory l
    ) external view returns (bool);
}

contract MinimalWesolowski {
    function verifyWesolowski(
        BigNumber memory x,
        BigNumber memory n,
        BigNumber memory T,
        BigNumber memory pi,
        BigNumber memory l
    ) external view returns (bool) {
        WesolowskiLibrary.verify(x, n, T, pi, l);
        return true;
    }
}

contract WesolowskiCalldata {
    function verifyWesolowski(
        BigNumber memory x,
        BigNumber memory n,
        BigNumber memory T,
        BigNumber memory pi,
        BigNumber memory l
    ) external {}
}

contract WesolowskiFixedWitness {
    function millerRanbinTest(uint256 n) external view returns (bool) {
        return WesolowskiLibrary.millerRabinTestFixedWitness(n);
    }
}

contract WesolowskiPseudoRandomWitness {
    function millerRanbinTest(uint256 n) external view returns (bool) {
        return WesolowskiLibrary.millerRabinTestPseudoRandomWitness(n);
    }
}
