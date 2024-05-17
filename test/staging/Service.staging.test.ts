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
import {
    AddressLike,
    BigNumberish,
    BytesLike,
    ContractTransactionReceipt,
    dataLength,
    toBeHex,
} from "ethers"
import fs from "fs"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { CRRNGCoordinator, CryptoDice, TonToken } from "../../typechain-types"
/**
 * struct ValueAtRound {
    uint256 startTime;
    uint256 numOfPariticipants;
    uint256 count; //This variable is used to keep track of the number of commitments and reveals, and to check if anything has been committed when moving to the reveal stage.
    address consumer;
    bytes bStar; // hash of commitsString
    bytes commitsString; // concatenated string of commits
    BigNumber omega; // the random number
    Stages stage; // stage of the contract
    bool isCompleted; // omega is finialized when this is true
    bool isAllRevealed; // true when all participants have revealed
}
 */
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
    : describe("Service Test", function () {
          const callback_gaslimit = 100000n
          const coordinatorConstructorParams: {
              disputePeriod: BigNumberish
              minimumDepositAmount: BigNumberish
              avgRecoveOverhead: BigNumberish
              premiumPercentage: BigNumberish
              flatFee: BigNumberish
          } = {
              disputePeriod: 1800n,
              minimumDepositAmount: ethers.parseEther("0.1"),
              avgRecoveOverhead: 2297700n,
              premiumPercentage: 0n,
              flatFee: ethers.parseEther("0.0013"),
          }
          const registrationDuration = 86400n
          const totalPrizeAmount = 1000n * 10n ** 18n
          const delta: number = 9
          const twoPowerOfDeltaBytes: BytesLike = toBeHex(
              2 ** delta,
              getLength(dataLength(toBeHex(2 ** delta))),
          )
          let testCaseJson
          let signers: SignerWithAddress[]
          let crrrngCoordinator: CRRNGCoordinator
          let tonToken: TonToken
          let cryptoDice: CryptoDice
          let crrngCoordinatorAddress: string
          let tonTokenAddress: string
          let cryptoDiceAddress: string
          let randomNumbers: number[]
          let diceNumCount: number[] = [0, 0, 0, 0, 0, 0, 0]
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
              it("deploy TestERC20", async function () {
                  const TonToken = await ethers.getContractFactory("TonToken")
                  tonToken = await TonToken.deploy()
                  await tonToken.waitForDeployment()
                  tonTokenAddress = await tonToken.getAddress()
                  const balance = await tonToken.balanceOf(signers[0].address)
                  expect(balance).to.equal(1000000000000000000000000000n)
                  expect(tonTokenAddress).to.be.properAddress
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
                  const balanceAfter = await ethers.provider.getBalance(signers[0].address)
              })
              it("deploy CryptoDice", async () => {
                  const CryptoDice = await ethers.getContractFactory("CryptoDice")
                  cryptoDice = (await CryptoDice.deploy(
                      crrngCoordinatorAddress,
                      tonTokenAddress,
                  )) as CryptoDice
                  await cryptoDice.waitForDeployment()
                  cryptoDiceAddress = await cryptoDice.getAddress()
                  expect(cryptoDiceAddress).to.be.properAddress
                  expect(await cryptoDice.getRNGCoordinator()).to.equal(crrngCoordinatorAddress)
                  expect(await cryptoDice.getAirdropTokenAddress()).to.equal(tonTokenAddress)
              })
              it("Start Registration on CryptoDice", async () => {
                  const round = 0n
                  const tx = await cryptoDice.startRegistration(
                      registrationDuration,
                      totalPrizeAmount,
                  )
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed
                  const blockNum = BigInt(receipt?.blockNumber.toString()!)
                  const block = await ethers.provider.getBlock(blockNum)
                  const timestamp = block?.timestamp!
                  const registrationTimeAndDuration: [bigint, bigint] =
                      await cryptoDice.getRegistrationTimeAndDuration()
                  const nextRound = await cryptoDice.getNextCryptoDiceRound()
                  const currentRound = nextRound === 0n ? 0n : nextRound - 1n
                  const registeredCount = await cryptoDice.getRegisteredCount(round)
                  const roundStatus = await cryptoDice.getRoundStatus(round)

                  // assert
                  expect(registrationTimeAndDuration[0]).to.equal(timestamp)
                  expect(registrationTimeAndDuration[1]).to.equal(registrationDuration)
                  expect(nextRound).to.equal(1n)
                  expect(currentRound).to.equal(0n)
                  expect(registeredCount).to.equal(0n)
                  /*
                struct RoundStatus {
                uint256 requestId;
                uint256 totalPrizeAmount;
                uint256 prizeAmountForEachWinner;
                bool registrationStarted;
                bool randNumRequested;
                bool randNumfulfilled;
            } */
                  expect(roundStatus.requestId).to.equal(0n)
                  expect(roundStatus.totalPrizeAmount).to.equal(totalPrizeAmount)
                  expect(roundStatus.prizeAmountForEachWinner).to.equal(0n)
                  expect(roundStatus.registrationStarted).to.equal(true)
                  expect(roundStatus.randNumRequested).to.equal(false)
                  expect(roundStatus.randNumfulfilled).to.equal(false)
              })
              it("500 participants register for CryptoDice", async () => {
                  const round = 0n
                  randomNumbers = []
                  //act
                  for (let i = 0; i < 500; i++) {
                      // get javascript random number 1 to 6
                      const randomNumber = Math.floor(Math.random() * 6) + 1
                      randomNumbers.push(randomNumber)
                      diceNumCount[randomNumber]++
                      await cryptoDice.connect(signers[i]).register(randomNumber)
                  }
                  //get
                  const registeredCount = await cryptoDice.getRegisteredCount(round)
                  expect(registeredCount).to.equal(500)
                  for (let i = 0; i < 500; i++) {
                      const participatedRounds = await cryptoDice.getParticipatedRounds(
                          signers[i].address,
                      )
                      const diceNum = await cryptoDice.getDiceNumAtRound(round, signers[i].address)
                      expect(diceNum).to.equal(randomNumbers[i])
                      expect(participatedRounds).to.deep.equal([0n])
                  }
              })
              it("transfer tonToken to CryptoDice for prize", async () => {
                  const round = 0n
                  const tx = await tonToken.transfer(cryptoDiceAddress, totalPrizeAmount)
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed
                  const cryptoDiceBalance = await tonToken.balanceOf(cryptoDiceAddress)
                  expect(cryptoDiceBalance).to.equal(totalPrizeAmount)
              })
          })
          describe("Coordinator Test", function () {
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
              it("RequestRandomWord on CryptoDice", async () => {
                  await time.increase(86400n)
                  const provider = ethers.provider
                  const fee = await provider.getFeeData()
                  const round = (await cryptoDice.getNextCryptoDiceRound()) - 1n
                  const gasPrice = fee.gasPrice as bigint
                  const directFundingCost = await crrrngCoordinator.estimateDirectFundingPrice(
                      callback_gaslimit,
                      gasPrice,
                  )
                  const avgRecoveOverhead = BigInt(coordinatorConstructorParams.avgRecoveOverhead)
                  const premiumPercentage = BigInt(coordinatorConstructorParams.premiumPercentage)
                  const flatFee = BigInt(coordinatorConstructorParams.flatFee)
                  const calculateDirectFundingPrice =
                      gasPrice *
                          (callback_gaslimit + avgRecoveOverhead) *
                          ((premiumPercentage + 100n) / 100n) +
                      flatFee
                  expect(directFundingCost).to.equal(calculateDirectFundingPrice)

                  const ethBalanceBeforeRequestRandomWord = await provider.getBalance(
                      signers[0].address,
                  )
                  const cryptoDiceBalanceBefore = await provider.getBalance(cryptoDiceAddress)

                  const tx = await cryptoDice.requestRandomWord(round, {
                      value: (directFundingCost * (100n + 1n)) / 100n,
                  })
                  const receipt: ContractTransactionReceipt =
                      (await tx.wait()) as ContractTransactionReceipt
                  const ethBalanceAfterRequestRandomWord = await provider.getBalance(
                      signers[0].address,
                  )
                  const gasCost = receipt.gasUsed * receipt.gasPrice
                  const crrRound = (await crrrngCoordinator.getNextRound()) - 1n

                  const valuesAtRound: ValueAtRound =
                      await crrrngCoordinator.getValuesAtRound(crrRound)
                  assertValuesAtRequestRandomWord(valuesAtRound, receipt)
                  const cost = await crrrngCoordinator.getCostAtRound(crrRound)
                  const cryptoDiceBalanceAfter = await provider.getBalance(cryptoDiceAddress)

                  const refundedAmount = cryptoDiceBalanceAfter - cryptoDiceBalanceBefore

                  expect(gasCost).to.equal(
                      ethBalanceBeforeRequestRandomWord -
                          ethBalanceAfterRequestRandomWord -
                          cost -
                          refundedAmount,
                  )
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
                  time.increase(120n)
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const tx = await crrrngCoordinator
                      .connect(thirdSmallestHashSigner)
                      .recover(round, recoverParams.v, recoverParams.x, recoverParams.y)
                  const receipt = await tx.wait()
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
                  expect(valueAtRound.consumer).to.equal(cryptoDiceAddress)
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

                  // ** cryptoDice Consumer assert test
                  const roundStatus = await cryptoDice.getRoundStatus(round)
                  const getRandNum = await cryptoDice.getRandNum(round)
                  const getWinningDiceNum = await cryptoDice.getWinningDiceNum(round)
                  // assert CryptoDice
                  expect(roundStatus.randNumRequested).to.equal(true)
                  expect(roundStatus.randNumfulfilled).to.equal(true)
                  expect(roundStatus.prizeAmountForEachWinner).to.equal(
                      totalPrizeAmount / BigInt(diceNumCount[Number(getWinningDiceNum)]),
                  )
                  console.log("getRandNum: ", getRandNum)
                  console.log("getWinningDiceNum: ", getWinningDiceNum)
              })
          })
          describe("consumer test", function () {
              it("participants withdraw on CryptoDice", async () => {
                  const round = (await cryptoDice.getNextCryptoDiceRound()) - 1n
                  // act
                  const winningDiceNum = await cryptoDice.getWinningDiceNum(round)
                  const balanceOfCryptoDiceBefore = await tonToken.balanceOf(cryptoDiceAddress)
                  for (let i = 0; i < 500; i++) {
                      // getDiceNumAtRound
                      const diceNum = await cryptoDice.getDiceNumAtRound(round, signers[i].address)
                      if (diceNum === winningDiceNum) {
                          await cryptoDice.connect(signers[i]).withdrawAirdropToken(round)
                      }
                  }
                  // get
                  const balanceOfCryptoDiceAfter = await tonToken.balanceOf(cryptoDiceAddress)
                  console.log(balanceOfCryptoDiceBefore, balanceOfCryptoDiceAfter)
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

                  console.log("yeah")
              })
          })
      })

async function assertValuesAtRequestRandomWord(
    valuesAtRound: ValueAtRound,
    receipt: ContractTransactionReceipt,
) {
    const provider = ethers.provider
    const blockNumber = receipt?.blockNumber
    const blockTimestamp = (await provider.getBlock(blockNumber as number))?.timestamp
    expect(valuesAtRound.startTime).to.equal(blockTimestamp)
    expect(valuesAtRound.numOfPariticipants).to.equal(0)
    expect(valuesAtRound.count).to.equal(0)
    expect(valuesAtRound.consumer).to.not.equal(ethers.ZeroAddress)
    expect(valuesAtRound.bStar).to.equal(ethers.ZeroHash)
    expect(valuesAtRound.commitsString).to.equal(ethers.ZeroHash)
    expect(valuesAtRound.omega.val).to.equal(ethers.ZeroHash)
    expect(valuesAtRound.omega.bitlen).to.equal(0)
    expect(valuesAtRound.stage).to.equal(1)
    expect(valuesAtRound.isCompleted).to.equal(false)
    expect(valuesAtRound.isAllRevealed).to.equal(false)
}
