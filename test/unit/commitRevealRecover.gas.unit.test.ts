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
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { BigNumberish, ContractTransactionReceipt, ContractTransactionResponse } from "ethers"
import { network, ethers, getNamedAccounts } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { assertTestAfterDeploy, assertTestAfterGettingOmega } from "../shared/assertFunctions"
import { TestCase, GasReportsObject, LAMDAs, Ts, GasReports } from "../shared/interfacesV2"
import fs from "fs"
import { createTestCase, deployCommitRevealRecoverRNGFixture } from "../shared/testFunctionsV2"

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("CommitRevealRecover RNG GAS TEST", () => {
          const testcases: TestCase[][][] = createTestCase()
          const chainId = network.config.chainId
          let commitDuration = networkConfig[chainId!].commitDuration
          let commitRevealDuration = networkConfig[chainId!].commitRevealDuration
          let signers: SignerWithAddress[]
          //FILE_DIR_NAME BY DATE
          const FILE_DIR_NAME =
              __dirname + `/gasReports/${new Date().toISOString().slice(0, 19)}` + ".json"
          it("Commit Reveal Calculate Omega", async () => {
              const gasCostsCommitRevealCalculateOmega: GasReportsObject[][] = []
              signers = await ethers.getSigners()
              for (let i = 0; i < testcases.length; i++) {
                  gasCostsCommitRevealCalculateOmega.push([])
                  for (let j = 0; j < testcases[i].length; j++) {
                      const { commitRevealRecoverRNG, receipt } = await loadFixture(
                          deployCommitRevealRecoverRNGFixture,
                      )
                      const key = `${LAMDAs[i]}${Ts[j]}`
                      gasCostsCommitRevealCalculateOmega[i].push({
                          [key]: [],
                      })
                      for (let round = 0; round < testcases[i][j].length; round++) {
                          const gasCostsPerFunction: GasReports = {
                              setUpGas: 0,
                              recoverGas: 0,
                              commitGas: [],
                              revealGas: [],
                              calculateOmegaGas: 0,
                              verifyRecursiveHalvingProofForSetup: 0,
                              verifyRecursiveHalvingProofForRecovery: 0,
                          }
                          //SetUp
                          let tx: ContractTransactionResponse = await commitRevealRecoverRNG.setUp(
                              commitDuration,
                              commitRevealDuration,
                              testcases[i][j][round].n,
                              testcases[i][j][round].setupProofs,
                          )
                          let receipt: ContractTransactionReceipt | null = await tx.wait()
                          gasCostsPerFunction.setUpGas = receipt ? receipt.gasUsed.toString() : 0

                          // verifyRecursiveHalvingProofForSetup
                          tx =
                              await commitRevealRecoverRNG.verifyRecursiveHalvingProofExternalForTest(
                                  testcases[i][j][round].setupProofs,
                                  testcases[i][j][round].n,
                                  testcases[i][j][round].setupProofs.length,
                              )
                          receipt = await tx.wait()
                          gasCostsPerFunction.verifyRecursiveHalvingProofForSetup = receipt
                              ? receipt.gasUsed.toString()
                              : 0

                          //Commit
                          for (
                              let l: number = 0;
                              l < testcases[i][j][round].commitList.length;
                              l++
                          ) {
                              const tx = await commitRevealRecoverRNG
                                  .connect(signers[l])
                                  .commit(round, testcases[i][j][round].commitList[l])
                              const receipt = await tx.wait()
                              gasCostsPerFunction.commitGas.push(
                                  receipt ? receipt.gasUsed.toString() : 0,
                              )
                          }
                          await time.increase(commitDuration)
                          //Reveal
                          for (
                              let l: number = 0;
                              l < testcases[i][j][round].randomList.length;
                              l++
                          ) {
                              const tx = await commitRevealRecoverRNG
                                  .connect(signers[l])
                                  .reveal(round, testcases[i][j][round].randomList[l])
                              const receipt = await tx.wait()
                              gasCostsPerFunction.revealGas.push(
                                  receipt ? receipt.gasUsed.toString() : 0,
                              )
                          }

                          //Calculate Omega
                          tx = await commitRevealRecoverRNG.calculateOmega(round)
                          receipt = await tx.wait()
                          gasCostsPerFunction.calculateOmegaGas = receipt
                              ? receipt.gasUsed.toString()
                              : 0

                          // push gasCostsPerFunction
                          gasCostsCommitRevealCalculateOmega[i][j][key].push(gasCostsPerFunction)
                      }
                  }
              }
              if (!fs.existsSync(FILE_DIR_NAME)) fs.writeFileSync(FILE_DIR_NAME, JSON.stringify({}))
              const jsonObject = JSON.parse(fs.readFileSync(FILE_DIR_NAME, "utf-8"))
              console.log(
                  "gasCostsCommitRevealCalculateOmega",
                  gasCostsCommitRevealCalculateOmega[0][0],
              )
              console.log(
                  "gasCostsCommitRevealCalculateOmega",
                  gasCostsCommitRevealCalculateOmega[0][0]["λ1024T2^20"],
              )
              jsonObject["gasCostsCommitRevealCalculateOmega"] = gasCostsCommitRevealCalculateOmega
              console.log(jsonObject)
              fs.writeFileSync(FILE_DIR_NAME, JSON.stringify(jsonObject))
          })
          it("Commit Recover", async () => {
              const gasCostsCommitRecover: GasReportsObject[][] = []
              signers = await ethers.getSigners()
              for (let i = 0; i < testcases.length; i++) {
                  gasCostsCommitRecover.push([])
                  for (let j = 0; j < testcases[i].length; j++) {
                      const { commitRevealRecoverRNG, receipt } = await loadFixture(
                          deployCommitRevealRecoverRNGFixture,
                      )
                      const key = `${LAMDAs[i]}${Ts[j]}`
                      gasCostsCommitRecover[i].push({
                          [key]: [],
                      })
                      for (let round: number = 0; round < testcases[i][j].length; round++) {
                          const gasCostsPerFunction: GasReports = {
                              setUpGas: 0,
                              recoverGas: 0,
                              commitGas: [],
                              revealGas: [],
                              calculateOmegaGas: 0,
                              verifyRecursiveHalvingProofForSetup: 0,
                              verifyRecursiveHalvingProofForRecovery: 0,
                          }
                          //SetUp
                          let tx: ContractTransactionResponse = await commitRevealRecoverRNG.setUp(
                              commitDuration,
                              commitRevealDuration,
                              testcases[i][j][round].n,
                              testcases[i][j][round].setupProofs,
                          )
                          let receipt: ContractTransactionReceipt | null = await tx.wait()
                          gasCostsPerFunction.setUpGas = receipt ? receipt.gasUsed.toString() : 0

                          // verifyRecursiveHalvingProofForSetup
                          tx =
                              await commitRevealRecoverRNG.verifyRecursiveHalvingProofExternalForTest(
                                  testcases[i][j][round].setupProofs,
                                  testcases[i][j][round].n,
                                  testcases[i][j][round].setupProofs.length,
                              )
                          receipt = await tx.wait()
                          gasCostsPerFunction.verifyRecursiveHalvingProofForSetup = receipt
                              ? receipt.gasUsed.toString()
                              : 0
                          //Commit
                          for (
                              let l: number = 0;
                              l < testcases[i][j][round].commitList.length;
                              l++
                          ) {
                              const tx = await commitRevealRecoverRNG
                                  .connect(signers[l])
                                  .commit(round, testcases[i][j][round].commitList[l])
                              const receipt = await tx.wait()
                              gasCostsPerFunction.commitGas.push(
                                  receipt ? receipt.gasUsed.toString() : 0,
                              )
                          }
                          await time.increase(commitDuration)

                          //Recover
                          tx = await commitRevealRecoverRNG.recover(
                              round,
                              testcases[i][j][round].recoveryProofs,
                          )
                          receipt = await tx.wait()
                          gasCostsPerFunction.recoverGas = receipt ? receipt.gasUsed.toString() : 0

                          // verifyRecursiveHalvingProofForRecovery
                          tx =
                              await commitRevealRecoverRNG.verifyRecursiveHalvingProofExternalForTest(
                                  testcases[i][j][round].recoveryProofs,
                                  testcases[i][j][round].n,
                                  testcases[i][j][round].recoveryProofs.length,
                              )
                          receipt = await tx.wait()
                          gasCostsPerFunction.verifyRecursiveHalvingProofForRecovery = receipt
                              ? receipt.gasUsed.toString()
                              : 0

                          // push gasCostsPerFunction
                          gasCostsCommitRecover[i][j][key].push(gasCostsPerFunction)
                      }
                  }
              }
              if (!fs.existsSync(FILE_DIR_NAME)) fs.writeFileSync(FILE_DIR_NAME, JSON.stringify({}))
              const jsonObject = JSON.parse(fs.readFileSync(FILE_DIR_NAME, "utf-8"))
              jsonObject["gasCostsCommitRecover"] = gasCostsCommitRecover
              console.log(jsonObject)
              fs.writeFileSync(FILE_DIR_NAME, JSON.stringify(jsonObject))
          })
      })
