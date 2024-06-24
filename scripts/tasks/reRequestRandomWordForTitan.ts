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
import { task } from "hardhat/config"

task("reRequestRandomWordForTitan", "Operator re-requests random word at round")
    .addParam("round", "The round to re-request")
    .setAction(async ({ round }, { deployments, ethers, getNamedAccounts }) => {
        const { deployer } = await getNamedAccounts()
        const crrrngCoordinatorAddress = (await deployments.get("CRRNGCoordinatorPoFV2ForTitan"))
            .address
        console.log("CRRRNGCoordinator address:", crrrngCoordinatorAddress)
        const crrngCoordinatorContract = await ethers.getContractAt(
            "CRRNGCoordinatorPoFV2ForTitan",
            crrrngCoordinatorAddress,
        )
        console.log("Re-request...")
        const tx = await crrngCoordinatorContract.reRequestRandomWordAtRound(round, {
            gasLimit: 100000,
        })
        const receipt = await tx.wait()
        console.log("Transaction receipt", receipt)
        console.log("Re-requested successfully")
        console.log("----------------------")
    })
