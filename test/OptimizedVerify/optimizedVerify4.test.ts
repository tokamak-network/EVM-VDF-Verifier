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
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { assert } from "chai"
import fs from "fs"
import { ethers } from "hardhat"

describe("Optimized Pietrzak Verification4", () => {
    const DELTA_8_FILENAME = __dirname + "/../../data/delta8.json"
    const DELTA_T22_24_FILENAME = __dirname + "/../../data/deltaT22_24.json"
    const delta8JsonData = {
        format: "delta, gasUsed, lambda, T",
        "2048": [] as any,
        "3072": [] as any,
    }
    const deltaT22_24JsonData = {
        format: "delta, gasUsed, lambda, T",
        "2048": [] as any,
        "3072": [] as any,
    }
    // async function deployVerifyRecursiveHalvingProofAlgorithm() {
    //     const verifyRecursiveHalvingProofAlgorithm = await ethers.deployContract(
    //         "VerifyRecursiveHalvingProofAlgorithm",
    //     )
    //     return verifyRecursiveHalvingProofAlgorithm
    // }
    async function deployVerifyRecursiveHalvingProofAlgorithm2() {
        const verifyRecursiveHalvingProofAlgorithm2 = await ethers.deployContract(
            "VerifyRecursiveHalvingProofAlgorithm2",
        )
        return verifyRecursiveHalvingProofAlgorithm2
    }
    // it("algorithm 1 vs 2 3072", async () => {
    //     const verifyRecursiveHalvingProofAlgorithm = await loadFixture(
    //         deployVerifyRecursiveHalvingProofAlgorithm,
    //     )
    //     const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
    //         deployVerifyRecursiveHalvingProofAlgorithm2,
    //     )
    //     const lambdas: string[] = ["λ3072"]
    //     const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
    //     const jsonName: string = "one"
    //     const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    //     const data = []
    //     for (let k: number = 0; k < deltas.length; k++) {
    //         const delta: number = deltas[k]
    //         for (let i: number = 0; i < lambdas.length; i++) {
    //             for (let j: number = 0; j < Ts.length; j++) {
    //                 const shift128TestCase = createshift128TestCaseNXYVT(
    //                     lambdas[i],
    //                     Ts[j],
    //                     jsonName,
    //                 )
    //                 const x = shift128TestCase.recoveryProofs[0].x
    //                 const y = shift128TestCase.recoveryProofs[0].y
    //                 if (delta > 0)
    //                     shift128TestCase.recoveryProofs = shift128TestCase.recoveryProofs.slice(
    //                         0,
    //                         -delta,
    //                     )
    //                 for (let i: number = 0; i < shift128TestCase.recoveryProofs.length; i++) {
    //                     delete shift128TestCase.recoveryProofs[i].n
    //                     delete shift128TestCase.recoveryProofs[i].T
    //                     delete shift128TestCase.recoveryProofs[i].x
    //                     delete shift128TestCase.recoveryProofs[i].y
    //                 }
    //                 let recoveryProofs = []
    //                 let imax = shift128TestCase.recoveryProofs.length - 1
    //                 for (let i: number = 0; i < imax; i++) {
    //                     recoveryProofs.push(shift128TestCase.recoveryProofs[i].v)
    //                 }
    //                 const calldataAlgorithm1 =
    //                     verifyRecursiveHalvingProofAlgorithm.interface.encodeFunctionData(
    //                         "verifyRecursiveHalvingProof",
    //                         [recoveryProofs, x, y, shift128TestCase.n, delta, shift128TestCase.T],
    //                     )
    //                 const gasUsedAlgorithm1 =
    //                     await verifyRecursiveHalvingProofAlgorithm.verifyRecursiveHalvingProof.estimateGas(
    //                         recoveryProofs,
    //                         x,
    //                         y,
    //                         shift128TestCase.n,
    //                         delta,
    //                         shift128TestCase.T,
    //                     )
    //                 const trueOrfalse1 =
    //                     await verifyRecursiveHalvingProofAlgorithm.verifyRecursiveHalvingProof(
    //                         recoveryProofs,
    //                         x,
    //                         y,
    //                         shift128TestCase.n,
    //                         delta,
    //                         shift128TestCase.T,
    //                     )
    //                 assert(trueOrfalse1)
    //                 const calldataAlgorithm2 =
    //                     verifyRecursiveHalvingProofAlgorithm2.interface.encodeFunctionData(
    //                         "verifyRecursiveHalvingProof",
    //                         [recoveryProofs, x, y, shift128TestCase.n, delta, shift128TestCase.T],
    //                     )
    //                 const gasUsedAlgorithm2 =
    //                     await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
    //                         recoveryProofs,
    //                         x,
    //                         y,
    //                         shift128TestCase.n,
    //                         delta,
    //                         shift128TestCase.T,
    //                     )
    //                 const trueOrfalse2 =
    //                     await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof(
    //                         recoveryProofs,
    //                         x,
    //                         y,
    //                         shift128TestCase.n,
    //                         delta,
    //                         shift128TestCase.T,
    //                     )
    //                 assert(trueOrfalse2)
    //                 data.push([
    //                     delta.toString(),
    //                     lambdas[i],
    //                     Ts[j],
    //                     gasUsedAlgorithm1.toString(),
    //                     gasUsedAlgorithm2.toString(),
    //                     (gasUsedAlgorithm2 - gasUsedAlgorithm1).toString(),
    //                     (calldataAlgorithm1.length / 2).toString(),
    //                     (calldataAlgorithm2.length / 2).toString(),
    //                     (calldataAlgorithm2.length - calldataAlgorithm1.length).toString(),
    //                 ])
    //             }
    //         }
    //     }
    //     console.log(
    //         "[delta, lambda, T, gasUsed1, gasUsed2, 2-1 gasUsed, calldataInBytes1, calldataInBytes2, 2-1 calldata]",
    //     )
    //     console.table(data)
    // })
    // it("algorithm 1 vs 2 2048", async () => {
    //     const verifyRecursiveHalvingProofAlgorithm = await loadFixture(
    //         deployVerifyRecursiveHalvingProofAlgorithm,
    //     )
    //     const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
    //         deployVerifyRecursiveHalvingProofAlgorithm2,
    //     )
    //     const lambdas: string[] = ["λ2048"]
    //     const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
    //     const jsonName: string = "one"
    //     const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
    //     const data = []
    //     for (let k: number = 0; k < deltas.length; k++) {
    //         const delta: number = deltas[k]
    //         for (let i: number = 0; i < lambdas.length; i++) {
    //             for (let j: number = 0; j < Ts.length; j++) {
    //                 const shift128TestCase = createshift128TestCaseNXYVT(
    //                     lambdas[i],
    //                     Ts[j],
    //                     jsonName,
    //                 )
    //                 const x = shift128TestCase.recoveryProofs[0].x
    //                 const y = shift128TestCase.recoveryProofs[0].y
    //                 if (delta > 0)
    //                     shift128TestCase.recoveryProofs = shift128TestCase.recoveryProofs.slice(
    //                         0,
    //                         -delta,
    //                     )
    //                 for (let i: number = 0; i < shift128TestCase.recoveryProofs.length; i++) {
    //                     delete shift128TestCase.recoveryProofs[i].n
    //                     delete shift128TestCase.recoveryProofs[i].T
    //                     delete shift128TestCase.recoveryProofs[i].x
    //                     delete shift128TestCase.recoveryProofs[i].y
    //                 }
    //                 let recoveryProofs = []
    //                 let imax = shift128TestCase.recoveryProofs.length - 1
    //                 for (let i: number = 0; i < imax; i++) {
    //                     recoveryProofs.push(shift128TestCase.recoveryProofs[i].v)
    //                 }
    //                 const calldataAlgorithm1 =
    //                     verifyRecursiveHalvingProofAlgorithm.interface.encodeFunctionData(
    //                         "verifyRecursiveHalvingProof",
    //                         [recoveryProofs, x, y, shift128TestCase.n, delta, shift128TestCase.T],
    //                     )
    //                 const gasUsedAlgorithm1 =
    //                     await verifyRecursiveHalvingProofAlgorithm.verifyRecursiveHalvingProof.estimateGas(
    //                         recoveryProofs,
    //                         x,
    //                         y,
    //                         shift128TestCase.n,
    //                         delta,
    //                         shift128TestCase.T,
    //                     )
    //                 const trueOrfalse1 =
    //                     await verifyRecursiveHalvingProofAlgorithm.verifyRecursiveHalvingProof(
    //                         recoveryProofs,
    //                         x,
    //                         y,
    //                         shift128TestCase.n,
    //                         delta,
    //                         shift128TestCase.T,
    //                     )
    //                 assert(trueOrfalse1)
    //                 const calldataAlgorithm2 =
    //                     verifyRecursiveHalvingProofAlgorithm2.interface.encodeFunctionData(
    //                         "verifyRecursiveHalvingProof",
    //                         [recoveryProofs, x, y, shift128TestCase.n, delta, shift128TestCase.T],
    //                     )
    //                 const gasUsedAlgorithm2 =
    //                     await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
    //                         recoveryProofs,
    //                         x,
    //                         y,
    //                         shift128TestCase.n,
    //                         delta,
    //                         shift128TestCase.T,
    //                     )
    //                 const trueOrfalse2 =
    //                     await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof(
    //                         recoveryProofs,
    //                         x,
    //                         y,
    //                         shift128TestCase.n,
    //                         delta,
    //                         shift128TestCase.T,
    //                     )
    //                 assert(trueOrfalse2)
    //                 data.push([
    //                     delta.toString(),
    //                     lambdas[i],
    //                     Ts[j],
    //                     gasUsedAlgorithm1.toString(),
    //                     gasUsedAlgorithm2.toString(),
    //                     (gasUsedAlgorithm2 - gasUsedAlgorithm1).toString(),
    //                     (calldataAlgorithm1.length / 2).toString(),
    //                     (calldataAlgorithm2.length / 2).toString(),
    //                     (calldataAlgorithm2.length - calldataAlgorithm1.length).toString(),
    //                 ])
    //             }
    //         }
    //     }
    //     console.log(
    //         "[delta, lambda, T, gasUsed1, gasUsed2, 2-1 gasUsed, calldataInBytes1, calldataInBytes2, 2-1 calldata]",
    //     )
    //     console.table(data)
    // })
    it("delta BigNumber gasUsed 2048 algorithm", async () => {
        const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2,
        )
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
                    const trueOrfalse2 =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            delta,
                            shift128TestCase.T,
                        )
                    assert(trueOrfalse2)
                    const calldata =
                        verifyRecursiveHalvingProofAlgorithm2.interface.encodeFunctionData(
                            "verifyRecursiveHalvingProof",
                            [recoveryProofs, x, y, shift128TestCase.n, delta, shift128TestCase.T],
                        )
                    const gasUsedAlgorithm2 =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            delta,
                            shift128TestCase.T,
                        )
                    data.push([
                        delta.toString(),
                        gasUsedAlgorithm2.toString(),
                        (calldata.length / 2).toString(),
                        lambdas[i],
                        Ts[j],
                    ])
                }
            }
        }
        console.log(data)
        delta8JsonData["2048"] = data
        fs.writeFileSync(DELTA_8_FILENAME, JSON.stringify(delta8JsonData, null, 2))
    })
    it("delta BigNumber gasUsed 3072 algorithm", async () => {
        const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2,
        )
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
                    const trueOrfalse2 =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            delta,
                            shift128TestCase.T,
                        )
                    assert(trueOrfalse2)
                    const gasUsedAlgorithm2 =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            delta,
                            shift128TestCase.T,
                        )
                    const calldata =
                        verifyRecursiveHalvingProofAlgorithm2.interface.encodeFunctionData(
                            "verifyRecursiveHalvingProof",
                            [recoveryProofs, x, y, shift128TestCase.n, delta, shift128TestCase.T],
                        )
                    data.push([
                        delta.toString(),
                        gasUsedAlgorithm2.toString(),
                        (calldata.length / 2).toString(),
                        lambdas[i],
                        Ts[j],
                    ])
                }
            }
        }
        console.log(data)
        delta8JsonData["3072"] = data
        fs.writeFileSync(DELTA_8_FILENAME, JSON.stringify(delta8JsonData, null, 2))
    })
    it("delta BigNumber gasUsed 2048 algorithm T 22~24", async () => {
        const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2,
        )
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^22", "T2^23", "T2^24"]
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
                    const trueOrfalse2 =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            delta,
                            shift128TestCase.T,
                        )
                    assert(trueOrfalse2)
                    const gasUsedAlgorithm2 =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            delta,
                            shift128TestCase.T,
                        )
                    data.push([delta.toString(), gasUsedAlgorithm2.toString(), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
        deltaT22_24JsonData["2048"] = data
        fs.writeFileSync(DELTA_T22_24_FILENAME, JSON.stringify(deltaT22_24JsonData, null, 2))
    })
    it("delta BigNumber gasUsed 3072 algorithm T 22~24", async () => {
        const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2,
        )
        const lambdas: string[] = ["λ3072"]
        const Ts: string[] = ["T2^22", "T2^23", "T2^24"]
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
                    const trueOrfalse2 =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            delta,
                            shift128TestCase.T,
                        )
                    assert(trueOrfalse2)
                    const gasUsedAlgorithm2 =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            shift128TestCase.n,
                            delta,
                            shift128TestCase.T,
                        )
                    data.push([delta.toString(), gasUsedAlgorithm2.toString(), lambdas[i], Ts[j]])
                }
            }
        }
        console.log(data)
        deltaT22_24JsonData["3072"] = data
        fs.writeFileSync(DELTA_T22_24_FILENAME, JSON.stringify(deltaT22_24JsonData, null, 2))
    })
})

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}

const getBitLenth = (num: bigint): number => {
    return num.toString(2).length
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
