// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {OptimismL1Fees} from "../OptimismL1Fees.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VDFCoordinatorForGetL1FeeTest is Ownable, OptimismL1Fees {
    uint256 public s_avgL2GasUsed;
    uint256 public s_premiumPercentage;
    uint256 public s_flatFee;
    uint256 public s_calldataSizeBytes;
    bytes public s_calldata;
    uint256 public round;
    uint256 public cost;

    constructor(
        address owner,
        uint256 avgL2GasUsed,
        uint256 premiumPercentage,
        uint256 flatFee,
        uint256 calldataSizeBytes,
        bytes memory allCalldata
    ) Ownable(owner) {
        s_avgL2GasUsed = avgL2GasUsed;
        s_premiumPercentage = premiumPercentage;
        s_flatFee = flatFee;
        s_calldataSizeBytes = calldataSizeBytes;
        s_calldata = allCalldata;
    }

    function isOwner() external view returns (bool) {
        return msg.sender == owner();
    }

    function directlyCallGetL1Fee(
        uint32 callbackGasLimit
    ) external payable returns (uint256) {
        cost =
            _calculateDirectFundingPrice(callbackGasLimit, tx.gasprice) +
            OVM_GASPRICEORACLE.getL1Fee(s_calldata);
        return round++;
    }

    function callCustomGetL1FeeEcotoneVer(
        uint32 callbackGasLimit
    ) external returns (uint256) {
        cost =
            _calculateDirectFundingPrice(callbackGasLimit, tx.gasprice) +
            _getL1CostWeiForCalldataSize(s_calldataSizeBytes);
        return round++;
    }

    function directlyCallGetL1FeeUpperBoundFjordVer(
        uint32 callbackGasLimit
    ) external returns (uint256) {
        cost =
            _calculateDirectFundingPrice(callbackGasLimit, tx.gasprice) +
            _getL1CostWeiForCalldataSize(s_calldataSizeBytes);
        return round++;
    }

    function estimateL1DirectFundingPrice(
        uint32 callbackGasLimit,
        uint256 gasPrice
    ) external view returns (uint256) {
        return _calculateDirectFundingPrice(callbackGasLimit, gasPrice);
    }

    function calculateDirectFundingPrice(
        uint32 callbackGasLimit
    ) external view returns (uint256) {
        return _calculateDirectFundingPrice(callbackGasLimit, tx.gasprice);
    }

    function _calculateDirectFundingPrice(
        uint32 callbackGasLimit,
        uint256 gasPrice
    ) private view returns (uint256) {
        return
            (((gasPrice * (callbackGasLimit + s_avgL2GasUsed)) *
                (s_premiumPercentage + 100)) / 100) + s_flatFee;
    }
}
