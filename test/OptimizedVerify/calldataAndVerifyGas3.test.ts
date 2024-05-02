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

async function deployVerifyRecursiveHalvingProofAlgorithm2() {
    const verifyRecursiveHalvingProofAlgorithm2 = await ethers.deployContract(
        "VerifyRecursiveHalvingProofAlgorithm2",
    )
    return verifyRecursiveHalvingProofAlgorithm2
}

async function deployVerifyRecursiveHalvingProofAlgorithm2Halving() {
    const verifyRecursiveHalvingProofAlgorithm2Halving = await ethers.deployContract(
        "VerifyRecursiveHalvingProofAlgorithm2Halving",
    )
    return verifyRecursiveHalvingProofAlgorithm2Halving
}
async function deployVerifyRecursiveHalvingProofAlgorithm2ModExp() {
    const verifyRecursiveHalvingProofAlgorithm2ModExp = await ethers.deployContract(
        "VerifyRecursiveHalvingProofAlgorithm2ModExp",
    )
    return verifyRecursiveHalvingProofAlgorithm2ModExp
}
async function deployCalldata2() {
    const calldata2 = await ethers.deployContract("Calldata2")
    return calldata2
}

describe("Calldata Halving Compare3", () => {
    it("print calldata 2048, T^22, delta 9", async () => {
        console.log("2048, T^22, delta 9")
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [9]
        const calldata2 = await loadFixture(deployCalldata2)
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    const testCase = createTestCase2048T22()
                    const x = testCase.recoveryProofs[0].x
                    const y = testCase.recoveryProofs[0].y
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
                    const calldata = await calldata2.interface.encodeFunctionData(
                        "verifyRecursiveHalvingProof",
                        [recoveryProofs, x, y, testCase.n, delta, testCase.T],
                    )
                    const tx = await calldata2.verifyRecursiveHalvingProof(
                        recoveryProofs,
                        x,
                        y,
                        testCase.n,
                        delta,
                        testCase.T,
                    )
                    const gasUsed = await calldata2.verifyRecursiveHalvingProof.estimateGas(
                        recoveryProofs,
                        x,
                        y,
                        testCase.n,
                        delta,
                        testCase.T,
                    )
                    const provider = ethers.getDefaultProvider("mainnet")
                    const network = await provider.getNetwork()
                    const receipt = await tx.wait()
                    assert.equal(gasUsed, receipt!.gasUsed)
                    console.log(delta)
                    console.log(recoveryProofs.length.toString())
                    console.log((calldata.length / 2).toString())
                    console.log(network.computeIntrinsicGas(tx).toString())
                    console.log((gasUsed - BigInt(network.computeIntrinsicGas(tx))).toString())
                    console.log(gasUsed.toString())
                    console.log(calldata)
                    console.log(calldata.substring(0, 10))
                    const data = calldata.slice(10)
                    let dataLocation = "  00"
                    for (let i = 0; i < data.length; i += 64) {
                        console.log(data.slice(i, i + 64))
                        //   dataLocation = (parseInt(dataLocation, 16) + 32).toString(16).padStart(4, " ")
                    }
                    for (let i = 0; i < data.length; i += 64) {
                        console.log(dataLocation)
                        dataLocation = (parseInt(dataLocation, 16) + 32)
                            .toString(16)
                            .padStart(4, " ")
                    }
                }
            }
        }
    })
    it("calldata cost 2048 3", async () => {
        const data: any = []
        for (let i: number = 0; i < 6; i++) {
            data.push([])
        }
        const calldata2 = await loadFixture(deployCalldata2)
        for (let delta: number = 0; delta < 26; delta++) {
            const testCase = createTestCase2048()
            const x = testCase.recoveryProofs[0].x
            const y = testCase.recoveryProofs[0].y
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
            const calldata = await calldata2.interface.encodeFunctionData(
                "verifyRecursiveHalvingProof",
                [recoveryProofs, x, y, testCase.n, delta, testCase.T],
            )
            const tx = await calldata2.verifyRecursiveHalvingProof(
                recoveryProofs,
                x,
                y,
                testCase.n,
                delta,
                testCase.T,
            )
            const gasUsed = await calldata2.verifyRecursiveHalvingProof.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                delta,
                testCase.T,
            )
            const provider = ethers.getDefaultProvider("mainnet")
            const network = await provider.getNetwork()
            const receipt = await tx.wait()
            assert.equal(gasUsed, receipt!.gasUsed)
            data[0].push(delta)
            data[1].push(recoveryProofs.length.toString())
            data[2].push((calldata.length / 2).toString())
            data[3].push(network.computeIntrinsicGas(tx).toString())
            data[4].push((gasUsed - BigInt(network.computeIntrinsicGas(tx))).toString())
            data[5].push(gasUsed.toString())
        }
        console.log("2048")
        console.log(
            "[delta, recoveryProofs.length, calldataInBytes, intrinsicGasUsed, gasUsed - intrinsicGasUsed, totalGasUsed]",
        )
        for (let i: number = 0; i < 6; i++) {
            for (let j: number = 0; j < data[0].length; j++) {
                console.log(data[i][j])
            }
            console.log("---")
        }
    })
    it("calldata cost 3072 3", async () => {
        const data: any = []
        for (let i: number = 0; i < 6; i++) {
            data.push([])
        }
        const calldata2 = await loadFixture(deployCalldata2)
        for (let delta: number = 0; delta < 26; delta++) {
            const testCase = createTestCase3072()
            const x = testCase.recoveryProofs[0].x
            const y = testCase.recoveryProofs[0].y
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
            const calldata = await calldata2.interface.encodeFunctionData(
                "verifyRecursiveHalvingProof",
                [recoveryProofs, x, y, testCase.n, delta, testCase.T],
            )
            const tx = await calldata2.verifyRecursiveHalvingProof(
                recoveryProofs,
                x,
                y,
                testCase.n,
                delta,
                testCase.T,
            )
            const gasUsed = await calldata2.verifyRecursiveHalvingProof.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                delta,
                testCase.T,
            )
            const provider = ethers.getDefaultProvider("mainnet")
            const network = await provider.getNetwork()
            const receipt = await tx.wait()
            assert.equal(gasUsed, receipt!.gasUsed)
            data[0].push(delta)
            data[1].push(recoveryProofs.length.toString())
            data[2].push((calldata.length / 2).toString())
            data[3].push(network.computeIntrinsicGas(tx).toString())
            data[4].push((gasUsed - BigInt(network.computeIntrinsicGas(tx))).toString())
            data[5].push(gasUsed.toString())
        }
        console.log("3072")
        console.log(
            "[delta, recoveryProofs.length, calldataInBytes, intrinsicGasUsed, gasUsed - intrinsicGasUsed, totalGasUsed]",
        )
        for (let i: number = 0; i < 6; i++) {
            for (let j: number = 0; j < data[0].length; j++) {
                console.log(data[i][j])
            }
            console.log("---")
        }
    })
    it("verifyRecursiveHalvingProof Halving 2048 3", async () => {
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const data: any = []
        for (let i: number = 0; i < 5; i++) {
            data.push([])
        }
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    const verifyRecursiveHalvingProofAlgorithm2Halving = await loadFixture(
                        deployVerifyRecursiveHalvingProofAlgorithm2Halving,
                    )
                    const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
                        deployVerifyRecursiveHalvingProofAlgorithm2,
                    )
                    const testCase = createshift128TestCaseNXYVT(lambdas[i], Ts[j], jsonName)
                    //const testCase = createTestCase2048()
                    const x = testCase.recoveryProofs[0].x
                    const y = testCase.recoveryProofs[0].y
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
                    const gasUsedHalving =
                        await verifyRecursiveHalvingProofAlgorithm2Halving.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    const tx =
                        await verifyRecursiveHalvingProofAlgorithm2Halving.verifyRecursiveHalvingProof(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        verifyRecursiveHalvingProofAlgorithm2Halving.interface.parseLog(
                                            log,
                                        )
                                    return parsed?.args[0]
                                } catch (e) {
                                    console.log(e)
                                }
                            })[0]
                            .toString(),
                    )

                    // const trueOrFalse =
                    //     await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof(
                    //         recoveryProofs,
                    //         x,
                    //         y,
                    //         testCase.n,
                    //         delta,
                    //         testCase.T,
                    //     )
                    // assert(trueOrFalse)
                    const gasUsed =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    data[0].push(delta)
                    data[1].push(recoveryProofs.length.toString())
                    data[2].push(gasUsed.toString())
                    data[3].push(gasUsedHalving.toString())
                    data[4].push((gasUsedHalving - gasUsed).toString())
                }
            }
        }
        console.log("---")
        for (let i: number = 0; i < 5; i++) {
            for (let j: number = 0; j < data[0].length; j++) {
                console.log(data[i][j])
            }
            console.log("---")
        }
    })
    it("verifyRecursiveHalvingProof Halving 3072 3", async () => {
        const verifyRecursiveHalvingProofAlgorithm2Halving = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2Halving,
        )
        const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2,
        )
        const lambdas: string[] = ["λ3072"]
        const Ts: string[] = ["T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const data: any = []
        for (let i: number = 0; i < 5; i++) {
            data.push([])
        }
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    const testCase = createTestCase3072()
                    const x = testCase.recoveryProofs[0].x
                    const y = testCase.recoveryProofs[0].y
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
                    const tx =
                        await verifyRecursiveHalvingProofAlgorithm2Halving.verifyRecursiveHalvingProof(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        verifyRecursiveHalvingProofAlgorithm2Halving.interface.parseLog(
                                            log,
                                        )
                                    return parsed?.args[0]
                                } catch (e) {
                                    console.log(e)
                                }
                            })[0]
                            .toString(),
                    )
                    const gasUsedHalving =
                        await verifyRecursiveHalvingProofAlgorithm2Halving.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    const gasUsed =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    data[0].push(delta)
                    data[1].push(recoveryProofs.length.toString())
                    data[2].push(gasUsed.toString())
                    data[3].push(gasUsedHalving.toString())
                    data[4].push((gasUsedHalving - gasUsed).toString())
                }
            }
        }
        console.log("---")
        for (let i: number = 0; i < 5; i++) {
            for (let j: number = 0; j < data[0].length; j++) {
                console.log(data[i][j])
            }
            console.log("---")
        }
    })
    it("verifyRecursiveHalvingProof ModExp 2048 3", async () => {
        const verifyRecursiveHalvingProofAlgorithm2ModExp = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2ModExp,
        )
        const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2,
        )
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const data: any = []
        for (let i: number = 0; i < 5; i++) {
            data.push([])
        }
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    const testCase = createTestCase2048()
                    const x = testCase.recoveryProofs[0].x
                    const y = testCase.recoveryProofs[0].y
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
                    const tx =
                        await verifyRecursiveHalvingProofAlgorithm2ModExp.verifyRecursiveHalvingProof(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        verifyRecursiveHalvingProofAlgorithm2ModExp.interface.parseLog(
                                            log,
                                        )
                                    return parsed?.args[0]
                                } catch (e) {
                                    console.log(e)
                                }
                            })[0]
                            .toString(),
                    )
                    const gasUsedModExp =
                        await verifyRecursiveHalvingProofAlgorithm2ModExp.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    const gasUsed =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    data[0].push(delta)
                    data[1].push(recoveryProofs.length.toString())
                    data[2].push(gasUsed.toString())
                    data[3].push(gasUsedModExp.toString())
                    data[4].push((gasUsedModExp - gasUsed).toString())
                }
            }
        }
        console.log("---")
        for (let i: number = 0; i < 5; i++) {
            for (let j: number = 0; j < data[0].length; j++) {
                console.log(data[i][j])
            }
            console.log("---")
        }
    })
    it("verifyRecursiveHalvingProof ModExp 3072 3", async () => {
        const verifyRecursiveHalvingProofAlgorithm2ModExp = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2ModExp,
        )
        const verifyRecursiveHalvingProofAlgorithm2 = await loadFixture(
            deployVerifyRecursiveHalvingProofAlgorithm2,
        )
        const lambdas: string[] = ["λ3072"]
        const Ts: string[] = ["T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]
        const data: any = []
        for (let i: number = 0; i < 5; i++) {
            data.push([])
        }
        for (let k: number = 0; k < deltas.length; k++) {
            const delta: number = deltas[k]
            for (let i: number = 0; i < lambdas.length; i++) {
                for (let j: number = 0; j < Ts.length; j++) {
                    const testCase = createTestCase3072()
                    const x = testCase.recoveryProofs[0].x
                    const y = testCase.recoveryProofs[0].y
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
                    const tx =
                        await verifyRecursiveHalvingProofAlgorithm2ModExp.verifyRecursiveHalvingProof(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        verifyRecursiveHalvingProofAlgorithm2ModExp.interface.parseLog(
                                            log,
                                        )
                                    return parsed?.args[0]
                                } catch (e) {
                                    console.log(e)
                                }
                            })[0]
                            .toString(),
                    )
                    const gasUsedModExp =
                        await verifyRecursiveHalvingProofAlgorithm2ModExp.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    const gasUsed =
                        await verifyRecursiveHalvingProofAlgorithm2.verifyRecursiveHalvingProof.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            delta,
                            testCase.T,
                        )
                    data[0].push(delta)
                    data[1].push(recoveryProofs.length.toString())
                    data[2].push(gasUsed.toString())
                    data[3].push(gasUsedModExp.toString())
                    data[4].push((gasUsedModExp - gasUsed).toString())
                }
            }
        }
        console.log("---")
        for (let i: number = 0; i < 5; i++) {
            for (let j: number = 0; j < data[0].length; j++) {
                console.log(data[i][j])
            }
            console.log("---")
        }
    })
})

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}

const createTestCase2048T22 = () => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(
            __dirname + "/../shared/correctAlgorithmTestCase/λ2048/T2^22/one.json",
            "utf-8",
        ),
    )
    return testCaseJson
}

const createTestCase2048 = () => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(
            __dirname + "/../shared/correctAlgorithmTestCase/λ2048/T2^25/one.json",
            "utf-8",
        ),
    )
    return testCaseJson
}

const createTestCase3072 = () => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(
            __dirname + "/../shared/correctAlgorithmTestCase/λ3072/T2^25/one.json",
            "utf-8",
        ),
    )
    return testCaseJson
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
