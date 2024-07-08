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
async function requestRandomWord() {
    const chainId: number = network.config.chainId as number
    const { deployer } = await getNamedAccounts()
    const provider = ethers.provider
    // get timestamp
    const timestamp = (await provider.getBlock("latest"))!.timestamp
    console.log("EOA address:", deployer)
    const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinatorPoFForTitan")).address
    console.log("CRRNGCoordinatorPoF address:", crrrngCoordinatorAddress)
    const crrngCoordinatorContract = await ethers.getContractAt(
        "CRRNGCoordinatorPoF",
        crrrngCoordinatorAddress,
    )
    const randomDayAddress = (await deployments.get("RandomDayForTitan")).address

    console.log("randomDayAddress address:", randomDayAddress)

    try {
        const callback_gaslimit = 210000n
        const fee = await provider.getFeeData()
        console.log("fee", fee)
        let gasPrice = fee.maxFeePerGas as bigint
        if (gasPrice == null) gasPrice = fee.gasPrice as bigint
        const directFundingCost = await crrngCoordinatorContract.estimateDirectFundingPrice(
            callback_gaslimit,
            gasPrice,
        )
        let tx
        console.log("directFundingCost", directFundingCost.toString())
        const randomDayContract = await ethers.getContractAt("RandomDayForTitan", randomDayAddress)
        try {
            const currentBlock = await provider.getBlock("latest")
            const currentTimestamp = currentBlock!.timestamp
            const eventEndTime = await randomDayContract.eventEndTime()
            console.log("currentTimestamp", currentTimestamp)
            console.log("eventEndTime", eventEndTime.toString())
            if (chainId == 5050 || chainId == 55004)
                tx = await randomDayContract.requestRandomWord({
                    gasLimit: 2400000,
                    value: directFundingCost,
                })
            else {
                tx = await randomDayContract.requestRandomWord({
                    value: (4467175825317694n * (100n + 15n)) / 100n,
                })
            }
            const receipt = await tx.wait()
            receipt!.logs?.forEach((event) => {
                console.log(event)
            })
            console.log("Transaction receipt", receipt)
            console.log("Random word requested")
            console.log("----------------------")
        } catch (e) {
            console.log(e)
        }

        //console logs
    } catch (error) {
        console.error(error)
    }
}

requestRandomWord()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
