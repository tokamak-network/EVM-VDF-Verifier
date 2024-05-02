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
import { dataLength, toBeHex } from "ethers"
import fs from "fs"
import { ethers } from "hardhat"
async function deployManyMany() {
    const manyMany = await ethers.deployContract("ManyMany")
    return manyMany
}
async function deployMinimal() {
    const minimalApplication = await ethers.deployContract("MinimalApplication")
    return minimalApplication
}
async function deployVerifyRecursiveHalvingProofExternalContract() {
    const verifyRecursiveHalvingProofExternal = await ethers.deployContract(
        "VerifyRecursiveHalvingProofExternalContract",
    )
    return verifyRecursiveHalvingProofExternal
}
async function deployVerifyRecursiveHalvingProofExternalGasConsoleHalvingContract() {
    const verifyRecursiveHalvingProofExternalGasConsoleHalving = await ethers.deployContract(
        "VerifyRecursiveHalvingProofExternalGasConsoleHalvingContract",
    )
    return verifyRecursiveHalvingProofExternalGasConsoleHalving
}
async function deployVerifyRecursiveHalvingProofExternalGasConsoleModExpContract() {
    const verifyRecursiveHalvingProofExternalGasConsoleModExp = await ethers.deployContract(
        "VerifyRecursiveHalvingProofExternalGasConsoleMoDExpContract",
    )
    return verifyRecursiveHalvingProofExternalGasConsoleModExp
}
async function deployA() {
    const a = await ethers.deployContract("A")
    return a
}

