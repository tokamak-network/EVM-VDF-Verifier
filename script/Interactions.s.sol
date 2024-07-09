// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {RNGCoordinatorPoF} from "../src/RNGCoordinatorPoF.sol";
import {ConsumerExample} from "../src/consumers/ConsumerExample.sol";
import {RandomDay} from "../src/consumers/RandomDay.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Utils is Script {
    address[10] public anvilDefaultAddresses = [
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
        0x90F79bf6EB2c4f870365E785982E1f101E93b906,
        0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
        0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
        0x976EA74026E726554dB657fA54763abd0C3a0aa9,
        0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
        0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f,
        0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
    ];
    uint256[10] public anvilDefaultPrivateKeys = [
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80,
        0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d,
        0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a,
        0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6,
        0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a,
        0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba,
        0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e,
        0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356,
        0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97,
        0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
    ];

    function castToEtherUnit(uint256 amount) public returns (string memory) {
        string[] memory inputs = new string[](4);
        inputs[0] = "cast";
        inputs[1] = "to-unit";
        inputs[2] = Strings.toString(amount);
        inputs[3] = "ether";
        bytes memory res = vm.ffi(inputs);
        return string(res);
    }
}

contract FiveOperatorsDepositAnvil is Utils {
    function run() external {
        RNGCoordinatorPoF rNGCoordinatorPoF = RNGCoordinatorPoF(
            DevOpsTools.get_most_recent_deployment(
                "RNGCoordinatorPoF",
                block.chainid
            )
        );
        uint256 minimumDepositAmount = rNGCoordinatorPoF
            .getMinimumDepositAmount();
        for (uint256 i = 1; i < 6; i++) {
            vm.startBroadcast(anvilDefaultPrivateKeys[i]);
            //vm.startBroadcast();
            rNGCoordinatorPoF.operatorDeposit{value: minimumDepositAmount}();
            //vm.stopBroadcast();
            vm.stopBroadcast();
            console2.log(
                anvilDefaultAddresses[i],
                "'s deposited amount:",
                castToEtherUnit(
                    rNGCoordinatorPoF.getDepositAmount(anvilDefaultAddresses[i])
                ),
                "ether"
            );
        }
    }
}

contract StartRandomdayEvent is Script {
    function run() external {
        RandomDay randomDay = RandomDay(
            DevOpsTools.get_most_recent_deployment("RandomDay", block.chainid)
        );
        vm.startBroadcast();
        randomDay.startEvent();
        vm.stopBroadcast();
        console2.log("event started!");
    }
}

contract ConsumerExampleRequestWord is Utils {
    function run() external {
        RNGCoordinatorPoF rNGCoordinatorPoF = RNGCoordinatorPoF(
            DevOpsTools.get_most_recent_deployment(
                "RNGCoordinatorPoF",
                block.chainid
            )
        );
        ConsumerExample consumerExample = ConsumerExample(
            DevOpsTools.get_most_recent_deployment(
                "ConsumerExample",
                block.chainid
            )
        );
        uint32 callback_gaslimit = consumerExample.CALLBACK_GAS_LIMIT();
        uint256 directFundingCost = rNGCoordinatorPoF
            .estimateDirectFundingPrice(callback_gaslimit, tx.gasprice);
        console2.log(
            "directFundingCost",
            castToEtherUnit(directFundingCost),
            "ether"
        );
        vm.startBroadcast();
        consumerExample.requestRandomWord{value: directFundingCost}();
        vm.stopBroadcast();
        uint256 lastRequestId = consumerExample.lastRequestId();
        console2.log("lastRequestId", lastRequestId);
    }
}

contract RandomDayRequestWord is Utils {
    function run() external {
        uint32 callback_gaslimit = 210000;
        RNGCoordinatorPoF rNGCoordinatorPoF = RNGCoordinatorPoF(
            DevOpsTools.get_most_recent_deployment(
                "RNGCoordinatorPoF",
                block.chainid
            )
        );
        RandomDay randomDay = RandomDay(
            DevOpsTools.get_most_recent_deployment("RandomDay", block.chainid)
        );
        uint256 directFundingCost = rNGCoordinatorPoF
            .estimateDirectFundingPrice(callback_gaslimit, tx.gasprice);
        console2.log(
            "directFundingCost",
            castToEtherUnit(directFundingCost),
            "ether"
        );
        vm.startBroadcast();
        randomDay.requestRandomWord{value: directFundingCost}();
        vm.stopBroadcast();
        uint256 lastRequestId = randomDay.lastRequestId();
        console2.log("lastRequestId", lastRequestId);
    }
}

contract ReRequestRandomWord is Script {
    function run(uint256 round) external {
        RNGCoordinatorPoF rNGCoordinatorPoF = RNGCoordinatorPoF(
            DevOpsTools.get_most_recent_deployment(
                "RNGCoordinatorPoF",
                block.chainid
            )
        );
        vm.startBroadcast();
        rNGCoordinatorPoF.reRequestRandomWordAtRound(round);
        vm.stopBroadcast();
    }
}
