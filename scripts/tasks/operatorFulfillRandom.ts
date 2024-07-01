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
import fs from "fs"
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

task("fulfillAtRound", "Operator fulfillRandomWord")
    .addParam("round", "The round to fulfill")
    .setAction(async ({ round }, { deployments, ethers, getNamedAccounts }) => {
        const { deployer } = await getNamedAccounts()
        console.log("EOA address:", deployer)
        const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinatorPoF")).address
        console.log("CRRRNGCoordinator address:", crrrngCoordinatorAddress)
        const crrngCoordinatorContract = await ethers.getContractAt(
            "CRRNGCoordinatorPoF",
            crrrngCoordinatorAddress,
        )
        console.log("Fulfill...")
        const tx = await crrngCoordinatorContract.fulfillRandomness(round)
        const receipt = await tx.wait()
        console.log("Transaction receipt", receipt)
        console.log("Fulfilled successfully")
        console.log("----------------------")
    })
const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(fs.readFileSync(__dirname + "/../recover.json", "utf-8"))
    return testCaseJson
}
