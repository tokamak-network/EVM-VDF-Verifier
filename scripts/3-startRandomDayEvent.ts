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
import { deployments, ethers, getNamedAccounts, network } from "hardhat"

async function startEvent() {
    const chainId: number = network.config.chainId as number
    const { deployer } = await getNamedAccounts()
    const registrationDuration = 120n
    const totalPrizeAmount = 1000n * 10n ** 18n
    console.log("EOA address:", deployer)
    const randomDayAddress = (await deployments.get("RandomDay")).address
    console.log("randomDay address:", randomDayAddress)
    const cryptoDiceConsumerContract = await ethers.getContractAt("RandomDay", randomDayAddress)
    try {
        console.log("Starting Event...")
        const tx = await cryptoDiceConsumerContract.startEvent()
        const receipt = await tx.wait()
        console.log("Transaction receipt", receipt)
        console.log("Event started")
        console.log("----------------------")
    } catch (error) {
        console.error(error)
    }
}

startEvent()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
