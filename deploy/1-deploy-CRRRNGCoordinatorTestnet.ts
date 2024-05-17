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
        avgRecoveOverhead: BigNumberish
        premiumPercentage: BigNumberish
        flatFee: BigNumberish
    } = {
        disputePeriod: 180n,
        minimumDepositAmount: ethers.parseEther("0.0001"),
        avgRecoveOverhead: 0n,
        premiumPercentage: 0n,
        flatFee: 0n,
    }

    const waitBlockConfirmations =
        chainId === 31337 || chainId === 5050 || chainId === 55004 || chainId === 111551115050
            ? 1
            : VERIFICATION_BLOCK_CONFIRMATIONS
    log("----------------------------------------------------")
    let crrRngCoordinator
    if (chainId === 55007) {
        crrRngCoordinator = await deploy("CRRNGCoordinator", {
            from: deployer,
            log: true,
            args: [
                coordinatorConstructorParams.disputePeriod,
                coordinatorConstructorParams.minimumDepositAmount,
                coordinatorConstructorParams.avgRecoveOverhead,
                coordinatorConstructorParams.premiumPercentage,
                coordinatorConstructorParams.flatFee,
            ],
            waitConfirmations: waitBlockConfirmations,
            gasLimit: 5000000,
        })
    } else {
        crrRngCoordinator = await deploy("CRRNGCoordinator", {
            from: deployer,
            log: true,
            args: [
                coordinatorConstructorParams.disputePeriod,
                coordinatorConstructorParams.minimumDepositAmount,
                coordinatorConstructorParams.avgRecoveOverhead,
                coordinatorConstructorParams.premiumPercentage,
                coordinatorConstructorParams.flatFee,
            ],
            waitConfirmations: waitBlockConfirmations,
        })
    }
    // deploy result
    log("CRRNGCoordinator deployed at:", crrRngCoordinator.address)
    if (chainId !== 31337 && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(crrRngCoordinator.address, [
            coordinatorConstructorParams.disputePeriod,
            coordinatorConstructorParams.minimumDepositAmount,
            coordinatorConstructorParams.avgRecoveOverhead,
            coordinatorConstructorParams.premiumPercentage,
            coordinatorConstructorParams.flatFee,
        ])
    }
    log("----------------------------------------------------")
}
export default deployCRRRNGCoordinator
deployCRRRNGCoordinator.tags = ["all", "CRRNGCoordinator", "testnet"]
