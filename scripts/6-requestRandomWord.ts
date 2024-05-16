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
import hre, { deployments, ethers, getNamedAccounts, network } from "hardhat"
async function requestRandomWord() {
    const chainId: number = network.config.chainId as number
    const { deployer } = await getNamedAccounts()
    const provider = ethers.provider
    // get timestamp
    const timestamp = (await provider.getBlock("latest"))!.timestamp
    console.log("Current timestamp:", timestamp)
    await hre.network.provider.request({
        method: "anvil_mine",
        params: [121],
    })
    //await time.increase(121)
    console.log("Time increased by 121 seconds")
    const newTimestamp = (await provider.getBlock("latest"))!.timestamp
    console.log("New timestamp:", newTimestamp)
    console.log("EOA address:", deployer)
    const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinator")).address
    console.log("CRRNGCoordinator address:", crrrngCoordinatorAddress)
    const crrngCoordinatorContract = await ethers.getContractAt(
        "CRRNGCoordinator",
        crrrngCoordinatorAddress,
    )
    const cryptoDiceConsumerAddress = (await deployments.get("CryptoDice")).address

    console.log("CryptoDice address:", cryptoDiceConsumerAddress)
    const cryptoDiceContract = await ethers.getContractAt("CryptoDice", cryptoDiceConsumerAddress)
    try {
        const round = (await cryptoDiceContract.getNextCryptoDiceRound()) - 1n
        console.log("Round:", round.toString())
        console.log("Requesting random word...")
        const provider = ethers.provider
        const fee = await provider.getFeeData()
        const gasPrice = fee.gasPrice as bigint
        console.log("gasPrice:", gasPrice.toString())
        const callback_gaslimit = 100000n
        const directFundingCost = await crrngCoordinatorContract.estimateDirectFundingPrice(
            callback_gaslimit,
            gasPrice,
        )
        let tx
        console.log("directFundingCost", directFundingCost.toString())
        console.log(await cryptoDiceContract.owner())
        if (chainId == 5050 || chainId == 55004)
            tx = await cryptoDiceContract.requestRandomWord(round, {
                gasLimit: 2400000,
                value: (directFundingCost * (100n + 5n)) / 100n,
            })
        else {
            tx = await cryptoDiceContract.requestRandomWord(round, {
                value: (directFundingCost * (100n + 5n)) / 100n,
            })
        }
        const receipt = await tx.wait()
        //console logs
        receipt!.logs?.forEach((event) => {
            console.log(event)
        })
        console.log("Transaction receipt", receipt)
        const requestId = (await cryptoDiceContract.getRoundStatus(round)).requestId
        console.log("Random word requested, roundId:", requestId.toString())
        console.log("----------------------")
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
