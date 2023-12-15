import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { assert, expect } from "chai"
import { BigNumberish, Contract, ContractTransactionReceipt, Log } from "ethers"
import { network, deployments, ethers, getNamedAccounts } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { CommitRecover, CommitRecover__factory } from "../../typechain-types"
import { TestCase, BigNumber, SetUpParams, CommitParams, RevealParams } from "../shared/interfaces"
import { testCases } from "../shared/testcases"
import {
    createTestCases,
    deployCommitRecover,
    setUpCommitRecoverRound,
    initializedContractCorrectly,
    deployFirstTestCaseCommitRevealContract,
    commit,
    reveal,
} from "../shared/testFunctions"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { assertTestAfterDeploy, assertTestAfterGettingOmega } from "../shared/assertFunctions"
//const { time } = require("@nomicfoundation/hardhat-network-helpers")}

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("CommitRecover Unit Test", () => {
          const testcases: TestCase[] = createTestCases(testCases)
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
          describe("deploy contract and check", () => {
              it("try deploy several times and should pass", async () => {
                  for (let i = 0; i < testcases.length; i++) {
                      const { commitRecoverContract, receipt } = await deployCommitRecover()
                      await assertTestAfterDeploy(commitRecoverContract)
                  }
              })
          })
          describe("setUp", () => {
              it("setUp for every testcase should pass, multiple rounds", async () => {
                  for (let i = 0; i < testcases.length; i++) {
                      let { commitRecoverContract, receipt } = await deployCommitRecover()
                      let params: SetUpParams = {
                          commitDuration,
                          commitRevealDuration,
                          n: testcases[i].n,
                          setupProofs: testcases[i].setupProofs,
                      }
                      let setUpReceipt = await setUpCommitRecoverRound(
                          commitRecoverContract,
                          params,
                      )
                  }
              })
          })
          let signers: SignerWithAddress[]
          describe("commit", () => {
              it("commit for every testcase should pass, multiple rounds", async () => {
                  let { commitRecoverContract, receipt } = await deployCommitRecover()
                  for (let round = 0; round < testcases.length; round++) {
                      let params: SetUpParams = {
                          commitDuration,
                          commitRevealDuration,
                          n: testcases[round].n,
                          setupProofs: testcases[round].setupProofs,
                      }
                      let setUpReceipt = await setUpCommitRecoverRound(
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
                  }
              })
          })
          describe("reveal", () => {
              it("reveal for every testcase should pass, multiple rounds", async () => {
                  let { commitRecoverContract, receipt } = await deployCommitRecover()
                  for (let round = 0; round < testcases.length; round++) {
                      let params: SetUpParams = {
                          commitDuration,
                          commitRevealDuration,
                          n: testcases[round].n,
                          setupProofs: testcases[round].setupProofs,
                      }
                      let setUpReceipt = await setUpCommitRecoverRound(
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
                  }
              })
          })
          describe("calculate Omega", () => {
              it("All Revealed, Calculated Omega should be correct for every testcase, multiple rounds", async () => {
                  let { commitRecoverContract, receipt } = await deployCommitRecover()
                  for (let round = 0; round < testcases.length; round++) {
                      let params: SetUpParams = {
                          commitDuration,
                          commitRevealDuration,
                          n: testcases[round].n,
                          setupProofs: testcases[round].setupProofs,
                      }
                      let setUpReceipt = await setUpCommitRecoverRound(
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
          describe("recover", () => {
              it("Recovered Omega should be correct for every testcase, multiple rounds", async () => {
                  let { commitRecoverContract, receipt } = await deployCommitRecover()
                  for (let round = 0; round < testcases.length; round++) {
                      let params: SetUpParams = {
                          commitDuration,
                          commitRevealDuration,
                          n: testcases[round].n,
                          setupProofs: testcases[round].setupProofs,
                      }
                      let setUpReceipt = await setUpCommitRecoverRound(
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
          })
      })
