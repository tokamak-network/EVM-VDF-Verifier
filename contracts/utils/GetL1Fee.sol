// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IOVM_GasPriceOracle} from "../interfaces/IOVM_GasPriceOracle.sol";
import {IL1Block} from "../interfaces/IL1Block.sol";

contract GetL1Fee {
    uint256 internal s_avgL1GasUsed;
    uint256 internal s_l1GasUsedTitan;
    /// @dev L1_FEE_DATA_PADDING includes 35 bytes for L1 data padding for Optimism
    bytes private constant L1_FEE_DATA_PADDING =
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    /// @dev OVM_GASPRICEORACLE_ADDR is the address of the OVM_GasPriceOracle precompile on Optimism.
    /// @dev reference: https://community.optimism.io/docs/developers/build/transaction-fees/#estimating-the-l1-data-fee
    address private constant OVM_GASPRICEORACLE_ADDR =
        address(0x420000000000000000000000000000000000000F);
    /// @notice Address of the L1Block predeploy.
    address internal constant L1_BLOCK_ATTRIBUTES = 0x4200000000000000000000000000000000000015;
    IOVM_GasPriceOracle private constant OVM_GASPRICEORACLE =
        IOVM_GasPriceOracle(OVM_GASPRICEORACLE_ADDR);
    IL1Block private constant L1_BLOCK = IL1Block(L1_BLOCK_ATTRIBUTES);

    //uint256 private constant l1GasUsed = 27824;
    uint256 private constant TEN_TOTHE_DECIMALS = 1000000;
    uint256 private constant MULTIPLYBY16 = 16000000;
    uint256 private constant L1_DISPUTERECOVER_TX_GAS = 72200;
    uint256 private constant L1_DISPUTERECOVER_TX_GAS_TITAN = 76200;
    uint256 private constant L1_DISPUTELEADERSHIP_TX_GAS = 1900;
    uint256 private constant L1_DISPUTELEADERSHIP_TX_GAS_TITAN = 5900;

    function _getDisputeLeadershipTxL1GasFee() internal view returns (uint256) {
        uint256 chainId = block.chainid;
        if (chainId == 55004 || chainId == 55007)
            return _getCurrentTxL1GasFeesTitan(L1_DISPUTELEADERSHIP_TX_GAS_TITAN);
        if (chainId == 11155420 || chainId == 10)
            return _getL1FeeBedrock(L1_DISPUTELEADERSHIP_TX_GAS);
        return 0;
    }

    function _getDisputeRecoverTxL1GasFee() internal view returns (uint256) {
        uint256 chainId = block.chainid;
        if (chainId == 55004 || chainId == 55007)
            return _getCurrentTxL1GasFeesTitan(L1_DISPUTERECOVER_TX_GAS_TITAN);
        if (chainId == 11155420 || chainId == 10) return _getL1FeeBedrock(L1_DISPUTERECOVER_TX_GAS);
        return 0;
    }

    function _getCurrentTxL1GasFee() internal view returns (uint256) {
        uint256 chainId = block.chainid;
        if (chainId == 55004 || chainId == 55007)
            return _getCurrentTxL1GasFeesTitan(s_l1GasUsedTitan);
        if (chainId == 11155420 || chainId == 10) return _getL1FeeEcotone(s_avgL1GasUsed);
        return 0;
    }

    function _getCurrentTxL1GasFeesTitan(uint256 gasUsed) private view returns (uint256) {
        uint256 l1Fee = gasUsed * OVM_GASPRICEORACLE.l1BaseFee();
        uint256 divisor = 10 ** OVM_GASPRICEORACLE.decimals();
        uint256 unscaled = l1Fee * OVM_GASPRICEORACLE.scalar();
        uint256 scaled = unscaled / divisor;
        return scaled;
    }

    /// @notice Computation of the L1 portion of the fee for Bedrock.
    /// @return L1 fee that should be paid for the tx
    function _getL1FeeBedrock(uint256 gasUsed) private view returns (uint256) {
        uint256 fee = (gasUsed + L1_BLOCK.l1FeeOverhead()) *
            L1_BLOCK.basefee() *
            L1_BLOCK.l1FeeScalar();
        return fee / TEN_TOTHE_DECIMALS;
    }

    /// @notice L1 portion of the fee after Ecotone.
    /// @return L1 fee that should be paid for the tx
    function _getL1FeeEcotone(uint256 gasUsed) private view returns (uint256) {
        uint256 scaledBaseFee = L1_BLOCK.baseFeeScalar() * 16 * L1_BLOCK.basefee();
        uint256 scaledBlobBaseFee = L1_BLOCK.blobBaseFeeScalar() * L1_BLOCK.blobBaseFee();
        uint256 fee = gasUsed * (scaledBaseFee + scaledBlobBaseFee);
        return fee / MULTIPLYBY16;
    }
}
