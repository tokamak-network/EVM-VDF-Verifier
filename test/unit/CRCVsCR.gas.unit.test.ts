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
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { expect } from "chai"
import { BigNumberish, BytesLike, dataLength, toBeHex } from "ethers"
import fs from "fs"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { CRCVsCR } from "../../typechain-types"
interface BigNumber {
    val: BytesLike
    bitlen: BigNumberish
}
interface VDFClaim2 {
    x: BigNumber
    y: BigNumber
    bigNumTwoPowerOfDelta: BytesLike
    delta: BigNumberish
}
type InitializeParams = [v: BigNumber[], xyd: VDFClaim2]
type CommitParams = [round: BigNumberish, c: BigNumber]
type RevealParams = [round: BigNumberish, a: BigNumber]
type CalculateOmegaParams = [round: BigNumberish]
type RecoverParams = [round: BigNumberish, v: BigNumber[], xyd: VDFClaim2]
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("CommitRevealCalculate Vs CommitRecover", async () => {
          let cRCVsCR: CRCVsCR
          let signers: SignerWithAddress[]
          it("CommitRevealCalculate", async function () {
              const CommitLens: number[] = [2, 3, 4, 5, 6, 7]
              const deltas = [8, 9, 10]
              const data = []
              signers = await ethers.getSigners()
              for (let i: number = 0; i < CommitLens.length; i++) {
                  const commitLen = CommitLens[i]
                  const { testCaseJson, setUpX, setUpY, recoverX, recoverY, setUpVs, recoverVs } =
                      createTestCase(commitLen)
                  for (let j: number = 0; j < deltas.length; j++) {
                      const delta = deltas[j]
                      let round: number = 0
                      const cRCVsCRFactory = await ethers.getContractFactory("CRCVsCR")
                      cRCVsCR = await cRCVsCRFactory.deploy()
                      await cRCVsCR.waitForDeployment()
                      //------------ initialize
                      const initializeParams: InitializeParams = [
                          setUpVs,
                          {
                              x: setUpX,
                              y: setUpY,
                              bigNumTwoPowerOfDelta: toBeHex(
                                  2 ** delta,
                                  getLength(dataLength(toBeHex(2 ** delta))),
                              ),
                              delta: delta,
                          },
                      ]
                      const txInitialize = await cRCVsCR.initialize(...initializeParams)
                      const receiptInitialize = await txInitialize.wait()
                      const gasUsedInitialize = receiptInitialize?.gasUsed
                      //   console.log(commitLen, delta, "initialize", gasUsedInitialize)
                      //------------ requestRandomWord
                      const txRequestRandomWord = await cRCVsCR.requestRandomWord()
                      const receiptRequestRandomWord = await txRequestRandomWord.wait()
                      const gasUsedRequestRandomWord = receiptRequestRandomWord?.gasUsed
                      //   console.log(commitLen, delta, "requestRandomWord", gasUsedRequestRandomWord)
                      //------------ commit
                      let gasUsedCommits = []
                      for (let k: number = 0; k < commitLen; k++) {
                          const commitParams: CommitParams = [round, testCaseJson.commitList[k]]
                          const txCommit = await cRCVsCR.connect(signers[k]).commit(...commitParams)
                          const receiptCommit = await txCommit.wait()
                          const gasUsedCommit = receiptCommit?.gasUsed
                          gasUsedCommits.push(gasUsedCommit)
                          //   console.log(commitLen, delta, "commit", gasUsedCommit)
                      }
                      //----------------- time incrase
                      await time.increase(120)
                      //----------------- reveal
                      let gasUsedReveals = []
                      for (let k: number = 0; k < commitLen; k++) {
                          const revealParams: RevealParams = [round, testCaseJson.randomList[k]]
                          const txReveal = await cRCVsCR.connect(signers[k]).reveal(...revealParams)
                          const receiptReveal = await txReveal.wait()
                          const gasUsedReveal = receiptReveal?.gasUsed
                          gasUsedReveals.push(gasUsedReveal)
                          //   console.log(commitLen, delta, "reveal", gasUsedReveal)
                      }
                      //----------------- calculateOmega
                      const calculateOmegaParams: CalculateOmegaParams = [round]
                      const txCalculateOmega = await cRCVsCR.calculateOmega(...calculateOmegaParams)
                      const receiptCalculateOmega = await txCalculateOmega.wait()
                      const gasUsedCalculateOmega = receiptCalculateOmega?.gasUsed
                      //   console.log(commitLen, delta, "calculateOmega", gasUsedCalculateOmega)
                      //----------------- get omega
                      const omega = await cRCVsCR.getValuesAtRound(round)
                      expect(omega[6].val).to.equal(testCaseJson.omega.val)
                      expect(omega[6].bitlen).to.equal(testCaseJson.omega.bitlen)
                      let gasUsedCommitSum = 0n
                      let gasUsedRevealSum = 0n
                      for (let k: number = 0; k < commitLen; k++) {
                          gasUsedCommitSum = gasUsedCommitSum + gasUsedCommits[k]!
                          gasUsedRevealSum = gasUsedRevealSum + gasUsedReveals[k]!
                      }
                      const totalRevealCalculateUsed = gasUsedRevealSum + gasUsedCalculateOmega!
                      data.push({
                          commitLen: commitLen,
                          delta: delta,
                          initialize: gasUsedInitialize,
                          requestRandomWord: gasUsedRequestRandomWord,
                          commit: gasUsedCommits,
                          reveal: gasUsedReveals,
                          calculateOmega: gasUsedCalculateOmega,
                          reveal_calculate: totalRevealCalculateUsed,
                      })
                      //   data.push([
                      //       commitLen,
                      //       delta,
                      //       Number(gasUsedInitialize),
                      //       Number(gasUsedRequestRandomWord),
                      //       Number(gasUsedCommitSum),
                      //       Number(gasUsedRevealSum),
                      //       Number(gasUsedCalculateOmega),
                      //       Number(totalRevealCalculateUsed),
                      //   ])
                  }
              }
              console.log(data)
          })
          it("CommitRecover", async function () {
              const CommitLens: number[] = [2, 3, 4, 5, 6, 7]
              const deltas = [8, 9, 10]
              const data = []
              signers = await ethers.getSigners()
              for (let i: number = 0; i < CommitLens.length; i++) {
                  const commitLen = CommitLens[i]
                  const { testCaseJson, setUpX, setUpY, recoverX, recoverY, setUpVs, recoverVs } =
                      createTestCase(commitLen)
                  for (let j: number = 0; j < deltas.length; j++) {
                      const delta = deltas[j]
                      let round: number = 0
                      const cRCVsCRFactory = await ethers.getContractFactory("CRCVsCR")
                      cRCVsCR = await cRCVsCRFactory.deploy()
                      await cRCVsCR.waitForDeployment()
                      //------------ initialize
                      const initializeParams: InitializeParams = [
                          setUpVs,
                          {
                              x: setUpX,
                              y: setUpY,
                              bigNumTwoPowerOfDelta: toBeHex(
                                  2 ** delta,
                                  getLength(dataLength(toBeHex(2 ** delta))),
                              ),
                              delta: delta,
                          },
                      ]
                      const txInitialize = await cRCVsCR.initialize(...initializeParams)
                      const receiptInitialize = await txInitialize.wait()
                      const gasUsedInitialize = receiptInitialize?.gasUsed
                      //   console.log(commitLen, delta, "initialize", gasUsedInitialize)
                      //------------ requestRandomWord
                      const txRequestRandomWord = await cRCVsCR.requestRandomWord()
                      const receiptRequestRandomWord = await txRequestRandomWord.wait()
                      const gasUsedRequestRandomWord = receiptRequestRandomWord?.gasUsed
                      //   console.log(commitLen, delta, "requestRandomWord", gasUsedRequestRandomWord)
                      //------------ commit
                      let gasUsedCommits = []
                      for (let k: number = 0; k < commitLen; k++) {
                          const commitParams: CommitParams = [round, testCaseJson.commitList[k]]
                          const txCommit = await cRCVsCR.connect(signers[k]).commit(...commitParams)
                          const receiptCommit = await txCommit.wait()
                          const gasUsedCommit = receiptCommit?.gasUsed
                          gasUsedCommits.push(gasUsedCommit)
                          //   console.log(commitLen, delta, "commit", gasUsedCommit)
                      }
                      //----------------- time incrase
                      await time.increase(120)
                      //----------------- recover
                      const recoverParams: RecoverParams = [
                          round,
                          recoverVs,
                          {
                              x: recoverX,
                              y: recoverY,
                              bigNumTwoPowerOfDelta: toBeHex(
                                  2 ** delta,
                                  getLength(dataLength(toBeHex(2 ** delta))),
                              ),
                              delta: delta,
                          },
                      ]
                      const txRecover = await cRCVsCR.recover(...recoverParams)
                      const receiptRecover = await txRecover.wait()
                      const gasUsedRecover = receiptRecover?.gasUsed
                      //   console.log(commitLen, delta, "recover", gasUsedRecover)
                      //----------------- get omega
                      const omega = await cRCVsCR.getValuesAtRound(round)
                      expect(omega[6].val).to.equal(testCaseJson.omega.val)
                      expect(omega[6].bitlen).to.equal(testCaseJson.omega.bitlen)
                      let gasUsedCommitSum = 0n
                      for (let k: number = 0; k < commitLen; k++) {
                          gasUsedCommitSum = gasUsedCommitSum + gasUsedCommits[k]!
                      }
                      data.push({
                          commitLen: commitLen,
                          delta: delta,
                          initialize: gasUsedInitialize,
                          requestRandomWord: gasUsedRequestRandomWord,
                          commit: gasUsedCommitSum,
                          recover: gasUsedRecover,
                      })
                      //   data.push([
                      //       commitLen,
                      //       delta,
                      //       Number(gasUsedInitialize),
                      //       Number(gasUsedRequestRandomWord),
                      //       Number(gasUsedCommitSum),
                      //       Number(gasUsedRecover),
                      //   ])
                  }
              }
              console.log(data)
          })
      })

