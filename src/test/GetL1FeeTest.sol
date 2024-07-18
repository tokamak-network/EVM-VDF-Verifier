// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {IOVM_GasPriceOracle} from "../interfaces/IOVM_GasPriceOracle.sol";
import {IL1Block} from "../interfaces/IL1Block.sol";
import {ReentrancyGuardTransient} from "../utils/ReentrancyGuardTransient.sol";
import {RNGCoordinatorPoF} from "../RNGCoordinatorPoF.sol";
import {LibZip} from "@solady/utils/LibZip.sol";

contract GetL1FeeTest {
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
    address internal constant L1_BLOCK_ATTRIBUTES =
        0x4200000000000000000000000000000000000015;
    IOVM_GasPriceOracle private constant OVM_GASPRICEORACLE =
        IOVM_GasPriceOracle(OVM_GASPRICEORACLE_ADDR);
    IL1Block private constant L1_BLOCK = IL1Block(L1_BLOCK_ATTRIBUTES);

    //uint256 private constant l1GasUsed = 27824;
    uint256 private constant TEN_TOTHE_DECIMALS = 1000000;
    uint256 private constant MULTIPLYBY16 = 16000000;

    function _getCurrentTxL1GasFee() internal view returns (uint256) {
        uint256 chainId = block.chainid;
        if (chainId == 55004 || chainId == 55007)
            return _getCurrentTxL1GasFeesTitan(s_l1GasUsedTitan);
        if (chainId == 11155420 || chainId == 10)
            return _getL1FeeEcotone(s_avgL1GasUsed);
        return 0;
    }

    function _getCurrentTxL1GasFeesTitan(
        uint256 gasUsed
    ) private view returns (uint256) {
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
        uint256 scaledBaseFee = L1_BLOCK.baseFeeScalar() *
            16 *
            L1_BLOCK.basefee();
        uint256 scaledBlobBaseFee = L1_BLOCK.blobBaseFeeScalar() *
            L1_BLOCK.blobBaseFee();
        uint256 fee = gasUsed * (scaledBaseFee + scaledBlobBaseFee);
        return fee / MULTIPLYBY16;
    }
}

contract GetL1FeeCoordinator is ReentrancyGuardTransient, GetL1FeeTest {
    struct ValueAtRound {
        address consumer;
        uint256 requestedTime;
    }
    bool private s_initialized;
    uint256 private s_nextRound;
    uint256 private s_operatorCount;
    uint256 private s_avgL2GasUsed;
    uint256 private s_premiumPercentage;
    uint256 private s_flatFee;

    mapping(uint256 => ValueAtRound) private s_valuesAtRound;
    mapping(uint256 => uint256) private s_cost;
    mapping(uint256 => uint32) private s_callbackGasLimit;

    event RandomWordsRequested(uint256 round);

    error NotVerified();
    error NotEnoughOperators();
    error InsufficientAmount();

    function initialize(
        uint256 operatorCount,
        uint256 avgL2GasUsed,
        uint256 avgL1GasUsed,
        uint256 premiumPercentage,
        uint256 flatFee
    ) external {
        if (s_initialized) revert("Already initialized");
        s_operatorCount = operatorCount;
        s_avgL2GasUsed = avgL2GasUsed;
        s_avgL1GasUsed = avgL1GasUsed;
        s_l1GasUsedTitan = avgL1GasUsed + 20000;
        s_premiumPercentage = premiumPercentage;
        s_flatFee = flatFee;
        s_initialized = true;
    }

    function requestRandomWordDirectFundingGetL1Directly(
        uint32 callbackGasLimit
    ) external payable nonReentrant returns (uint256 round) {
        if (!s_initialized) revert NotVerified();
        if (s_operatorCount < 2) revert NotEnoughOperators();
        uint256 cost = _calculateDirectFundingPriceTest(
            callbackGasLimit,
            tx.gasprice
        );
        if (msg.value < cost) revert InsufficientAmount();
        round = s_nextRound++;
        s_valuesAtRound[round].consumer = msg.sender;
        s_valuesAtRound[round].requestedTime = block.timestamp;
        s_cost[round] = msg.value;
        s_callbackGasLimit[round] = callbackGasLimit;
        emit RandomWordsRequested(round);
    }

    function estimateDirectFundingPriceTest(
        uint32 callbackGasLimit,
        uint256 gasPrice
    ) external view returns (uint256) {
        return _calculateDirectFundingPriceTest(callbackGasLimit, gasPrice);
    }

    function _calculateDirectFundingPriceTest(
        uint32 _callbackGasLimit,
        uint256 gasPrice
    ) private view returns (uint256) {
        return
            (((gasPrice * (_callbackGasLimit + s_avgL2GasUsed)) *
                (s_premiumPercentage + 100)) / 100) +
            s_flatFee +
            _getCurrentTxL1GasFee();
    }
}
