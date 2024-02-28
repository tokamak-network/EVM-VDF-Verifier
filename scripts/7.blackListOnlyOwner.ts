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
const blackListAddress = [
    "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
    "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
]
async function requestRandomWord() {
    const chainId: number = network.config.chainId as number
    const { deployer } = await getNamedAccounts()
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
        console.log("blackLists...")
        const participants = await airdropConsumerContract.getParticipantsAtRound(round)
        for (let i = 0; i < blackListAddress.length; i++) {
            if (!participants.includes(blackListAddress[i])) {
                console.log("not registered address:", blackListAddress[i])
                process.exit(1)
            }
        }
        const participatedLength = await airdropConsumerContract.getNumOfParticipants(round)
        let tx
        if (chainId == 5050 || 55004)
            tx = await airdropConsumerContract.blackList(round, blackListAddress, {
                gasLimit: 197694,
            })
        else tx = await airdropConsumerContract.blackList(round, blackListAddress)
        const receipt = await tx.wait()
        const participatedLengthAfter = await airdropConsumerContract.getNumOfParticipants(round)
        console.log("Transaction receipt", receipt)
        console.log("BlackList Done")
        console.log("Participated Length Before:", participatedLength.toString())
        console.log("Participated Length After:", participatedLengthAfter.toString())
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
