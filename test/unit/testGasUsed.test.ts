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
import OVM_GasPriceOracleABI from "../shared/Abis/OVM_GasPriceOracle.json"
interface BigNumber {
    val: BytesLike
    bitlen: BigNumberish
}
interface ValueAtRound {
    startTime: BigNumberish
    commitCounts: BigNumberish
    consumer: AddressLike
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
    : describe("GasUsed Test", function () {
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
              flatFee: BigNumberish
          } = {
              disputePeriod: 180n,
              minimumDepositAmount: ethers.parseEther("0.0001"),
              avgL2GasUsed: 0n,
              avgL1GasUsed: 0n,
              premiumPercentage: 0n,
              flatFee: 0n,
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
              it("test initial values on Titan", async function () {
                  // ** deploy CRRNGCoordinatorPoF
                  const CRRNGCoordinatorPoF = await ethers.getContractFactory("CRRNGCoordinatorPoF")
                  const crrrngCoordinator = await CRRNGCoordinatorPoF.deploy(
                      coordinatorConstructorParams.disputePeriod,
                      coordinatorConstructorParams.minimumDepositAmount,
                      coordinatorConstructorParams.avgL2GasUsed,
                      coordinatorConstructorParams.avgL1GasUsed,
                      coordinatorConstructorParams.premiumPercentage,
                      coordinatorConstructorParams.flatFee,
                  )
                  await crrrngCoordinator.waitForDeployment()
                  const crrngCoordinatorAddress = await crrrngCoordinator.getAddress()

                  // ** initialize CRRNGCoordinatorPoF
                  const tx = await crrrngCoordinator.initialize(
                      initializeParams.v,
                      initializeParams.x,
                      initializeParams.y,
                  )
                  const receipt = await tx.wait()
                  const ConsumerExample = await ethers.getContractFactory("ConsumerExample")

                  // ** deploy ConsumerExample
                  const consumerExample = await ConsumerExample.deploy(crrngCoordinatorAddress)
                  await consumerExample.waitForDeployment()

                  // ** 5 operators deposit to become operator
                  const minimumDepositAmount = coordinatorConstructorParams.minimumDepositAmount
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
                  }

                  // ** requestRandomWord
                  const provider = ethers.provider
                  const fee = await provider.getFeeData()
                  const gasPrice = fee.gasPrice as bigint
                  const directFundingCost = await crrrngCoordinator.estimateDirectFundingPrice(
                      callback_gaslimit,
                      gasPrice,
                  )
                  const txRequest = await consumerExample.requestRandomWord({
                      value: (directFundingCost * (100n + 1n)) / 100n,
                  })
                  await txRequest.wait()

                  // ** get OVM_GasPriceOracle contract from Titan network
                  const titanProvider = new ethers.JsonRpcProvider(
                      "https://rpc.titan.tokamak.network",
                  )
                  const signer = new ethers.JsonRpcSigner(titanProvider, signers[0].address)
                  const OVM_GasPriceOracle = await ethers.getContractAt(
                      OVM_GasPriceOracleABI,
                      "0x420000000000000000000000000000000000000F",
                      signer,
                  )

                  // ** allConcanatedData
                  let allConcanatedData: BytesLike = "0x"

                  // ** commits
                  const round = (await crrrngCoordinator.getNextRound()) - 1n
                  const numOfOperators = 3
                  for (let i = 0; i < numOfOperators; i++) {
                      const encodedFuncData = crrrngCoordinator.interface.encodeFunctionData(
                          "commit",
                          [round, commitParams[i]],
                      )
                      const concatedNatedData = ethers.concat([
                          encodedFuncData,
                          L1_FEE_DATA_PADDING,
                      ])
                      allConcanatedData = ethers.concat([allConcanatedData, concatedNatedData])
                      //console.log(concatedNatedData)
                      const tx = await crrrngCoordinator
                          .connect(signers[i])
                          .commit(round, commitParams[i])
                      const receipt = await tx.wait()
                      const gasUsed = receipt?.gasUsed as bigint
                      console.log(`commit L2gasUsed: ${gasUsed}`)
                      console.log(
                          `commit L1gasUsed: ${await OVM_GasPriceOracle.getL1GasUsed(
                              concatedNatedData,
                          )}`,
                      )
                  }

                  // ** recover
                  await time.increase(120n)
                  const txRecover = await crrrngCoordinator
                      .connect(signers[0])
                      .recover(round, recoverParams.y)
                  const receiptRecover = await txRecover.wait()
                  const gasUsedRecover = receiptRecover?.gasUsed as bigint
                  const encodedFuncData = crrrngCoordinator.interface.encodeFunctionData(
                      "recover",
                      [round, recoverParams.y],
                  )
                  const concatedNatedData = ethers.concat([encodedFuncData, L1_FEE_DATA_PADDING])
                  allConcanatedData = ethers.concat([allConcanatedData, concatedNatedData])
                  console.log(`recover L2gasUsed: ${gasUsedRecover}`)
                  console.log(
                      `recover L1gasUsed: ${await OVM_GasPriceOracle.getL1GasUsed(
                          concatedNatedData,
                      )}`,
                  )

                  // ** fulfill
                  await time.increase(180n)
                  const txFulfill = await crrrngCoordinator.fulfillRandomness(round)
                  const receiptFulfill = await txFulfill.wait()
                  const gasUsedFulfill = receiptFulfill?.gasUsed as bigint
                  const encodedFuncDataFulfill = crrrngCoordinator.interface.encodeFunctionData(
                      "fulfillRandomness",
                      [round],
                  )
                  const concatedNatedDataFulfill = ethers.concat([
                      encodedFuncDataFulfill,
                      L1_FEE_DATA_PADDING,
                  ])
                  allConcanatedData = ethers.concat([allConcanatedData, concatedNatedDataFulfill])
                  console.log(`fulfill L2gasUsed: ${gasUsedFulfill}`)
                  console.log(
                      `fulfill L1gasUsed: ${await OVM_GasPriceOracle.getL1GasUsed(
                          concatedNatedDataFulfill,
                      )}`,
                  )

                  const l1GasUsed = await OVM_GasPriceOracle.getL1GasUsed(allConcanatedData)
                  console.log(`all L1gasUsed: `, l1GasUsed)

                  const overhead = await OVM_GasPriceOracle.overhead()
                  const overhead2 = 68n * 16n
                  const overhead3 = (overhead + overhead2) * 4n
                  console.log(l1GasUsed + overhead3)

                  console.log(allConcanatedData)
              })
              it("GetL1FeeTest Titan gas compare", async function () {
                  const GetL1FeeTest = await ethers.getContractFactory("GetL1FeeTest")
                  const getL1FeeTest = await GetL1FeeTest.deploy()

                  const getCurrentTxL1GasFeesByBytes =
                      await getL1FeeTest.getCurrentTxL1GasFeesTitan()
                  //   await expect(getCurrentTxL1GasFeesByBytes).to.be.eq(
                  //       getCurrentTxL1GasFeesByGasUsed,
                  //   )
                  console.log(`getCurrentTxL1GasFeesByBytes: ${getCurrentTxL1GasFeesByBytes}`)

                  const estimatedGasUsed1 =
                      await getL1FeeTest.getCurrentTxL1GasFeesTitan.estimateGas()
                  console.log(`estimatedGasUsed1: ${estimatedGasUsed1}`)

                  const titanProvider = new ethers.JsonRpcProvider(
                      "https://rpc.titan.tokamak.network",
                  )
                  signers = await ethers.getSigners()
                  const signer = new ethers.JsonRpcSigner(titanProvider, signers[0].address)
                  const OVM_GasPriceOracle = await ethers.getContractAt(
                      OVM_GasPriceOracleABI,
                      "0x420000000000000000000000000000000000000F",
                      signer,
                  )
              })
              it("GetL1FeeTest OPMainnet gas compare", async function () {
                  const GetL1FeeTest = await ethers.getContractFactory("GetL1FeeTest")
                  const getL1FeeTest = await GetL1FeeTest.deploy()

                  const getL1FeeBedrock = await getL1FeeTest.getL1FeeBedrock()
                  const getL1FeeEcotone = await getL1FeeTest.getL1FeeEcotone()

                  console.log(`getL1FeeBedrock: ${getL1FeeBedrock}`)
                  console.log(`getL1FeeEcotone: ${getL1FeeEcotone}`)

                  const estimatedGasUsed1 = await getL1FeeTest.getL1FeeBedrock.estimateGas()
                  console.log(`estimatedGasUsed for bedrock: ${estimatedGasUsed1}`)
                  const estimatedGasUsed2 = await getL1FeeTest.getL1FeeEcotone.estimateGas()
                  console.log(`estimatedGasUsed2 for ecotone: ${estimatedGasUsed2}`)
              })
          })
      })
