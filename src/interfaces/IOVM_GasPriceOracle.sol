// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IOVM_GasPriceOracle {
    event DecimalsUpdated(uint256);
    event GasPriceUpdated(uint256);
    event L1BaseFeeUpdated(uint256);
    event OverheadUpdated(uint256);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ScalarUpdated(uint256);

    function decimals() external view returns (uint256);

    function gasPrice() external view returns (uint256);

    function getL1Fee(bytes memory _data) external view returns (uint256);

    function getL1GasUsed(bytes memory _data) external view returns (uint256);

    function l1BaseFee() external view returns (uint256);

    function overhead() external view returns (uint256);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function scalar() external view returns (uint256);

    function setDecimals(uint256 _decimals) external;

    function setGasPrice(uint256 _gasPrice) external;

    function setL1BaseFee(uint256 _baseFee) external;

    function setOverhead(uint256 _overhead) external;

    function setScalar(uint256 _scalar) external;

    function transferOwnership(address newOwner) external;
}
