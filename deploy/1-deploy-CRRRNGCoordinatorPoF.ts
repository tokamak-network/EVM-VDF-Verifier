// Copyright 2024 justin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import { BigNumberish } from "ethers"
import { ethers } from "hardhat"
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { VERIFICATION_BLOCK_CONFIRMATIONS } from "../helper-hardhat-config"
import verify from "../utils/verify"
const deployCRRRNGCoordinator: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    const coordinatorConstructorParams: {
        disputePeriod: BigNumberish
        minimumDepositAmount: BigNumberish
        avgL2GasUsed: BigNumberish
        avgL1GasUsed: BigNumberish
        premiumPercentage: BigNumberish
        penaltyPercentage: BigNumberish
        flatFee: BigNumberish
    } = {
        disputePeriod: 180n,
        minimumDepositAmount: ethers.parseEther("0.005"),
        avgL2GasUsed: 2101449n,
        avgL1GasUsed: 27824n,
        premiumPercentage: 0n,
        penaltyPercentage: 20n,
        flatFee: ethers.parseEther("0.001"),
    }

    const waitBlockConfirmations =
        chainId === 31337 || chainId === 5050 || chainId === 55004 || chainId === 111551115050
            ? 1
            : VERIFICATION_BLOCK_CONFIRMATIONS
    log("----------------------------------------------------")
    const crrRngCoordinator = await deploy("CRRNGCoordinatorPoF", {
        from: deployer,
        log: true,
        args: [
            coordinatorConstructorParams.disputePeriod,
            coordinatorConstructorParams.minimumDepositAmount,
            coordinatorConstructorParams.avgL2GasUsed,
            coordinatorConstructorParams.avgL1GasUsed,
            coordinatorConstructorParams.premiumPercentage,
            coordinatorConstructorParams.penaltyPercentage,
            coordinatorConstructorParams.flatFee,
        ],
        waitConfirmations: waitBlockConfirmations,
    })
    // deploy result
    log("CRRNGCoordinatorPoF deployed at:", crrRngCoordinator.address)
    if (chainId !== 31337 && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(crrRngCoordinator.address, [
            coordinatorConstructorParams.disputePeriod,
            coordinatorConstructorParams.minimumDepositAmount,
            coordinatorConstructorParams.avgL2GasUsed,
            coordinatorConstructorParams.avgL1GasUsed,
            coordinatorConstructorParams.premiumPercentage,
            coordinatorConstructorParams.penaltyPercentage,
            coordinatorConstructorParams.flatFee,
        ])
    }
    log("----------------------------------------------------")
}
export default deployCRRRNGCoordinator
deployCRRRNGCoordinator.tags = [
    "all",
    "sepolia",
    "anvil",
    "",
    "crr",
    "opSepolia",
    "opSepoliaRandom",
    "PoF",
]
