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
const VDF_PROVER_ABI_FILE_CONSUMER = __dirname + "/../../VDF-prover/consumerContractABI.json"
const VDF_PROVER_ABI_FILE_COORDINATOR = __dirname + "/../../VDF-prover/coordinatorContractABI.json"
const VDF_PROVER_ADDRESS_FILE_CONSUMER =
    __dirname + "/../../VDF-prover/consumerContractAddress.json"
const VDF_PROVER_ADDRESS_FILE_COORDINATOR =
    __dirname + "/../../VDF-prover/coordinatorContractAddress.json"
export default async function updateVDFProver() {
    if (process.env.UPDATE_ABI_ADDRESS_FRONTEND_VDFPROVER === "true") {
        console.log("Updating vdf-prover...")
        await updateContractAddress()
        await updateAbi()
    }
}
async function updateContractAddress() {
    // cryptoDice
    const cryptoDice = await ethers.getContract("CryptoDice")
    const chainId = network.config.chainId?.toString()
    const currentAddress = JSON.parse(fs.readFileSync(VDF_PROVER_ADDRESS_FILE_CONSUMER, "utf8"))
    if (chainId! in currentAddress) {
        if (!currentAddress[chainId!].includes(await cryptoDice.getAddress())) {
            currentAddress[chainId!].push(await cryptoDice.getAddress())
        }
    } else {
        currentAddress[chainId!] = [await cryptoDice.getAddress()]
    }
    fs.writeFileSync(VDF_PROVER_ADDRESS_FILE_CONSUMER, JSON.stringify(currentAddress))
    // CRRNGCoordinatorPoF
    const CRRNGCoordinatorPoF = await ethers.getContract("CRRNGCoordinatorPoF")
    const currentAddressCoordinator = JSON.parse(
        fs.readFileSync(VDF_PROVER_ADDRESS_FILE_COORDINATOR, "utf8"),
    )
    if (chainId! in currentAddressCoordinator) {
        if (!currentAddressCoordinator[chainId!].includes(await CRRNGCoordinatorPoF.getAddress())) {
            currentAddressCoordinator[chainId!].push(await CRRNGCoordinatorPoF.getAddress())
        }
    } else {
        currentAddressCoordinator[chainId!] = [await CRRNGCoordinatorPoF.getAddress()]
    }
    fs.writeFileSync(VDF_PROVER_ADDRESS_FILE_COORDINATOR, JSON.stringify(currentAddressCoordinator))
}

async function updateAbi() {
    const cryptoDice = await ethers.getContract("CryptoDice")
    fs.writeFileSync(VDF_PROVER_ABI_FILE_CONSUMER, cryptoDice.interface.formatJson())
    const CRRNGCoordinatorPoF = await ethers.getContract("CRRNGCoordinatorPoF")
    fs.writeFileSync(VDF_PROVER_ABI_FILE_COORDINATOR, CRRNGCoordinatorPoF.interface.formatJson())
}
updateVDFProver.tags = ["all", "vdf-prover"]
