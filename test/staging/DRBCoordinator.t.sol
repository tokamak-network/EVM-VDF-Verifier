// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {DRBCoordinator} from "../../src/DRBCoordinator.sol";
import {BaseTest} from "../shared/BaseTest.t.sol";
import {ConsumerExample} from "../../src/ConsumerExample.sol";

import {console2} from "forge-std/Test.sol";

contract DRBCoordinatorTest is BaseTest {
    DRBCoordinator drbCoordinator;
    address[] operatorAddresses;
    address[] consumerAddresses;
    ConsumerExample consumerExample;
    uint256 minDeposit = 10 ether;

    function setUp() public override {
        BaseTest.setUp(); // Start Prank
        vm.txGasPrice(100 gwei);
        vm.deal(OWNER, 10000 ether); // Give some ether to OWNER
        operatorAddresses = getRandomAddresses(0, 5);
        consumerAddresses = getRandomAddresses(5, 10);
        for (uint256 i = 0; i < operatorAddresses.length; i++) {
            vm.deal(operatorAddresses[i], 10000 ether);
            vm.deal(consumerAddresses[i], 10000 ether);
        }
        drbCoordinator = new DRBCoordinator(minDeposit);
        consumerExample = new ConsumerExample(address(drbCoordinator));

        // ** set L1
        drbCoordinator.setL1FeeCalculation(3, 100);
    }

    function deposit(address operator) public {
        vm.startPrank(operator);
        drbCoordinator.deposit{value: minDeposit}();
        assertEq(drbCoordinator.getDepositAmount(operator), minDeposit);
        vm.stopPrank();
    }

    function testDeposit() public {
        vm.stopPrank();
        deposit(operatorAddresses[0]);
        vm.startPrank(OWNER);
    }

    function test5Deposits() public {
        vm.stopPrank();
        for (uint256 i = 0; i < operatorAddresses.length; i++) {
            deposit(operatorAddresses[i]);
        }
        vm.startPrank(OWNER);
    }

    function activate(address operator) public {
        vm.startPrank(operator);
        drbCoordinator.activate();
        vm.stopPrank();
        address[] memory activatedOperators = drbCoordinator
            .getActivatedOperators();
        assertEq(
            activatedOperators[
                drbCoordinator.getActivatedOperatorIndex(operator)
            ],
            operator
        );
    }

    function test5Activate() public {
        vm.stopPrank();
        for (uint256 i = 0; i < operatorAddresses.length; i++) {
            deposit(operatorAddresses[i]);
            activate(operatorAddresses[i]);
        }
        address[] memory activatedOperators = drbCoordinator
            .getActivatedOperators();
        assertEq(activatedOperators.length - 1, operatorAddresses.length);
        vm.startPrank(OWNER);
    }

    modifier make5Activate() {
        vm.stopPrank();
        for (uint256 i = 0; i < operatorAddresses.length; i++) {
            deposit(operatorAddresses[i]);
            activate(operatorAddresses[i]);
        }
        _;
    }

    function deactivate(address operator) public {
        address[] memory activatedOperatorsBefore = drbCoordinator
            .getActivatedOperators();
        vm.startPrank(operator);
        drbCoordinator.deactivate();
        vm.stopPrank();
        address[] memory activatedOperatorsAfter = drbCoordinator
            .getActivatedOperators();
        assertEq(drbCoordinator.getActivatedOperatorIndex(operator), 0);
        assertEq(
            activatedOperatorsBefore.length - 1,
            activatedOperatorsAfter.length
        );
    }

    function test5Deactivate() public make5Activate {
        for (uint256 i = 0; i < operatorAddresses.length; i++) {
            deactivate(operatorAddresses[i]);
        }
        vm.startPrank(OWNER);
        address[] memory activatedOperators = drbCoordinator
            .getActivatedOperators();
        assertEq(activatedOperators.length, 1);
        assertEq(activatedOperators[0], address(0));
    }

    function testRequestRandomNumber() public make5Activate {
        address consumer = consumerAddresses[0];
        vm.startPrank(consumer);

        uint256 callbackGasLimit = consumerExample.CALLBACK_GAS_LIMIT();
        uint256 cost = drbCoordinator.estimateRequestPrice(
            callbackGasLimit,
            tx.gasprice
        );
        consumerExample.requestRandomNumber{value: cost}();

        // ** assert on ConsumerExample
        uint256 requestId = consumerExample.lastRequestId();
        (bool requested, bool fulfilled, uint256 randomNumber) = consumerExample
            .getRequestStatus(requestId);
        assertEq(requested, true);
        assertEq(fulfilled, false);
        assertEq(randomNumber, 0);
        assertEq(requestId, 0);

        // ** assert on DRBCoordinator
        DRBCoordinator.RequestInfo memory requestInfo = drbCoordinator
            .getRequestInfo(requestId);
        address[] memory activatedOperatorsAtRound = drbCoordinator
            .getActivatedOperatorsAtRound(requestId);
        assertEq(requestInfo.consumer, address(consumerExample), "consumer");
        assertEq(requestInfo.cost, cost, "cost");
        assertEq(
            requestInfo.callbackGasLimit,
            callbackGasLimit,
            "callbackGasLimit"
        );
        assertEq(activatedOperatorsAtRound.length, 6, "activatedOperators");

        for (uint256 i; i < operatorAddresses.length; i++) {
            uint256 depositAmount = drbCoordinator.getDepositAmount(
                operatorAddresses[i]
            );
            if (depositAmount < minDeposit) {
                assertEq(
                    drbCoordinator.getActivatedOperatorIndex(
                        operatorAddresses[i]
                    ),
                    0
                );
            } else {
                assertEq(
                    drbCoordinator.getActivatedOperatorIndex(
                        operatorAddresses[i]
                    ),
                    i + 1
                );
            }
        }
    }

    function requestRandomNumber() public {
        uint256 callbackGasLimit = consumerExample.CALLBACK_GAS_LIMIT();
        uint256 cost = drbCoordinator.estimateRequestPrice(
            callbackGasLimit,
            tx.gasprice
        );
        consumerExample.requestRandomNumber{value: cost}();
    }

    function testCommitReveal() public make5Activate {
        /// ** 1. requestRandomNumber
        requestRandomNumber();
        uint256 requestId = consumerExample.lastRequestId();

        /// ** 2. commit
        for (uint256 i; i < operatorAddresses.length; i++) {
            address operator = operatorAddresses[i];
            vm.startPrank(operator);
            drbCoordinator.commit(requestId, keccak256(abi.encodePacked(i)));
            vm.stopPrank();

            uint256 commitOrder = drbCoordinator.getCommitOrder(
                requestId,
                operator
            );
            assertEq(commitOrder, i + 1);
        }
        DRBCoordinator.RoundInfo memory roundInfo = drbCoordinator.getRoundInfo(
            requestId
        );
        bytes32[] memory commits = drbCoordinator.getCommits(requestId);
        assertEq(commits.length, 5);
        assertGt(roundInfo.commitEndTime, block.timestamp);
        assertEq(roundInfo.randomNumber, 0);
        assertEq(roundInfo.fulfillSucceeded, false);

        /// ** 3. reveal
        bytes32[] memory reveals = new bytes32[](operatorAddresses.length);
        for (uint256 i; i < operatorAddresses.length; i++) {
            address operator = operatorAddresses[i];
            vm.startPrank(operator);
            drbCoordinator.reveal(requestId, bytes32(i));
            reveals[i] = bytes32(i);
            vm.stopPrank();
            uint256 revealOrder = drbCoordinator.getRevealOrder(
                requestId,
                operator
            );
            assertEq(revealOrder, i + 1);
        }
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(reveals)));
        bytes32[] memory revealsOnChain = drbCoordinator.getReveals(requestId);
        assertEq(revealsOnChain.length, 5);
        roundInfo = drbCoordinator.getRoundInfo(requestId);
        assertEq(roundInfo.randomNumber, randomNumber);
        assertEq(roundInfo.fulfillSucceeded, true);

        for (uint256 i; i < operatorAddresses.length; i++) {
            uint256 depositAmount = drbCoordinator.getDepositAmount(
                operatorAddresses[i]
            );
            if (depositAmount < minDeposit) {
                assertEq(
                    drbCoordinator.getActivatedOperatorIndex(
                        operatorAddresses[i]
                    ),
                    0
                );
            } else {
                assertEq(
                    drbCoordinator.getActivatedOperatorIndex(
                        operatorAddresses[i]
                    ),
                    i + 1
                );
            }
        }
    }
}
