// Copyright 2024 justin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { VERIFICATION_BLOCK_CONFIRMATIONS, networkConfig } from "../helper-hardhat-config"
import verify from "../utils/verify"
const deployCryptoDice: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts, network } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    const waitBlockConfirmations =
        chainId === 31337 || chainId === 5050 || chainId === 55004 || chainId === 111551115050
            ? 1
            : VERIFICATION_BLOCK_CONFIRMATIONS
    log("----------------------------------------------------")
    // get crrRngCoordinatorAddress
    const crrRngCoordinatorAddress = (await deployments.get("CRRNGCoordinator")).address
    let tonTokenAddress: string
    if (chainId == 31337) {
        tonTokenAddress = (await deployments.get("TonToken")).address
    } else {
        tonTokenAddress = networkConfig[chainId!].tonAddress
    }
    const cryptoDice = await deploy("CryptoDice", {
        from: deployer,
        log: true,
        args: [crrRngCoordinatorAddress, tonTokenAddress],
        waitConfirmations: waitBlockConfirmations,
    })
    // deploy result
    log("cryptoDice deployed at:", cryptoDice.address)
    if (chainId !== 31337 && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(cryptoDice.address, [crrRngCoordinatorAddress, tonTokenAddress])
    }
    log("----------------------------------------------------")
}
export default deployCryptoDice
deployCryptoDice.tags = ["all", "cryptoDice", "testnet", "anvil"]
