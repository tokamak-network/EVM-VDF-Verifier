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
import { CRRNGCoordinatorPoF, ConsumerExample } from "../../typechain-types"
import OVM_GasPriceOracleABI from "../shared/OVM_GasPriceOracle.json"
interface BigNumber {
    val: BytesLike
    bitlen: BigNumberish
}
interface ValueAtRound {
    startTime: BigNumberish
    commitCounts: BigNumberish
    consumer: AddressLike
    omega: BigNumber
    stage: BigNumberish
    isCompleted: boolean
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
    : describe("ProofOfFraud Test PoF1", function () {
          const L1_FEE_DATA_PADDING =
              "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
          let callback_gaslimit: BigNumberish
          const delta: number = 9
          const coordinatorConstructorParams: {
              disputePeriod: BigNumberish
              minimumDepositAmount: BigNumberish
              avgL2GasUsed: BigNumberish
              avgL1GasUsed: BigNumberish
              premiumPercentage: BigNumberish
              penaltyPercentage: BigNumberish
              flatFee: BigNumberish
          } = {
              disputePeriod: 180n,
              minimumDepositAmount: ethers.parseEther("0.005"),
              avgL2GasUsed: 2101449n,
              avgL1GasUsed: 27824n,
              premiumPercentage: 0n,
              penaltyPercentage: 20n,
              flatFee: ethers.parseEther("0.001"),
          }
          let testCaseJson
          let signers: SignerWithAddress[]
          let crrrngCoordinator: CRRNGCoordinatorPoF
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
                  await expect(signers.length).to.eq(500)
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
              it("test callbackGasLimit for example contract", async function () {
                  const ConsumerExample = await ethers.getContractFactory("ConsumerExampleTest")
                  const consumerExample = await ConsumerExample.deploy(signers[0])
                  const tx = await consumerExample.rawFulfillRandomWords(
                      0,
                      ethers.keccak256("0x01"),
                  )
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  console.log(`example test fulfillRandomword gasUsed: ${gasUsed}`)
                  console.log(
                      "callback_gaslimit should be greater than the gasUsed * 1.25",
                      (gasUsed * (100n + 25n)) / 100n,
                  )
                  callback_gaslimit = (gasUsed * (100n + 25n)) / 100n
              })
              it("deploy CRRRRNGCoordinator", async function () {
                  const CRRNGCoordinator = await ethers.getContractFactory("CRRNGCoordinatorPoF")
                  crrrngCoordinator = await CRRNGCoordinator.deploy(
                      coordinatorConstructorParams.disputePeriod,
                      coordinatorConstructorParams.minimumDepositAmount,
                      coordinatorConstructorParams.avgL2GasUsed,
                      coordinatorConstructorParams.avgL1GasUsed,
                      coordinatorConstructorParams.premiumPercentage,
                      coordinatorConstructorParams.penaltyPercentage,
                      coordinatorConstructorParams.flatFee,
                  )
                  await crrrngCoordinator.waitForDeployment()
                  const receipt = await crrrngCoordinator.deploymentTransaction()?.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  console.log("deploy CRRRRNGCoordinators", gasUsed)
                  crrngCoordinatorAddress = await crrrngCoordinator.getAddress()
                  await expect(crrngCoordinatorAddress).to.be.properAddress

                  // ** get
                  const feeSettings = await crrrngCoordinator.getFeeSettings()
                  const disputePeriod = await crrrngCoordinator.getDisputePeriod()

                  // ** assert
                  await expect(feeSettings[0]).to.equal(
                      coordinatorConstructorParams.minimumDepositAmount,
                  )
                  await expect(feeSettings[1]).to.equal(coordinatorConstructorParams.avgL2GasUsed)
                  await expect(feeSettings[2]).to.equal(coordinatorConstructorParams.avgL1GasUsed)
                  await expect(feeSettings[3]).to.equal(
                      coordinatorConstructorParams.premiumPercentage,
                  )
                  await expect(feeSettings[4]).to.equal(coordinatorConstructorParams.flatFee)
                  await expect(disputePeriod).to.equal(coordinatorConstructorParams.disputePeriod)
              })
              it("initialize CRRNGCoordinator", async () => {
                  const tx = await crrrngCoordinator.initialize(
                      initializeParams.v,
                      initializeParams.x,
                      initializeParams.y,
                  )
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  console.log("initialize", gasUsed)

                  // ** get
                  const isInitialized = await crrrngCoordinator.isInitialized()

                  // ** assert
                  await expect(isInitialized).to.equal(true)
              })
              it("deploy ConsumerExample", async () => {
                  const ConsumerExample = await ethers.getContractFactory("ConsumerExample")
                  consumerExample = await ConsumerExample.deploy(crrngCoordinatorAddress)
                  await consumerExample.waitForDeployment()
                  const receipt = await consumerExample.deploymentTransaction()?.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  console.log("deploy ConsumerExample", gasUsed)
                  const consumerExampleAddress = await consumerExample.getAddress()
                  await expect(consumerExampleAddress).to.be.properAddress
              })
              it("5 operators deposit to become operator", async () => {
                  const minimumDepositAmount = coordinatorConstructorParams.minimumDepositAmount
                  const minimumDepositAmountFromContract =
                      await crrrngCoordinator.getMinimumDepositAmount()
                  await expect(minimumDepositAmount).to.equal(minimumDepositAmountFromContract)
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
                      const isOperator = await crrrngCoordinator.isOperator(signers[i].address)
                      await expect(depositedAmountAfter).to.equal(minimumDepositAmount)
                      await expect(isOperator).to.equal(true)
                  }
                  // ** get
                  const operatorCount = await crrrngCoordinator.getOperatorCount()

                  // ** assert
                  await expect(operatorCount).to.equal(5)
              })
          })
          describe("test RequestRandomWords", function () {
              it("try other external functions, and see if revert", async () => {
                  const round = await crrrngCoordinator.getNextRound()
                  await expect(
                      crrrngCoordinator.recover(round, recoverParams.y),
                  ).to.be.revertedWithCustomError(crrrngCoordinator, "NotStartedRound")
                  await expect(
                      crrrngCoordinator.connect(signers[0]).commit(round, commitParams[0]),
                  ).to.be.revertedWithCustomError(crrrngCoordinator, "NotStartedRound")
                  await expect(
                      crrrngCoordinator.disputeRecover(
                          round,
                          recoverParams.v,
                          recoverParams.x,
                          recoverParams.y,
                      ),
                  ).to.be.revertedWithCustomError(crrrngCoordinator, "OmegaNotCompleted")
                  await expect(
                      crrrngCoordinator.fulfillRandomness(round),
                  ).to.be.revertedWithCustomError(crrrngCoordinator, "NotCommittedParticipant")
              })
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
                  console.log("requestRandomWord", gasUsed)
                  const requestCount = await consumerExample.requestCount()
                  const lastReqeustId = await consumerExample.lastRequestId()
                  const lastRequestIdfromArray = await consumerExample.requestIds(requestCount - 1n)
                  await expect(lastReqeustId).to.equal(lastRequestIdfromArray)
                  const requestStatus = await consumerExample.getRequestStatus(lastReqeustId)
                  await expect(requestStatus[0]).to.equal(true)
                  await expect(requestStatus[1]).to.equal(false)
                  await expect(requestStatus[2]).to.equal(0n)

                  // ** crrngCoordinator get
                  // 1. s_valuesAtRound[_round].stage is Stages.Commit
                  // 2. s_valuesAtRound[_round].consumer is consumerExample.address
                  // s_cost[_round]

                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                  const consumerAddress = await crrrngCoordinator.getConsumerAtRound(round)

                  // ** assert
                  await expect(valuesAtRound.startTime).to.be.equal(0n)
                  await expect(valuesAtRound.commitCounts).to.be.equal(0n)
                  await expect(valuesAtRound.consumer).to.be.equal(
                      await consumerExample.getAddress(),
                  )
                  await expect(consumerAddress).to.be.equal(await consumerExample.getAddress())
                  await expect(valuesAtRound.omega.val).to.be.equal("0x")
                  await expect(valuesAtRound.stage).to.be.equal(1n)
                  await expect(valuesAtRound.isCompleted).to.be.equal(false)
                  await expect(valuesAtRound.isVerified).to.be.equal(false)
              })
              it("1 operator commit once and reRequestRandomWord", async () => {
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const numOfOperators = 1
                  for (let i = 0; i < numOfOperators; i++) {
                      const tx = await crrrngCoordinator
                          .connect(signers[i])
                          .commit(round, commitParams[i])
                      const receipt = await tx.wait()
                      const valuesAtRound: ValueAtRound =
                          await crrrngCoordinator.getValuesAtRound(round)
                      await expect(valuesAtRound.commitCounts).to.equal(i + 1)
                      const gasUsed = receipt?.gasUsed as bigint
                      console.log("commit", gasUsed)

                      const userStatusAtRound = await crrrngCoordinator.getUserStatusAtRound(
                          signers[i].address,
                          round,
                      )
                      await expect(userStatusAtRound.committed).to.equal(true)
                      await expect(userStatusAtRound.commitIndex).to.equal(i)
                      const getCommitValues = await crrrngCoordinator.getCommitValue(
                          round,
                          userStatusAtRound.commitIndex,
                      )
                      await expect(getCommitValues.commit.val).to.equal(commitParams[i].val)
                      await expect(getCommitValues.operatorAddress).to.equal(signers[i].address)

                      if (i == 0) {
                          const blockNumber = receipt?.blockNumber as number
                          const provider = ethers.provider
                          const blockTimestamp = (await provider.getBlock(blockNumber))?.timestamp
                          const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                          await expect(valuesAtRound.stage).to.equal(1)
                          await expect(valuesAtRound.commitCounts).to.equal(1)
                          await expect(valuesAtRound.startTime).to.equal(blockTimestamp)
                      }
                  }
                  const committedOperators =
                      await crrrngCoordinator.getCommittedOperatorsAtRound(round)
                  console.log("committedOperators", committedOperators)
                  await time.increase(120n)

                  // ** reRequestRandomWordAtRound
                  const tx = await crrrngCoordinator.reRequestRandomWordAtRound(round)
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed as bigint
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
                      await expect(valuesAtRound.commitCounts).to.equal(i + 1)
                      const gasUsed = receipt?.gasUsed as bigint
                      console.log("commit", gasUsed)

                      const userStatusAtRound = await crrrngCoordinator.getUserStatusAtRound(
                          signers[i].address,
                          round,
                      )
                      await expect(userStatusAtRound.committed).to.equal(true)
                      await expect(userStatusAtRound.commitIndex).to.equal(i)
                      const getCommitValues = await crrrngCoordinator.getCommitValue(
                          round,
                          userStatusAtRound.commitIndex,
                      )
                      await expect(getCommitValues.commit.val).to.equal(commitParams[i].val)
                      await expect(getCommitValues.operatorAddress).to.equal(signers[i].address)

                      if (i == 0) {
                          const blockNumber = receipt?.blockNumber as number
                          const provider = ethers.provider
                          const blockTimestamp = (await provider.getBlock(blockNumber))?.timestamp
                          const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                          //await expect(valuesAtRound.startTime).to.equal(blockTimestamp)
                          await expect(valuesAtRound.stage).to.equal(1)
                          await expect(valuesAtRound.commitCounts).to.equal(1)
                      }
                  }
                  const committedOperators =
                      await crrrngCoordinator.getCommittedOperatorsAtRound(round)
                  console.log("committedOperators", committedOperators)
              })
              it("try all other external functions that are not supposed to be in Commit phase, and see if revert", async () => {
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  await expect(
                      crrrngCoordinator.recover(round, recoverParams.y),
                  ).to.be.revertedWithCustomError(crrrngCoordinator, "FunctionInvalidAtThisStage")
                  await expect(
                      crrrngCoordinator.disputeRecover(
                          round,
                          recoverParams.v,
                          recoverParams.x,
                          recoverParams.y,
                      ),
                  ).to.be.revertedWithCustomError(crrrngCoordinator, "OmegaNotCompleted")
                  await expect(
                      crrrngCoordinator.fulfillRandomness(round),
                  ).to.be.revertedWithCustomError(crrrngCoordinator, "OmegaNotCompleted")
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
                  await time.increase(1200n)
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const tx = await crrrngCoordinator
                      .connect(thirdSmallestHashSigner)
                      .recover(round, recoverParams.x)
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  console.log("recover", gasUsed)

                  const provider = ethers.provider
                  const blockNumber = receipt?.blockNumber as number
                  const blockTimestamp = BigInt(
                      (await provider.getBlock(blockNumber))?.timestamp as number,
                  )

                  // ** get
                  const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                  const getDisputeEndTimeAndLeaderAtRound =
                      await crrrngCoordinator.getDisputeEndTimeAndLeaderAtRound(round)
                  const getDisputeEndTimeOfOperator =
                      await crrrngCoordinator.getDisputeEndTimeOfOperator(
                          thirdSmallestHashSigner.address,
                      )

                  // ** assert
                  await expect(valuesAtRound.commitCounts).to.equal(3)
                  await expect(valuesAtRound.isCompleted).to.equal(true)
                  await expect(valuesAtRound.stage).to.equal(0)
                  await expect(valuesAtRound.omega.val).to.equal(recoverParams.x.val)
                  await expect(valuesAtRound.omega.bitlen).to.equal(recoverParams.x.bitlen)
                  await expect(valuesAtRound.isVerified).to.equal(false)

                  await expect(getDisputeEndTimeAndLeaderAtRound[0]).to.equal(
                      blockTimestamp + BigInt(coordinatorConstructorParams.disputePeriod),
                  )
                  await expect(getDisputeEndTimeAndLeaderAtRound[1]).to.equal(
                      thirdSmallestHashSigner.address,
                  )

                  await expect(getDisputeEndTimeOfOperator).to.equal(
                      blockTimestamp + BigInt(coordinatorConstructorParams.disputePeriod),
                  )
                  await expect(
                      await crrrngCoordinator.getDepositAmount(thirdSmallestHashSigner.address),
                  ).to.equal(coordinatorConstructorParams.minimumDepositAmount)
              })
              it("try all other external functions that are not supposed to be executed after Recover phase, and see if revert", async () => {
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  await expect(
                      crrrngCoordinator.commit(round, commitParams[0]),
                  ).to.be.revertedWithCustomError(crrrngCoordinator, "FunctionInvalidAtThisStage")
                  await expect(
                      crrrngCoordinator.recover(round, recoverParams.y),
                  ).to.be.revertedWithCustomError(crrrngCoordinator, "FunctionInvalidAtThisStage")
                  await expect(
                      crrrngCoordinator.fulfillRandomness(round),
                  ).to.be.revertedWithCustomError(
                      crrrngCoordinator,
                      "DisputePeriodNotEndedOrStarted",
                  )
              })
              it("disputeRecover by secondSmallestHashSigner", async () => {
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const tx = await crrrngCoordinator
                      .connect(secondSmallestHashSigner)
                      .disputeRecover(round, recoverParams.v, recoverParams.x, recoverParams.y)
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  console.log("disputeRecover", gasUsed)

                  const encodedFuncData = crrrngCoordinator.interface.encodeFunctionData(
                      "disputeRecover",
                      [round, recoverParams.v, recoverParams.x, recoverParams.y],
                  )
                  const concatedNatedData = ethers.concat([encodedFuncData, L1_FEE_DATA_PADDING])
                  const titanProvider = new ethers.JsonRpcProvider(
                      "https://rpc.titan.tokamak.network",
                  )
                  const signer = new ethers.JsonRpcSigner(titanProvider, signers[0].address)
                  const OVM_GasPriceOracle = await ethers.getContractAt(
                      OVM_GasPriceOracleABI,
                      "0x420000000000000000000000000000000000000F",
                      signer,
                  )
                  const l1GasUsed =
                      (await OVM_GasPriceOracle.getL1GasUsed(concatedNatedData)) - 4000n
                  console.log("disputeRecover l1GasUsed: ", l1GasUsed)

                  // ** get
                  const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                  const getDisputeEndTimeAndLeaderAtRound =
                      await crrrngCoordinator.getDisputeEndTimeAndLeaderAtRound(round)
                  const getDisputeEndTimeOfOperatorThird =
                      await crrrngCoordinator.getDisputeEndTimeOfOperator(
                          thirdSmallestHashSigner.address,
                      )
                  const getDisputeEndTimeOfOperatorSecond =
                      await crrrngCoordinator.getDisputeEndTimeOfOperator(
                          secondSmallestHashSigner.address,
                      )

                  // ** assert
                  await expect(valuesAtRound.commitCounts).to.equal(3)
                  await expect(valuesAtRound.isCompleted).to.equal(true)
                  await expect(valuesAtRound.stage).to.equal(0)
                  await expect(valuesAtRound.omega.val).to.equal(recoverParams.y.val)
                  await expect(valuesAtRound.omega.bitlen).to.equal(recoverParams.y.bitlen)
                  await expect(valuesAtRound.isVerified).to.equal(true)

                  await expect(getDisputeEndTimeAndLeaderAtRound[1]).to.equal(
                      secondSmallestHashSigner.address,
                  )
                  await expect(getDisputeEndTimeOfOperatorThird).to.equal(0n)
                  await expect(getDisputeEndTimeOfOperatorSecond).to.equal(
                      getDisputeEndTimeAndLeaderAtRound[0],
                  )
                  console.log(getDisputeEndTimeAndLeaderAtRound[0])
                  console.log(
                      await crrrngCoordinator.getDepositAmount(thirdSmallestHashSigner.address),
                  )
                  console.log(
                      await crrrngCoordinator.getDepositAmount(secondSmallestHashSigner.address),
                  )

                  const operatorCount = await crrrngCoordinator.getOperatorCount()
                  const isOperatorSecond = await crrrngCoordinator.isOperator(
                      secondSmallestHashSigner.address,
                  )
                  const isOperatorThird = await crrrngCoordinator.isOperator(
                      thirdSmallestHashSigner.address,
                  )

                  // ** assert
                  await expect(operatorCount).to.equal(4)
                  await expect(isOperatorSecond).to.equal(true)
                  await expect(isOperatorThird).to.equal(false)
              })
              //   it("disputeLeadership by smallestHashSigner", async () => {
              //       const round = (await crrrngCoordinator.getNextRound()) - 1n
              //       const tx = await crrrngCoordinator
              //           .connect(smallestHashSigner)
              //           .disputeLeadershipAtRound(round)
              //       const receipt = await tx.wait()
              //       const gasUsed = receipt?.gasUsed as bigint
              //       console.log("disputeLeadership l2GasUsed", gasUsed)

              //       const encodedFuncData = crrrngCoordinator.interface.encodeFunctionData(
              //           "disputeLeadershipAtRound",
              //           [round],
              //       )
              //       const concatedNatedData = ethers.concat([encodedFuncData, L1_FEE_DATA_PADDING])
              //       const titanProvider = new ethers.JsonRpcProvider(
              //           "https://rpc.titan.tokamak.network",
              //       )
              //       const signer = new ethers.JsonRpcSigner(titanProvider, signers[0].address)
              //       const OVM_GasPriceOracle = await ethers.getContractAt(
              //           OVM_GasPriceOracleABI,
              //           "0x420000000000000000000000000000000000000F",
              //           signer,
              //       )
              //       const l1GasUsed =
              //           (await OVM_GasPriceOracle.getL1GasUsed(concatedNatedData)) - 4000n
              //       console.log("disputeRecover l1GasUsed: ", l1GasUsed)

              //       // ** get
              //       const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
              //       const getDisputeEndTimeAndLeaderAtRound =
              //           await crrrngCoordinator.getDisputeEndTimeAndLeaderAtRound(round)
              //       const getDisputeEndTimeOfOperatorSecond =
              //           await crrrngCoordinator.getDisputeEndTimeOfOperator(
              //               secondSmallestHashSigner.address,
              //           )
              //       const getDisputeEndTimeOfOperatorSmallest =
              //           await crrrngCoordinator.getDisputeEndTimeOfOperator(
              //               smallestHashSigner.address,
              //           )

              //       // ** assert
              //       await expect(valuesAtRound.commitCounts).to.equal(3)
              //       await expect(valuesAtRound.isCompleted).to.equal(true)
              //       await expect(valuesAtRound.stage).to.equal(0)
              //       await expect(valuesAtRound.omega.val).to.equal(recoverParams.y.val)
              //       await expect(valuesAtRound.omega.bitlen).to.equal(recoverParams.y.bitlen)
              //       await expect(valuesAtRound.isVerified).to.equal(true)
              //       await expect(getDisputeEndTimeAndLeaderAtRound[1]).to.equal(
              //           smallestHashSigner.address,
              //       )
              //       await expect(getDisputeEndTimeOfOperatorSecond).to.equal(0n)
              //       await expect(getDisputeEndTimeOfOperatorSmallest).to.equal(
              //           getDisputeEndTimeAndLeaderAtRound[0],
              //       )
              //       const operatorCount = await crrrngCoordinator.getOperatorCount()
              //       const isOperatorSecond = await crrrngCoordinator.isOperator(
              //           secondSmallestHashSigner.address,
              //       )
              //       console.log("operatorCount", operatorCount)
              //       console.log("isOperatorSecond", isOperatorSecond)
              //       console.log(
              //           "Second Deposited Amount",
              //           await crrrngCoordinator.getDepositAmount(secondSmallestHashSigner.address),
              //       )
              //       console.log(
              //           "Smallest Deposited Amount",
              //           await crrrngCoordinator.getDepositAmount(smallestHashSigner.address),
              //       )
              //   })
              it("fulfillRandomness by smallestHashSigner", async () => {
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const disputePeriod = coordinatorConstructorParams.disputePeriod
                  await time.increase(BigInt(disputePeriod) + 1n)
                  const tx = await crrrngCoordinator
                      .connect(smallestHashSigner)
                      .fulfillRandomness(round)
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed as bigint
                  console.log("fulfillRandomness", gasUsed)

                  // ** get
                  const getFulfillStatusAtRound =
                      await crrrngCoordinator.getFulfillStatusAtRound(round)
                  const depositAmountThird = await crrrngCoordinator.getDepositAmount(
                      thirdSmallestHashSigner.address,
                  )
                  const depositAmountSecond = await crrrngCoordinator.getDepositAmount(
                      secondSmallestHashSigner.address,
                  )
                  const depositAmount = await crrrngCoordinator.getDepositAmount(
                      smallestHashSigner.address,
                  )
                  const getCostAtRound = await crrrngCoordinator.getCostAtRound(round)

                  // ** assert
                  await expect(getFulfillStatusAtRound[0]).to.equal(true)
                  await expect(getFulfillStatusAtRound[1]).to.equal(true)
                  console.log("getCostAtRound", getCostAtRound)

                  console.log("depositAmount", depositAmount)
                  console.log("depositAmountSecond", depositAmountSecond)
                  console.log("depositAmountThird", depositAmountThird)
              })
          })
          describe("disputeLeadershipAfterFulfill test", function () {
              it("run a round and fulfillRandomness by not leader", async () => {
                  // ** make five operators again
                  const minimumDepositAmount = coordinatorConstructorParams.minimumDepositAmount
                  for (let i: number = 0; i < 5; i++) {
                      const depositedAmount = await crrrngCoordinator.getDepositAmount(
                          signers[i].address,
                      )
                      if (depositedAmount < BigInt(minimumDepositAmount)) {
                          const tx = await crrrngCoordinator.connect(signers[i]).operatorDeposit({
                              value: BigInt(minimumDepositAmount) - depositedAmount,
                          })
                          await tx.wait()
                      }
                  }
                  // ** request randomWord
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
                  await tx.wait()
                  // ** three operator commit
                  const numOfOperators = 3
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  for (let i = 0; i < numOfOperators; i++) {
                      const tx = await crrrngCoordinator
                          .connect(signers[i])
                          .commit(round, commitParams[i])
                      await tx.wait()
                  }
                  // ** thirdSmallestHashSigner recover
                  await time.increase(1200n)
                  const txRecover = await crrrngCoordinator
                      .connect(thirdSmallestHashSigner)
                      .recover(round, recoverParams.y)
                  await txRecover.wait()
                  // ** fulfillRandomness by secondSmallestHashSigner
                  const disputePeriod = coordinatorConstructorParams.disputePeriod
                  await time.increase(BigInt(disputePeriod) + 1n)
                  const txFulfill = await crrrngCoordinator
                      .connect(secondSmallestHashSigner)
                      .fulfillRandomness(round)
                  await txFulfill.wait()

                  // ** disputeLeadershipAfterfufill by smallestHashSigner
                  const txDispute = await crrrngCoordinator
                      .connect(smallestHashSigner)
                      .disputeLeadershipAtRound(round)
                  await txDispute.wait()

                  // ** get
                  const getFulfillStatusAtRound =
                      await crrrngCoordinator.getFulfillStatusAtRound(round)
                  const depositAmountThird = await crrrngCoordinator.getDepositAmount(
                      thirdSmallestHashSigner.address,
                  )
                  const depositAmountSecond = await crrrngCoordinator.getDepositAmount(
                      secondSmallestHashSigner.address,
                  )
                  const depositAmount = await crrrngCoordinator.getDepositAmount(
                      smallestHashSigner.address,
                  )
                  const getCostAtRound = await crrrngCoordinator.getCostAtRound(round)

                  // ** assert
                  console.log("getCostAtRound", getCostAtRound)
                  console.log("depositAmount", depositAmount)
                  console.log("depositAmountSecond", depositAmountSecond)
                  console.log("depositAmountThird", depositAmountThird)

                  await expect(getFulfillStatusAtRound[0]).to.equal(true)
                  await expect(getFulfillStatusAtRound[1]).to.equal(true)
              })
          })
      })
/***
 * **
 * struct ValueAtRound {
        uint256 startTime;
        uint256 commitCounts;
        address consumer;
        bytes commitsString; // concatenated string of commits
        BigNumber omega; // the random number
        Stages stage; // stage of the contract
        bool isCompleted; // the flag to check if the round is completed
        bool isVerified; // omega is verified when this is true
    }
 */
