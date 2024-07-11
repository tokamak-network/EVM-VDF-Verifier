// Copyright 2024 justin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import { ethers, getNamedAccounts, network } from "hardhat"

async function finalizeRankingandSendPrize() {
    const chainId: number = network.config.chainId as number
    const { deployer } = await getNamedAccounts()
    const tonTokenAddress = "0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2"
    const tonTokenContract = await ethers.getContractAt("TonToken", tonTokenAddress)
    const randomDayAddress = "0x8D6D4fAA4f502c1612c6dec7288a3F58bddd709A"
    console.log("randomDay address:", randomDayAddress)
    const randomDayConsumerContract = await ethers.getContractAt(
        "RandomDayForTitan",
        randomDayAddress,
    )
    const firstPlace = "0xB68AA9E398c054da7EBAaA446292f611CA0CD52B"
    const secondPlace = "0x1a681d0e32f8a1d0a5ba94113ecbc1a5df92e50f"
    const thirdPlace = "0x8bcfafd30d4e945b556ffe4db897ea6376ae85a5"
    try {
        console.log("Finalizing Ranking and Sending Prize...")
        const firstBalance = await tonTokenContract.balanceOf(firstPlace)
        const secondBalance = await tonTokenContract.balanceOf(secondPlace)
        const thirdBalance = await tonTokenContract.balanceOf(thirdPlace)
        //await time.increase(86400)
        const tx = await randomDayConsumerContract.finalizeRankingandSendPrize({
            gasLimit: 2400000,
        })
        const receipt = await tx.wait()
        console.log("Transaction receipt", receipt)
        console.log("Ranking finalized and prize sent")
        const newFirstBalance = await tonTokenContract.balanceOf(firstPlace)
        const newSecondBalance = await tonTokenContract.balanceOf(secondPlace)
        const newThirdBalance = await tonTokenContract.balanceOf(thirdPlace)
        console.log(
            "First place balance",
            firstBalance.toString(),
            newFirstBalance.toString(),
            (firstBalance - newFirstBalance).toString(),
        )
        console.log(
            "Second place balance",
            secondBalance.toString(),
            newSecondBalance.toString(),
            (secondBalance - newSecondBalance).toString(),
        )
        console.log(
            "Third place balance",
            thirdBalance.toString(),
            newThirdBalance.toString(),
            (thirdBalance - newThirdBalance).toString(),
        )
        console.log("----------------------")
    } catch (error) {
        console.error(error)
    }
}

finalizeRankingandSendPrize()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
