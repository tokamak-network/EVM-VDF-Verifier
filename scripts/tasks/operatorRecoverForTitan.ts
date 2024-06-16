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
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { BigNumberish, BytesLike } from "ethers"
import { task } from "hardhat/config"

interface BigNumber {
    val: BytesLike
    bitlen: number
}
function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
export const getBitLenth2 = (num: string): BigNumberish => {
    return BigInt(num).toString(2).length
}

task("recoverAtRoundForTitan", "Operator recover For Titan")
    .addParam("round", "The round to recover")
    .setAction(async ({ round }, { getChainId, deployments, ethers, getNamedAccounts }) => {
        const chainId = await getChainId()
        const { deployer } = await getNamedAccounts()
        console.log("EOA address:", deployer)
        const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinatorPoFForTitan"))
            .address
        console.log("CRRRNGCoordinator address:", crrrngCoordinatorAddress)
        const crrngCoordinatorContract = await ethers.getContractAt(
            "CRRNGCoordinatorPoFForTitan",
            crrrngCoordinatorAddress,
        )

        console.log("Recovering...")
        let rand = crypto.getRandomValues(new Uint8Array(2048 / 8))
        const bytesHex = "0x" + rand.reduce((o, v) => o + ("00" + v.toString(16)).slice(-2), "")
        const recover = {
            val: ethers.toBeHex(bytesHex, getLength(ethers.dataLength(ethers.toBeHex(bytesHex)))),
            bitlen: getBitLenth2(ethers.toBeHex(bytesHex)),
        }
        console.log(recover)
        try {
            if (chainId == "31337") {
                await time.increase(121)
            }
            let tx = await crrngCoordinatorContract.recover(round, recover)
            const receipt = await tx.wait()
            console.log("Transaction receipt", receipt)
            console.log("Recovered")
            console.log("----------------------")
        } catch (e) {
            console.log(e)
        }
    })