describe("Calldata Halving Compare", async () => {
    it("calldata cost 2048", async () => {
        const data: any = []
        for (let i: number = 0; i < 6; i++) {
            data.push([])
        }
        const a = await loadFixture(deployA)
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
            const calldata = a.interface.encodeFunctionData("verifyRecursiveHalvingProof", [
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            ])
            const tx = await a.verifyRecursiveHalvingProof(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed = await a.verifyRecursiveHalvingProof.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const provider = ethers.getDefaultProvider("mainnet")
            const network = await provider.getNetwork()
            const receipt = await tx.wait()
            assert.equal(gasUsed, receipt!.gasUsed)
            // data.push([
            //     delta,
            //     recoveryProofs.length.toString(),
            //     (calldata.length / 2).toString(),
            //     network.computeIntrinsicGas(tx).toString(),
            //     (gasUsed - BigInt(network.computeIntrinsicGas(tx))).toString(),
            //     gasUsed.toString(),
            // ])

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
    it("calldata cost 3072", async () => {
        const data: any = []
        for (let i: number = 0; i < 6; i++) {
            data.push([])
        }
        const a = await loadFixture(deployA)
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
            const calldata = a.interface.encodeFunctionData("verifyRecursiveHalvingProof", [
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            ])
            const tx = await a.verifyRecursiveHalvingProof(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed = await a.verifyRecursiveHalvingProof.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const provider = ethers.getDefaultProvider("mainnet")
            const network = await provider.getNetwork()
            const receipt = await tx.wait()
            assert.equal(gasUsed, receipt!.gasUsed)
            // data.push([
            //     delta,
            //     recoveryProofs.length.toString(),
            //     (calldata.length / 2).toString(),
            //     network.computeIntrinsicGas(tx).toString(),
            //     (gasUsed - BigInt(network.computeIntrinsicGas(tx))).toString(),
            //     gasUsed.toString(),
            // ])
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
    it("verifyRecursiveHalvingProof3 Halving 2048", async () => {
        const VerifyRecursiveHalvingProof = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalContract,
        )
        const VerifyRecursiveHalvingProofExternalGasConsoleHalving = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalGasConsoleHalvingContract,
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
                        await VerifyRecursiveHalvingProofExternalGasConsoleHalving.verifyRecursiveHalvingProofExternal(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    // get event
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        VerifyRecursiveHalvingProofExternalGasConsoleHalving.interface.parseLog(
                                            log,
                                        )
                                    return parsed?.args[0]
                                } catch (e) {
                                    console.log(e)
                                }
                            })[0]
                            .toString(),
                    )
                    const gasUsedConsoleHalving =
                        await VerifyRecursiveHalvingProofExternalGasConsoleHalving.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    const gasUsed =
                        await VerifyRecursiveHalvingProof.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    data[0].push(delta)
                    data[1].push(recoveryProofs.length.toString())
                    data[2].push(gasUsed.toString())
                    data[3].push(gasUsedConsoleHalving.toString())
                    data[4].push((gasUsedConsoleHalving - gasUsed).toString())
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
    it("verifyRecursiveHalvingProof3 Halving 3072", async () => {
        const VerifyRecursiveHalvingProof = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalContract,
        )
        const VerifyRecursiveHalvingProofExternalGasConsoleHalving = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalGasConsoleHalvingContract,
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
                        await VerifyRecursiveHalvingProofExternalGasConsoleHalving.verifyRecursiveHalvingProofExternal(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    // get event
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        VerifyRecursiveHalvingProofExternalGasConsoleHalving.interface.parseLog(
                                            log,
                                        )
                                    return parsed?.args[0]
                                } catch (e) {
                                    console.log(e)
                                }
                            })[0]
                            .toString(),
                    )
                    const gasUsedConsoleHalving =
                        await VerifyRecursiveHalvingProofExternalGasConsoleHalving.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    const gasUsed =
                        await VerifyRecursiveHalvingProof.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    data[0].push(delta)
                    data[1].push(recoveryProofs.length.toString())
                    data[2].push(gasUsed.toString())
                    data[3].push(gasUsedConsoleHalving.toString())
                    data[4].push((gasUsedConsoleHalving - gasUsed).toString())
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
    it("verifyRecursiveHalvingProof3 modExp 2048", async () => {
        const VerifyRecursiveHalvingProof = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalContract,
        )
        const VerifyRecursiveHalvingProofExternalGasConsoleModExp = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalGasConsoleModExpContract,
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
                        await VerifyRecursiveHalvingProofExternalGasConsoleModExp.verifyRecursiveHalvingProofExternal(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    // get event
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        VerifyRecursiveHalvingProofExternalGasConsoleModExp.interface.parseLog(
                                            log,
                                        )
                                    return parsed?.args[0]
                                } catch (e) {
                                    console.log(e)
                                }
                            })[0]
                            .toString(),
                    )

                    const gasUsedConsoleHalving =
                        await VerifyRecursiveHalvingProofExternalGasConsoleModExp.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    const gasUsed =
                        await VerifyRecursiveHalvingProof.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    data[0].push(delta)
                    data[1].push(recoveryProofs.length.toString())
                    data[2].push(gasUsed.toString())
                    data[3].push(gasUsedConsoleHalving.toString())
                    data[4].push((gasUsedConsoleHalving - gasUsed).toString())
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
    it("verifyRecursiveHalvingProof3 modExp 3072", async () => {
        const VerifyRecursiveHalvingProof = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalContract,
        )
        const VerifyRecursiveHalvingProofExternalGasConsoleModExp = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalGasConsoleModExpContract,
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
                        await VerifyRecursiveHalvingProofExternalGasConsoleModExp.verifyRecursiveHalvingProofExternal(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    // get event
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        VerifyRecursiveHalvingProofExternalGasConsoleModExp.interface.parseLog(
                                            log,
                                        )
                                    return parsed?.args[0]
                                } catch (e) {
                                    console.log(e)
                                }
                            })[0]
                            .toString(),
                    )
                    const gasUsedConsoleHalving =
                        await VerifyRecursiveHalvingProofExternalGasConsoleModExp.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    const gasUsed =
                        await VerifyRecursiveHalvingProof.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    data[0].push(delta)
                    data[1].push(recoveryProofs.length.toString())
                    data[2].push(gasUsed.toString())
                    data[3].push(gasUsedConsoleHalving.toString())
                    data[4].push((gasUsedConsoleHalving - gasUsed).toString())
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
    it("verifyRecursiveHalvingProof3 Halving SameContract Many External Functions", async () => {
        const VerifyRecursiveHalvingProof = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalContract,
        )
        const VerifyRecursiveHalvingProofExternalGasConsoleHalving = await loadFixture(
            deployVerifyRecursiveHalvingProofExternalGasConsoleHalvingContract,
        )
        const MinimalApplication = await loadFixture(deployMinimal)
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
                    const result = await MinimalApplication.verifyRecursiveHalvingProofExternal(
                        recoveryProofs,
                        x,
                        y,
                        testCase.n,
                        toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                        2 ** delta,
                        testCase.T,
                    )
                    assert.equal(result, true)
                    // get event
                    const gasUsed1 =
                        await MinimalApplication.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    const gasUsed2 =
                        await MinimalApplication.verifyRecursiveHalvingProofExternal3.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                            2 ** delta,
                            testCase.T,
                        )
                    data.push([gasUsed1, gasUsed2])
                }
            }
        }
        console.log(data)
    })
    it("calldata cost 2048 many externals", async () => {
        const data: any = []
        for (let i: number = 0; i < 6; i++) {
            data.push([])
        }
        const minimalApplication = await loadFixture(deployManyMany)
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
            const gasUsed = await minimalApplication.a.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed2 = await minimalApplication.b.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed3 = await minimalApplication.c.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed4 = await minimalApplication.d.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed5 = await minimalApplication.e.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed6 = await minimalApplication.f.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed7 = await minimalApplication.g.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed8 = await minimalApplication.h.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const gasUsed9 = await minimalApplication.i.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                2 ** delta,
                testCase.T,
            )
            const provider = ethers.getDefaultProvider("mainnet")
            const network = await provider.getNetwork()
            //console.log(gasUsed, gasUsed2)
            console.log(
                gasUsed,
                gasUsed2,
                gasUsed3,
                gasUsed4,
                gasUsed5,
                gasUsed6,
                gasUsed7,
                gasUsed8,
                gasUsed9,
            )
        }
    })
})
function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
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
