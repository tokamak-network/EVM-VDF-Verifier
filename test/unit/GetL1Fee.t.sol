// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../shared/BaseTest.t.sol";
import {console2} from "forge-std/Test.sol";
import {OptimismL1Fees} from "../../src/OptimismL1Fees.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {IOVM_GasPriceOracle} from "../../src/interfaces/IOVM_GasPriceOracle.sol";
import {VDFCoordinatorForGetL1FeeTest} from "../../src/test/VDFCoordinatorForGetL1FeeTest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {GasHelpers} from "../shared/Utils.t.sol";
import {DecodeJsonBigNumber} from "../shared/DecodeJsonBigNumber.sol";
import {BigNumber} from "../../src/libraries/BigNumbers.sol";

interface IVDFCoordinator {
    function commit(uint256 round, BigNumber memory c) external;

    function reveal(uint256 round, BigNumber memory a) external;

    function recover(uint256 round, uint256 r) external;

    function recover2(
        uint256 round,
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y
    ) external;

    function fulfillRandomness(uint256 round) external;

    function calculateOmegAndFulfill(uint256 round) external;
}

contract GetL1Fee is BaseTest, GasHelpers, DecodeJsonBigNumber {
    uint256 public optimismFork;
    string public constant key = "OP_MAINNET_RPC_URL";
    string public OP_MAINNET_RPC_URL = vm.envString(key);
    uint256 public constant PROOFLENGTH = 13;
    uint256 public s_avgL2GasUsed = 2101449;
    uint256 public s_premiumPercentage = 0;
    uint256 public s_flatFee = 0.001 ether;
    uint256 public s_calldataSizeBytes;
    bytes public s_calldata;
    uint32 public s_callbackGasLimit = 210000;

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

    VDFCoordinatorForGetL1FeeTest public s_testCoordinator;

    uint8 internal constant L1_GAS_FEES_UPPER_BOUND_MODE = 0;
    uint8 internal constant L1_GAS_FEES_ECOTONE_MODE = 1;
    uint8 internal constant L1_GAS_FEES_LEGACY_MODE = 2;
    uint8 internal constant NOT_L2 = 4;

    function getCommitRevealCalculateOmegaFulFillCalldata()
        public
        view
        returns (bytes memory totalCalldata)
    {
        // 2 commits, 2 reveal, 1 calculateOmegaWithFulfill
        // ** Get the calldatas
        string memory root = vm.projectRoot();
        string memory path = string(
            abi.encodePacked(root, "/test/shared/currentTestCase.json")
        );
        string memory json = vm.readFile(path);
        BigNumber[] memory commits = new BigNumber[](2);
        BigNumber[] memory reveals = new BigNumber[](2);
        for (uint256 i; i < 2; i++) {
            commits[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(".commitList[", Strings.toString(i), "]")
                )
            );
            reveals[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(".randomList[", Strings.toString(i), "]")
                )
            );
        }
        uint256 round = 9;
        bytes memory commit1Data = abi.encodeWithSelector(
            IVDFCoordinator.commit.selector,
            round,
            commits[0]
        );
        totalCalldata = bytes.concat(commit1Data, L1_FEE_DATA_PADDING);
        bytes memory commit2Data = abi.encodeWithSelector(
            IVDFCoordinator.commit.selector,
            round,
            commits[1]
        );
        totalCalldata = bytes.concat(
            totalCalldata,
            commit2Data,
            L1_FEE_DATA_PADDING
        );
        bytes memory reveal1Data = abi.encodeWithSelector(
            IVDFCoordinator.reveal.selector,
            round,
            reveals[0]
        );
        totalCalldata = bytes.concat(
            totalCalldata,
            reveal1Data,
            L1_FEE_DATA_PADDING
        );
        bytes memory reveal2Data = abi.encodeWithSelector(
            IVDFCoordinator.reveal.selector,
            round,
            reveals[1]
        );
        totalCalldata = bytes.concat(
            totalCalldata,
            reveal2Data,
            L1_FEE_DATA_PADDING
        );
        bytes memory fulfillData = abi.encodeWithSelector(
            IVDFCoordinator.calculateOmegAndFulfill.selector,
            round
        );
        totalCalldata = bytes.concat(
            totalCalldata,
            fulfillData,
            L1_FEE_DATA_PADDING
        );
        return totalCalldata;
    }

    function getAllCalldata() public view returns (bytes memory totalCalldata) {
        // Eg. 2 commits, 2 reveals, 1 recover, 1 fulfill
        // ** Get the calldatas
        string memory root = vm.projectRoot();
        string memory path = string(
            abi.encodePacked(root, "/test/shared/currentTestCase.json")
        );
        string memory json = vm.readFile(path);
        BigNumber[] memory commits = new BigNumber[](2);
        BigNumber[] memory reveals = new BigNumber[](2);
        for (uint256 i; i < 2; i++) {
            commits[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(".commitList[", Strings.toString(i), "]")
                )
            );
            reveals[i] = decodeBigNumber(
                vm.parseJson(
                    json,
                    string.concat(".randomList[", Strings.toString(i), "]")
                )
            );
        }
        BigNumber memory x = decodeBigNumber(
            vm.parseJson(json, ".recoveryProofs[0].x")
        );
        BigNumber memory y = decodeBigNumber(
            vm.parseJson(json, ".recoveryProofs[0].y")
        );
        BigNumber[] memory v = new BigNumber[](PROOFLENGTH);
        for (uint256 i; i < PROOFLENGTH; i++) {
            v[i] = (
                decodeBigNumber(
                    vm.parseJson(
                        json,
                        string.concat(
                            ".recoveryProofs[",
                            Strings.toString(i),
                            "].v"
                        )
                    )
                )
            );
        }
        uint256 round = 9;
        bytes memory commit1Data = abi.encodeWithSelector(
            IVDFCoordinator.commit.selector,
            round,
            commits[0]
        );
        totalCalldata = bytes.concat(commit1Data, L1_FEE_DATA_PADDING);
        bytes memory commit2Data = abi.encodeWithSelector(
            IVDFCoordinator.commit.selector,
            round,
            commits[1]
        );
        totalCalldata = bytes.concat(
            totalCalldata,
            commit2Data,
            L1_FEE_DATA_PADDING
        );
        bytes memory reveal1Data = abi.encodeWithSelector(
            IVDFCoordinator.reveal.selector,
            round,
            reveals[0]
        );
        totalCalldata = bytes.concat(
            totalCalldata,
            reveal1Data,
            L1_FEE_DATA_PADDING
        );
        bytes memory reveal2Data = abi.encodeWithSelector(
            IVDFCoordinator.reveal.selector,
            round,
            reveals[1]
        );
        totalCalldata = bytes.concat(
            totalCalldata,
            reveal2Data,
            L1_FEE_DATA_PADDING
        );
        bytes memory recoverData2 = abi.encodeWithSelector(
            IVDFCoordinator.recover2.selector,
            round,
            v,
            x,
            y
        );
        totalCalldata = bytes.concat(
            totalCalldata,
            recoverData2,
            L1_FEE_DATA_PADDING
        );
        bytes memory fulfillData = abi.encodeWithSelector(
            IVDFCoordinator.fulfillRandomness.selector,
            round
        );
        totalCalldata = bytes.concat(
            totalCalldata,
            fulfillData,
            L1_FEE_DATA_PADDING
        );
        return totalCalldata;
    }

    function setUp() public override {
        BaseTest.setUp();

        // Fund our users.abi
        optimismFork = vm.createFork(OP_MAINNET_RPC_URL);
        vm.selectFork(optimismFork);
        assertEq(vm.activeFork(), optimismFork);
        vm.deal(DEPLOYER, 10_000 ether);
        vm.deal(OWNER, 10_000 ether);
        vm.stopPrank();
        vm.startPrank(DEPLOYER);
        vm.txGasPrice(100 gwei);
        s_calldata = getAllCalldata();
        s_calldataSizeBytes = s_calldata.length;
        s_testCoordinator = new VDFCoordinatorForGetL1FeeTest(
            DEPLOYER,
            s_avgL2GasUsed,
            s_premiumPercentage,
            s_flatFee,
            s_calldataSizeBytes,
            s_calldata
        );
    }

    modifier forkSpecificBlock(uint256 blockNumber) {
        vm.selectFork(optimismFork);
        vm.rollFork(blockNumber);
        assertEq(vm.activeFork(), optimismFork);
        assertEq(block.number, blockNumber);
        _;
    }

    function _checkL1FeeCalculationSetEmittedLogs(
        uint8 expectedMode,
        uint8 expectedCoefficient
    ) internal {
        VmSafe.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics.length, 1);
        assertEq(
            entries[0].topics[0],
            keccak256("L1FeeCalculationSet(uint8,uint8)")
        );
        (uint8 actualMode, uint8 actualCoefficient) = abi.decode(
            entries[0].data,
            (uint8, uint8)
        );
        assertEq(expectedMode, actualMode);
        assertEq(expectedCoefficient, actualCoefficient);
    }

    function test_setL1FeePaymentMethod() public {
        assertEq(NOT_L2, s_testCoordinator.s_l1FeeCalculationMode());
        assertEq(100, uint256(s_testCoordinator.s_l1FeeCoefficient()));

        vm.recordLogs();
        s_testCoordinator.setL1FeeCalculation(L1_GAS_FEES_ECOTONE_MODE, 70);
        _checkL1FeeCalculationSetEmittedLogs(L1_GAS_FEES_ECOTONE_MODE, 70);
        assertEq(
            L1_GAS_FEES_ECOTONE_MODE,
            s_testCoordinator.s_l1FeeCalculationMode()
        );
        assertEq(70, uint256(s_testCoordinator.s_l1FeeCoefficient()));

        s_testCoordinator.setL1FeeCalculation(L1_GAS_FEES_LEGACY_MODE, 30);
        _checkL1FeeCalculationSetEmittedLogs(L1_GAS_FEES_LEGACY_MODE, 30);
        assertEq(
            uint256(L1_GAS_FEES_LEGACY_MODE),
            uint256(s_testCoordinator.s_l1FeeCalculationMode())
        );
        assertEq(30, uint256(s_testCoordinator.s_l1FeeCoefficient()));

        // should revert if invalid L1 fee calculation  mode is used
        vm.expectRevert(
            abi.encodeWithSelector(
                OptimismL1Fees.InvalidL1FeeCalculationMode.selector,
                5
            )
        );
        s_testCoordinator.setL1FeeCalculation(5, 100);

        // should revert if invalid coefficient is used (equal to zero, this would disable l1 fees completely)
        vm.expectRevert(
            abi.encodeWithSelector(
                OptimismL1Fees.InvalidL1FeeCoefficient.selector,
                0
            )
        );
        s_testCoordinator.setL1FeeCalculation(L1_GAS_FEES_UPPER_BOUND_MODE, 0);

        // should revert if invalid coefficient is used (greater than 100)
        vm.expectRevert(
            abi.encodeWithSelector(
                OptimismL1Fees.InvalidL1FeeCoefficient.selector,
                101
            )
        );
        s_testCoordinator.setL1FeeCalculation(
            L1_GAS_FEES_UPPER_BOUND_MODE,
            101
        );
    }

    // Before Fjord, and after Ecotone
    function test_calculateDirectFundingEcotone() public {
        s_testCoordinator.setL1FeeCalculation(L1_GAS_FEES_ECOTONE_MODE, 100);
        bytes memory txMsgData = abi.encodeWithSelector(
            VDFCoordinatorForGetL1FeeTest.directlyCallGetL1Fee.selector,
            s_callbackGasLimit
        );
        (bool success, bytes memory returnData) = address(s_testCoordinator)
            .call(txMsgData);
        assertTrue(success);
        uint256 round = abi.decode(returnData, (uint256));
        assertEq(round, 0);
        uint256 cost = s_testCoordinator.cost();
        console2.log("Cost: ", cost);
    }

    function test_calculateDirectFundingUsingL1_GAS_FEES_UPPER_BOUND_MODE()
        public
    {
        s_testCoordinator.setL1FeeCalculation(
            L1_GAS_FEES_UPPER_BOUND_MODE,
            100
        );
        bytes memory txMsgData = abi.encodeWithSelector(
            VDFCoordinatorForGetL1FeeTest
                .directlyCallGetL1FeeUpperBoundFjordVer
                .selector,
            s_callbackGasLimit
        );
        (bool success, bytes memory returnData) = address(s_testCoordinator)
            .call(txMsgData);
        assertTrue(success);
        uint256 round = abi.decode(returnData, (uint256));
        assertEq(round, 0);
        uint256 cost = s_testCoordinator.cost();
        console2.log("Cost: ", cost);
    }

    function testGetCommitRevealCalculateOmegaFulFillCalldata() public view {
        bytes
            memory totalCalldata = getCommitRevealCalculateOmegaFulFillCalldata();
        console2.logBytes(totalCalldata);
        console2.log("Calldata size: ", totalCalldata.length);
    }
}
