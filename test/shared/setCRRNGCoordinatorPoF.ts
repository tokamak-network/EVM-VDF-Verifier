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
import { ethers } from "hardhat"
interface BigNumber {
    val: BytesLike
    bitlen: BigNumberish
}

export const returnCoordinatorConstructorParams = () => {
    const coordinatorConstructorParams: {
        disputePeriod: BigNumberish
        minimumDepositAmount: BigNumberish
        avgL2GasUsed: BigNumberish
        avgL1GasUsed: BigNumberish
        premiumPercentage: BigNumberish
        penaltyPercentage: BigNumberish
        flatFee: BigNumberish
    } = {
        disputePeriod: 180n,
        minimumDepositAmount: ethers.parseEther("0.005"),
        avgL2GasUsed: 2101449n,
        avgL1GasUsed: 27824n,
        premiumPercentage: 0n,
        penaltyPercentage: 20n,
        flatFee: ethers.parseEther("0.001"),
    }
    return coordinatorConstructorParams
}

export const returnIntializeAndCommitAndRecoverParams = () => {
    const initializeParams = createInitializeParams()
    const commitParams = createCommitParams()
    const recoverParams = createRecoverPrarams()
    return { initializeParams, commitParams, recoverParams }
}

export const createInitializeParams = () => {
    let initializeParams: {
        v: BigNumber[]
        x: BigNumber
        y: BigNumber
    } = {
        v: [],
        x: { val: "0x0", bitlen: 0 },
        y: { val: "0x0", bitlen: 0 },
    }
    const delta: number = 9
    const testCaseJson = createCurrentTestCase()
    initializeParams.x = testCaseJson.setupProofs[0].x
    initializeParams.y = testCaseJson.setupProofs[0].y
    testCaseJson.setupProofs = testCaseJson.setupProofs?.slice(0, -(delta + 1))
    for (let i = 0; i < testCaseJson.setupProofs.length; i++)
        initializeParams.v.push(testCaseJson.setupProofs[i].v)
    return initializeParams
}

export const createRecoverPrarams = () => {
    let recoverParams: {
        round: number
        v: BigNumber[]
        x: BigNumber
        y: BigNumber
    } = {
        round: 0,
        v: [],
        x: { val: "0x0", bitlen: 0 },
        y: { val: "0x0", bitlen: 0 },
    }
    const delta: number = 9
    const testCaseJson = createCurrentTestCase()
    testCaseJson.recoveryProofs = testCaseJson.recoveryProofs?.slice(0, -(delta + 1))
    for (let i = 0; i < testCaseJson.recoveryProofs.length; i++)
        recoverParams.v.push(testCaseJson.recoveryProofs[i].v)
    recoverParams.x = testCaseJson.recoveryProofs[0].x
    recoverParams.y = testCaseJson.recoveryProofs[0].y
    return recoverParams
}

export const createCommitParams = () => {
    let commitParams: BigNumber[] = []
    const testCaseJson = createCurrentTestCase()
    for (let i = 0; i < testCaseJson.commitList.length; i++) {
        commitParams.push(testCaseJson.commitList[i])
    }
    return commitParams
}

const createCurrentTestCase = () => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(__dirname + "/TestCases/currentTestCase.json", "utf-8"),
    )
    return testCaseJson
}
