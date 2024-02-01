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

import { TestCase } from "./interfacesV2"
import fs from "fs"
import { LAMDAs, Ts, JsonNames } from "./interfacesV2"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { ethers } from "hardhat"
import { ContractFactory } from "ethers"
import { CommitRevealRecoverRNGTest } from "../../typechain-types"

export const createTestCase = (): TestCase[][][] => {
    const result: TestCase[][][] = []
    for (let i: number = 0; i < LAMDAs.length; i++) {
        result.push([])
        for (let j: number = 0; j < Ts.length; j++) {
            result[i].push([])
            for (let k: number = 0; k < JsonNames.length; k++) {
                const testCaseJson = JSON.parse(
                    fs.readFileSync(
                        __dirname + `/testCases/${LAMDAs[i]}/${Ts[j]}/${JsonNames[k]}.json`,
                        "utf8",
                    ),
                )
                for (let l: number = 0; l < testCaseJson.setupProofs.length; l++) {
                    delete testCaseJson.setupProofs[l].n
                }
                for (let l: number = 0; l < testCaseJson.recoveryProofs.length; l++) {
                    delete testCaseJson.recoveryProofs[l].n
                }
                result[i][j].push(testCaseJson as TestCase)
            }
        }
    }
    return result
}

export const createSimpleTestCase = (): TestCase[][][] => {
    const result: TestCase[][][] = []
    for (let i: number = 0; i < LAMDAs.length; i++) {
        result.push([])
        for (let j: number = 0; j < Ts.length; j++) {
            result[i].push([])
            for (let k: number = 0; k < 1; k++) {
                const testCaseJson = JSON.parse(
                    fs.readFileSync(
                        __dirname + `/testCases/${LAMDAs[i]}/${Ts[j]}/${JsonNames[k]}.json`,
                        "utf8",
                    ),
                )
                for (let l: number = 0; l < testCaseJson.setupProofs.length; l++) {
                    delete testCaseJson.setupProofs[l].n
                }
                for (let l: number = 0; l < testCaseJson.recoveryProofs.length; l++) {
                    delete testCaseJson.recoveryProofs[l].n
                }
                result[i][j].push(testCaseJson as TestCase)
            }
        }
    }
    return result
}

export const deployCommitRevealRecoverRNGTestFixture = async () => {
    const CommitRevealRecoverRNG: ContractFactory = await ethers.getContractFactory(
        "CommitRevealRecoverRNGTest",
    )
    let commitRevealRecoverRNG: CommitRevealRecoverRNGTest =
        (await CommitRevealRecoverRNG.deploy()) as CommitRevealRecoverRNGTest
    commitRevealRecoverRNG = await commitRevealRecoverRNG.waitForDeployment()
    let tx = commitRevealRecoverRNG.deploymentTransaction()
    let receipt = await tx?.wait()
    return { commitRevealRecoverRNG, receipt }
}
