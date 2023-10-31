import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { assert, expect } from "chai"
import { BigNumberish, Contract, ContractTransactionReceipt, Log } from "ethers"
import { network, deployments, ethers, getNamedAccounts } from "hardhat"
import { developmentChains, networkConfig } from "../helper-hardhat-config"
import { CommitRecover, CommitRecover__factory } from "../typechain-types"
import { VDFClaim, TestCase, testCases } from "../test/shared/testcases"
import {
    createTestCases,
    deployCommitRevealContract,
    initializedContractCorrectly,
    deployFirstTestCaseCommitRevealContract,
    commit,
    reveal,
} from "../test/shared/testFunctions"
import { CommitRecover as CommitRecoverType } from "../typechain-types"
//import { abi } from "./constant"
import {abi} from "../artifacts/contracts/CommitRecover.sol/CommitRecover.json"

async function main() {
    const chainId = network.config.chainId
    let deployer: SignerWithAddress = await ethers.getSigner((await getNamedAccounts()).deployer)
    const testcases: TestCase[] = createTestCases(testCases)
    const commitRecover = await ethers.getContractAt(
        abi,
        "0x2c46476e2B0DB71c4a6b3db460184f3B92f00b3F",
    )
    await commitRecover.recover(1, testcases[0].recoveryProofs, { gasLimit: 7000000 })
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
