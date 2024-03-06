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
import { assert, expect } from "chai"
import { BytesLike, dataLength, toBeHex } from "ethers"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { AirdropConsumer, CRRRNGCoordinator, TonToken } from "../../typechain-types"
import { TestCase } from "../shared/interfacesV2"
import { createTestCaseV2 } from "../shared/testFunctionsV2"
function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("RandomAirdrop Staging Test", () => {
          //const
          const testcases: TestCase = createTestCaseV2()
          const firstPlacePrizeAmount = 500n * 10n ** 18n
          const secondPlacePrizeAmount = 77n * 10n ** 18n
          const registrationDuration = 86400n
          const totalPrizeAmount = 1000n * 10n ** 18n
          const blackListedIndexs = [3, 53, 103, 153, 203, 253, 303, 353, 403, 453]
          const delta: bigint = 9n
          const twoPowerOfDeltaBytes: BytesLike = toBeHex(
              2n ** delta,
              getLength(dataLength(toBeHex(2n ** delta))),
          )
          // let
          let signers: SignerWithAddress[]
          let crrrngCoordinator: CRRRNGCoordinator
          let tonToken: TonToken
          let airdropConsumer: AirdropConsumer
          let crrrngCoordinatorAddress: string
          let tonTokenAddress: string
          let airdropConsumerAddress: string
          it("get 500 signers", async () => {
              signers = await ethers.getSigners()
              assert.equal(signers.length, 500)
          })
          it("deploy CRRRNGCoordinator Contract", async () => {
              const CRRRNGCoordinator = await ethers.getContractFactory("CRRRNGCoordinator")
              crrrngCoordinator = await CRRRNGCoordinator.deploy()
              await crrrngCoordinator.waitForDeployment()
              assert.isNotNull(await crrrngCoordinator.getAddress())
              crrrngCoordinatorAddress = await crrrngCoordinator.getAddress()
              const tx = await crrrngCoordinator.initialize(
                  testcases.setupProofs,
                  twoPowerOfDeltaBytes,
                  delta,
              )
              const receipt = tx.wait()
          })
          it("deploy Ton Token Contract", async () => {
              const TonToken = await ethers.getContractFactory("TonToken")
              tonToken = await TonToken.deploy()
              await tonToken.waitForDeployment()
              assert.isNotNull(await tonToken.getAddress())
              const balance = await tonToken.balanceOf(signers[0].address)
              assert.equal(balance, 1000000000000000000000000000n)
              tonTokenAddress = await tonToken.getAddress()
          })
          it("deploy AirdropConsumer Contract", async () => {
              // act
              const AirdropConsumer = await ethers.getContractFactory("AirdropConsumer")

              airdropConsumer = await AirdropConsumer.deploy(
                  crrrngCoordinatorAddress,
                  tonTokenAddress,
                  firstPlacePrizeAmount,
                  secondPlacePrizeAmount,
              )
              await airdropConsumer.waitForDeployment()
              // get
              airdropConsumerAddress = await airdropConsumer.getAddress()
              // assert
              assert.isNotNull(airdropConsumerAddress)
              assert.equal(
                  await airdropConsumer.getRNGCoordinatorAddress(),
                  crrrngCoordinatorAddress,
              )
              assert.equal(await airdropConsumer.getAirdropTokenAddress(), tonTokenAddress)
              const prizes: [bigint, bigint] =
                  await airdropConsumer.getPrizeAmountForFirstAndSecondtoFourthPlace()
              assert.equal(prizes[0], firstPlacePrizeAmount)
              assert.equal(prizes[1], secondPlacePrizeAmount)
          })
          it("send TonToken to AirdropConsumer Contract and Withdraw Test", async () => {
              //send TonToken to AirdropConsumer Contract
              const airdropConsumerBalance = await tonToken.balanceOf(airdropConsumerAddress)
              const signer0Balance = await tonToken.balanceOf(signers[0].address)
              await tonToken.transfer(airdropConsumerAddress, 1000n * 10n ** 18n)
              const airdropConsumerBalanceAfter = await tonToken.balanceOf(airdropConsumerAddress)
              const signer0BalanceAfter = await tonToken.balanceOf(signers[0].address)
              assert.equal(airdropConsumerBalanceAfter - airdropConsumerBalance, 1000n * 10n ** 18n)
              assert.equal(signer0Balance - signer0BalanceAfter, 1000n * 10n ** 18n)

              // Withdraw
              await airdropConsumer.withdrawAirdropTokenOnlyOwner()
              const airdropConsumerBalanceAfterWithdraw =
                  await tonToken.balanceOf(airdropConsumerAddress)
              assert.equal(airdropConsumerBalanceAfterWithdraw, 0n)
              const signer0BalanceAfterWithdraw = await tonToken.balanceOf(signers[0].address)
              assert.equal(signer0BalanceAfterWithdraw, signer0Balance)
          })
          it("start Registration on AirdropConsumer Contract", async () => {
              // act
              const tx = await airdropConsumer.startRegistration(
                  registrationDuration,
                  totalPrizeAmount,
              )
              // get
              const receipt = await tx.wait()
              const blockNum = BigInt(receipt?.blockNumber.toString()!)
              const block = await ethers.provider.getBlock(blockNum)
              const timestamp = block?.timestamp!
              const registrationTimeAndDuration: [bigint, bigint] =
                  await airdropConsumer.getRegistrationTimeAndDuration()
              const nextRound = await airdropConsumer.getNextRandomAirdropRound()
              const currentRound = nextRound === 0n ? 0n : nextRound - 1n
              const numOfParticipants = await airdropConsumer.getNumOfParticipants(currentRound)
              const isRegistrationStarted = await airdropConsumer.getRoundStatus(currentRound)
              const totalPrizeAmountInContract =
                  await airdropConsumer.getTotalPrizeAmount(currentRound)

              // assert
              assert.equal(registrationTimeAndDuration[0], BigInt(timestamp))
              assert.equal(registrationTimeAndDuration[1], registrationDuration)
              assert.equal(nextRound, 1n)
              assert.equal(currentRound, 0n)
              assert.equal(numOfParticipants, 0n)
              assert.isTrue(isRegistrationStarted[0])
              assert.equal(totalPrizeAmountInContract, totalPrizeAmount)
          })
          it("restart Registration on AirdropConsumer Contract", async () => {
              await time.increase(86400n)
              // act
              const tx = await airdropConsumer.startRegistration(
                  registrationDuration,
                  totalPrizeAmount,
              )
              // get
              const receipt = await tx.wait()
              const blockNum = BigInt(receipt?.blockNumber.toString()!)
              const block = await ethers.provider.getBlock(blockNum)
              const timestamp = block?.timestamp!
              const registrationTimeAndDuration: [bigint, bigint] =
                  await airdropConsumer.getRegistrationTimeAndDuration()
              const nextRound = await airdropConsumer.getNextRandomAirdropRound()
              const currentRound = nextRound === 0n ? 0n : nextRound - 1n
              const numOfParticipants = await airdropConsumer.getNumOfParticipants(currentRound)
              const isRegistrationStarted = await airdropConsumer.getRoundStatus(currentRound)
              const totalPrizeAmountInContract =
                  await airdropConsumer.getTotalPrizeAmount(currentRound)

              // assert
              assert.equal(registrationTimeAndDuration[0], BigInt(timestamp))
              assert.equal(registrationTimeAndDuration[1], registrationDuration)
              assert.equal(nextRound, 1n)
              assert.equal(currentRound, 0n)
              assert.equal(numOfParticipants, 0n)
              assert.isTrue(isRegistrationStarted[0])
              assert.equal(totalPrizeAmountInContract, totalPrizeAmount)
          })
          it("500 participants register for the airdrop", async () => {
              // act
              for (let i = 0; i < 500; i++) {
                  await airdropConsumer.connect(signers[i]).register()
              }
              // get
              const participantsAtRound = await airdropConsumer.getParticipantsAtRound(0n)
              const numOfParticipants = await airdropConsumer.getNumOfParticipants(0n)
              // assert
              assert.equal(numOfParticipants, 500n)
              for (let i = 0; i < 500; i++) {
                  assert.equal(participantsAtRound[i], signers[i].address)
                  assert.equal(
                      await airdropConsumer.getRegisterIndexAtRound(signers[i].address, 0n),
                      BigInt(i),
                  )
                  const participatedRounds = await airdropConsumer.getParticipatedRounds(
                      signers[i].address,
                  )
                  assert.equal(participatedRounds.length, 1)
                  assert.equal(participatedRounds[0], 0n)
              }
          })
          it("blackList a few participants on AirdropConsumer Contract", async () => {
              // act
              const round = (await airdropConsumer.getNextRandomAirdropRound()) - 1n
              let blackListAddresses: string[] = []
              let blackListCount: number = 0
              await time.increase(86400)
              for (let i = 3; i < 500; i += 50) {
                  blackListAddresses.push(signers[i].address)
                  blackListCount++
              }
              await airdropConsumer.blackList(round, blackListAddresses)
              const participatedNum = await airdropConsumer.getNumOfParticipants(round)
              // assert
              for (let i = 3; i < 500; i += 50) {
                  // expect to revert getRegisterIndexAtRound
                  await expect(airdropConsumer.getRegisterIndexAtRound(signers[i].address, round))
                      .to.be.reverted
              }
              assert.equal(participatedNum, 500n - BigInt(blackListCount))
          })
          it("transfer ton token to airdropConsumer and requestRandomWord on airdropConsumer Contract", async () => {
              //act
              // transfer ton to airdropConsumer
              const signer0Balance = await tonToken.balanceOf(signers[0].address)
              const airdropConsumerBalance = await tonToken.balanceOf(airdropConsumerAddress)
              await tonToken.transfer(airdropConsumerAddress, 1000n * 10n ** 18n)
              const airdropConsumerBalanceAfter = await tonToken.balanceOf(airdropConsumerAddress)
              const signer0BalanceAfter = await tonToken.balanceOf(signers[0].address)
              const round = (await airdropConsumer.getNextRandomAirdropRound()) - 1n
              const tx = await airdropConsumer.requestRandomWord(round)
              const receipt = await tx.wait()
              // get (airdropConsumer)
              // get timestamp
              const blockNum = BigInt(receipt?.blockNumber.toString()!)
              const block = await ethers.provider.getBlock(blockNum)
              const timestamp = block?.timestamp!
              const status = await airdropConsumer.getRoundStatus(round)
              const prizeAmountStartingAtFifthPlace =
                  await airdropConsumer.getPrizeAmountStartingAtFifthPlace(round)
              const prizes: [bigint, bigint] =
                  await airdropConsumer.getPrizeAmountForFirstAndSecondtoFourthPlace()
              const totalPrizeAmountInContract = await airdropConsumer.getTotalPrizeAmount(round)
              const requestIdAtRound = await airdropConsumer.getRequestIdAtRound(round)
              const roundAtRequestId = await airdropConsumer.getRoundAtRequestId(requestIdAtRound)
              const numOfParticipants = await airdropConsumer.getNumOfParticipants(0n)
              // assert (airdropConsumer)
              assert.equal(airdropConsumerBalanceAfter - airdropConsumerBalance, 1000n * 10n ** 18n)
              assert.equal(signer0Balance - signer0BalanceAfter, 1000n * 10n ** 18n)
              assert.isTrue(status[1])
              assert.equal(
                  prizeAmountStartingAtFifthPlace,
                  (totalPrizeAmountInContract - prizes[0] - prizes[1] * 3n) /
                      (numOfParticipants - 4n),
              )
              assert.equal(roundAtRequestId, round)
              assert.equal(requestIdAtRound, 0n)

              // get (crrrngCoordinator)
              const nextRound = await crrrngCoordinator.getNextRound()
              const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
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
              // assert (crrrngCoordinator)
              assert.equal(nextRound, 1n)
              assert.equal(valuesAtRound.startTime, BigInt(timestamp))
              assert.equal(valuesAtRound.stage, 1n)
              assert.equal(valuesAtRound.consumer, airdropConsumerAddress)
          })
          it("reRequestRandomWordAtRound on CRRRNGCoordinator Contract", async () => {
              // act
              await time.increase(120)
              const round = (await airdropConsumer.getNextRandomAirdropRound()) - 1n
              const requestIdAtRound = await airdropConsumer.getRequestIdAtRound(round)
              const tx = await crrrngCoordinator.reRequestRandomWordAtRound(requestIdAtRound)
              const receipt = await tx.wait()
              // get (crrrngCoordinator)
              const blockNum = BigInt(receipt?.blockNumber.toString()!)
              const block = await ethers.provider.getBlock(blockNum)
              const timestamp = block?.timestamp!
              const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
              // assert (crrrngCoordinator)
              assert.equal(valuesAtRound.startTime, BigInt(timestamp))
              assert.equal(valuesAtRound.stage, 1n)
              assert.equal(valuesAtRound.consumer, airdropConsumerAddress)
              for (let i = 0; i < 1; i++) {
                  const tx = await crrrngCoordinator
                      .connect(signers[i])
                      .commit(round, testcases.commitList[i])
                  const receipt = await tx.wait()
                  const blockNum = BigInt(receipt?.blockNumber.toString()!)
                  const block = await ethers.provider.getBlock(blockNum)
                  const timestamp = block?.timestamp!
                  const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                  const userInfosAtRound = await crrrngCoordinator.getUserInfosAtRound(
                      signers[i],
                      round,
                  )
                  /*
                struct UserAtRound {
                  uint256 index; // index of the commitRevealValues
                  bool committed; // true if committed
                  bool revealed; // true if revealed
              }
                */
                  const commitRevealValues = await crrrngCoordinator.getCommitRevealValues(
                      0n,
                      userInfosAtRound.index,
                  )
                  /*
                    struct CommitRevealValue {
                      BigNumber c;
                      BigNumber a;
                      address participantAddress;
                  } */

                  // assert
                  assert.equal(valuesAtRound.count, BigInt(i) + 1n)
                  assert.equal(userInfosAtRound.committed, true)
                  assert.equal(userInfosAtRound.revealed, false)
                  assert.equal(commitRevealValues.c.val, testcases.commitList[i].val)
                  assert.equal(commitRevealValues.c.bitlen, testcases.commitList[i].bitlen)
                  assert.equal(commitRevealValues.participantAddress, signers[i].address)
              }
          })
          it("3 commits on CRRRNGCoordinator Contract", async () => {
              // act
              const round = (await airdropConsumer.getNextRandomAirdropRound()) - 1n
              for (let i = 1; i < 3; i++) {
                  const tx = await crrrngCoordinator
                      .connect(signers[i])
                      .commit(round, testcases.commitList[i])
                  const receipt = await tx.wait()
                  const blockNum = BigInt(receipt?.blockNumber.toString()!)
                  const block = await ethers.provider.getBlock(blockNum)
                  const timestamp = block?.timestamp!
                  const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                  const userInfosAtRound = await crrrngCoordinator.getUserInfosAtRound(
                      signers[i],
                      round,
                  )
                  /*
                  struct UserAtRound {
                    uint256 index; // index of the commitRevealValues
                    bool committed; // true if committed
                    bool revealed; // true if revealed
                }
                  */
                  const commitRevealValues = await crrrngCoordinator.getCommitRevealValues(
                      0n,
                      userInfosAtRound.index,
                  )
                  /*
                      struct CommitRevealValue {
                        BigNumber c;
                        BigNumber a;
                        address participantAddress;
                    } */

                  // assert
                  assert.equal(valuesAtRound.count, BigInt(i) + 1n)
                  assert.equal(userInfosAtRound.committed, true)
                  assert.equal(userInfosAtRound.revealed, false)
                  assert.equal(commitRevealValues.c.val, testcases.commitList[i].val)
                  assert.equal(commitRevealValues.c.bitlen, testcases.commitList[i].bitlen)
                  assert.equal(commitRevealValues.participantAddress, signers[i].address)
              }
          })
          it("recover on CRRRNGCoordinator Contract", async () => {
              // act
              await time.increase(120)
              const round = (await airdropConsumer.getNextRandomAirdropRound()) - 1n
              let receipt
              let blockNum
              try {
                  const tx = await crrrngCoordinator.recover(
                      round,
                      testcases.recoveryProofs,
                      twoPowerOfDeltaBytes,
                      delta,
                  )
                  receipt = await tx.wait()
                  blockNum = BigInt(receipt?.blockNumber.toString()!)
              } catch (error) {
                  console.log(error)
              }
              // get (crrrngCoordinator)
              const block = await ethers.provider.getBlock(blockNum!)
              const timestamp = block?.timestamp!
              const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
              // assert crrrngCoordinator contract
              assert.equal(valuesAtRound.numOfPariticipants, 3n)
              assert.equal(valuesAtRound.stage, 0n)
              assert.equal(valuesAtRound.isCompleted, true)
              assert.equal(valuesAtRound.isAllRevealed, false)
              assert.equal(valuesAtRound.omega.val, testcases.omega.val)
              assert.equal(valuesAtRound.omega.bitlen, testcases.omega.bitlen)
              assert.equal(valuesAtRound.omega.val, testcases.recoveredOmega.val)
              assert.equal(valuesAtRound.omega.bitlen, testcases.recoveredOmega.bitlen)
              // get (airdropConsumer)
              const status = await airdropConsumer.getRoundStatus(round)
              const randomNum = await airdropConsumer.getRandomNumAtRound(round)
              // calculate first to fourth place prize in typescript
              const numOfParticipants = await airdropConsumer.getNumOfParticipants(0n)
              const prizes: [bigint, bigint] =
                  await airdropConsumer.getPrizeAmountForFirstAndSecondtoFourthPlace()
              const prizeAmountStartingAtFifthPlace =
                  await airdropConsumer.getPrizeAmountStartingAtFifthPlace(round)
              const firstPlaceIndex = BigInt(randomNum.val) % numOfParticipants
              const gap = numOfParticipants / 4n
              const secondPlaceIndex = (firstPlaceIndex + gap) % numOfParticipants
              const thirdPlaceIndex = (secondPlaceIndex + gap) % numOfParticipants
              const fourthPlaceIndex = (thirdPlaceIndex + gap) % numOfParticipants
              const winnersIndex = await airdropConsumer.getWinnersIndexAndAddressAtRound(round)

              // assert airdropConsumer contract
              assert.isTrue(status[2])
              assert.equal(randomNum.val, testcases.omega.val)
              assert.equal(randomNum.bitlen, testcases.omega.bitlen)
              assert.equal(prizes[0], firstPlacePrizeAmount)
              assert.equal(prizes[1], secondPlacePrizeAmount)
              assert.equal(winnersIndex[0][0], firstPlaceIndex)
              assert.equal(winnersIndex[0][1], secondPlaceIndex)
              assert.equal(winnersIndex[0][2], thirdPlaceIndex)
              assert.equal(winnersIndex[0][3], fourthPlaceIndex)
              assert.equal(winnersIndex[1][0], signers[Number(firstPlaceIndex)].address)
              assert.equal(winnersIndex[1][1], signers[Number(secondPlaceIndex)].address)
              assert.equal(winnersIndex[1][2], signers[Number(thirdPlaceIndex)].address)
              assert.equal(winnersIndex[1][3], signers[Number(fourthPlaceIndex)].address)
          })
          it("500 participants withdraw their airdrop", async () => {
              // act
              const round = (await airdropConsumer.getNextRandomAirdropRound()) - 1n
              const winnersIndexAndAddress =
                  await airdropConsumer.getWinnersIndexAndAddressAtRound(round)
              const prizeAmountStartingAtFifthPlace =
                  await airdropConsumer.getPrizeAmountStartingAtFifthPlace(round)
              for (let i = 0; i < 500; i++) {
                  if (blackListedIndexs.includes(i)) {
                      continue
                  }
                  const signerBalance = await tonToken.balanceOf(signers[i].address)
                  const airdropConsumerBalance = await tonToken.balanceOf(airdropConsumerAddress)
                  await airdropConsumer.connect(signers[i]).withdrawAirdropToken(round)
                  const signerBalanceAfter = await tonToken.balanceOf(signers[i].address)
                  const airdropConsumerBalanceAfter =
                      await tonToken.balanceOf(airdropConsumerAddress)
                  // assert
                  const prizeAmount = await airdropConsumer.getPrizeAmountAtRoundAndIndex(round, i)
                  assert.equal(signerBalanceAfter - signerBalance, prizeAmount)
                  assert.equal(
                      airdropConsumerBalanceAfter - airdropConsumerBalance,
                      -BigInt(prizeAmount),
                  )
                  assert.isTrue(await airdropConsumer.getIsWithdrawn(round, signers[i].address))
              }
              // get
              const airdropConsumerBalanceAfterWithdraw =
                  await tonToken.balanceOf(airdropConsumerAddress)
              console.log(
                  "airdropConsumer Balance After all Withdraw",
                  airdropConsumerBalanceAfterWithdraw,
              )
          })
          it("withdrawRemainingAirdropToken on AirdropConsumer Contract", async () => {
              // act
              const airdropConsumerBalance = await tonToken.balanceOf(airdropConsumerAddress)
              await airdropConsumer.withdrawAirdropTokenOnlyOwner()
              const airdropConsumerBalanceAfter = await tonToken.balanceOf(airdropConsumerAddress)
              // assert
              assert.equal(airdropConsumerBalanceAfter, 0n)
          })
          it("iterate through 3 rounds without get and assert tests", async () => {
              // act
              for (let round = 1; round < 4; round++) {
                  await airdropConsumer.startRegistration(registrationDuration, totalPrizeAmount)
                  for (let j = 0; j < 500; j++) {
                      await airdropConsumer.connect(signers[j]).register()
                  }
                  await time.increase(86400)
                  await tonToken.transfer(airdropConsumerAddress, 1000n * 10n ** 18n)
                  await airdropConsumer.requestRandomWord(round)
                  for (let j = 0; j < 3; j++) {
                      await crrrngCoordinator
                          .connect(signers[j])
                          .commit(round, testcases.commitList[j])
                  }
                  await time.increase(120)
                  await crrrngCoordinator.recover(
                      round,
                      testcases.recoveryProofs,
                      twoPowerOfDeltaBytes,
                      delta,
                  )
                  for (let j = 0; j < 500; j++) {
                      await airdropConsumer.connect(signers[j]).withdrawAirdropToken(round)
                  }
                  await airdropConsumer.withdrawAirdropTokenOnlyOwner()
              }
              // assert
              assert.isTrue(true)
          })
      })
