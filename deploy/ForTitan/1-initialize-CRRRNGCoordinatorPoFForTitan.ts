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

import { BytesLike } from "ethers"
import fs from "fs"
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { VERIFICATION_BLOCK_CONFIRMATIONS } from "../../helper-hardhat-config"

interface BigNumber {
    val: BytesLike
    bitlen: number
}
function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}

const deployCRRRNGCoordinator: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts, network, ethers } = hre
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    const waitBlockConfirmations =
        chainId === 31337 ||
        chainId === 5050 ||
        chainId === 55004 ||
        chainId === 111551115050 ||
        chainId == 55007
            ? 1
            : VERIFICATION_BLOCK_CONFIRMATIONS
    log("----------------------------------------------------")
    log("initialize Coordinator contract...")
    const testCaseJson = createCorrectAlgorithmVersionTestCase()
    //****** initialize params...
    const delta: number = 9
    let initializeParams: {
        v: BigNumber[]
        x: BigNumber
        y: BigNumber
    } = {
        v: [],
        x: { val: "0x0", bitlen: 0 },
        y: { val: "0x0", bitlen: 0 },
    }
    initializeParams.x = testCaseJson.setupProofs[0].x
    initializeParams.y = testCaseJson.setupProofs[0].y
    if (delta > 0) {
        testCaseJson.setupProofs = testCaseJson.setupProofs?.slice(0, -(delta + 1))
    }
    for (let i = 0; i < testCaseJson.setupProofs.length; i++) {
        initializeParams.v.push(testCaseJson.setupProofs[i].v)
    }

    const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinatorPoFForTitan")).address
    const crrngCoordinatorContract = await ethers.getContractAt(
        "CRRNGCoordinatorPoFForTitan",
        crrrngCoordinatorAddress,
    )
    const tx = await crrngCoordinatorContract.initialize(
        initializeParams.v,
        initializeParams.x,
        initializeParams.y,
        { from: deployer, gasLimit: 3000000 },
    )
    const receipt = await tx.wait()
    log("Transaction receipt")
    log(receipt)
    log("initialized!")
    log("----------------------------------------------------")
}
export default deployCRRRNGCoordinator
deployCRRRNGCoordinator.tags = [
    "all",
    "CRRRNGCoordinatorInitialize",
    "testnet",
    "anvil",
    "titan",
    "anvilTitan",
]

const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(__dirname + "/../../test/shared/correct.json", "utf-8"),
    )
    return testCaseJson
}
