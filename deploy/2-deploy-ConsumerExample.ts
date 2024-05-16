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

import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { VERIFICATION_BLOCK_CONFIRMATIONS } from "../helper-hardhat-config"
const deployTestERC20: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    const crrRngCoordinatorAddress = (await deployments.get("CRRNGCoordinator")).address
    const waitBlockConfirmations =
        chainId === 31337 || chainId === 5050 || chainId === 55004 || chainId === 111551115050
            ? 1
            : VERIFICATION_BLOCK_CONFIRMATIONS
    if (chainId == 31337) {
        log("----------------------------------------------------")
        const consumerExample = await deploy("ConsumerExample", {
            from: deployer,
            log: true,
            args: [crrRngCoordinatorAddress],
            waitConfirmations: waitBlockConfirmations,
        })
        // deploy result
        log("consumerExample deployed at:", consumerExample.address)
    }
}
export default deployTestERC20
deployTestERC20.tags = ["all", "consumerExample", "testnet"]
