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

async function participantsRegister() {
    // **** start Registration
    const chainId: number = network.config.chainId as number
    const { deployer } = await getNamedAccounts()
    console.log("EOA address:", deployer)
    const cryptoDiceAddress = (await deployments.get("CryptoDice")).address
    console.log("cryptoDiceAddress address:", cryptoDiceAddress)
    const cryptoDiceConsumerContract = await ethers.getContractAt("CryptoDice", cryptoDiceAddress)

    // **** register
    const signers = await ethers.getSigners()
    const round = (await cryptoDiceConsumerContract.getNextCryptoDiceRound()) - 1n
    for (let i = 0; i < 10; i++) {
        const randomNumber = Math.floor(Math.random() * 6) + 1
        try {
            const tx = await cryptoDiceConsumerContract.connect(signers[i]).register(randomNumber)
            await tx.wait()
        } catch (e) {
            console.error(e)
        }
    }
}

participantsRegister()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
