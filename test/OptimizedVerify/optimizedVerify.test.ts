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
import { assert } from "chai"
import { dataLength, toBeHex } from "ethers"
import fs from "fs"
import { ethers } from "hardhat"
import { MinimalApplication } from "../../typechain-types"
import { TestCase } from "../shared/interfacesV2"

describe("Optimized Pietrzak Verification", async () => {
    let minimalApplication: MinimalApplication
    //   it("operation compare", async function () {
    //       let x = 5n
    //       const n = 19n
    //       const delta = 4n
    //       const firstResult = x ** (2n ** (2n ** delta)) % n

    //       let thirdResult = x ** (2n ** (2n ** delta) % n) % n

    //       x = x ** 2n % n
    //       let i = 1n
    //       while (i++ < 2n ** delta) {
    //           x = x ** 2n % n
    //       }
    //       const secondResult = x
    //       console.log(firstResult, secondResult, thirdResult)
    //   })
    it("verifyRecursiveHalvingProofNTXYVInProof", async function () {
        const lambdas: string[] = ["λ1024", "λ2048", "λ3072"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const proofLastIndex: number[] = [20, 21, 22, 23, 24, 25]
        const jsonName: string = "one"
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let i: number = 0; i < lambdas.length; i++) {
            for (let j: number = 0; j < Ts.length; j++) {
                minimalApplication =
                    (await minimalApplicationFactory.deploy()) as MinimalApplication
                await minimalApplication.waitForDeployment()
                const shift128TestCase = createshift128TestCaseNXYVT(lambdas[i], Ts[j], jsonName)
                const gasUsed =
                    await minimalApplication.verifyRecursiveHalvingProofNTXYVInProofExternal.estimateGas(
                        shift128TestCase.recoveryProofs,
                    )
                const trueOrFalse =
                    await minimalApplication.verifyRecursiveHalvingProofNTXYVInProofExternal(
                        shift128TestCase.recoveryProofs,
                    )
                assert(trueOrFalse)
                data.push([Number(gasUsed), lambdas[i], Ts[j]])
            }
        }
        console.log(data)
    })
    it("verifyRecursiveHalvingProofNTXYVDeltaApplied", async function () {
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^22", "T2^23", "T2^24"]
        const proofLastIndex: number[] = [22, 23, 24]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    minimalApplication =
                        (await minimalApplicationFactory.deploy()) as MinimalApplication
                    await minimalApplication.waitForDeployment()
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
                    data.push([delta, Number(gasUsedYesDelta), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
    })
    it("verifyRecursiveHalvingProofNTXYVDeltaRepeated", async function () {
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^22", "T2^23", "T2^24"]
        const proofLastIndex: number[] = [22, 23, 24]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    minimalApplication =
                        (await minimalApplicationFactory.deploy()) as MinimalApplication
                    await minimalApplication.waitForDeployment()
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
                        await minimalApplication.verifyRecursiveHalvingProofNTXYVDeltaRepeatedExternal.estimateGas(
                            shift128TestCase.recoveryProofs,
                            2 ** delta,
                        )
                    const trueOrFalse =
                        await minimalApplication.verifyRecursiveHalvingProofNTXYVDeltaRepeatedExternal(
                            shift128TestCase.recoveryProofs,
                            2 ** delta,
                        )
                    assert(trueOrFalse)
                    data.push([delta, Number(gasUsedYesDelta), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
    })
    it("verifyRecursiveHalvingProofSkippingN", async function () {
        const lambdas: string[] = ["λ1024", "λ2048", "λ3072"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const proofLastIndex: number[] = [20, 21, 22, 23, 24, 25]
        const jsonName: string = "one"
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let i: number = 0; i < lambdas.length; i++) {
            for (let j: number = 0; j < Ts.length; j++) {
                minimalApplication =
                    (await minimalApplicationFactory.deploy()) as MinimalApplication
                await minimalApplication.waitForDeployment()
                const shift128TestCase = createshift128TestCaseSkippingN(
                    lambdas[i],
                    Ts[j],
                    jsonName,
                )
                const gasUsedYesDelta =
                    await minimalApplication.verifyRecursiveHalvingProofSkippingNExternal.estimateGas(
                        shift128TestCase.n,
                        shift128TestCase.recoveryProofs,
                    )
                const trueOrFalse =
                    await minimalApplication.verifyRecursiveHalvingProofSkippingNExternal(
                        shift128TestCase.n,
                        shift128TestCase.recoveryProofs,
                    )
                assert(trueOrFalse)
                data.push([Number(gasUsedYesDelta), lambdas[i], Ts[j]])
            }
        }
        console.log(data)
    })
    it("verifyRecursiveHalvingProofSkippingTXY", async function () {
        const lambdas: string[] = ["λ1024", "λ2048", "λ3072"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const proofLastIndex: number[] = [20, 21, 22, 23, 24, 25]
        const jsonName: string = "one"
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let i: number = 0; i < lambdas.length; i++) {
            for (let j: number = 0; j < Ts.length; j++) {
                minimalApplication =
                    (await minimalApplicationFactory.deploy()) as MinimalApplication
                await minimalApplication.waitForDeployment()
                const shift128TestCase = createshift128TestCaseSkippingT(
                    lambdas[i],
                    Ts[j],
                    jsonName,
                )
                const x = shift128TestCase.recoveryProofs[0].x
                const y = shift128TestCase.recoveryProofs[0].y
                for (let i: number = 0; i < shift128TestCase.recoveryProofs.length; i++) {
                    delete shift128TestCase.recoveryProofs[i].x
                    delete shift128TestCase.recoveryProofs[i].y
                }
                const gasUsedYesDelta =
                    await minimalApplication.verifyRecursiveHalvingProofSkippingTXYExternal.estimateGas(
                        shift128TestCase.recoveryProofs,
                        x,
                        y,
                        shift128TestCase.T,
                    )
                const trueOrFalse =
                    await minimalApplication.verifyRecursiveHalvingProofSkippingTXYExternal(
                        shift128TestCase.recoveryProofs,
                        x,
                        y,
                        shift128TestCase.T,
                    )
                assert(trueOrFalse)
                //console.log(trueOrFalse)
                data.push([Number(gasUsedYesDelta), lambdas[i], Ts[j]])
                console.log("recoveryProofs Length", shift128TestCase.recoveryProofs.length)
                console.log("Gas Used =", gasUsedYesDelta, lambdas[i], Ts[j])
            }
        }
        console.log(data)
    })
    it("verifyRecursiveHalvingProofWithoutDelta Shortening Proof Size", async function () {
        const lambdas: string[] = ["λ1024", "λ2048", "λ3072"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const proofLastIndex: number[] = [20, 21, 22, 23, 24, 25]
        const jsonName: string = "one"
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let i: number = 0; i < lambdas.length; i++) {
            for (let j: number = 0; j < Ts.length; j++) {
                minimalApplication =
                    (await minimalApplicationFactory.deploy()) as MinimalApplication
                await minimalApplication.waitForDeployment()
                const shift128TestCase = createshift128TestCaseNXYVT(lambdas[i], Ts[j], jsonName)
                const x = shift128TestCase.recoveryProofs[0].x
                const y = shift128TestCase.recoveryProofs[0].y
                for (let i: number = 0; i < shift128TestCase.recoveryProofs.length; i++) {
                    delete shift128TestCase.recoveryProofs[i].x
                    delete shift128TestCase.recoveryProofs[i].y
                    delete shift128TestCase.recoveryProofs[i].n
                    delete shift128TestCase.recoveryProofs[i].T
                }
                let recoveryProofs = []
                let imax = shift128TestCase.recoveryProofs.length - 1
                for (let i: number = 0; i < imax; i++) {
                    recoveryProofs.push(shift128TestCase.recoveryProofs[i].v)
                }
                const gasUsedYesDelta =
                    await minimalApplication.verifyRecursiveHalvingProofWithoutDeltaExternal.estimateGas(
                        recoveryProofs,
                        x,
                        y,
                        shift128TestCase.n,
                        shift128TestCase.T,
                    )
                const trueOrFalse =
                    await minimalApplication.verifyRecursiveHalvingProofWithoutDeltaExternal(
                        recoveryProofs,
                        x,
                        y,
                        shift128TestCase.n,
                        shift128TestCase.T,
                    )
                assert(trueOrFalse)
                data.push([Number(gasUsedYesDelta), lambdas[i], Ts[j]])
                console.log("recoveryProofs Length", shift128TestCase.recoveryProofs.length)
                console.log("Gas Used =", gasUsedYesDelta, lambdas[i], Ts[j])
            }
        }
        console.log(data)
    })
    it("verifyRecursiveHalvingProof 2048bits, delta 22~24", async function () {
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^22", "T2^23", "T2^24"]
        const proofLastIndex: number[] = [22, 23, 24]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    minimalApplication =
                        (await minimalApplicationFactory.deploy()) as MinimalApplication
                    await minimalApplication.waitForDeployment()
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
                    data.push([delta, Number(gasUsedYesDelta), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
    })
    it("verifyRecursiveHalvingProof", async function () {
        const lambdas: string[] = ["λ1024", "λ2048", "λ3072"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const proofLastIndex: number[] = [20, 21, 22, 23, 24, 25]
        const jsonName: string = "one"
        const deltas: number[] = [8, 9, 10]
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    minimalApplication =
                        (await minimalApplicationFactory.deploy()) as MinimalApplication
                    await minimalApplication.waitForDeployment()
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
                    data.push([delta, Number(gasUsedYesDelta), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
    })
    it("encode function data", async function () {
        const lambdas: string[] = ["λ1024", "λ2048", "λ3072"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const proofLastIndex: number[] = [20, 21, 22, 23, 24, 25]
        const jsonName: string = "one"
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let i: number = 0; i < lambdas.length; i++) {
            for (let j: number = 0; j < Ts.length; j++) {
                minimalApplication =
                    (await minimalApplicationFactory.deploy()) as MinimalApplication
                await minimalApplication.waitForDeployment()
                const shift128TestCase = createshift128TestCaseNXYVT(lambdas[i], Ts[j], jsonName)
                //   const gasUsed =
                //       await minimalApplication.verifyRecursiveHalvingProofNTXYVInProofExternal.estimateGas(
                //           shift128TestCase.recoveryProofs,
                //       )
                //   const trueOrFalse =
                //       await minimalApplication.verifyRecursiveHalvingProofNTXYVInProofExternal(
                //           shift128TestCase.recoveryProofs,
                //       )
                //   assert(trueOrFalse)
                const itfce = minimalApplication.interface
                const transactionrawdata = itfce.encodeFunctionData(
                    "verifyRecursiveHalvingProofNTXYVInProofExternal",
                    [shift128TestCase.recoveryProofs],
                )
                const sizeInBytes = (transactionrawdata.length - 2) / 2
                const sizeInKb = sizeInBytes / 1024
                data.push([sizeInKb, lambdas[i], Ts[j]])
            }
        }
        console.log(data)
    })
    it("encode function data2", async function () {
        const lambdas: string[] = ["λ1024", "λ2048", "λ3072"]
        const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
        const proofLastIndex: number[] = [20, 21, 22, 23, 24, 25]
        const jsonName: string = "one"
        const deltas: number[] = [8, 9, 10]
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        const data = []
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    minimalApplication =
                        (await minimalApplicationFactory.deploy()) as MinimalApplication
                    await minimalApplication.waitForDeployment()
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
                    const itfce = minimalApplication.interface
                    const transactionrawdata = itfce.encodeFunctionData(
                        "verifyRecursiveHalvingProofExternal",
                        [
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            shift128TestCase.T,
                        ],
                    )

                    //console.log(transactionrawdata)
                    const sizeInBytes = (transactionrawdata.length - 2) / 2
                    const sizeInKb = sizeInBytes / 1024

                    data.push([delta, sizeInKb, lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
    })
    it("test correct algorithm version", async function () {
        const minimalApplicationFactory = await ethers.getContractFactory("MinimalApplication")
        minimalApplication = (await minimalApplicationFactory.deploy()) as MinimalApplication
        await minimalApplication.waitForDeployment()
        const testCase = createCorrectAlgorithmVersionTestCase()
        const x = testCase.recoveryProofs[0].x
        const y = testCase.recoveryProofs[0].y
        const delta = 9
        console.log(testCase.recoveryProofs.length)
        testCase.recoveryProofs = testCase.recoveryProofs.slice(0, -(delta + 1))
        for (let i: number = 0; i < testCase.recoveryProofs.length; i++) {
            delete testCase.recoveryProofs[i].n
            delete testCase.recoveryProofs[i].T
            delete testCase.recoveryProofs[i].x
            delete testCase.recoveryProofs[i].y
        }
        let recoveryProofs = []
        for (let i: number = 0; i < testCase.recoveryProofs.length; i++) {
            recoveryProofs.push(testCase.recoveryProofs[i].v)
        }
        console.log(recoveryProofs.length, delta)
        const gasUsed =
            await minimalApplication.verifyRecursiveHalvingProofCorrectExternal.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
        const trueOrFalse = await minimalApplication.verifyRecursiveHalvingProofCorrectExternal(
            recoveryProofs,
            x,
            y,
            testCase.n,
            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
            2 ** delta,
            testCase.T,
        )
        assert(trueOrFalse)
        console.log(gasUsed)
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
