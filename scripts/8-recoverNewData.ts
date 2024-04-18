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
import { BigNumberish, BytesLike, dataLength, toBeHex } from "ethers"
import fs from "fs"
import { deployments, ethers, getNamedAccounts, network } from "hardhat"
interface BigNumber {
    val: BytesLike
    bitlen: number
}
function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
async function recover() {
    const chainId: number = network.config.chainId as number
    const { deployer } = await getNamedAccounts()
    console.log("EOA address:", deployer)
    const cryptoDiceConsumerAddress = (await deployments.get("CryptoDice")).address
    console.log("CryptoDice address:", cryptoDiceConsumerAddress)
    const cryptoDiceContract = await ethers.getContractAt("CryptoDice", cryptoDiceConsumerAddress)
    const crrrngCoordinatorAddress = (await deployments.get("CRRRNGCoordinator")).address
    console.log("CRRRNGCoordinator address:", crrrngCoordinatorAddress)
    const crrngCoordinatorContract = await ethers.getContractAt(
        "CRRRNGCoordinator",
        crrrngCoordinatorAddress,
    )
    const round = (await cryptoDiceContract.getNextCryptoDiceRound()) - 1n
    const requestId = (await cryptoDiceContract.getRoundStatus(round)).requestId

    // ******* recover params...
    const testCaseJson = createCorrectAlgorithmVersionTestCase()
    const delta: number = 9
    const twoPowerOfDeltaBytes: BytesLike = toBeHex(
        2 ** delta,
        getLength(dataLength(toBeHex(2 ** delta))),
    )
    let recoverParams: {
        round: BigNumberish
        v: BigNumber[]
        x: BigNumber
        y: BigNumber
        bigNumTwoPowerOfDelta: BytesLike
        delta: number
    } = {
        round: round,
        v: [],
        x: { val: "0x0", bitlen: 0 },
        y: { val: "0x0", bitlen: 0 },
        bigNumTwoPowerOfDelta: twoPowerOfDeltaBytes,
        delta: delta,
    }
    recoverParams.x = testCaseJson.recoveryProofs[0].x
    recoverParams.y = testCaseJson.recoveryProofs[0].y
    if (delta > 0) {
        testCaseJson.recoveryProofs = testCaseJson.recoveryProofs?.slice(0, -(delta + 1))
    }
    for (let i = 0; i < testCaseJson.recoveryProofs.length; i++) {
        recoverParams.v.push(testCaseJson.recoveryProofs[i].v)
    }
    recoverParams.bigNumTwoPowerOfDelta = twoPowerOfDeltaBytes
    recoverParams.delta = delta

    console.log("Recovering...")
    const tx = await crrngCoordinatorContract.recover(
        recoverParams.round,
        recoverParams.v,
        recoverParams.x,
        recoverParams.y,
        recoverParams.bigNumTwoPowerOfDelta,
        recoverParams.delta,
        { gasLimit: 4000000 },
    )
    const receipt = await tx.wait()
    console.log("Transaction receipt", receipt)
    console.log("Recovered")
    console.log("----------------------")
}

const createCorrectAlgorithmVersionTestCase = () => {
    const testCaseJson = JSON.parse(fs.readFileSync(__dirname + "/recover.json", "utf-8"))
    return testCaseJson
}

recover()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
