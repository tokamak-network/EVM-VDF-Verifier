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
    const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinatorPoF")).address
    console.log("CRRNGCoordinatorPoF address:", crrrngCoordinatorAddress)
    const crrngCoordinatorContract = await ethers.getContractAt(
        "CRRNGCoordinatorPoF",
        crrrngCoordinatorAddress,
    )
    try {
        //const round = (await crrngCoordinatorContract.getNextRound()) - 1n
        const round = 2n
        console.log("Round:", round.toString())
        console.log("ReRequesting random word...")
        let tx
        if (chainId == 5050 || chainId == 55004)
            tx = await crrngCoordinatorContract.reRequestRandomWordAtRound(round, {
                gasLimit: 810000,
            })
        else tx = await crrngCoordinatorContract.reRequestRandomWordAtRound(round)
        const receipt = await tx.wait()
        console.log("Transaction receipt", receipt)
        console.log("Random word reRequested")
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
