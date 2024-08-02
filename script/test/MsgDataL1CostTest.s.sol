// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {A, BBB} from "../../src/test/GetL1FeeTest.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {IOVM_GasPriceOracle} from "../../src/interfaces/IOVM_GasPriceOracle.sol";

contract DeployMsgDataL1CostTest is Script {
    function run() external {
        vm.startBroadcast();
        address bbb = address(new BBB());
        address a = address(new A(bbb));
        vm.stopBroadcast();
        console2.log("a: ", a);
        console2.log("bbb: ", bbb);
    }
}

contract SetA is Script {
    bytes public data =
        hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

    function run() external {
        address a = DevOpsTools.get_most_recent_deployment("A", block.chainid);
        console2.log("a: ", a);
        A aContract = A(a);
        vm.startBroadcast();
        aContract.setA(1);
        aContract.setB(data);
        vm.stopBroadcast();
    }
}

contract GetL1FeeOfContractA is Script {
    bytes public data =
        hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    bytes internal constant L1_FEE_DATA_PADDING =
        hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    bytes internal constant L1_FEE_DATA_PADDING2 =
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

    function run() external view {
        IOVM_GasPriceOracle ovmGasPriceOracle = IOVM_GasPriceOracle(
            address(0x420000000000000000000000000000000000000F)
        );
        bytes memory rawCalldata = abi.encodeWithSelector(A.setA.selector, 1);
        uint256 l1Fee = ovmGasPriceOracle.getL1Fee(
            bytes.concat(rawCalldata, L1_FEE_DATA_PADDING)
        );
        console2.log("l1Fee: ", l1Fee);
        uint256 l1Fee2 = ovmGasPriceOracle.getL1Fee(
            bytes.concat(
                abi.encodeWithSelector(A.setB.selector, data),
                L1_FEE_DATA_PADDING
            )
        );
        console2.log("l1Fee2: ", l1Fee2);
        uint256 l1GasUsed2 = ovmGasPriceOracle.getL1GasUsed(
            bytes.concat(rawCalldata, L1_FEE_DATA_PADDING2)
        );
        console2.log("l1GasUsed2: ", l1GasUsed2);
        uint256 l1GasUsed = ovmGasPriceOracle.getL1GasUsed(
            bytes.concat(rawCalldata, L1_FEE_DATA_PADDING)
        );
        console2.log("l1GasUsed: ", l1GasUsed);
        uint256 l1GasUsed1 = ovmGasPriceOracle.getL1GasUsed(
            bytes.concat(
                abi.encodeWithSelector(BBB.callFromA.selector, 2, 4, data),
                L1_FEE_DATA_PADDING
            )
        );
        console2.log("l1GasUsed: ", l1GasUsed1);
    }
}
