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
    const registrationDuration = 86400n
    const totalPrizeAmount = 1000n * 10n ** 18n
    console.log("EOA address:", deployer)
    const airdropConsumerAddress = (await deployments.get("AirdropConsumer")).address
    console.log("airdropConsumer address:", airdropConsumerAddress)
    const airdropConsumerContract = await ethers.getContractAt(
        "AirdropConsumer",
        airdropConsumerAddress,
    )
    try {
        const round = (await airdropConsumerContract.getNextRandomAirdropRound()) - 1n
        console.log("Round:", round.toString())
        console.log("Requesting random word...")
        let tx
        if (chainId == 5050 || 55004)
            tx = await airdropConsumerContract.requestRandomWord(round, { gasLimit: 240000 })
        else tx = await airdropConsumerContract.requestRandomWord(round)
        const receipt = await tx.wait()
        console.log("Transaction receipt", receipt)
        console.log("Random word requested")
        const prizeAmountStartingAtFifthPlace =
            await airdropConsumerContract.getPrizeAmountStartingAtFifthPlace(round)
        console.log(
            "Prize amount starting at fifth place:",
            prizeAmountStartingAtFifthPlace.toString(),
        )
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
