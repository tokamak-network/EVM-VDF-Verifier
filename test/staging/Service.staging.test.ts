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
import { BigNumberish, BytesLike, dataLength, toBeHex } from "ethers"
import fs from "fs"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { CRRRNGCoordinator, CryptoDice, TonToken } from "../../typechain-types"
function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(fs.readFileSync(__dirname + "/../shared/correct.json", "utf-8"))
    return testCaseJson
}
interface BigNumber {
    val: BytesLike
    bitlen: number
}
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Service Test", function () {
          const coordinatorConstructorParams: {
              disputePeriod: BigNumberish
              minimumDepositAmount: BigNumberish
              avgRecoveOverhead: BigNumberish
              premiumPercentage: BigNumberish
              flatFee: BigNumberish
          } = {
              disputePeriod: 1800n,
              minimumDepositAmount: ethers.parseEther("0.1"),
              avgRecoveOverhead: 2500000n,
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
          let crrrngCoordinator: CRRRNGCoordinator
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
              bigNumTwoPowerOfDelta: BytesLike
              delta: number
          } = {
              v: [],
              x: { val: "0x0", bitlen: 0 },
              y: { val: "0x0", bitlen: 0 },
              bigNumTwoPowerOfDelta: twoPowerOfDeltaBytes,
              delta: delta,
          }
          let commitParams: BigNumber[] = []
          let recoverParams: {
              round: number
              v: BigNumber[]
              x: BigNumber
              y: BigNumber
              bigNumTwoPowerOfDelta: BytesLike
              delta: number
          } = {
              round: 0,
              v: [],
              x: { val: "0x0", bitlen: 0 },
              y: { val: "0x0", bitlen: 0 },
              bigNumTwoPowerOfDelta: twoPowerOfDeltaBytes,
              delta: delta,
          }
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
                  initializeParams.bigNumTwoPowerOfDelta = twoPowerOfDeltaBytes
                  initializeParams.delta = delta
                  //commitParams
                  for (let i = 0; i < testCaseJson.commitList.length; i++) {
                      commitParams.push(testCaseJson.commitList[i])
                  }
                  //recoverParams
                  recoverParams.x = testCaseJson.recoveryProofs[0].x
                  recoverParams.y = testCaseJson.recoveryProofs[0].y
                  recoverParams.bigNumTwoPowerOfDelta = twoPowerOfDeltaBytes
                  recoverParams.delta = delta
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
                  const CRRRNGCoordinator = await ethers.getContractFactory("CRRRNGCoordinator")
                  crrrngCoordinator = await CRRRNGCoordinator.deploy(
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
              it("initialize CRRRNGCoordinator", async () => {
                  const tx = await crrrngCoordinator.initialize(
                      initializeParams.v,
                      initializeParams.x,
                      initializeParams.y,
                      initializeParams.bigNumTwoPowerOfDelta,
                      initializeParams.delta,
                  )
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed
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
          describe("Real Test", function () {
              it("5 operators deposit to become operator", async () => {
                  const minimumDepositAmount = coordinatorConstructorParams.minimumDepositAmount
              })
              it("RequestRandomWord on CryptoDice", async () => {
                  await time.increase(86400n)
                  const provider = ethers.provider
                  const fee = await provider.getFeeData()
                  console.log("fee", fee)
                  const callback_gaslimit = 100000n
                  const round = (await cryptoDice.getNextCryptoDiceRound()) - 1n
                  const directFundingCost = await crrrngCoordinator.estimateDirectFundingPrice(
                      callback_gaslimit,
                      fee.gasPrice as bigint,
                  )
                  console.log("directFundingCost", directFundingCost.toString())
                  const tx = await cryptoDice.requestRandomWord(round, { value: directFundingCost })
                  const receipt = await tx.wait()
              })
          })
      })
