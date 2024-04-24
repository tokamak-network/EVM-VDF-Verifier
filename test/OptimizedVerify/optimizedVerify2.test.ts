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
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { assert } from "chai"
import { dataLength, toBeHex } from "ethers"
import fs from "fs"
import { ethers } from "hardhat"
import { TestCase } from "../shared/interfacesV2"

describe("Optimized Pietrzak Verification2", async () => {
    const DELTA_FILENAME = __dirname + "/../../data/delta4.json"
    const DELTA_8_FILENAME = __dirname + "/../../data/delta8.json"
    const deltaJsonData = {
        format: "delta, gasUsed, lambda, T",
        "2048": [] as any,
        "3072": [] as any,
    }
    const delta8JsonData = {
        format: "delta, gasUsed, lambda, T",
        "2048": [] as any,
        "3072": [] as any,
    }
    async function deployMinimal() {
        const minimalApplication = await ethers.deployContract("MinimalApplication")
        return minimalApplication
    }
    it("only delta, 2048", async () => {
        const minimalApplication = await loadFixture(deployMinimal)
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const data = []
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    const shift128TestCase = createshift128TestCaseNXYVT(
                        lambdas[i],
                        Ts[j],
                        jsonName,
                    )
                    if (delta > 0)
                        shift128TestCase.recoveryProofs = shift128TestCase.recoveryProofs.slice(
                            0,
                            -delta,
                        )
                    const gasUsedYesDelta =
                        await minimalApplication.verifyRecursiveHalvingProofNTXYVDeltaAppliedExternal.estimateGas(
                            shift128TestCase.recoveryProofs,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                        )
                    const trueOrFalse =
                        await minimalApplication.verifyRecursiveHalvingProofNTXYVDeltaAppliedExternal(
                            shift128TestCase.recoveryProofs,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                        )
                    assert(trueOrFalse)
                    data.push([delta.toString(), gasUsedYesDelta.toString(), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
        deltaJsonData["2048"] = data
        fs.writeFileSync(DELTA_FILENAME, JSON.stringify(deltaJsonData))
    })
    it("only delta, 3072", async () => {
        const minimalApplication = await loadFixture(deployMinimal)
        const lambdas: string[] = ["λ3072"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const data = []
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    const shift128TestCase = createshift128TestCaseNXYVT(
                        lambdas[i],
                        Ts[j],
                        jsonName,
                    )
                    if (delta > 0)
                        shift128TestCase.recoveryProofs = shift128TestCase.recoveryProofs.slice(
                            0,
                            -delta,
                        )
                    const gasUsedYesDelta =
                        await minimalApplication.verifyRecursiveHalvingProofNTXYVDeltaAppliedExternal.estimateGas(
                            shift128TestCase.recoveryProofs,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                        )
                    const trueOrFalse =
                        await minimalApplication.verifyRecursiveHalvingProofNTXYVDeltaAppliedExternal(
                            shift128TestCase.recoveryProofs,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                        )
                    assert(trueOrFalse)
                    data.push([delta.toString(), gasUsedYesDelta.toString(), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
        deltaJsonData["3072"] = data
        fs.writeFileSync(DELTA_FILENAME, JSON.stringify(deltaJsonData))
    })
    it("delta, every technique, T=20~25, 2048", async () => {
        const minimalApplication = await loadFixture(deployMinimal)
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const data = []
        console.log("dd")
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    const shift128TestCase = createshift128TestCaseNXYVT(
                        lambdas[i],
                        Ts[j],
                        jsonName,
                    )
                    const x = shift128TestCase.recoveryProofs[0].x
                    const y = shift128TestCase.recoveryProofs[0].y
                    if (delta > 0)
                        shift128TestCase.recoveryProofs = shift128TestCase.recoveryProofs.slice(
                            0,
                            -delta,
                        )

                    for (let i: number = 0; i < shift128TestCase.recoveryProofs.length; i++) {
                        delete shift128TestCase.recoveryProofs[i].n
                        delete shift128TestCase.recoveryProofs[i].T
                        delete shift128TestCase.recoveryProofs[i].x
                        delete shift128TestCase.recoveryProofs[i].y
                    }
                    let recoveryProofs = []
                    let imax = shift128TestCase.recoveryProofs.length - 1
                    for (let i: number = 0; i < imax; i++) {
                        recoveryProofs.push(shift128TestCase.recoveryProofs[i].v)
                    }
                    const gasUsedYesDelta =
                        await minimalApplication.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            shift128TestCase.T,
                        )
                    const trueOrFalse =
                        await minimalApplication.verifyRecursiveHalvingProofExternal(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            shift128TestCase.T,
                        )
                    assert(trueOrFalse)
                    data.push([delta.toString(), gasUsedYesDelta.toString(), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
        delta8JsonData["2048"] = data
        fs.writeFileSync(DELTA_8_FILENAME, JSON.stringify(delta8JsonData))
    })
    it("delta, every technique, T=20~25, 3072", async () => {
        const minimalApplication = await loadFixture(deployMinimal)
        const lambdas: string[] = ["λ3072"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const data = []
        console.log("dd")
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    const shift128TestCase = createshift128TestCaseNXYVT(
                        lambdas[i],
                        Ts[j],
                        jsonName,
                    )
                    const x = shift128TestCase.recoveryProofs[0].x
                    const y = shift128TestCase.recoveryProofs[0].y
                    if (delta > 0)
                        shift128TestCase.recoveryProofs = shift128TestCase.recoveryProofs.slice(
                            0,
                            -delta,
                        )

                    for (let i: number = 0; i < shift128TestCase.recoveryProofs.length; i++) {
                        delete shift128TestCase.recoveryProofs[i].n
                        delete shift128TestCase.recoveryProofs[i].T
                        delete shift128TestCase.recoveryProofs[i].x
                        delete shift128TestCase.recoveryProofs[i].y
                    }
                    let recoveryProofs = []
                    let imax = shift128TestCase.recoveryProofs.length - 1
                    for (let i: number = 0; i < imax; i++) {
                        recoveryProofs.push(shift128TestCase.recoveryProofs[i].v)
                    }
                    const gasUsedYesDelta =
                        await minimalApplication.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            shift128TestCase.T,
                        )
                    const trueOrFalse =
                        await minimalApplication.verifyRecursiveHalvingProofExternal(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            shift128TestCase.T,
                        )
                    assert(trueOrFalse)
                    data.push([delta.toString(), gasUsedYesDelta.toString(), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
        delta8JsonData["3072"] = data
        fs.writeFileSync(DELTA_8_FILENAME, JSON.stringify(delta8JsonData))
    })
})

interface BigNumber {
    val: string
    bitlen: number
}

const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(fs.readFileSync(__dirname + "/../shared/correct.json", "utf-8"))
    return testCaseJson
}

const createshift128TestCaseNXYVT = (lambd: string, T: string, jsonName: string) => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(
            __dirname + `/../shared/correctAlgorithmTestCase/${lambd}/${T}/${jsonName}.json`,
            "utf-8",
        ),
    )
    return testCaseJson
}

const createshift128TestCase = (lambd: string, T: string, jsonName: string): TestCase => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(
            __dirname + `/../shared/correctAlgorithmTestCase/${lambd}/${T}/${jsonName}.json`,
            "utf-8",
        ),
    )
    for (let i: number = 0; i < testCaseJson.setupProofs.length; i++) {
        delete testCaseJson.setupProofs[i].n
        delete testCaseJson.setupProofs[i].T
    }
    for (let i: number = 0; i < testCaseJson.recoveryProofs.length; i++) {
        delete testCaseJson.recoveryProofs[i].n
        delete testCaseJson.recoveryProofs[i].T
    }
    return testCaseJson
}

const createshift128TestCaseSkippingN = (lambd: string, T: string, jsonName: string) => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(
            __dirname + `/../shared/correctAlgorithmTestCase/${lambd}/${T}/${jsonName}.json`,
            "utf-8",
        ),
    )
    for (let i: number = 0; i < testCaseJson.setupProofs.length; i++) {
        delete testCaseJson.setupProofs[i].n
    }
    for (let i: number = 0; i < testCaseJson.recoveryProofs.length; i++) {
        delete testCaseJson.recoveryProofs[i].n
    }
    return testCaseJson
}

const createshift128TestCaseSkippingT = (lambd: string, T: string, jsonName: string) => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(
            __dirname + `/../shared/correctAlgorithmTestCase/${lambd}/${T}/${jsonName}.json`,
            "utf-8",
        ),
    )
    for (let i: number = 0; i < testCaseJson.setupProofs.length; i++) {
        delete testCaseJson.setupProofs[i].T
    }
    for (let i: number = 0; i < testCaseJson.recoveryProofs.length; i++) {
        delete testCaseJson.recoveryProofs[i].T
    }
    return testCaseJson
}

const getBitLenth = (num: bigint): number => {
    return num.toString(2).length
}

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}

interface OptimizedTestCase {
    x: BigNumber
    y: BigNumber
    pi: BigNumber[]
    tau: number
    delta: number
    n: BigNumber
}
