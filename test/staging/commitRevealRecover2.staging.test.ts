// Copyright 2023 justin
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
import { assert, expect } from "chai"
import { BigNumberish, Contract, ContractTransactionReceipt, Log } from "ethers"
import { network, deployments, ethers, getNamedAccounts } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { CommitRecover, CommitRecover__factory } from "../../typechain-types"
import { TestCase, BigNumber, StartParams, CommitParams, RevealParams } from "../shared/interfaces"
import { testCases2 } from "../shared/testcases2"
import {
    createTestCases,
    createTestCases2,
    deployCommitRecover,
    startCommitRecoverRound,
    initializedContractCorrectly,
    deployFirstTestCaseCommitRevealContract,
    commit,
    reveal,
} from "../shared/testFunctions"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { assertTestAfterDeploy, assertTestAfterGettingOmega } from "../shared/assertFunctions"

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("CommitRecover Staging Test2", () => {
          const testcases: TestCase[] = createTestCases2()
          const chainId = network.config.chainId
          let deployer: SignerWithAddress
          let commitDuration = networkConfig[chainId!].commitDuration
          let commitRevealDuration = networkConfig[chainId!].commitRevealDuration
          let _n: BigNumberish
          before(async () => {
              deployer = await ethers.getSigner((await getNamedAccounts()).deployer)
              console.log(
                  "\n   ___  _                       ___  _  __  ___       _____ \n \
  / _ )(_)______  _______  ____/ _ | |/_/ / _ ___  / ___/ \n \
  / _  / / __/ _ / __/ _ /___/ , _/>  <  / ___/ _ / /__  \n \
  /____/_/__/___/_/ /_//_/   /_/|_/_/|_| /_/   ___/___/  \n",
              )
          })
          let signers: SignerWithAddress[]
          let firstTestCases: TestCase
          let firstrandomList: BigNumber[] = []
          let firstcommitList: BigNumber[] = []
          const testCaseNum = 0
          describe("test 1 round", () => {
              it("commit recover", async () => {
                  let { commitRecoverContract, receipt } = await deployCommitRecover()
                  for (let round = 0; round < testcases.length; round++) {
                      let params: StartParams = {
                          commitDuration,
                          commitRevealDuration,
                          n: testcases[round].n,
                          setupProofs: testcases[round].setupProofs,
                      }
                      let startReceipt = await startCommitRecoverRound(
                          commitRecoverContract,
                          params,
                      )
                      signers = await ethers.getSigners()
                      for (let j = 0; j < testcases[round].commitList.length; j++) {
                          let commitParams: CommitParams = {
                              round: round,
                              commit: testcases[round].commitList[j],
                          }
                          await commit(commitRecoverContract, signers[j], commitParams)
                      }
                      await time.increase(commitDuration)
                      const tx = await commitRecoverContract.recover(
                          round,
                          testcases[round].recoveryProofs,
                      )
                      const receipt = await tx.wait()
                      const omega = (await commitRecoverContract.valuesAtRound(round)).omega
                      assertTestAfterGettingOmega(
                          omega,
                          testcases[round].omega,
                          testcases[round].recoveredOmega,
                      )
                  }
              })
              it("commit reveal calculateOmega", async () => {
                  let { commitRecoverContract, receipt } = await deployCommitRecover()
                  for (let round = 0; round < testcases.length; round++) {
                      let params: StartParams = {
                          commitDuration,
                          commitRevealDuration,
                          n: testcases[round].n,
                          setupProofs: testcases[round].setupProofs,
                      }
                      let startReceipt = await startCommitRecoverRound(
                          commitRecoverContract,
                          params,
                      )
                      signers = await ethers.getSigners()
                      for (let j = 0; j < testcases[round].commitList.length; j++) {
                          let commitParams: CommitParams = {
                              round: round,
                              commit: testcases[round].commitList[j],
                          }
                          await commit(commitRecoverContract, signers[j], commitParams)
                      }
                      await time.increase(commitDuration)
                      for (let j = 0; j < testcases[round].randomList.length; j++) {
                          let revealParams: RevealParams = {
                              round: round,
                              reveal: testcases[round].randomList[j],
                          }
                          await reveal(commitRecoverContract, signers[j], revealParams)
                      }
                      const tx = await commitRecoverContract.calculateOmega(round)
                      const receipt = await tx.wait()
                      const omega = (await commitRecoverContract.valuesAtRound(round)).omega
                      assertTestAfterGettingOmega(
                          omega,
                          testcases[round].omega,
                          testcases[round].recoveredOmega,
                      )
                  }
              })
          })
      })
