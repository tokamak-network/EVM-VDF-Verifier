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
import { AddressLike, BigNumberish, BytesLike } from "ethers"
import fs from "fs"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { CRRNGCoordinatorPoF, TonToken } from "../../typechain-types"
import {
    returnCoordinatorConstructorParams,
    returnIntializeAndCommitAndRecoverParams,
} from "../shared/setCRRNGCoordinatorPoF"
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
    isRecovered: boolean
}
function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(
        fs.readFileSync(__dirname + "/../shared/TestCases/currentTestCase.json", "utf-8"),
    )
    return testCaseJson
}

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Decode Custom Error", function () {
          let coordinatorConstructorParams: {
              disputePeriod: BigNumberish
              minimumDepositAmount: BigNumberish
              avgL2GasUsed: BigNumberish
              avgL1GasUsed: BigNumberish
              premiumPercentage: BigNumberish
              penaltyPercentage: BigNumberish
              flatFee: BigNumberish
          }
          let signers: SignerWithAddress[]
          let crrrngCoordinator: CRRNGCoordinatorPoF
          let crrngCoordinatorAddress: string
          let initializeParams: {
              v: BigNumber[]
              x: BigNumber
              y: BigNumber
          }
          let commitParams: BigNumber[]
          let recoverParams: {
              round: number
              v: BigNumber[]
              x: BigNumber
              y: BigNumber
          }
          let tonToken: TonToken
          let tonTokenAddress: string
          it("get signers", async () => {
              signers = await ethers.getSigners()
              expect(signers.length).to.eq(500)
          })
          it("Create TestCase And PreProcess Data", async () => {
              ;({ initializeParams, commitParams, recoverParams } =
                  returnIntializeAndCommitAndRecoverParams())
              coordinatorConstructorParams = returnCoordinatorConstructorParams()
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
              const CRRNGCoordinatorPoF = await ethers.getContractFactory("CRRNGCoordinatorPoF")
              crrrngCoordinator = await CRRNGCoordinatorPoF.deploy(
                  coordinatorConstructorParams.disputePeriod,
                  coordinatorConstructorParams.minimumDepositAmount,
                  coordinatorConstructorParams.avgL2GasUsed,
                  coordinatorConstructorParams.avgL1GasUsed,
                  coordinatorConstructorParams.premiumPercentage,
                  coordinatorConstructorParams.penaltyPercentage,
                  coordinatorConstructorParams.flatFee,
              )
              await crrrngCoordinator.waitForDeployment()
              crrngCoordinatorAddress = await crrrngCoordinator.getAddress()
              expect(crrngCoordinatorAddress).to.be.properAddress
          })
          it("initialize CRRNGCoordinatorPoF", async () => {
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
          describe("decode", function () {
              it("decode 0xa264a954", async function () {
                  console.log(crrrngCoordinator.interface.parseError("0x28a1045e"))
              })
          })
      })
