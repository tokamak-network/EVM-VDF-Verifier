// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {DRBCoordinatorMock} from "../../src/DRBCoordinatorMock.sol";
import {DRBConsumerExample} from "../../src/consumers/DRBConsumerExample.sol";
import {IDRBCoordinator} from "../../src/interfaces/IDRBCoordinator.sol";

contract DRBCoordinatorMockConsumerTest is Test {
    address public constant FOUNDRY_DEFAULT_SENDER =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    DRBCoordinatorMock public drbCoordinatorMock;
    DRBConsumerExample public drbConsumerExample;
    IDRBCoordinator.RandomWordsRequest public requestInfo =
        IDRBCoordinator.RandomWordsRequest(0, 0, 100000);

    function _deployDRBCoordinatorMock() internal returns (DRBCoordinatorMock) {
        uint256 avgL2GasUsed = 2100000;
        uint256 premiumPercentage = 0;
        uint256 flatFee = 0.001 ether;
        /// @dev calldataSize Bytes for 2 commits, 2 reveals, 1 calculateOmegaAndFulfill
        uint256 calldataSizeBytes = 2071;
        return
            new DRBCoordinatorMock(
                avgL2GasUsed,
                premiumPercentage,
                flatFee,
                calldataSizeBytes
            );
    }

    function setUp() public {
        /// Sets `tx.gasprice`.
        vm.deal(FOUNDRY_DEFAULT_SENDER, 20000 ether);
        vm.txGasPrice(100 gwei);
        vm.startPrank(FOUNDRY_DEFAULT_SENDER);

        /// Deploy DRBCoordinatorMock contract
        drbCoordinatorMock = _deployDRBCoordinatorMock();

        /// Deploy DRBConsumerExample contract
        drbConsumerExample = new DRBConsumerExample(
            address(drbCoordinatorMock)
        );
    }

    function _checkRandomWordsRequestEmittedLogs(uint256 requestId) internal {
        // ** RandomWordsRequested event from DRBCoordinatorMock contract
        VmSafe.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 1);
        assertEq(entries[0].topics.length, 1);
        assertEq(
            entries[0].topics[0],
            keccak256("RandomWordsRequested(uint256)")
        );
        uint256 actualRequestId = abi.decode(entries[0].data, (uint256));
        assertEq(requestId, actualRequestId);
    }

    function _checkFulfillRandomnessEmittedLogs(
        uint256 requestId,
        uint256 randomNumber,
        address fulfiller
    ) internal {
        VmSafe.Log[] memory entries = vm.getRecordedLogs();
        assertEq(entries.length, 2);
        /// ** 1. ReturnedRandomness event from DRBConsumerExample contract
        assertEq(entries[0].topics.length, 1);
        assertEq(
            entries[0].topics[0],
            keccak256("ReturnedRandomness(uint256,uint256)")
        );
        (uint256 actualRequestId, uint256 actualRandomNumber) = abi.decode(
            entries[0].data,
            (uint256, uint256)
        );
        assertEq(requestId, actualRequestId);
        assertEq(randomNumber, actualRandomNumber);

        /// ** 2. FulfillRandomness event from DRBCoordinatorMock contract
        assertEq(entries[1].topics.length, 1);
        assertEq(
            entries[1].topics[0],
            keccak256("FulfillRandomness(uint256,bool,address)")
        );
        bool success;
        address actualFulfiller;
        (actualRequestId, success, actualFulfiller) = abi.decode(
            entries[1].data,
            (uint256, bool, address)
        );
        assertEq(requestId, actualRequestId);
        assertTrue(success);
        assertEq(fulfiller, actualFulfiller);
    }

    function testRequestRandomWordAndGetTheWord() public {
        /// ** 1. estimateDirectFundingPrice from DRBCoordinatorMock
        /// On networks with fluctuating gas prices a lot, give it a buffer.
        uint256 estimatedDirectFundingPrice = drbCoordinatorMock
            .estimateDirectFundingPrice(tx.gasprice, requestInfo);

        /// ** 2. requestRandomWords from DRBConsumerExample
        vm.recordLogs();
        uint256 requestId = drbConsumerExample.requestRandomWord{
            value: estimatedDirectFundingPrice
        }();
        _checkRandomWordsRequestEmittedLogs(requestId);
        (bool requested, uint256 randomNumber) = (
            drbConsumerExample.s_requestsInfos(requestId)
        );
        assertTrue(requested);
        assertEq(randomNumber, 0);

        // ** 3. fulfillRandomWords from DRBCoordinatorMock
        // ** Because you are testing on a local blockchain environment, you must fulfill the random number request yourself.
        drbCoordinatorMock.fulfillRandomness(requestId);

        // ** Assert test on DRBConsumerExample
        (requested, randomNumber) = drbConsumerExample.s_requestsInfos(
            requestId
        );
        assertTrue(requested);
        _checkFulfillRandomnessEmittedLogs(
            requestId,
            randomNumber,
            FOUNDRY_DEFAULT_SENDER
        );
        console2.log("Generated Random Number: ", randomNumber);
    }
}
