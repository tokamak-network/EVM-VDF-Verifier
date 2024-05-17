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
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { time } from "@nomicfoundation/hardhat-network-helpers"
import { expect } from "chai"
import { AddressLike, BigNumberish, BytesLike } from "ethers"
import fs from "fs"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { CRRNGCoordinator, ConsumerExample } from "../../typechain-types"
interface BigNumber {
    val: BytesLike
    bitlen: BigNumberish
}
interface ValueAtRound {
    startTime: BigNumberish
    numOfPariticipants: BigNumberish
    count: BigNumberish
    consumer: AddressLike
    bStar: BytesLike
    commitsString: BytesLike
    omega: BigNumber
    stage: BigNumberish
    isCompleted: boolean
    isAllRevealed: boolean
}
function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(fs.readFileSync(__dirname + "/../shared/correct.json", "utf-8"))
    return testCaseJson
}

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("ConsumerExample Test", function () {
          const callback_gaslimit = 50000
          const delta: number = 9
          const coordinatorConstructorParams: {
              disputePeriod: BigNumberish
              minimumDepositAmount: BigNumberish
              avgRecoveOverhead: BigNumberish
              premiumPercentage: BigNumberish
              flatFee: BigNumberish
          } = {
              disputePeriod: 180n,
              minimumDepositAmount: ethers.parseEther("0.0001"),
              avgRecoveOverhead: 0n,
              premiumPercentage: 0n,
              flatFee: 0n,
          }
          let testCaseJson
          let signers: SignerWithAddress[]
          let crrrngCoordinator: CRRNGCoordinator
          let crrngCoordinatorAddress: string
          let consumerExample: ConsumerExample
          let initializeParams: {
              v: BigNumber[]
              x: BigNumber
              y: BigNumber
          } = {
              v: [],
              x: { val: "0x0", bitlen: 0 },
              y: { val: "0x0", bitlen: 0 },
          }
          let commitParams: BigNumber[] = []
          let recoverParams: {
              round: number
              v: BigNumber[]
              x: BigNumber
              y: BigNumber
          } = {
              round: 0,
              v: [],
              x: { val: "0x0", bitlen: 0 },
              y: { val: "0x0", bitlen: 0 },
          }
          let smallestHashSigner: SignerWithAddress
          let secondSmallestHashSigner: SignerWithAddress
          let thirdSmallestHashSigner: SignerWithAddress
          describe("Settings", function () {
              it("get signers", async () => {
                  signers = await ethers.getSigners()
                  expect(signers.length).to.eq(500)
              })
              it("Create TestCase And PreProcess Data", async () => {
                  testCaseJson = createCorrectAlgorithmVersionTestCase()
                  //initializeParams
                  initializeParams.x = testCaseJson.setupProofs[0].x
                  initializeParams.y = testCaseJson.setupProofs[0].y
                  if (delta > 0) {
                      testCaseJson.setupProofs = testCaseJson.setupProofs?.slice(0, -(delta + 1))
                      testCaseJson.recoveryProofs = testCaseJson.recoveryProofs?.slice(
                          0,
                          -(delta + 1),
                      )
                  }
                  for (let i = 0; i < testCaseJson.setupProofs.length; i++) {
                      initializeParams.v.push(testCaseJson.setupProofs[i].v)
                      recoverParams.v.push(testCaseJson.recoveryProofs[i].v)
                  }
                  //commitParams
                  for (let i = 0; i < testCaseJson.commitList.length; i++) {
                      commitParams.push(testCaseJson.commitList[i])
                  }
                  //recoverParams
                  recoverParams.x = testCaseJson.recoveryProofs[0].x
                  recoverParams.y = testCaseJson.recoveryProofs[0].y
              })
              it("deploy CRRRRNGCoordinator", async function () {
                  const CRRNGCoordinator = await ethers.getContractFactory("CRRNGCoordinator")
                  crrrngCoordinator = await CRRNGCoordinator.deploy(
                      coordinatorConstructorParams.disputePeriod,
                      coordinatorConstructorParams.minimumDepositAmount,
                      coordinatorConstructorParams.avgRecoveOverhead,
                      coordinatorConstructorParams.premiumPercentage,
                      coordinatorConstructorParams.flatFee,
                  )
                  await crrrngCoordinator.waitForDeployment()
                  const receipt = await crrrngCoordinator.deploymentTransaction()?.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  const gasPrice = receipt?.gasPrice as bigint
                  console.log("deploy CRRRRNGCoordinators", gasUsed * gasPrice)
                  crrngCoordinatorAddress = await crrrngCoordinator.getAddress()
                  expect(crrngCoordinatorAddress).to.be.properAddress
              })
              it("initialize CRRNGCoordinator", async () => {
                  const balanceBefore = await ethers.provider.getBalance(signers[0].address)
                  const tx = await crrrngCoordinator.initialize(
                      initializeParams.v,
                      initializeParams.x,
                      initializeParams.y,
                  )
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  const gasPrice = receipt?.gasPrice as bigint
                  console.log("initialize", gasUsed * gasPrice)
                  const balanceAfter = await ethers.provider.getBalance(signers[0].address)
              })
              it("deploy ConsumerExample", async () => {
                  const ConsumerExample = await ethers.getContractFactory("ConsumerExample")
                  consumerExample = await ConsumerExample.deploy(crrngCoordinatorAddress)
                  await consumerExample.waitForDeployment()
                  const receipt = await consumerExample.deploymentTransaction()?.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  const gasPrice = receipt?.gasPrice as bigint
                  console.log("deploy ConsumerExample", gasUsed * gasPrice)
                  const consumerExampleAddress = await consumerExample.getAddress()
                  expect(consumerExampleAddress).to.be.properAddress
              })
              it("5 operators deposit to become operator", async () => {
                  const minimumDepositAmount = coordinatorConstructorParams.minimumDepositAmount
                  const minimumDepositAmountFromContract =
                      await crrrngCoordinator.getMinimumDepositAmount()
                  expect(minimumDepositAmount).to.equal(minimumDepositAmountFromContract)

                  for (let i: number = 0; i < 5; i++) {
                      const depositedAmount = await crrrngCoordinator.getDepositAmount(
                          signers[i].address,
                      )
                      if (depositedAmount < BigInt(minimumDepositAmount)) {
                          const tx = await crrrngCoordinator.connect(signers[i]).operatorDeposit({
                              value: BigInt(minimumDepositAmount) - depositedAmount,
                          })
                          const receipt = await tx.wait()
                      }
                      const depositedAmountAfter = await crrrngCoordinator.getDepositAmount(
                          signers[i].address,
                      )
                      expect(depositedAmountAfter).to.equal(minimumDepositAmount)
                  }
              })
          })
          describe("test RequestRandomWord", function () {
              it("Request Randomword on ConsumerExample", async () => {
                  const provider = ethers.provider
                  const fee = await provider.getFeeData()
                  const gasPrice = fee.gasPrice as bigint
                  const directFundingCost = await crrrngCoordinator.estimateDirectFundingPrice(
                      callback_gaslimit,
                      gasPrice,
                  )
                  const tx = await consumerExample.requestRandomWord({
                      value: (directFundingCost * (100n + 1n)) / 100n,
                  })
                  console.log("directFundingCost", directFundingCost)
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  const gasPrice2 = receipt?.gasPrice as bigint
                  console.log("requestRandomWord", gasUsed * gasPrice2)
                  const requestCount = await consumerExample.requestCount()
                  const lastReqeustId = await consumerExample.lastRequestId()
                  const lastRequestIdfromArray = await consumerExample.requestIds(requestCount - 1n)
                  expect(lastReqeustId).to.equal(lastRequestIdfromArray)
                  const requestStatus = await consumerExample.getRequestStatus(lastReqeustId)
                  expect(requestStatus[0]).to.equal(true)
                  expect(requestStatus[1]).to.equal(false)
                  expect(requestStatus[2]).to.equal(0n)
              })
              it("3 operators commit to CRRNGCoordinator", async () => {
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const numOfOperators = 3
                  for (let i = 0; i < numOfOperators; i++) {
                      const tx = await crrrngCoordinator
                          .connect(signers[i])
                          .commit(round, commitParams[i])
                      const receipt = await tx.wait()
                      const valuesAtRound: ValueAtRound =
                          await crrrngCoordinator.getValuesAtRound(round)
                      expect(valuesAtRound.count).to.equal(i + 1)
                      const gasUsed = receipt?.gasUsed as bigint
                      const gasPrice = receipt?.gasPrice as bigint
                      console.log("commit", gasUsed * gasPrice)

                      const userInfoAtRound = await crrrngCoordinator.getUserStatusAtRound(
                          signers[i].address,
                          round,
                      )
                      expect(userInfoAtRound.committed).to.equal(true)
                      expect(userInfoAtRound.revealed).to.equal(false)
                      expect(userInfoAtRound.index).to.equal(i)

                      const getCommitRevealValues = await crrrngCoordinator.getCommitRevealValues(
                          round,
                          userInfoAtRound.index,
                      )
                      expect(getCommitRevealValues.c.val).to.equal(commitParams[i].val)
                      expect(getCommitRevealValues.participantAddress).to.equal(signers[i].address)
                  }
              })
              it("calculate hash(R|address) for each operator", async () => {
                  const Rval = recoverParams.y.val
                  const hashResults: any = []
                  for (let i = 0; i < 3; i++) {
                      const hash = ethers.solidityPackedKeccak256(
                          ["bytes", "address"],
                          [Rval, signers[i].address],
                      )
                      hashResults.push([hash, signers[i].address, i])
                  }
                  hashResults.sort()
                  const provider = ethers.provider
                  thirdSmallestHashSigner = await provider.getSigner(hashResults[2][1])
                  secondSmallestHashSigner = await provider.getSigner(hashResults[1][1])
                  smallestHashSigner = await provider.getSigner(hashResults[0][1])
              })
              it("thirdSmallestHashSigner recover", async () => {
                  await time.increase(120n)
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const tx = await crrrngCoordinator
                      .connect(thirdSmallestHashSigner)
                      .recover(round, recoverParams.v, recoverParams.x, recoverParams.y)
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  const gasPrice = receipt?.gasPrice as bigint
                  console.log("recover", gasUsed * gasPrice)
                  const valuesAtRound: ValueAtRound =
                      await crrrngCoordinator.getValuesAtRound(round)
                  expect(valuesAtRound.count).to.equal(3)
                  const userInfoAtRound = await crrrngCoordinator.getUserStatusAtRound(
                      thirdSmallestHashSigner.address,
                      round,
                  )
                  expect(userInfoAtRound.committed).to.equal(true)
                  expect(userInfoAtRound.index).to.equal(2)

                  const valueAtRound = await crrrngCoordinator.getValuesAtRound(round)
                  expect(valueAtRound.isAllRevealed).to.equal(false)
                  expect(valueAtRound.stage).to.equal(0n)
                  expect(valueAtRound.omega.val).to.equal(recoverParams.y.val)
                  expect(valueAtRound.omega.bitlen).to.equal(recoverParams.y.bitlen)
                  const consumerAddress = await consumerExample.getAddress()
                  expect(valueAtRound.consumer).to.equal(consumerAddress)
                  expect(valueAtRound.numOfPariticipants).to.equal(3)
                  expect(valueAtRound.isCompleted).to.equal(true)
                  expect(valueAtRound.count).to.equal(3)

                  const provider = ethers.provider
                  const serviceValueAtRound =
                      await crrrngCoordinator.getDisputeEndTimeAndLeaderAtRound(round)
                  const blockNumber = receipt?.blockNumber
                  const blockTimestamp = (await provider.getBlock(blockNumber as number))?.timestamp
                  expect(serviceValueAtRound[0]).to.equal(
                      BigInt(blockTimestamp as number) +
                          BigInt(coordinatorConstructorParams.disputePeriod),
                  )
                  expect(serviceValueAtRound[1]).to.equal(thirdSmallestHashSigner.address)

                  const serviceValueForOperator =
                      await crrrngCoordinator.getDisputeEndTimeAndIncentiveOfOperator(
                          thirdSmallestHashSigner.address,
                      )
                  expect(serviceValueForOperator[0]).to.equal(
                      BigInt(blockTimestamp as number) +
                          BigInt(coordinatorConstructorParams.disputePeriod),
                  )
                  expect(serviceValueForOperator[1]).to.equal(
                      await crrrngCoordinator.getCostAtRound(round),
                  )

                  const requestCount = await consumerExample.requestCount()
                  const lastReqeustId = await consumerExample.lastRequestId()
                  const lastRequestIdfromArray = await consumerExample.requestIds(requestCount - 1n)
                  expect(lastReqeustId).to.equal(lastRequestIdfromArray)
                  const requestStatus = await consumerExample.getRequestStatus(lastReqeustId)
                  expect(requestStatus[0]).to.equal(true)
                  expect(requestStatus[1]).to.equal(true)
                  console.log(requestStatus[2].toString())
              })
          })
          describe("test Dispute", function () {
              it("secondSmallestHashSigner disputeLeadershipAtRound", async () => {
                  // ** get before
                  const getServiceValueForOperatorThirdBefore =
                      await crrrngCoordinator.getDisputeEndTimeAndIncentiveOfOperator(
                          thirdSmallestHashSigner.address,
                      )
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const tx = await crrrngCoordinator
                      .connect(secondSmallestHashSigner)
                      .disputeLeadershipAtRound(round)
                  const receipt = await tx.wait()

                  // ** get
                  const getDisputeEndTimeAndLeaderAtRound =
                      await crrrngCoordinator.getDisputeEndTimeAndLeaderAtRound(round)
                  const getServiceValueForOperatorSecond =
                      await crrrngCoordinator.getDisputeEndTimeAndIncentiveOfOperator(
                          secondSmallestHashSigner.address,
                      )
                  const getServiceValueForOperatorThird =
                      await crrrngCoordinator.getDisputeEndTimeAndIncentiveOfOperator(
                          thirdSmallestHashSigner.address,
                      )

                  // ** assert
                  expect(getDisputeEndTimeAndLeaderAtRound[1]).to.equal(
                      secondSmallestHashSigner.address,
                  )
                  expect(getServiceValueForOperatorSecond[0]).to.equal(
                      getDisputeEndTimeAndLeaderAtRound[0],
                  )
                  expect(getServiceValueForOperatorSecond[1]).to.equal(
                      await crrrngCoordinator.getCostAtRound(round),
                  )
                  expect(getServiceValueForOperatorThird[0]).to.equal(0n)
                  expect(getServiceValueForOperatorThird[1]).to.equal(
                      getServiceValueForOperatorThirdBefore[1] -
                          (await crrrngCoordinator.getCostAtRound(round)),
                  )
                  console.log("yeah")
              })
              it("firstSmallestHashSigner disputeLeadershipAtRound", async () => {
                  // ** get before
                  const getServiceValueForOperatorSecondBefore =
                      await crrrngCoordinator.getDisputeEndTimeAndIncentiveOfOperator(
                          secondSmallestHashSigner.address,
                      )
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const tx = await crrrngCoordinator
                      .connect(smallestHashSigner)
                      .disputeLeadershipAtRound(round)
                  const receipt = await tx.wait()

                  // ** get
                  const getDisputeEndTimeAndLeaderAtRound =
                      await crrrngCoordinator.getDisputeEndTimeAndLeaderAtRound(round)
                  const getServiceValueForOperatorSecond =
                      await crrrngCoordinator.getDisputeEndTimeAndIncentiveOfOperator(
                          secondSmallestHashSigner.address,
                      )
                  const getServiceValueForSmallest =
                      await crrrngCoordinator.getDisputeEndTimeAndIncentiveOfOperator(
                          smallestHashSigner.address,
                      )

                  // ** assert
                  expect(getDisputeEndTimeAndLeaderAtRound[1]).to.equal(smallestHashSigner.address)
                  expect(getServiceValueForOperatorSecond[0]).to.equal(0n)
                  expect(getServiceValueForSmallest[1]).to.equal(
                      await crrrngCoordinator.getCostAtRound(round),
                  )
                  expect(getServiceValueForSmallest[0]).to.equal(
                      getDisputeEndTimeAndLeaderAtRound[0],
                  )
                  expect(getServiceValueForOperatorSecond[1]).to.equal(
                      getServiceValueForOperatorSecondBefore[1] -
                          (await crrrngCoordinator.getCostAtRound(round)),
                  )
              })
          })
      })
