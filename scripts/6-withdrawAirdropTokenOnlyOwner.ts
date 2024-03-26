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
import { deployments, ethers, getNamedAccounts, network } from "hardhat"
import { networkConfig } from "../helper-hardhat-config"
async function withdrawAirdropTokenOnlyOwner() {
    const chainId: number = network.config.chainId as number
    const { deployer } = await getNamedAccounts()
    console.log("EOA address:", deployer)
    let tonTokenAddress: string
    if (chainId == 31337) {
        tonTokenAddress = (await deployments.get("TonToken")).address
    } else {
        tonTokenAddress = networkConfig[chainId].tonAddress
    }
    const tonTokenContract = await ethers.getContractAt("TonToken", tonTokenAddress)
    const cryptoDiceConsumerAddress = (await deployments.get("CryptoDice")).address
    console.log("cryptoDiceConsumer address:", cryptoDiceConsumerAddress)
    const cryptoDiceConsumerContract = await ethers.getContractAt(
        "CryptoDice",
        cryptoDiceConsumerAddress,
    )
    try {
        console.log("withdraw token only owner")
        const balanceOfCryptoDiceConsumer =
            await tonTokenContract.balanceOf(cryptoDiceConsumerAddress)
        const balanceOfEOA = await tonTokenContract.balanceOf(deployer)
        console.log(
            "Balance of CryptoDice before withdraw:",
            balanceOfCryptoDiceConsumer.toString(),
        )
        console.log("Balance of EOA before withdraw:", balanceOfEOA.toString())
        const tx = await cryptoDiceConsumerContract.withdrawAirdropTokenOnlyOwner()
        const receipt = await tx.wait()
        console.log("Transaction receipt", receipt)
        console.log("Withdrawed")
        const newBalanceOfCryptoDiceConsumer =
            await tonTokenContract.balanceOf(cryptoDiceConsumerAddress)
        console.log(
            "Balance of CryptoDice after withdraw:",
            newBalanceOfCryptoDiceConsumer.toString(),
        )
        const newBalanceOfEOA = await tonTokenContract.balanceOf(deployer)
        console.log("Balance of EOA after withdraw:", newBalanceOfEOA.toString())
        console.log("----------------------")
    } catch (error) {
        console.error(error)
    }
}

withdrawAirdropTokenOnlyOwner()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
