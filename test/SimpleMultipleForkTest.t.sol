// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {StdCheats} from "forge-std/StdCheats.sol";
import {Test, console2} from "forge-std/Test.sol";
import {RNGCoordinatorPoF} from "../src/RNGCoordinatorPoF.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract CostOfVDFRNGTest is StdCheats, Test {
    RNGCoordinatorPoF public rNGCoordinatorPoF =
        RNGCoordinatorPoF(0x4015e2c6263188D176fD14F324627d8DeEECe4cf);
    uint256 public titanFork;
    string public key = "TITAN_RPC_URL";
    string public TITAN_RPC_URL = vm.envString(key);

    uint256 public constant EVENT_START_BLOCK = 3351;
    uint256 public constant Operator1_WITHDRAW_BLOCK = 3675;
    uint256 public constant OPERATOR2_WITHDRAW_BLOCK = 3669;
    uint256 public constant LAST_FULFILL_BLOCK = 3734;

    address public constant OPERATOR1 =
        0x01ab7d55c9878feB9e4b5249373c9D04eB3eA1AD;
    address public constant OPERATORS2 =
        0x4E0aF6520FB7EB595D92b3d98Dd20567E26BC442;

    function setUp() public {
        titanFork = vm.createFork(TITAN_RPC_URL);
    }

    modifier forkSpecificBlock(uint256 blockNumber) {
        vm.selectFork(titanFork);
        vm.rollFork(blockNumber);
        assertEq(vm.activeFork(), titanFork);
        assertEq(block.number, blockNumber);
        _;
    }

    function castToEtherUnit(uint256 amount) public returns (string memory) {
        string[] memory inputs = new string[](4);
        inputs[0] = "cast";
        inputs[1] = "to-unit";
        inputs[2] = Strings.toString(amount);
        inputs[3] = "ether";
        bytes memory res = vm.ffi(inputs);
        return string(res);
    }

    function testConsoleLogBalance()
        public
        forkSpecificBlock(EVENT_START_BLOCK)
    {
        console2.log("Operator balance at event start block");
        console2.log(castToEtherUnit(OPERATOR1.balance), "ETH");
        console2.log(castToEtherUnit(OPERATORS2.balance), "ETH");

        console2.log("Operator deposit amount at event start block");
        console2.log(
            castToEtherUnit(rNGCoordinatorPoF.getDepositAmount(OPERATOR1)),
            "ETH"
        );
        console2.log(
            castToEtherUnit(rNGCoordinatorPoF.getDepositAmount(OPERATORS2)),
            "ETH"
        );
    }

    function testConsoleLogBalanceAfter()
        public
        forkSpecificBlock(LAST_FULFILL_BLOCK)
    {
        console2.log("Operator balance at last fulfill block");
        console2.log(castToEtherUnit(OPERATOR1.balance), "ETH");
        console2.log(castToEtherUnit(OPERATORS2.balance), "ETH");

        console2.log("Operator deposit amount at last fulfill block");
        console2.log(
            castToEtherUnit(rNGCoordinatorPoF.getDepositAmount(OPERATOR1)),
            "ETH"
        );
        console2.log(
            castToEtherUnit(rNGCoordinatorPoF.getDepositAmount(OPERATORS2)),
            "ETH"
        );
    }

    function testOperator1WithdrawBefore()
        public
        forkSpecificBlock(Operator1_WITHDRAW_BLOCK - 1)
    {
        console2.log("Operator1 balance before withdraw");
        console2.log(castToEtherUnit(OPERATOR1.balance), "ETH");

        console2.log("Operator1 deposit amount before withdraw");
        console2.log(
            castToEtherUnit(rNGCoordinatorPoF.getDepositAmount(OPERATOR1)),
            "ETH"
        );
    }

    function testOperator1WithdrawAfter()
        public
        forkSpecificBlock(Operator1_WITHDRAW_BLOCK)
    {
        console2.log("Operator1 balance after withdraw");
        console2.log(castToEtherUnit(OPERATOR1.balance), "ETH");

        console2.log("Operator1 deposit amount after withdraw");
        console2.log(
            castToEtherUnit(rNGCoordinatorPoF.getDepositAmount(OPERATOR1)),
            "ETH"
        );
    }

    function testOperator2WithdrawBefore()
        public
        forkSpecificBlock(OPERATOR2_WITHDRAW_BLOCK - 1)
    {
        console2.log("Operator2 balance before withdraw");
        console2.log(castToEtherUnit(OPERATORS2.balance), "ETH");

        console2.log("Operator2 deposit amount before withdraw");
        console2.log(
            castToEtherUnit(rNGCoordinatorPoF.getDepositAmount(OPERATORS2)),
            "ETH"
        );
    }

    function testOperator2WithdrawAfter()
        public
        forkSpecificBlock(OPERATOR2_WITHDRAW_BLOCK)
    {
        console2.log("Operator2 balance after withdraw");
        console2.log(castToEtherUnit(OPERATORS2.balance), "ETH");

        console2.log("Operator2 deposit amount after withdraw");
        console2.log(
            castToEtherUnit(rNGCoordinatorPoF.getDepositAmount(OPERATORS2)),
            "ETH"
        );
    }
}
