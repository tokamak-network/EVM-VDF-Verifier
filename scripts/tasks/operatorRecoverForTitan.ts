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

task("recoverAtRoundForTitan", "Operator recover For Titan")
    .addParam("round", "The round to recover")
    .setAction(async ({ round }, { deployments, ethers, getNamedAccounts }) => {
        const { deployer } = await getNamedAccounts()
        console.log("EOA address:", deployer)
        const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinatorPoFForTitan"))
            .address
        console.log("CRRRNGCoordinator address:", crrrngCoordinatorAddress)
        const crrngCoordinatorContract = await ethers.getContractAt(
            "CRRNGCoordinatorPoFForTitan",
            crrrngCoordinatorAddress,
        )
        const testCaseJson = createCorrectAlgorithmVersionTestCase()
        const delta: number = 9
        let recoverParams: {
            round: BigNumberish
            v: BigNumber[]
            x: BigNumber
            y: BigNumber
        } = {
            round: round,
            v: [],
            x: { val: "0x0", bitlen: 0 },
            y: { val: "0x0", bitlen: 0 },
        }
        recoverParams.x = testCaseJson.recoveryProofs[0].x
        recoverParams.y = testCaseJson.recoveryProofs[0].y
        if (delta > 0) {
            testCaseJson.recoveryProofs = testCaseJson.recoveryProofs?.slice(0, -(delta + 1))
        }
        for (let i = 0; i < testCaseJson.recoveryProofs.length; i++) {
            recoverParams.v.push(testCaseJson.recoveryProofs[i].v)
        }

        console.log("Recovering...")
        const tx = await crrngCoordinatorContract.recover(recoverParams.round, recoverParams.y)
        const receipt = await tx.wait()
        console.log("Transaction receipt", receipt)
        console.log("Recovered")
        console.log("----------------------")
    })
const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(fs.readFileSync(__dirname + "/../recover.json", "utf-8"))
    return testCaseJson
}
