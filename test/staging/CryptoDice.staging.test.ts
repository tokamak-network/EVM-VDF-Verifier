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
import { assert, expect } from "chai"
import { BytesLike, dataLength, toBeHex } from "ethers"
import fs from "fs"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { CRRRNGCoordinator, CryptoDice, TonToken } from "../../typechain-types"
function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
interface BigNumber {
    val: BytesLike
    bitlen: number
}
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("CryptoDice", function () {
          // const
          const registrationDuration = 86400n
          const totalPrizeAmount = 1000n * 10n ** 18n
          const blackListedIndexs = [3, 53, 103, 153, 203, 253, 303, 353, 403, 453]
          const delta: number = 9
          const twoPowerOfDeltaBytes: BytesLike = toBeHex(
              2 ** delta,
              getLength(dataLength(toBeHex(2 ** delta))),
          )
          // let
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
          it("get 500 signers", async () => {
              signers = await ethers.getSigners()
              expect(signers.length).to.equal(500)
          })
          it("Create TestCase And PreProcess Data", async () => {
              testCaseJson = createCorrectAlgorithmVersionTestCase()
              //initializeParams
              initializeParams.x = testCaseJson.setupProofs[0].x
              initializeParams.y = testCaseJson.setupProofs[0].y
              if (delta > 0) {
                  testCaseJson.setupProofs = testCaseJson.setupProofs?.slice(0, -(delta + 1))
                  testCaseJson.recoveryProofs = testCaseJson.recoveryProofs?.slice(0, -(delta + 1))
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
          it("deploy CRRRNGCoordinator", async () => {
              const CRRRNGCoordinator = await ethers.getContractFactory("CRRRNGCoordinator")
              crrrngCoordinator = (await CRRRNGCoordinator.deploy()) as CRRRNGCoordinator
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
              console.log("initialize CRRRNGCoordinator gasUsed: ", gasUsed)
          })
          it("deploy TonToken", async () => {
              const TonToken = await ethers.getContractFactory("TonToken")
              tonToken = (await TonToken.deploy()) as TonToken
              await tonToken.waitForDeployment()
              tonTokenAddress = await tonToken.getAddress()
              expect(tonTokenAddress).to.be.properAddress
              const balance = await tonToken.balanceOf(signers[0].address)
              expect(balance).to.equal(1000000000000000000000000000n)
              tonTokenAddress = await tonToken.getAddress()
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
          it("send TonToken to CryptoDice and Withdraw OnlyOwner", async () => {
              // deposit
              const cryptoDiceBalance = await tonToken.balanceOf(cryptoDiceAddress)
              const signer0Balance = await tonToken.balanceOf(signers[0].address)
              await tonToken.transfer(cryptoDiceAddress, totalPrizeAmount)
              const cryptoDiceBalanceAfter = await tonToken.balanceOf(cryptoDiceAddress)
              const signer0BalanceAfter = await tonToken.balanceOf(signers[0].address)
              expect(cryptoDiceBalanceAfter).to.equal(cryptoDiceBalance + totalPrizeAmount)
              expect(signer0BalanceAfter).to.equal(signer0Balance - totalPrizeAmount)

              // withdraw by not owner
              await expect(
                  cryptoDice.connect(signers[1]).withdrawAirdropTokenOnlyOwner(),
              ).to.be.revertedWithCustomError(cryptoDice, "OwnableUnauthorizedAccount")

              // withdraw
              const owner = await cryptoDice.owner()
              await cryptoDice.connect(signers[0]).withdrawAirdropTokenOnlyOwner()
              const cryptoDiceBalanceAfterWithdraw = await tonToken.balanceOf(cryptoDiceAddress)
              expect(cryptoDiceBalanceAfterWithdraw).to.equal(0)
              const signer0BalanceAfterWithdraw = await tonToken.balanceOf(signers[0].address)
              expect(signer0BalanceAfterWithdraw).to.equal(signer0Balance)
          })
          it("Start Registration on CryptoDice", async () => {
              const round = 0n
              const tx = await cryptoDice.startRegistration(registrationDuration, totalPrizeAmount)
              const receipt = await tx.wait()
              const gasUsed = receipt?.gasUsed
              console.log("Start Registration gasUsed: ", gasUsed)
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
          it("restart Registration on CryptoDice", async () => {
              await time.increase(86400n)
              const round = 0n
              const tx = await cryptoDice.startRegistration(registrationDuration, totalPrizeAmount)
              const receipt = await tx.wait()
              const gasUsed = receipt?.gasUsed
              console.log("restart Registration gasUsed: ", gasUsed)
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
          it("blackList a few participants on CryptoDice", async () => {
              //act
              const round = 0n
              let blackListAddresses: string[] = []
              let blackListCount: number = 0
              await time.increase(86400n)
              for (let i = 0; i < blackListedIndexs.length; i++) {
                  const index = blackListedIndexs[i]
                  const diceNum = await cryptoDice.getDiceNumAtRound(round, signers[index].address)
                  diceNumCount[Number(diceNum)]--
                  blackListAddresses.push(signers[index].address)
                  blackListCount++
              }
              const tx = await cryptoDice.blackList(round, blackListAddresses)
              const receipt = await tx.wait()
              const gasUsed = receipt?.gasUsed
              // get
              const registeredCount = await cryptoDice.getRegisteredCount(round)
              // assert
              expect(registeredCount).to.equal(500 - blackListCount)
          })
          it("transfer tonToken to CryptoDice for prize", async () => {
              const round = 0n
              const tx = await tonToken.transfer(cryptoDiceAddress, totalPrizeAmount)
              const receipt = await tx.wait()
              const gasUsed = receipt?.gasUsed
              console.log("transfer tonToken to CryptoDice for prize gasUsed: ", gasUsed)
              const cryptoDiceBalance = await tonToken.balanceOf(cryptoDiceAddress)
              expect(cryptoDiceBalance).to.equal(totalPrizeAmount)
          })
          it("requestRandomWord on CryptoDice", async () => {
              const round = (await cryptoDice.getNextCryptoDiceRound()) - 1n
              const tx = await cryptoDice.requestRandomWord(round)
              const receipt = await tx.wait()
              // get timestamp
              const blockNum = BigInt(receipt?.blockNumber.toString()!)
              const block = await ethers.provider.getBlock(blockNum)
              const timestamp = block?.timestamp!
              // get cryptodice
              const roundStatus = await cryptoDice.getRoundStatus(round)
              const registeredCount = await cryptoDice.getRegisteredCount(round)
              // assert cryptodice
              expect(roundStatus.requestId).to.equal(0n)
              expect(roundStatus.totalPrizeAmount).to.equal(totalPrizeAmount)
              expect(roundStatus.prizeAmountForEachWinner.toString()).to.equal("0")
              expect(roundStatus.registrationStarted).to.equal(true)
              expect(roundStatus.randNumRequested).to.equal(true)
              expect(roundStatus.randNumfulfilled).to.equal(false)

              // get crrngCoordinator
              const nextRound = await crrrngCoordinator.getNextRound()
              const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
              /*
                struct ValueAtRound {
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
              // assert crrngCoordinator
              expect(nextRound).to.equal(1n)
              expect(valuesAtRound.startTime).to.equal(timestamp)
              expect(valuesAtRound.numOfPariticipants).to.equal(0n)
              expect(valuesAtRound.count).to.equal(0n)
              expect(valuesAtRound.consumer).to.equal(cryptoDiceAddress)
              expect(valuesAtRound.bStar).to.equal("0x")
              expect(valuesAtRound.commitsString).to.equal("0x")
              expect(valuesAtRound.omega.val).to.equal("0x")
              expect(valuesAtRound.stage).to.equal(1)
              expect(valuesAtRound.isCompleted).to.equal(false)
              expect(valuesAtRound.isAllRevealed).to.equal(false)
          })
          it("reRequestRandomWord on CryptoDice", async () => {
              // act
              await time.increase(120)
              const round = (await cryptoDice.getNextCryptoDiceRound()) - 1n
              const roundStatus = await cryptoDice.getRoundStatus(round)
              const requestId = roundStatus.requestId
              const tx = await crrrngCoordinator.reRequestRandomWordAtRound(requestId)
              const receipt = await tx.wait()
              // get timestmap
              const blockNum = BigInt(receipt?.blockNumber.toString()!)
              const block = await ethers.provider.getBlock(blockNum)
              const timestamp = block?.timestamp!
              // get crrngCoordinator
              const nextRound = await crrrngCoordinator.getNextRound()
              const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
              // assert crrngCoordinator
              expect(nextRound).to.equal(1n)
              expect(valuesAtRound.startTime).to.equal(timestamp)
              expect(valuesAtRound.numOfPariticipants).to.equal(0n)
              expect(valuesAtRound.count).to.equal(0n)
              expect(valuesAtRound.consumer).to.equal(cryptoDiceAddress)
              expect(valuesAtRound.bStar).to.equal("0x")
              expect(valuesAtRound.commitsString).to.equal("0x")
              expect(valuesAtRound.omega.val).to.equal("0x")
              expect(valuesAtRound.stage).to.equal(1)
              expect(valuesAtRound.isCompleted).to.equal(false)
              expect(valuesAtRound.isAllRevealed).to.equal(false)
          })
          it("3 commits on CRRRNGCoordinator", async () => {
              // act
              const round = (await cryptoDice.getNextCryptoDiceRound()) - 1n
              for (let i = 0; i < 3; i++) {
                  const tx = await crrrngCoordinator
                      .connect(signers[i])
                      .commit(round, commitParams[i])
                  const receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed
                  console.log("commit gasUsed: ", gasUsed)
                  const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                  const userInfosAtRound = await crrrngCoordinator.getUserInfosAtRound(
                      signers[i],
                      round,
                  )
                  const commitRevealValues = await crrrngCoordinator.getCommitRevealValues(
                      0n,
                      userInfosAtRound.index,
                  )
                  assert.equal(valuesAtRound.count, BigInt(i) + 1n)
                  assert.equal(userInfosAtRound.committed, true)
                  assert.equal(userInfosAtRound.revealed, false)
                  assert.equal(commitRevealValues.c.val, commitParams[i].val)
                  assert.equal(commitRevealValues.c.bitlen, BigInt(commitParams[i].bitlen))
                  assert.equal(commitRevealValues.participantAddress, signers[i].address)
              }
          })
          it("recover on CRRRNGCoordinator", async () => {
              await time.increase(120)
              const round = (await cryptoDice.getNextCryptoDiceRound()) - 1n
              let receipt
              let blockNum
              try {
                  const tx = await crrrngCoordinator.recover(
                      round,
                      recoverParams.v,
                      recoverParams.x,
                      recoverParams.y,
                      recoverParams.bigNumTwoPowerOfDelta,
                      recoverParams.delta,
                  )
                  receipt = await tx.wait()
                  const gasUsed = receipt?.gasUsed
                  console.log("recover gasUsed: ", gasUsed)
                  blockNum = BigInt(receipt?.blockNumber.toString()!)
              } catch (error) {
                  console.log(error)
              }
              // get timestamp
              const block = await ethers.provider.getBlock(blockNum!)
              const timestamp = block?.timestamp!
              // get crrngCoordinator
              const nextRound = await crrrngCoordinator.getNextRound()
              const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
              // assert crrngCoordinator
              expect(nextRound).to.equal(1n)
              expect(valuesAtRound.omega.val).to.equal(testCaseJson!.omega.val)
              expect(valuesAtRound.omega.bitlen).to.equal(testCaseJson!.omega.bitlen)
              expect(valuesAtRound.isCompleted).to.equal(true)
              expect(valuesAtRound.isAllRevealed).to.equal(false)
              expect(valuesAtRound.stage).to.equal(0)

              // get CryptoDice
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
          it("participants withdraw on CryptoDice", async () => {
              const round = (await cryptoDice.getNextCryptoDiceRound()) - 1n
              // act
              const winningDiceNum = await cryptoDice.getWinningDiceNum(round)
              const balanceOfCryptoDiceBefore = await tonToken.balanceOf(cryptoDiceAddress)
              for (let i = 0; i < 500; i++) {
                  // getDiceNumAtRound
                  const diceNum = await cryptoDice.getDiceNumAtRound(round, signers[i].address)
                  if (!blackListedIndexs.includes(i) && diceNum === winningDiceNum) {
                      await cryptoDice.connect(signers[i]).withdrawAirdropToken(round)
                  }
              }
              // get
              const balanceOfCryptoDiceAfter = await tonToken.balanceOf(cryptoDiceAddress)
              console.log(balanceOfCryptoDiceBefore, balanceOfCryptoDiceAfter)
          })
          it("withdrawRemainingPrize on CryptoDice", async () => {
              const round = (await cryptoDice.getNextCryptoDiceRound()) - 1n
              const balanceOfCryptoDiceBefore = await tonToken.balanceOf(cryptoDiceAddress)
              await cryptoDice.withdrawAirdropTokenOnlyOwner()
              const balanceOfCryptoDiceAfter = await tonToken.balanceOf(cryptoDiceAddress)
              expect(balanceOfCryptoDiceAfter).to.equal(0)
          })
          it("iterate through 3 rounds without get and assert tests", async () => {
              for (let round = 1; round < 4; round++) {
                  await cryptoDice.startRegistration(registrationDuration, totalPrizeAmount)
                  // 500 participants register for CryptoDice
                  for (let i = 0; i < 300; i++) {
                      const randomNumber = Math.floor(Math.random() * 6) + 1
                      await cryptoDice.connect(signers[i]).register(randomNumber)
                  }
                  await time.increase(86400n)
                  // transfer
                  await tonToken.transfer(cryptoDiceAddress, totalPrizeAmount)
                  await cryptoDice.requestRandomWord(round)
                  for (let i = 0; i < 3; i++) {
                      await crrrngCoordinator.connect(signers[i]).commit(round, commitParams[i])
                  }
                  await time.increase(120)
                  await crrrngCoordinator.recover(
                      round,
                      recoverParams.v,
                      recoverParams.x,
                      recoverParams.y,
                      recoverParams.bigNumTwoPowerOfDelta,
                      recoverParams.delta,
                  )
                  const winningDiceNum = await cryptoDice.getWinningDiceNum(round)
                  for (let i = 0; i < 500; i++) {
                      const diceNum = await cryptoDice.getDiceNumAtRound(round, signers[i].address)
                      if (!blackListedIndexs.includes(i) && diceNum === winningDiceNum) {
                          await cryptoDice.connect(signers[i]).withdrawAirdropToken(round)
                      }
                  }
                  await cryptoDice.withdrawAirdropTokenOnlyOwner()
              }
          })
      })

const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(fs.readFileSync(__dirname + "/../shared/correct.json", "utf-8"))
    return testCaseJson
}
