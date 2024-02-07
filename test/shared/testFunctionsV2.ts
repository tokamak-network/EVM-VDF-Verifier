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

import { TestCase, TestCaseWithTInProof, TestCaseWithNTInProof } from "./interfacesV2"
import fs from "fs"
import { LAMDAs, Ts, JsonNames } from "./interfacesV2"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { ethers } from "hardhat"
import { ContractFactory } from "ethers"
import {
    CommitRevealRecoverRNGTest,
    CommitRevealRecoverRNG,
    CRRWithTInProof,
    CRRWithNTInProof,
    CRRWithNTInProofVerifyAndProcessSeparate,
    CRRWithNTInProofVerifyAndProcessSeparateFileSeparate,
} from "../../typechain-types"

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
                    delete testCaseJson.setupProofs[l].T
                }
                for (let l: number = 0; l < testCaseJson.recoveryProofs.length; l++) {
                    delete testCaseJson.recoveryProofs[l].n
                    delete testCaseJson.recoveryProofs[l].T
                }
                result[i][j].push(testCaseJson as TestCase)
            }
        }
    }
    return result
}

export const createSimpleTestCaseWithT = (): TestCaseWithTInProof[][][] => {
    const result: TestCaseWithTInProof[][][] = []
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
                result[i][j].push(testCaseJson as TestCaseWithTInProof)
            }
        }
    }
    return result
}

export const createSimpleTestCaseWithNT = (): TestCaseWithNTInProof[][][] => {
    const result: TestCaseWithNTInProof[][][] = []
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
                result[i][j].push(testCaseJson as TestCaseWithNTInProof)
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

export const deployCRRWithTInProofFixture = async () => {
    const CRRWithTInProof: ContractFactory = await ethers.getContractFactory("CRRWithTInProof")
    let commitRevealRecoverRNG: CRRWithTInProof =
        (await CRRWithTInProof.deploy()) as CRRWithTInProof
    commitRevealRecoverRNG = await commitRevealRecoverRNG.waitForDeployment()
    let tx = commitRevealRecoverRNG.deploymentTransaction()
    let receipt = await tx?.wait()
    return { commitRevealRecoverRNG, receipt }
}

export const deployCRRWithNTInProofFixture = async () => {
    const CRRWithNTInProof: ContractFactory = await ethers.getContractFactory("CRRWithNTInProof")
    let commitRevealRecoverRNG: CRRWithNTInProof =
        (await CRRWithNTInProof.deploy()) as CRRWithNTInProof
    commitRevealRecoverRNG = await commitRevealRecoverRNG.waitForDeployment()
    let tx = commitRevealRecoverRNG.deploymentTransaction()
    let receipt = await tx?.wait()
    return { commitRevealRecoverRNG, receipt }
}

export const deployCRRWithNTInProofVerifyAndProcessSeparateFixture = async () => {
    const CRRWithNTInProofVerifyAndProcessSeparate: ContractFactory =
        await ethers.getContractFactory("CRRWithNTInProofVerifyAndProcessSeparate")
    let commitRevealRecoverRNG: CRRWithNTInProofVerifyAndProcessSeparate =
        (await CRRWithNTInProofVerifyAndProcessSeparate.deploy()) as CRRWithNTInProofVerifyAndProcessSeparate
    commitRevealRecoverRNG = await commitRevealRecoverRNG.waitForDeployment()
    let tx = commitRevealRecoverRNG.deploymentTransaction()
    let receipt = await tx?.wait()
    return { commitRevealRecoverRNG, receipt }
}

export const deployCRRWithNTInProofVerifyAndProcessSeparateFileSeparateFixture = async () => {
    const CRRWithNTInProofVerifyAndProcessSeparateFileSeparate: ContractFactory =
        await ethers.getContractFactory("CRRWithNTInProofVerifyAndProcessSeparateFileSeparate")
    let commitRevealRecoverRNG: CRRWithNTInProofVerifyAndProcessSeparateFileSeparate =
        (await CRRWithNTInProofVerifyAndProcessSeparateFileSeparate.deploy()) as CRRWithNTInProofVerifyAndProcessSeparateFileSeparate
    commitRevealRecoverRNG = await commitRevealRecoverRNG.waitForDeployment()
    let tx = commitRevealRecoverRNG.deploymentTransaction()
    let receipt = await tx?.wait()
    return { commitRevealRecoverRNG, receipt }
}

export const deployCommitRevealRecoverRNGFixture = async () => {
    const CommitRevealRecoverRNG: ContractFactory =
        await ethers.getContractFactory("CommitRevealRecoverRNG")
    let commitRevealRecoverRNG: CommitRevealRecoverRNG =
        (await CommitRevealRecoverRNG.deploy()) as CommitRevealRecoverRNG
    commitRevealRecoverRNG = await commitRevealRecoverRNG.waitForDeployment()
    let tx = commitRevealRecoverRNG.deploymentTransaction()
    let receipt = await tx?.wait()
    return { commitRevealRecoverRNG, receipt }
}
