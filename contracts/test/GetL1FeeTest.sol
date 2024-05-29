pragma solidity ^0.8.24;
import {IOVM_GasPriceOracle} from "../interfaces/IOVM_GasPriceOracle.sol";
import {IL1Block} from "../interfaces/IL1Block.sol";

contract GetL1FeeTest {
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

    uint256 private constant l1GasUsedTitan = 47824;
    uint256 private constant l1GasUsed = 27824;
    uint256 private constant TEN_TOTHE_DECIMALS = 1000000;
    uint256 private constant MULTIPLYBY16 = 16000000;

    function getCurrentTxL1GasFeesTitan() external view returns (uint256) {
        uint256 l1Fee = l1GasUsedTitan * OVM_GASPRICEORACLE.l1BaseFee();
        uint256 divisor = 10 ** OVM_GASPRICEORACLE.decimals();
        uint256 unscaled = l1Fee * OVM_GASPRICEORACLE.scalar();
        uint256 scaled = unscaled / divisor;
        return scaled;
    }

    /// @notice Computation of the L1 portion of the fee for Bedrock.
    /// @return L1 fee that should be paid for the tx
    function getL1FeeBedrock() external view returns (uint256) {
        uint256 fee = (l1GasUsed + L1_BLOCK.l1FeeOverhead()) *
            L1_BLOCK.basefee() *
            L1_BLOCK.l1FeeScalar();
        return fee / TEN_TOTHE_DECIMALS;
    }

    /// @notice L1 portion of the fee after Ecotone.
    /// @return L1 fee that should be paid for the tx
    function getL1FeeEcotone() external view returns (uint256) {
        uint256 scaledBaseFee = L1_BLOCK.baseFeeScalar() * 16 * L1_BLOCK.basefee();
        uint256 scaledBlobBaseFee = L1_BLOCK.blobBaseFeeScalar() * L1_BLOCK.blobBaseFee();
        uint256 fee = l1GasUsed * (scaledBaseFee + scaledBlobBaseFee);
        return fee / MULTIPLYBY16;
    }
}
