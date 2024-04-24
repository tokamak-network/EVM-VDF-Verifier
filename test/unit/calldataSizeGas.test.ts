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
import { dataLength, toBeHex } from "ethers"
import fs from "fs"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("CalldataSizeGasTest", () => {
          it("test bytes memory gas", async () => {
              const E = await ethers.getContractFactory("E")
              const e = await E.deploy()
              await e.waitForDeployment()
              let calldata = e.interface.encodeFunctionData("verifyRecursiveHalvingProof", ["0x"])
              const gasUsed0x = await e.verifyRecursiveHalvingProof.estimateGas("0x")
              console.log(calldata, gasUsed0x)
              //// ****
              calldata = e.interface.encodeFunctionData("verifyRecursiveHalvingProof", ["0x01"])
              const gasUsed0x01 = await e.verifyRecursiveHalvingProof.estimateGas("0x01")
              console.log(calldata, gasUsed0x01)

              console.log(gasUsed0x01 - gasUsed0x)
              //// ****
              calldata = e.interface.encodeFunctionData("verifyRecursiveHalvingProof", ["0x000001"])
              const gasUsed0x000001 = await e.verifyRecursiveHalvingProof.estimateGas("0x0001")
              console.log(calldata, gasUsed0x000001)
              //// ****
              calldata = e.interface.encodeFunctionData("verifyRecursiveHalvingProof", ["0x010001"])
              const gasUsed0x010001 = await e.verifyRecursiveHalvingProof.estimateGas("0x010001")
              console.log(calldata, gasUsed0x010001)
              console.log(gasUsed0x010001 - gasUsed0x000001)

              calldata = e.interface.encodeFunctionData("verifyRecursiveHalvingProof", ["0x100001"])
              const gasUsed0x100001 = await e.verifyRecursiveHalvingProof.estimateGas("0x100001")
              console.log(calldata, gasUsed0x100001)
              console.log(gasUsed0x100001 - gasUsed0x010001)

              calldata = e.interface.encodeFunctionData("verifyRecursiveHalvingProof", ["0x110001"])
              const gasUsed0x110001 = await e.verifyRecursiveHalvingProof.estimateGas("0x110001")
              console.log(calldata, gasUsed0x110001)
              console.log(gasUsed0x110001 - gasUsed0x100001)

              calldata = e.interface.encodeFunctionData("verifyRecursiveHalvingProof", ["0x111001"])
              const gasUsed0x111001 = await e.verifyRecursiveHalvingProof.estimateGas("0x111001")
              console.log(calldata, gasUsed0x111001)
              console.log(gasUsed0x111001 - gasUsed0x110001)
          })
          it("test bytes calldata gas", async () => {
              const F = await ethers.getContractFactory("F")
              const f = await F.deploy()
              await f.waitForDeployment()
              const calldata = f.interface.encodeFunctionData("verifyRecursiveHalvingProof", ["0x"])
              const gasUsed = await f.verifyRecursiveHalvingProof.estimateGas("0x")
              console.log(calldata, gasUsed)
          })
          it("test non parameter gas", async () => {
              const B = await ethers.getContractFactory("B")
              const b = await B.deploy()
              await b.waitForDeployment()
              const calldata = b.interface.encodeFunctionData("verifyRecursiveHalvingProof")
              const gasUsed = await b.verifyRecursiveHalvingProof.estimateGas()
              console.log(calldata, gasUsed)
          })
          it("verifyRecursiveHalvingProof", async () => {
              let arr = [] // calldataSizeinBytes, totalGasUsed, intrinsicGas, memoryCopyingGas
              for (let delta: number = 21; delta >= 0; delta--) {
                  const testCase = createCorrectAlgorithmVersionTestCase()
                  const x = testCase.recoveryProofs[0].x
                  const y = testCase.recoveryProofs[0].y
                  if (delta > 0)
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
                  const A = await ethers.getContractFactory("A")
                  const a = await A.deploy()
                  await a.waitForDeployment()
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
                  //   console.log("returnValue", returnValue)
                  const provider = ethers.getDefaultProvider("mainnet")
                  const network = await provider.getNetwork()
                  const receipt = await tx.wait()

                  const gasUsed = await a.verifyRecursiveHalvingProof.estimateGas(
                      recoveryProofs,
                      x,
                      y,
                      testCase.n,
                      toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                      2 ** delta,
                      testCase.T,
                  )
                  //console.log(calldata, gasUsed)
                  console.log(gasUsed)
                  let sum = 0
                  for (let i = 2; i < calldata.length - 1; i += 2) {
                      const data = calldata.substring(i, i + 2)
                      if (data === "00") {
                          sum += 4
                      } else {
                          sum += 16
                      }
                  }
                  console.log(sum, delta)
                  //memory_size_word = (calldataSizeinBytes + 31) / 32
                  //memory_cost = (memory_size_word ** 2) / 512 + (3 * memory_size_word)
                  const memory_size_word = (calldata.length / 2 + 31) / 32
                  const memory_cost = memory_size_word ** 2 / 512 + 3 * memory_size_word
                  //totalGasUsed=memory_cost+(1.62×calldataSizeinBytes+202.16)
                  const additionalGas = 1.62 * (calldata.length / 2) + 202.16
                  const totalGasUsed = memory_cost + additionalGas

                  arr.push([
                      calldata.length / 2,
                      gasUsed,
                      network.computeIntrinsicGas(tx),
                      receipt!.gasUsed - BigInt(network.computeIntrinsicGas(tx)),
                      totalGasUsed,
                  ])
              }
              console.log(arr)
          })
          it("verifyRecursiveHalvingProof2", async () => {
              const testCase = createCorrectAlgorithmVersionTestCase()
              const x = testCase.recoveryProofs[0].x
              const y = testCase.recoveryProofs[0].y
              const delta = 9
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
              const A = await ethers.getContractFactory("AA")
              const a = await A.deploy()
              await a.waitForDeployment()
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
              //   console.log("returnValue", returnValue)
              const provider = ethers.getDefaultProvider("mainnet")
              const network = await provider.getNetwork()
              console.log("intrinsicGas", network.computeIntrinsicGas(tx))
              const receipt = await tx.wait()
              console.log("gasUsed", receipt!.gasUsed)
              console.log(recoveryProofs.length)

              const gasUsed = await a.verifyRecursiveHalvingProof.estimateGas(
                  recoveryProofs,
                  x,
                  y,
                  testCase.n,
                  toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
                  2 ** delta,
                  testCase.T,
              )
              //console.log(calldata, gasUsed)
              console.log(gasUsed)
              let sum = 0
              for (let i = 2; i < calldata.length - 1; i += 2) {
                  const data = calldata.substring(i, i + 2)
                  if (data === "00") {
                      sum += 4
                  } else {
                      sum += 16
                  }
              }
              console.log(sum)
          })
          //   it("verifyRecursiveHalvingProof2", async () => {
          //       const testCase = createCorrectAlgorithmVersionTestCase()
          //       const x = testCase.recoveryProofs[0].x
          //       const y = testCase.recoveryProofs[0].y
          //       const delta = 9
          //       testCase.recoveryProofs = testCase.recoveryProofs.slice(0, -(delta + 1))
          //       for (let i: number = 0; i < testCase.recoveryProofs.length; i++) {
          //           delete testCase.recoveryProofs[i].n
          //           delete testCase.recoveryProofs[i].T
          //           delete testCase.recoveryProofs[i].x
          //           delete testCase.recoveryProofs[i].y
          //       }
          //       let recoveryProofs = []
          //       for (let i: number = 0; i < testCase.recoveryProofs.length; i++) {
          //           recoveryProofs.push(testCase.recoveryProofs[i].v)
          //       }
          //       const A = await ethers.getContractFactory("AAA")
          //       const a = await A.deploy()
          //       await a.waitForDeployment()
          //       const calldata = a.interface.encodeFunctionData("verifyRecursiveHalvingProof", [
          //           recoveryProofs,
          //           x,
          //           y,
          //           testCase.n,
          //           toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
          //           2 ** delta,
          //           testCase.T,
          //       ])
          //       const returnValue = await a.verifyRecursiveHalvingProof(
          //           recoveryProofs,
          //           x,
          //           y,
          //           testCase.n,
          //           toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
          //           2 ** delta,
          //           testCase.T,
          //       )
          //       console.log("returnValue", returnValue)

          //       const gasUsed = await a.verifyRecursiveHalvingProof.estimateGas(
          //           recoveryProofs,
          //           x,
          //           y,
          //           testCase.n,
          //           toBeHex(2 ** delta, getLength(dataLength(toBeHex(2 ** delta)))),
          //           2 ** delta,
          //           testCase.T,
          //       )
          //       console.log(calldata, gasUsed)
          //       let sum = 0
          //       for (let i = 2; i < calldata.length - 1; i += 2) {
          //           const data = calldata.substring(i, i + 2)
          //           if (data === "00") {
          //               sum += 4
          //           } else {
          //               sum += 16
          //           }
          //       }
          //       console.log(sum)
          //   })
      })

const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(fs.readFileSync(__dirname + "/../shared/correct.json", "utf-8"))
    return testCaseJson
}

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
