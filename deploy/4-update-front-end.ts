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
import fs from "fs"
import { ethers, network } from "hardhat"
import { DeployFunction } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
const FRONT_END_ADDRESS_FILE_CONSUMER =
    __dirname + "/../../demo-front/constants/consumerContractAddress.json"
const FRONT_END_ADDRESS_FILE_COORDINATOR =
    __dirname + "/../../demo-front/constants/coordinatorContractAddress.json"
const FRONT_END_ADDRESS_FILE_TESTERC20 =
    __dirname + "/../../demo-front/constants/testErc20Address.json"
const FRONT_END_ABI_FILE_TESTERC20 = __dirname + "/../../demo-front/constants/testErc20Abi.json"
const FRONT_END_ABI_FILE_COORDINATOR = __dirname + "/../../demo-front/constants/crrngAbi.json"
const updateFrontEnd: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    if (process.env.UPDATE_ABI_ADDRESS_FRONTEND_VDFPROVER === "true") {
        console.log("Updating frontend with VDFProver contract address and ABI...")
        await updateContractAddress()
        await updateAbi()
    }
}
async function updateAbi() {
    const chainId = network.config.chainId?.toString()
    const CRRNGCoordinatorPoF = await ethers.getContract("CRRNGCoordinatorPoF")
    fs.writeFileSync(FRONT_END_ABI_FILE_COORDINATOR, CRRNGCoordinatorPoF.interface.formatJson())
    if (chainId == "31337") {
        const tonToken = await ethers.getContract("TonToken")
        fs.writeFileSync(FRONT_END_ABI_FILE_TESTERC20, tonToken.interface.formatJson())
    }
}
async function updateContractAddress() {
    const chainId = network.config.chainId?.toString()
    const currentAddress = JSON.parse(fs.readFileSync(FRONT_END_ADDRESS_FILE_CONSUMER, "utf8"))
    fs.writeFileSync(FRONT_END_ADDRESS_FILE_CONSUMER, JSON.stringify(currentAddress))
    // CRRNGCoordinatorPoF
    const CRRNGCoordinatorPoF = await ethers.getContract("CRRNGCoordinatorPoF")
    const currentAddressCoordinator = JSON.parse(
        fs.readFileSync(FRONT_END_ADDRESS_FILE_COORDINATOR, "utf8"),
    )
    if (chainId! in currentAddressCoordinator) {
        if (!currentAddressCoordinator[chainId!].includes(await CRRNGCoordinatorPoF.getAddress())) {
            currentAddressCoordinator[chainId!].push(await CRRNGCoordinatorPoF.getAddress())
        }
    } else {
        currentAddressCoordinator[chainId!] = [await CRRNGCoordinatorPoF.getAddress()]
    }
    fs.writeFileSync(FRONT_END_ADDRESS_FILE_COORDINATOR, JSON.stringify(currentAddressCoordinator))
    // tonToken
    if (chainId == "31337") {
        const tonToken = await ethers.getContract("TonToken")
        const currentAddressTonToken = JSON.parse(
            fs.readFileSync(FRONT_END_ADDRESS_FILE_TESTERC20, "utf8"),
        )
        if (chainId! in currentAddressTonToken) {
            if (!currentAddressTonToken[chainId!].includes(await tonToken.getAddress())) {
                currentAddressTonToken[chainId!].push(await tonToken.getAddress())
            }
        } else {
            currentAddressTonToken[chainId!] = [await tonToken.getAddress()]
        }
        fs.writeFileSync(FRONT_END_ADDRESS_FILE_TESTERC20, JSON.stringify(currentAddressTonToken))
    }
}
export default updateFrontEnd
updateFrontEnd.tags = ["all", "frontend"]
