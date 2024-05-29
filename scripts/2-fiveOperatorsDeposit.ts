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
import { deployments, ethers, network } from "hardhat"

async function fiveOperatorsDeposit() {
    const chainId: number = network.config.chainId as number
    const signers = await ethers.getSigners()
    const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinatorPoF")).address
    console.log("CRRNGCoordinatorPoF address:", crrrngCoordinatorAddress)
    const crrngCoordinatorContract = await ethers.getContractAt(
        "CRRNGCoordinatorPoF",
        crrrngCoordinatorAddress,
    )
    const minimumDepositAmount = await crrngCoordinatorContract.getMinimumDepositAmount()
    for (let i: number = 0; i < 5; i++) {
        const depositedAmount = await crrngCoordinatorContract.getDepositAmount(signers[i].address)
        if (depositedAmount < BigInt(minimumDepositAmount)) {
            const tx = await crrngCoordinatorContract.connect(signers[i]).operatorDeposit({
                value: BigInt(minimumDepositAmount) - depositedAmount,
            })
            const receipt = await tx.wait()
        }
        const depositedAmountAfter = await crrngCoordinatorContract.getDepositAmount(
            signers[i].address,
        )
        console.log(
            `Operator ${i} deposited amount: ${ethers.formatEther(
                depositedAmountAfter.toString(),
            )} ETH`,
        )
    }
}

fiveOperatorsDeposit()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