const createTestCase = (commitLen: number) => {
    const commitLenString = commitLen.toString()
    const testCaseJson = JSON.parse(
        fs.readFileSync(
            __dirname + `/../shared/differentCommitLength/${commitLenString}/one.json`,
            "utf-8",
        ),
    )
    const setUpX = testCaseJson.setupProofs[0].x
    const setUpY = testCaseJson.setupProofs[0].y
    const recoverX = testCaseJson.recoveryProofs[0].x
    const recoverY = testCaseJson.recoveryProofs[0].y
    let setUpVs = []
    let recoverVs = []
    for (let i: number = 0; i < testCaseJson.setupProofs.length; i++) {
        delete testCaseJson.setupProofs[i].x
        delete testCaseJson.setupProofs[i].y
        delete testCaseJson.setupProofs[i].n
        delete testCaseJson.setupProofs[i].T
        delete testCaseJson.recoveryProofs[i].x
        delete testCaseJson.recoveryProofs[i].y
        delete testCaseJson.recoveryProofs[i].n
        delete testCaseJson.recoveryProofs[i].T
        setUpVs.push(testCaseJson.setupProofs[i].v)
        recoverVs.push(testCaseJson.recoveryProofs[i].v)
    }
    return { testCaseJson, setUpX, setUpY, recoverX, recoverY, setUpVs, recoverVs }
}

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
