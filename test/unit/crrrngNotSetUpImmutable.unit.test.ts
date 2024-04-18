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
import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers"
import { ContractTransactionReceipt, ContractTransactionResponse } from "ethers"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { TestCase } from "../shared/interfacesV2"
import { createTestCaseV2, deployCommitRevealRecoverRNGFixture } from "../shared/testFunctionsV2"

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("CommitRevealRecover SetUp Not Immutable", () => {
          const testcases: TestCase = createTestCaseV2()
          const chainId = network.config.chainId
          let commitDuration = 120
          let commitRevealDuration = 240
          let signers: SignerWithAddress[]
          it("Commit Reveal Recover", async () => {
              signers = await ethers.getSigners()
              // Contract Deploy
              const { commitRevealRecoverRNG, receipt } = await loadFixture(
                  deployCommitRevealRecoverRNGFixture,
              )
              for (let r = 0; r < 3; r++) {
                  // SetUp
                  let tx: ContractTransactionResponse = await commitRevealRecoverRNG.setUp(
                      commitDuration,
                      commitRevealDuration,
                      testcases.T,
                      testcases.n,
                      testcases.setupProofs,
                  )
                  let txReceipt: ContractTransactionReceipt | null = await tx.wait()
                  let round: number = Number(
                      await commitRevealRecoverRNG.interface
                          .parseLog({
                              topics: txReceipt?.logs[0].topics as string[],
                              data: txReceipt?.logs[0].data as string,
                          })
                          ?.args[8].toString(),
                  )
                  console.log("round:", round)
                  // Commit
                  for (let i: number = 0; i < testcases.commitList.length; i++) {
                      tx = await commitRevealRecoverRNG
                          .connect(signers[i])
                          .commit(round, testcases.commitList[i])
                      txReceipt = await tx.wait()
                  }
                  // Recover
                  await time.increase(commitDuration)
                  tx = await commitRevealRecoverRNG.recover(round, testcases.recoveryProofs)
                  txReceipt = await tx.wait()
              }
          })
      })
