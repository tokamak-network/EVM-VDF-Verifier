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
import { BigNumber } from "../shared/interfaces"

async function deployVerifyRecursiveHalvingProofDeltaBigNumberContract() {
    const verifyRecursiveHalvingProofDeltaBigNumber = await ethers.deployContract(
        "VerifyRecursiveHalvingProofDeltaBigNumber",
    )
    return verifyRecursiveHalvingProofDeltaBigNumber
}
async function deployVerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent() {
    const verifyRecursiveHalvingProofDeltaBigNumberHalvingEvent = await ethers.deployContract(
        "VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent",
    )
    return verifyRecursiveHalvingProofDeltaBigNumberHalvingEvent
}
async function deployVerifyRecursiveHalvingProofDeltaBigNumberModExpEvent() {
    const verifyRecursiveHalvingProofDeltaBigNumberModExpEvent = await ethers.deployContract(
        "VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent",
    )
    return verifyRecursiveHalvingProofDeltaBigNumberModExpEvent
}
async function deployCalldata() {
    const calldata = await ethers.deployContract("Calldata")
    return calldata
}
describe("Calldata Halving Compare2", () => {
    it("print calldata 2048, T^22, delta 9", async () => {
        console.log("2048, T^22, delta 9")
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^22"]
        const jsonName: string = "one"
        const deltas: number[] = [9]
        const Calldata = await loadFixture(deployCalldata)
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
                    const DeltaBigNumber: BigNumber = {
                        val: toBeHex(
                            2n ** (2n ** BigInt(delta)),
                            getLength(dataLength(toBeHex(2n ** (2n ** BigInt(delta))))),
                        ),
                        bitlen: getBitLenth(2n ** (2n ** BigInt(delta))),
                    }
                    console.log(DeltaBigNumber)
                    console.log(
                        toBeHex(
                            2n ** (2n ** BigInt(delta)),
                            getLength(dataLength(toBeHex(2n ** (2n ** BigInt(delta))))),
                        ),
                    )
                    const calldata = Calldata.interface.encodeFunctionData(
                        "verifyRecursiveHalvingProof",
                        [recoveryProofs, x, y, testCase.n, DeltaBigNumber, testCase.T],
                    )
                    const tx = await Calldata.verifyRecursiveHalvingProof(
                        recoveryProofs,
                        x,
                        y,
                        testCase.n,
                        DeltaBigNumber,
                        testCase.T,
                    )
                    const gasUsed = await Calldata.verifyRecursiveHalvingProof.estimateGas(
                        recoveryProofs,
                        x,
                        y,
                        testCase.n,
                        DeltaBigNumber,
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
    it("calldata cost 2048 2", async () => {
        const data: any = []
        for (let i: number = 0; i < 6; i++) {
            data.push([])
        }
        const Calldata = await loadFixture(deployCalldata)
        for (let delta: number = 0; delta < 25; delta++) {
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
            const DeltaBigNumber: BigNumber = {
                val: toBeHex(
                    2n ** (2n ** BigInt(delta)),
                    getLength(dataLength(toBeHex(2n ** (2n ** BigInt(delta))))),
                ),
                bitlen: getBitLenth(2n ** (2n ** BigInt(delta))),
            }
            const calldata = Calldata.interface.encodeFunctionData("verifyRecursiveHalvingProof", [
                recoveryProofs,
                x,
                y,
                testCase.n,
                DeltaBigNumber,
                testCase.T,
            ])
            const tx = await Calldata.verifyRecursiveHalvingProof(
                recoveryProofs,
                x,
                y,
                testCase.n,
                DeltaBigNumber,
                testCase.T,
            )
            const gasUsed = await Calldata.verifyRecursiveHalvingProof.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                DeltaBigNumber,
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
    it("calldata cost 3072 2", async () => {
        const data: any = []
        for (let i: number = 0; i < 6; i++) {
            data.push([])
        }
        const Calldata = await loadFixture(deployCalldata)
        for (let delta: number = 0; delta < 25; delta++) {
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
            const DeltaBigNumber: BigNumber = {
                val: toBeHex(
                    2n ** (2n ** BigInt(delta)),
                    getLength(dataLength(toBeHex(2n ** (2n ** BigInt(delta))))),
                ),
                bitlen: getBitLenth(2n ** (2n ** BigInt(delta))),
            }
            const calldata = Calldata.interface.encodeFunctionData("verifyRecursiveHalvingProof", [
                recoveryProofs,
                x,
                y,
                testCase.n,
                DeltaBigNumber,
                testCase.T,
            ])
            const tx = await Calldata.verifyRecursiveHalvingProof(
                recoveryProofs,
                x,
                y,
                testCase.n,
                DeltaBigNumber,
                testCase.T,
            )
            const gasUsed = await Calldata.verifyRecursiveHalvingProof.estimateGas(
                recoveryProofs,
                x,
                y,
                testCase.n,
                DeltaBigNumber,
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
    it("verifyRecursiveHalvingProof3 Halving 2048 2", async () => {
        const VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent = await loadFixture(
            deployVerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent,
        )
        const VerifyRecursiveHalvingProofDeltaBigNumber = await loadFixture(
            deployVerifyRecursiveHalvingProofDeltaBigNumberContract,
        )
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
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
                    const DeltaBigNumber: BigNumber = {
                        val: toBeHex(
                            2n ** (2n ** BigInt(delta)),
                            getLength(dataLength(toBeHex(2n ** (2n ** BigInt(delta))))),
                        ),
                        bitlen: getBitLenth(2n ** (2n ** BigInt(delta))),
                    }
                    const tx =
                        await VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent.verifyRecursiveHalvingProofDeltaBigNumberHalvingExternal(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent.interface.parseLog(
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
                        await VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent.verifyRecursiveHalvingProofDeltaBigNumberHalvingExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
                            testCase.T,
                        )
                    const gasUsed =
                        await VerifyRecursiveHalvingProofDeltaBigNumber.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
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
    it("verifyRecursiveHalvingProof3 Halving 3072 2", async () => {
        const VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent = await loadFixture(
            deployVerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent,
        )
        const VerifyRecursiveHalvingProofDeltaBigNumber = await loadFixture(
            deployVerifyRecursiveHalvingProofDeltaBigNumberContract,
        )
        const lambdas: string[] = ["λ3072"]
        const Ts: string[] = ["T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
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
                    const DeltaBigNumber: BigNumber = {
                        val: toBeHex(
                            2n ** (2n ** BigInt(delta)),
                            getLength(dataLength(toBeHex(2n ** (2n ** BigInt(delta))))),
                        ),
                        bitlen: getBitLenth(2n ** (2n ** BigInt(delta))),
                    }
                    const tx =
                        await VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent.verifyRecursiveHalvingProofDeltaBigNumberHalvingExternal(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent.interface.parseLog(
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
                        await VerifyRecursiveHalvingProofDeltaBigNumberHalvingEvent.verifyRecursiveHalvingProofDeltaBigNumberHalvingExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
                            testCase.T,
                        )
                    const gasUsed =
                        await VerifyRecursiveHalvingProofDeltaBigNumber.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
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
    it("verifyRecursiveHalvingProof3 modExp 2048 2", async () => {
        const VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent = await loadFixture(
            deployVerifyRecursiveHalvingProofDeltaBigNumberModExpEvent,
        )
        const VerifyRecursiveHalvingProofDeltaBigNumber = await loadFixture(
            deployVerifyRecursiveHalvingProofDeltaBigNumberContract,
        )
        const lambdas: string[] = ["λ2048"]
        const Ts: string[] = ["T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
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
                    const DeltaBigNumber: BigNumber = {
                        val: toBeHex(
                            2n ** (2n ** BigInt(delta)),
                            getLength(dataLength(toBeHex(2n ** (2n ** BigInt(delta))))),
                        ),
                        bitlen: getBitLenth(2n ** (2n ** BigInt(delta))),
                    }
                    const tx =
                        await VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent.verifyRecursiveHalvingProofDeltaBigNumberModExpCompareExternal(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent.interface.parseLog(
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
                        await VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent.verifyRecursiveHalvingProofDeltaBigNumberModExpCompareExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
                            testCase.T,
                        )
                    const gasUsed =
                        await VerifyRecursiveHalvingProofDeltaBigNumber.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
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
    it("verifyRecursiveHalvingProof3 modExp 3072 2", async () => {
        const VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent = await loadFixture(
            deployVerifyRecursiveHalvingProofDeltaBigNumberModExpEvent,
        )
        const VerifyRecursiveHalvingProofDeltaBigNumber = await loadFixture(
            deployVerifyRecursiveHalvingProofDeltaBigNumberContract,
        )
        const lambdas: string[] = ["λ3072"]
        const Ts: string[] = ["T2^25"]
        const jsonName: string = "one"
        const deltas: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
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
                    const DeltaBigNumber: BigNumber = {
                        val: toBeHex(
                            2n ** (2n ** BigInt(delta)),
                            getLength(dataLength(toBeHex(2n ** (2n ** BigInt(delta))))),
                        ),
                        bitlen: getBitLenth(2n ** (2n ** BigInt(delta))),
                    }
                    const tx =
                        await VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent.verifyRecursiveHalvingProofDeltaBigNumberModExpCompareExternal(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
                            testCase.T,
                        )
                    const receipt = await tx.wait()
                    console.log(
                        receipt?.logs
                            .map((log: any) => {
                                try {
                                    const parsed =
                                        VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent.interface.parseLog(
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
                        await VerifyRecursiveHalvingProofDeltaBigNumberModExpEvent.verifyRecursiveHalvingProofDeltaBigNumberModExpCompareExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
                            testCase.T,
                        )
                    const gasUsed =
                        await VerifyRecursiveHalvingProofDeltaBigNumber.verifyRecursiveHalvingProofExternal.estimateGas(
                            recoveryProofs,
                            x,
                            y,
                            testCase.n,
                            DeltaBigNumber,
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
