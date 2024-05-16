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

task("commitAtRound", "Operator commits")
    .addParam("round", "The round to commit")
    .setAction(async ({ round }, { deployments, ethers, getNamedAccounts }) => {
        const { deployer } = await getNamedAccounts()
        console.log("EOA address:", deployer)
        const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinator")).address
        console.log("CRRRNGCoordinator address:", crrrngCoordinatorAddress)
        const crrngCoordinatorContract = await ethers.getContractAt(
            "CRRNGCoordinator",
            crrrngCoordinatorAddress,
        )
        const commitCount = (await crrngCoordinatorContract.getValuesAtRound(round)).count
        const signer = (await ethers.getSigners())[Number(commitCount)]
        let rand = crypto.getRandomValues(new Uint8Array(2048 / 8))
        const bytesHex = "0x" + rand.reduce((o, v) => o + ("00" + v.toString(16)).slice(-2), "")

        const commitData = {
            val: ethers.toBeHex(bytesHex, getLength(ethers.dataLength(bytesHex))),
            bitlen: getBitLenth2(bytesHex),
        }
        console.log(commitData)

        const tx = await crrngCoordinatorContract.connect(signer).commit(round, commitData)
        await tx.wait()
        console.log(`Operator ${commitCount} committed successfully`)
    })
