// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

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

contract MinimalPietrzak204820 {
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

contract MinimalPietrzak204821 {
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

contract MinimalPietrzak204822 {
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

contract MinimalPietrzak204823 {
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

contract MinimalPietrzak204824 {
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

contract MinimalPietrzak204825 {
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

contract MinimalPietrzak307220 {
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

contract MinimalPietrzak307221 {
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

contract MinimalPietrzak307222 {
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

contract MinimalPietrzak307223 {
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

contract MinimalPietrzak307224 {
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

contract MinimalPietrzak307225 {
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
