// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../shared/BaseTest.t.sol";
import {OptimismL1Fees} from "../../src/OptimismL1Fees.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IOVM_GasPriceOracle} from "../../src/interfaces/IOVM_GasPriceOracle.sol";
import {VDFCoordinatorForGetL1FeeTest} from "../../src/test/VDFCoordinatorForGetL1FeeTest.sol";

interface IVDFCoordinator {
    struct BigNumber {
        bytes val;
        uint256 bitlen;
    }

    function commit(uint256 round, BigNumber memory c) external;

    function reveal(uint256 round, BigNumber memory a) external;

    function recover(uint256 round, uint256 r) external;

    function recover(
        uint256 round,
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y
    ) external;
}

contract GetL1Fee is BaseTest {
    uint256 public s_premiumPercentage = 0;
    uint256 public s_flatFee = 0.001 ether;
    uint256 public s_calldataSizeBytes;
    bytes public s_calldata;

    address private constant OVM_GASPRICEORACLE_ADDR =
        address(0x420000000000000000000000000000000000000F);
    IOVM_GasPriceOracle private constant OVM_GASPRICEORACLE =
        IOVM_GasPriceOracle(OVM_GASPRICEORACLE_ADDR);

    /// @dev L1_FEE_DATA_PADDING inclues 71 bytes for L1 data padding for Optimism
    bytes internal constant L1_FEE_DATA_PADDING =
        hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

    address internal constant DEPLOYER =
        0xD883a6A1C22fC4AbFE938a5aDF9B2Cc31b1BF18B;

    uint256 gasPrice = 0.003 gwei;

    /// @dev Option 1: getL1Fee() function from predeploy GasPriceOracle contract with the calldata payload
    /// @dev This option is only available for the Coordinator contract
    uint8 internal constant L1_GAS_FEES_MODE = 0;
    /// @dev Option 2: our own implementation of getL1Fee() function (Ecotone version) with projected
    /// @dev calldata payload
    /// @dev This option is available for the Coordinator contract
    uint8 internal constant L1_CALLDATA_GAS_COST_MODE = 1;
    /// @dev Option 3: getL1FeeUpperBound() function from predeploy GasPriceOracle contract (available after Fjord upgrade)
    /// @dev This option is available for the Coordinator contract
    uint8 internal constant L1_GAS_FEES_UPPER_BOUND_MODE = 2;

    function setCalldata() public {}

    function setUp() public override {
        BaseTest.setUp();

        // Fund our users.abi
        vm.roll(1);
        vm.deal(DEPLOYER, 10_000 ether);
        changePrank(DEPLOYER);
        vm.txGasPrice(100 gwei);
    }
}
