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
//
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { expect } from "chai"
import { AddressLike, BigNumberish, BytesLike, dataLength, toBeHex } from "ethers"
import fs from "fs"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { CRRNGCoordinator, CryptoDice, TonToken } from "../../typechain-types"
interface BigNumber {
    val: BytesLike
    bitlen: BigNumberish
}
interface ValueAtRound {
    startTime: BigNumberish
    commitCounts: BigNumberish
    consumer: AddressLike
    bStar: BytesLike
    commitsString: BytesLike
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
    : describe("Decode Custom Error", function () {
          const callback_gaslimit = 100000n
          const coordinatorConstructorParams: {
              disputePeriod: BigNumberish
              minimumDepositAmount: BigNumberish
              avgL2GasUsed: BigNumberish
              premiumPercentage: BigNumberish
              flatFee: BigNumberish
          } = {
              disputePeriod: 1800n,
              minimumDepositAmount: ethers.parseEther("0.1"),
              avgL2GasUsed: 2297700n,
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
                  testCaseJson.recoveryProofs = testCaseJson.recoveryProofs?.slice(0, -(delta + 1))
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
                  coordinatorConstructorParams.avgL2GasUsed,
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
          describe("decode", function () {
              it("decode 0xa264a954", async function () {
                  console.log(crrrngCoordinator.interface.parseError("0xa264a954"))
                  console.log(crrrngCoordinator.interface.parseError("0xaf1bddf7"))
              })
          })
      })
