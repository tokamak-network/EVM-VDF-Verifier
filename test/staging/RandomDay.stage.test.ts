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
import { getRandomValues } from "crypto"
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
import { CRRNGCoordinatorPoF, RandomDayTest, TonToken } from "../../typechain-types"
import OVM_GasPriceOracleABI from "../shared/OVM_GasPriceOracle.json"
const getBitLenth2 = (num: string): BigNumberish => {
    return BigInt(num).toString(2).length
}
interface BigNumber {
    val: BytesLike
    bitlen: BigNumberish
}
interface ValueAtRound {
    startTime: BigNumberish
    requestedTime: BigNumberish
    commitCounts: BigNumberish
    consumer: AddressLike
    commitsString: BytesLike
    omega: BigNumber
    stage: BigNumberish
    isCompleted: boolean
    isVerified: boolean
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

async function getTitanL1GasUsed(encodedFuncData: BytesLike) {
    const signers = await ethers.getSigners()
    const L1_FEE_DATA_PADDING =
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    const concatedNatedData = ethers.concat([encodedFuncData, L1_FEE_DATA_PADDING])
    const titanProvider = new ethers.JsonRpcProvider("https://rpc.titan.tokamak.network")
    const signer = new ethers.JsonRpcSigner(titanProvider, signers[0].address)
    const OVM_GasPriceOracle = await ethers.getContractAt(
        OVM_GasPriceOracleABI,
        "0x420000000000000000000000000000000000000F",
        signer,
    )
    const l1GasUsed = await OVM_GasPriceOracle.getL1GasUsed(concatedNatedData)
    return l1GasUsed
}

async function getTitanL1gasCost(encodedFuncData: BytesLike) {
    return (await getTitanL1GasUsed(encodedFuncData)) * 23433261599n
}

async function getTotalTitanGasCost(encodedFuncData: BytesLike, L2GasUsed: BigNumberish) {
    return (await getTitanL1gasCost(encodedFuncData)) + BigInt(L2GasUsed) * 1000000n
}

async function getL1GasUsed(encodedFuncData: BytesLike) {
    return (await getTitanL1GasUsed(encodedFuncData)) - 4000n
}

describe("RandomDay", function () {
    const L1_FEE_DATA_PADDING =
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
    let callback_gaslimit: BigNumberish = 210000n
    const delta: number = 9
    const eventPeriod: number = 864000
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
    let randomDay: RandomDayTest
    let randomDayAddress: string
    let tonToken: TonToken
    let tonTokenAddress: string
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
    let directFundingCostOnTitan: BigNumberish
    describe("Settings", function () {
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
        it("deploy crrrngCoordinator to titan and estimateDirectFundingPrice", async () => {
            await network.provider.request({
                method: "hardhat_reset",
                params: [
                    {
                        forking: {
                            jsonRpcUrl: "https://rpc.titan.tokamak.network",
                        },
                    },
                ],
            })
            const CRRNGCoordinator = await ethers.getContractFactory("CRRNGCoordinatorPoFForTitan")
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
            const avgL1GasUsed = BigInt(coordinatorConstructorParams.avgL1GasUsed) + 20000n

            const estimateDirectFundingPrice = await crrrngCoordinator.estimateDirectFundingPrice(
                callback_gaslimit,
                1000000n,
            )
            console.log(
                "estimateDirectFundingPrice",
                ethers.formatEther(estimateDirectFundingPrice + avgL1GasUsed * 23433261599n),
                "ETH",
            )
            directFundingCostOnTitan = estimateDirectFundingPrice + avgL1GasUsed * 23433261599n
            await network.provider.request({
                method: "hardhat_reset",
            })
        })
        it("get signers", async () => {
            signers = await ethers.getSigners()
            await expect(signers.length).to.eq(500)
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

            const titanGasCost = await getTotalTitanGasCost(
                crrrngCoordinator.deploymentTransaction()?.data as BytesLike,
                gasUsed,
            )
            console.log(
                "deploy CRRNGCoordinator total gasCost on Titan",
                ethers.formatEther(titanGasCost),
                "ETH",
            )

            crrngCoordinatorAddress = await crrrngCoordinator.getAddress()
            await expect(crrngCoordinatorAddress).to.be.properAddress
            // ** get
            const feeSettings = await crrrngCoordinator.getFeeSettings()
            const disputePeriod = await crrrngCoordinator.getDisputePeriod()

            // ** assert
            await expect(feeSettings[0]).to.equal(coordinatorConstructorParams.minimumDepositAmount)
            await expect(feeSettings[1]).to.equal(coordinatorConstructorParams.avgL2GasUsed)
            await expect(feeSettings[2]).to.equal(coordinatorConstructorParams.avgL1GasUsed)
            await expect(feeSettings[3]).to.equal(coordinatorConstructorParams.premiumPercentage)
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
            const encodedFuncData = crrrngCoordinator.interface.encodeFunctionData("initialize", [
                initializeParams.v,
                initializeParams.x,
                initializeParams.y,
            ])
            const titanGasCost = await getTotalTitanGasCost(encodedFuncData, gasUsed)
            console.log(
                "initialize CRRNGCoordinator total gasCost on Titan",
                ethers.formatEther(titanGasCost),
                "ETH",
            )

            // ** get
            const isInitialized = await crrrngCoordinator.isInitialized()

            // ** assert
            await expect(isInitialized).to.equal(true)
        })
        it("deploy TonToken", async function () {
            const TonToken = await ethers.getContractFactory("TonToken")
            tonToken = await TonToken.deploy()
            await tonToken.waitForDeployment()
            const receipt = await tonToken.deploymentTransaction()?.wait()
            const gasUsed = receipt?.gasUsed as bigint

            const titanGasCost = await getTotalTitanGasCost(
                tonToken.deploymentTransaction()?.data as BytesLike,
                gasUsed,
            )
            console.log(
                "deploy TonToken total gasCost on Titan",
                ethers.formatEther(titanGasCost),
                "ETH",
            )

            tonTokenAddress = await tonToken.getAddress()
            await expect(tonTokenAddress).to.be.properAddress
        })
        it("deploy RandomDay", async function () {
            const RandomDay = await ethers.getContractFactory("RandomDayTest")
            randomDay = await RandomDay.deploy(crrngCoordinatorAddress, tonTokenAddress)
            await randomDay.waitForDeployment()
            const receipt = await randomDay.deploymentTransaction()?.wait()
            const gasUsed = receipt?.gasUsed as bigint

            const titanGasCost = await getTotalTitanGasCost(
                randomDay.deploymentTransaction()?.data as BytesLike,
                gasUsed,
            )
            console.log(
                "deploy RandomDay total gasCost on Titan",
                ethers.formatEther(titanGasCost),
                "ETH",
            )

            randomDayAddress = await randomDay.getAddress()
            await expect(randomDayAddress).to.be.properAddress
        })
        it("5 operators deposit to become operator", async () => {
            const minimumDepositAmount = coordinatorConstructorParams.minimumDepositAmount
            const minimumDepositAmountFromContract =
                await crrrngCoordinator.getMinimumDepositAmount()
            await expect(minimumDepositAmount).to.equal(minimumDepositAmountFromContract)
            for (let i: number = 0; i < 5; i++) {
                const depositedAmount = await crrrngCoordinator.getDepositAmount(signers[i].address)
                if (depositedAmount < BigInt(minimumDepositAmount)) {
                    const tx = await crrrngCoordinator.connect(signers[i]).operatorDeposit({
                        value: BigInt(minimumDepositAmount) - depositedAmount,
                    })
                    const receipt = await tx.wait()
                    const gasUsed = receipt?.gasUsed as bigint
                    const titanGasCost = await getTotalTitanGasCost(tx.data as BytesLike, gasUsed)
                    console.log(
                        "operatorDeposit total gasCost on Titan",
                        ethers.formatEther(titanGasCost),
                        "ETH",
                    )
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
    async function getEvent(receipt: ContractTransactionReceipt) {
        const eventInterface = crrrngCoordinator.interface.getEvent("FulfillRandomness")
        const eventName = "FulfillRandomness"
        let eventIndex = -1
        for (let i = 0; i < receipt.logs.length; i++) {
            if (receipt.logs[i].topics[0] === eventInterface.topicHash) {
                eventIndex = i
                break
            }
        }
        if (eventIndex === -1) {
            console.log("No Events")
            process.exit()
        }
        const data = receipt.logs[eventIndex].data
        const topics = receipt.logs[eventIndex].topics
        const event = crrrngCoordinator.interface.decodeEventLog(eventName, data, topics)
        if (event[2] == false) {
            console.log("fulfilledFailed", event)
        }
    }
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
            await expect(crrrngCoordinator.fulfillRandomness(round)).to.be.revertedWithCustomError(
                crrrngCoordinator,
                "NotCommittedParticipant",
            )
        })
        it("startEvent by Owner", async () => {
            const encodedFuncData = randomDay.interface.encodeFunctionData("startEvent")
            const tx = await randomDay.startEvent()
            const receipt = await tx.wait()
            const gasUsed = receipt?.gasUsed as bigint
            const titanGasCost = await getTotalTitanGasCost(encodedFuncData, gasUsed)
            console.log(
                "startEvent total gasCost on Titan",
                ethers.formatEther(titanGasCost),
                "ETH",
            )

            // ** get
            const eventEndTime = await randomDay.eventEndTime()
            const time = await ethers.provider.getBlock("latest")

            // ** assert
            await expect(eventEndTime).to.equal(time!.timestamp + eventPeriod)
        })
        it("500 signers requestRandomWords once each", async () => {
            const provider = ethers.provider
            let totalCostAvg = 0n
            for (let i = 0; i < 500; i++) {
                const fee = await provider.getFeeData()
                const gasPrice = fee.gasPrice as bigint
                const directFundingCost = await crrrngCoordinator.estimateDirectFundingPrice(
                    callback_gaslimit,
                    gasPrice,
                )
                const tx = await randomDay
                    .connect(signers[i])
                    .requestRandomWord({ value: directFundingCost })
                const receipt = await tx.wait()
                const gasUsed = receipt?.gasUsed as bigint
                const titanGasCost = await getTotalTitanGasCost(tx.data as BytesLike, gasUsed)
                const totalCost = titanGasCost + BigInt(directFundingCostOnTitan)

                totalCostAvg += totalCost

                // ** get
                const s_requests = await randomDay.s_requests(i)
                const s_requesters = await randomDay.getRequestersInfos(signers[i].address)
                const requestCount = await randomDay.requestCount()
                const lastRequestId = await randomDay.lastRequestId()

                // ** assert
                await expect(s_requests.requested).to.equal(true)
                await expect(s_requests.fulfilled).to.equal(false)
                await expect(s_requests.randomWord).to.equal(0n)
                await expect(s_requests.requester).to.equal(signers[i].address)
                await expect(s_requesters[0]).to.equal(0n)
                await expect(s_requesters[1]).to.eql([BigInt(i)])
                // await expect(s_requesters[2]).to.eql([0n])
                await expect(requestCount).to.equal(i + 1)
                await expect(lastRequestId).to.equal(i)

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
                await expect(valuesAtRound.consumer).to.be.equal(await randomDay.getAddress())
                await expect(consumerAddress).to.be.equal(await randomDay.getAddress())
                await expect(valuesAtRound.commitsString).to.be.equal("0x")
                await expect(valuesAtRound.omega.val).to.be.equal("0x")
                await expect(valuesAtRound.stage).to.be.equal(1n)
                await expect(valuesAtRound.isCompleted).to.be.equal(false)
                await expect(valuesAtRound.isVerified).to.be.equal(false)
            }
            console.log("request randomword avg cost", totalCostAvg / 500n)
        })
        it("3 operators fulfill 500 rounds", async () => {
            let _commitAvgGas = 0n
            let commitAvgGas = 0n
            let recoverAvgGas = 0n
            let fulfillAvgGas = 0n
            for (let round = 0; round < 500; round++) {
                for (let i = 0; i < 3; i++) {
                    // ** commit
                    const tx = await crrrngCoordinator
                        .connect(signers[i])
                        .commit(round, commitParams[i])
                    const receipt = await tx.wait()
                    const valuesAtRound: ValueAtRound =
                        await crrrngCoordinator.getValuesAtRound(round)
                    await expect(valuesAtRound.commitCounts).to.equal(i + 1)
                    const gasUsed = receipt?.gasUsed as bigint
                    const titanGasCost = await getTotalTitanGasCost(tx.data as BytesLike, gasUsed)
                    _commitAvgGas += titanGasCost

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
                _commitAvgGas /= 3n
                commitAvgGas += _commitAvgGas

                // ** recover
                let rand = getRandomValues(new Uint8Array(2048 / 8))
                const bytesHex =
                    "0x" + rand.reduce((o, v) => o + ("00" + v.toString(16)).slice(-2), "")
                const recover = {
                    val: toBeHex(bytesHex, getLength(dataLength(toBeHex(bytesHex)))),
                    bitlen: getBitLenth2(toBeHex(bytesHex)),
                }

                await time.increase(180)
                let tx = await crrrngCoordinator.connect(signers[0]).recover(round, recover)
                let receipt = await tx.wait()
                let gasUsed = receipt?.gasUsed as bigint
                let titanGasCost = await getTotalTitanGasCost(tx.data as BytesLike, gasUsed)
                recoverAvgGas += titanGasCost

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
                    await crrrngCoordinator.getDisputeEndTimeOfOperator(signers[0].address)

                // ** assert
                await expect(valuesAtRound.commitCounts).to.equal(3)
                await expect(valuesAtRound.isCompleted).to.equal(true)
                await expect(valuesAtRound.stage).to.equal(0)
                await expect(valuesAtRound.isVerified).to.equal(false)

                await expect(getDisputeEndTimeAndLeaderAtRound[0]).to.equal(
                    blockTimestamp + BigInt(coordinatorConstructorParams.disputePeriod),
                )
                await expect(getDisputeEndTimeAndLeaderAtRound[1]).to.equal(signers[0].address)

                await expect(getDisputeEndTimeOfOperator).to.equal(
                    blockTimestamp + BigInt(coordinatorConstructorParams.disputePeriod),
                )

                // ** fulfill
                const disputePeriod = coordinatorConstructorParams.disputePeriod
                await time.increase(BigInt(disputePeriod) + 1n)
                tx = await crrrngCoordinator.connect(signers[0]).fulfillRandomness(round)
                receipt = await tx.wait()
                gasUsed = receipt?.gasUsed as bigint
                titanGasCost = await getTotalTitanGasCost(tx.data as BytesLike, gasUsed)
                await getEvent(receipt!)

                fulfillAvgGas += titanGasCost

                // ** get
                const s_requesters = await randomDay.getRequestersInfos(signers[round].address)
                const s_requests = await randomDay.s_requests(round)

                const getFulfillStatusAtRound =
                    await crrrngCoordinator.getFulfillStatusAtRound(round)

                // ** assert
                await expect(getFulfillStatusAtRound[0]).to.equal(true)
                await expect(getFulfillStatusAtRound[1]).to.equal(true)

                await expect(s_requesters[0]).to.equal(s_requesters[2][0])
                await expect(s_requesters[1]).to.eql([BigInt(round)])
                await expect(s_requests.requested).to.equal(true)
                await expect(s_requests.fulfilled).to.equal(true)
                await expect(s_requests.randomWord).to.equal(
                    BigInt(ethers.keccak256(valuesAtRound.omega.val)),
                )
                await expect(s_requests.requester).to.equal(signers[round].address)
            }
            console.log("commit avg gas", commitAvgGas / 500n)
            console.log("recover avg gas", recoverAvgGas / 500n)
            console.log("fulfill avg gas", fulfillAvgGas / 500n)

            let requesterNum = 0n
            for (let i = 1; i < 1001; i++) {
                const requesters = await randomDay.getTickRequesters(i)
                if (requesters.length > 0) {
                    console.log("tick:", i, " requestersNum:", requesters.length)
                    requesterNum += BigInt(requesters.length)
                }
            }
            expect(requesterNum).to.equal(500n)
            it("getThreeClosestToSevenHundred", async () => {
                const getThreeClosestToSevenHundreds =
                    await randomDay.getThreeClosestToSevenHundred()
                console.log("ticks, nums")
                console.log(getThreeClosestToSevenHundreds)
            })
        })
        it("500 signers requestRandomWords ~ fulfill one more #1", async () => {
            // ** requestRandomWords
            const provider = ethers.provider
            for (let i = 0; i < 500; i++) {
                const fee = await provider.getFeeData()
                const gasPrice = fee.gasPrice as bigint
                const directFundingCost = await crrrngCoordinator.estimateDirectFundingPrice(
                    callback_gaslimit,
                    gasPrice,
                )
                const tx = await randomDay
                    .connect(signers[i])
                    .requestRandomWord({ value: directFundingCost })
                const receipt = await tx.wait()
            }
            for (let round = 500; round < 1000; round++) {
                for (let i = 0; i < 3; i++) {
                    // ** commit
                    const tx = await crrrngCoordinator
                        .connect(signers[i])
                        .commit(round, commitParams[i])
                    await tx.wait()
                }

                // ** recover
                let rand = getRandomValues(new Uint8Array(2048 / 8))
                const bytesHex =
                    "0x" + rand.reduce((o, v) => o + ("00" + v.toString(16)).slice(-2), "")
                const recover = {
                    val: toBeHex(bytesHex, getLength(dataLength(toBeHex(bytesHex)))),
                    bitlen: getBitLenth2(toBeHex(bytesHex)),
                }

                await time.increase(180)
                let tx = await crrrngCoordinator.connect(signers[0]).recover(round, recover)
                let receipt = await tx.wait()

                // ** fulfill
                const disputePeriod = coordinatorConstructorParams.disputePeriod
                await time.increase(BigInt(disputePeriod) + 1n)
                tx = await crrrngCoordinator.connect(signers[0]).fulfillRandomness(round)
                receipt = await tx.wait()
                await getEvent(receipt!)

                // ** get
                const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                const s_requesters = await randomDay.getRequestersInfos(
                    signers[round % 500].address,
                )
                const s_requests = await randomDay.s_requests(round)

                const getFulfillStatusAtRound =
                    await crrrngCoordinator.getFulfillStatusAtRound(round)

                // ** assert
                await expect(getFulfillStatusAtRound[0]).to.equal(true)
                await expect(getFulfillStatusAtRound[1]).to.equal(true)

                await expect(s_requesters[0]).to.equal(
                    (s_requesters[2][0] + s_requesters[2][1]) / 2n,
                )
                await expect(s_requesters[1]).to.eql([BigInt(round) - 500n, BigInt(round)])
                await expect(s_requests.requested).to.equal(true)
                await expect(s_requests.fulfilled).to.equal(true)
                await expect(s_requests.randomWord).to.equal(
                    BigInt(ethers.keccak256(valuesAtRound.omega.val)),
                )
                await expect(s_requests.requester).to.equal(signers[round % 500].address)
            }
            let requesterNum = 0n
            for (let i = 1; i < 1001; i++) {
                const requesters = await randomDay.getTickRequesters(i)
                if (requesters.length > 0) {
                    console.log("tick:", i, " requestersNum:", requesters.length)
                    requesterNum += BigInt(requesters.length)
                }
            }
            expect(requesterNum).to.equal(500n)
        })
        it("500 signers requestRandomWords ~ fulfill one more #2", async () => {
            // ** requestRandomWords
            const provider = ethers.provider
            for (let i = 0; i < 500; i++) {
                const fee = await provider.getFeeData()
                const gasPrice = fee.gasPrice as bigint
                const directFundingCost = await crrrngCoordinator.estimateDirectFundingPrice(
                    callback_gaslimit,
                    gasPrice,
                )
                const tx = await randomDay
                    .connect(signers[i])
                    .requestRandomWord({ value: directFundingCost })
                const receipt = await tx.wait()
            }
            for (let round = 1000; round < 1500; round++) {
                for (let i = 0; i < 3; i++) {
                    // ** commit
                    const tx = await crrrngCoordinator
                        .connect(signers[i])
                        .commit(round, commitParams[i])
                    await tx.wait()
                }

                // ** recover
                let rand = getRandomValues(new Uint8Array(2048 / 8))
                const bytesHex =
                    "0x" + rand.reduce((o, v) => o + ("00" + v.toString(16)).slice(-2), "")
                const recover = {
                    val: toBeHex(bytesHex, getLength(dataLength(toBeHex(bytesHex)))),
                    bitlen: getBitLenth2(toBeHex(bytesHex)),
                }

                await time.increase(180)
                let tx = await crrrngCoordinator.connect(signers[0]).recover(round, recover)
                let receipt = await tx.wait()

                // ** fulfill
                const disputePeriod = coordinatorConstructorParams.disputePeriod
                await time.increase(BigInt(disputePeriod) + 1n)
                tx = await crrrngCoordinator.connect(signers[0]).fulfillRandomness(round)
                receipt = await tx.wait()
                await getEvent(receipt!)

                // ** get
                const valuesAtRound = await crrrngCoordinator.getValuesAtRound(round)
                const s_requesters = await randomDay.getRequestersInfos(
                    signers[round % 500].address,
                )
                const s_requests = await randomDay.s_requests(round)

                const getFulfillStatusAtRound =
                    await crrrngCoordinator.getFulfillStatusAtRound(round)

                // ** assert
                await expect(getFulfillStatusAtRound[0]).to.equal(true)
                await expect(getFulfillStatusAtRound[1]).to.equal(true)

                const calculated =
                    (s_requesters[2][0] + s_requesters[2][1] + s_requesters[2][2]) / 3n
                const difference = Math.abs(Number(calculated - s_requesters[0]))
                await expect(difference).to.be.lessThan(2)

                await expect(s_requesters[1]).to.eql([
                    BigInt(round) - 1000n,
                    BigInt(round) - 500n,
                    BigInt(round),
                ])
                await expect(s_requests.requested).to.equal(true)
                await expect(s_requests.fulfilled).to.equal(true)
                await expect(s_requests.randomWord).to.equal(
                    BigInt(ethers.keccak256(valuesAtRound.omega.val)),
                )
                await expect(s_requests.requester).to.equal(signers[round % 500].address)
            }
        })
        it("transfer 1000 TON to RandomDay", async () => {
            const tx = await tonToken.transfer(randomDayAddress, ethers.parseEther("1000"))
            await tx.wait()
            const balance = await tonToken.balanceOf(randomDayAddress)
            await expect(balance).to.equal(ethers.parseEther("1000"))
        })
        it("finalizeRankingandSendPrize", async () => {
            const eventEndTime = await randomDay.eventEndTime()
            const currentTimestamp = await ethers.provider.getBlock("latest")
            await time.increase(eventEndTime - BigInt(currentTimestamp!.timestamp) + 1n)

            // ** blackList funciton
            const blackListAddresses: string[] = []
            for (let i = 10; i < 15; i++) {
                blackListAddresses.push(signers[i].address)
            }
            let tx = await randomDay.blackList(blackListAddresses)
            let receipt = await tx.wait()
            let gasUsed = receipt?.gasUsed as bigint
            let titanGasCost = await getTotalTitanGasCost(tx.data as BytesLike, gasUsed)
            console.log(
                "blackList 5 people total gasCost on Titan",
                ethers.formatEther(titanGasCost),
                "ETH",
            )

            let requesterNum = 0n
            for (let i = 1; i < 1001; i++) {
                const requesters = await randomDay.getTickRequesters(i)
                if (requesters.length > 0) {
                    console.log("tick:", i, " requestersNum:", requesters.length)
                    requesterNum += BigInt(requesters.length)
                }
            }
            expect(requesterNum).to.equal(495n)

            // ** finalizeRankingandSendPrize
            const getThreeClosestToSevenHundreds = await randomDay.getThreeClosestToSevenHundred()
            console.log("ticks, nums")
            console.log(getThreeClosestToSevenHundreds)
            const winners: {
                [key: number]: string[]
            } = {}
            for (let i = 0; i < getThreeClosestToSevenHundreds[0].length; i++) {
                if (getThreeClosestToSevenHundreds[0][i] != 1001n) {
                    const tickRequesters = await randomDay.getTickRequesters(
                        getThreeClosestToSevenHundreds[0][i],
                    )
                    winners[Number(getThreeClosestToSevenHundreds[0][i])] = tickRequesters
                }
            }

            tx = await randomDay.finalizeRankingandSendPrize()
            receipt = await tx.wait()
            gasUsed = receipt?.gasUsed as bigint
            titanGasCost = await getTotalTitanGasCost(tx.data as BytesLike, gasUsed)
            console.log(
                "finalizeRankingandSendPrize total gasCost on Titan",
                ethers.formatEther(titanGasCost),
                "ETH",
            )
            const balance = await tonToken.balanceOf(randomDayAddress)
            console.log("randomDay contract Ton balance", balance)

            for (const key in winners) {
                console.log("tick:", key, " Ton balance")
                for (let i = 0; i < winners[key].length; i++) {
                    console.log(await tonToken.balanceOf(winners[key][i]))
                }
            }
        })
    })
})
