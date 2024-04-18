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
import { ethers, network } from "hardhat"

async function depositNativeToken() {
    const chainId: number = network.config.chainId as number
    const { deployer } = await ethers.getNamedSigners()

    // approve
    const erc20Abi = ["function approve(address spender,uint256 amount)"]
    const erc20Address = "0xa30fe40285B8f5c0457DbC3B7C8A280373c40044"
    const erc20Contract = new ethers.Contract(erc20Address, erc20Abi, deployer)
    const approveTx = await erc20Contract.approve(
        "0x5D2Ed95c0230Bd53E336f12fA9123847768B2B3E",
        20000000000000000000000n,
    )
    console.log("Approve transaction hash:", approveTx.hash)
    const approveReceipt = await approveTx.wait()
    console.log("Approve transaction receipt", approveReceipt)

    //--------

    const humanReadableAbi = [
        "function depositERC20(address _l1Token,address _l2Token,uint256 _amount,uint32 _l2Gas,bytes _data)",
    ]
    const _l1Token = "0xa30fe40285B8f5c0457DbC3B7C8A280373c40044"
    const _l2Token = "0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000"
    const _amount = 20000000000000000000000n
    const _l2Gas = 200000n
    const _data = "0x00"
    const contractAddress = "0x5D2Ed95c0230Bd53E336f12fA9123847768B2B3E"
    // get the contract
    const contract = new ethers.Contract(contractAddress, humanReadableAbi, deployer)
    // call the contract
    const tx = await contract.depositERC20(_l1Token, _l2Token, _amount, _l2Gas, _data)
    console.log("Transaction hash:", tx.hash)
    const receipt = await tx.wait()
    console.log("Transaction receipt", receipt)
}
depositNativeToken()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
