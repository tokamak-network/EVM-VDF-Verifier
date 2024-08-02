// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "../libraries/WesolowskiLibrary.sol";
import "../libraries/PietrzakLibrary.sol";

interface IMinimalPietrzak {
    function verifyPietrzak(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external view returns (bool);
}

contract MinimalPietrzakHalving {
    function verifyPietrzak(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external returns (bool) {
        return PietrzakLibraryMeasureHalvingGas.verify(v, x, y, n, delta, T);
    }
}

contract MinimalPietrzakModExp {
    function verifyPietrzak(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external returns (bool) {
        return PietrzakLibraryMeasureModExpGas.verify(v, x, y, n, delta, T);
    }
}

contract MinimalPietrzakHalvingReturnGas {
    function verifyPietrzak(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external view returns (uint256) {
        return
            PietrzakLibraryMeasureHalvingGas.verifyReturnGas(
                v,
                x,
                y,
                n,
                delta,
                T
            );
    }
}

contract MinimalPietrzakModExpReturnGas {
    function verifyPietrzak(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external view returns (uint256) {
        return
            PietrzakLibraryMeasureModExpGas.verifyReturnGas(
                v,
                x,
                y,
                n,
                delta,
                T
            );
    }
}

contract MinimalPietrzakExternal {
    function verifyPietrzak(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external returns (bool) {
        return PietrzakLibrary.verify(v, x, y, n, delta, T);
    }
}

contract MinimalPietrzak {
    function verifyPietrzak(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        uint256 delta,
        uint256 T
    ) external view returns (bool) {
        return PietrzakLibrary.verify(v, x, y, n, delta, T);
    }
}
