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
import { expect } from "chai"
import { dataLength, toBeHex } from "ethers"
import fs from "fs"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { OptimizedPietrzak } from "../../typechain-types"
import { TestCase } from "../shared/interfacesV2"

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Optimized Pietrzak Verification", () => {
          let optimizedPietrzak: OptimizedPietrzak
          it("should deploy OptimizedPietrzak Contract", async function () {
              const OptimizedPietrzak = await ethers.getContractFactory("OptimizedPietrzak")
              optimizedPietrzak = await OptimizedPietrzak.deploy()
              await optimizedPietrzak.waitForDeployment()
              await expect(await optimizedPietrzak.getAddress()).to.be.properAddress
          })
          //   it("should verify the proof optimized version", async function () {
          //       const testCase: OptimizedTestCase = createOptimizedTestCase("λ2048", "T2^22", "one")
          //       await optimizedPietrzak.verifyOptimizedVersion(
          //           testCase.x,
          //           testCase.y,
          //           testCase.pi,
          //           testCase.n,
          //       )
          //       const gasUsedOptimizedVersion =
          //           await optimizedPietrzak.verifyOptimizedVersion.estimateGas(
          //               testCase.x,
          //               testCase.y,
          //               testCase.pi,
          //               testCase.n,
          //           )
          //       console.log("Gas used for optimized version: ", gasUsedOptimizedVersion)
          //   })
          it("should verify the proof", async function () {
              const notOptimizedTestCase: TestCase = createNotOptimizedTestCase(
                  "λ2048",
                  "T2^22",
                  "one",
              )
              const gasUsedNoDelta =
                  await optimizedPietrzak.verifyRecursiveHalvingProof1.estimateGas(
                      notOptimizedTestCase.recoveryProofs,
                      notOptimizedTestCase.n,
                  )
              console.log("recoveryProofs Length", notOptimizedTestCase.recoveryProofs.length)
              console.log("Gas Used delta:", 0, " =", gasUsedNoDelta)

              //   const gasUsedRepeated =
              //       await optimizedPietrzak.verifyRecursiveHalvingProofRepeated.estimateGas(
              //           notOptimizedTestCase.recoveryProofs,
              //           notOptimizedTestCase.n,
              //           1,
              //           0,
              //       )
              //   console.log("Gas Used delta Repeated:", 0, " =", gasUsedRepeated)

              //   const gasUsedRepeatedBytes =
              //       await optimizedPietrzak.verifyRecursiveHalvingProofRepeatedBytes.estimateGas(
              //           notOptimizedTestCase.recoveryProofs,
              //           notOptimizedTestCase.n,
              //           1,
              //           0,
              //       )
              //   console.log("Gas Used delta Repeated:", 0, " =", gasUsedRepeatedBytes)

              //   const gasUsedBytes =
              //       await optimizedPietrzak.verifyRecursiveHalvingProofBytes.estimateGas(
              //           notOptimizedTestCase.recoveryProofs,
              //           notOptimizedTestCase.n,
              //           toBeHex(0, getLength(dataLength(toBeHex(0)))),
              //           1,
              //           0,
              //       )
              //   console.log("Gas Used delta Bytes:", 0, " =", gasUsedBytes)

              for (let i: number = 0; i < 16; i++) {
                  const delta = i

                  const twoPowerOfDelta = BigInt(2) ** BigInt(delta)

                  const bigNumtwoPowerOfDelta: BigNumber = {
                      val: toBeHex(
                          twoPowerOfDelta,
                          getLength(dataLength(toBeHex(twoPowerOfDelta))),
                      ),
                      bitlen: getBitLenth(twoPowerOfDelta),
                  }
                  let recoveryProofs
                  if (delta > 0)
                      recoveryProofs = notOptimizedTestCase.recoveryProofs.slice(0, -delta)
                  else recoveryProofs = notOptimizedTestCase.recoveryProofs
                  console.log("recoveryProofs Length", recoveryProofs.length)
                  //   await optimizedPietrzak.verifyRecursiveHalvingProof(
                  //       recoveryProofs,
                  //       notOptimizedTestCase.n,
                  //       bigNumtwoPowerOfDelta,
                  //       twoPowerOfDelta,
                  //       delta,
                  //   )

                  const gasUsedNotOptimizedVersion =
                      await optimizedPietrzak.verifyRecursiveHalvingProof.estimateGas(
                          recoveryProofs,
                          notOptimizedTestCase.n,
                          bigNumtwoPowerOfDelta,
                          twoPowerOfDelta,
                          delta,
                      )
                  //console.log("Gas Used delta:", delta, " =", gasUsedNotOptimizedVersion)

                  const gasUsedBytes =
                      await optimizedPietrzak.verifyRecursiveHalvingProofBytes.estimateGas(
                          recoveryProofs,
                          notOptimizedTestCase.n,
                          bigNumtwoPowerOfDelta.val,
                          2n ** BigInt(delta),
                          delta,
                      )
                  //console.log("Gas Used Bytes delta:", delta, " =", gasUsedBytes)

                  const gasUsedBytes1 =
                      await optimizedPietrzak.verifyRecursiveHalvingProofBytes1.estimateGas(
                          recoveryProofs,
                          notOptimizedTestCase.n,
                          bigNumtwoPowerOfDelta.val,
                          delta,
                      )
                  //console.log("Gas Used Bytes1 delta:", delta, " =", gasUsedBytes1)

                  const repeatedGasUsed =
                      await optimizedPietrzak.verifyRecursiveHalvingProofRepeatedBytes.estimateGas(
                          recoveryProofs,
                          notOptimizedTestCase.n,
                          2n ** BigInt(delta),
                          delta,
                      )
                  console.log("Gas Used repeated delta:", delta, " =", repeatedGasUsed)

                  //   await optimizedPietrzak.compareGasModLeftAndRight(notOptimizedTestCase.recoveryProofs)
              }
          })
      })

interface BigNumber {
    val: string
    bitlen: number
}
interface OptimizedTestCase {
    x: BigNumber
    y: BigNumber
    pi: BigNumber[]
    tau: number
    delta: number
    n: BigNumber
}

const createOptimizedTestCase = (lambd: string, T: string, jsonName: string): OptimizedTestCase => {
    const testCaseJson: OptimizedTestCase = JSON.parse(
        fs.readFileSync(
            __dirname + `/../shared/OptimizedTestCases/${lambd}/${T}/${jsonName}.json`,
            "utf-8",
        ),
    )
    return testCaseJson
}

const createNotOptimizedTestCase = (lambd: string, T: string, jsonName: string): TestCase => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(
            __dirname + `/../shared/NotOptimizedTestCases/${lambd}/${T}/${jsonName}.json`,
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

const getBitLenth = (num: bigint): number => {
    return num.toString(2).length
}

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
