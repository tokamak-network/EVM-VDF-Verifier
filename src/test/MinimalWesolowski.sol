// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../libraries/WesolowskiLibrary.sol";

interface IMinimalWesolowski {
    function verifyWesolowski(
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory T,
        BigNumber memory pi,
        BigNumber memory l
    ) external view returns (bool);
}

contract MinimalWesolowski {
    function verifyWesolowski(
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        BigNumber memory T,
        BigNumber memory pi,
        BigNumber memory l
    ) external view returns (bool) {
        WesolowskiLibrary.verify(x, y, n, T, pi, l);
        return true;
    }
}
