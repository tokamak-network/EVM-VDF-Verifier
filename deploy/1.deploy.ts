import { DeployFunction } from "hardhat-deploy/dist/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"

import { networkConfig, VERIFICATION_BLOCK_CONFIRMATIONS } from "../helper-hardhat-config"
import verify from "../utils/verify"

const deployCommitRecover: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts, network, ethers } = hre
    const { deploy, log, get } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    const waitBlockConfirmations = chainId === 31337 ? 1 : VERIFICATION_BLOCK_CONFIRMATIONS

    log("----------------------------------------------------")
    const args: any[] = []
    const CommitRecover = await deploy("CommitRecover", {
        from: deployer,
        args: args,
        log: true,
        //waitConfirmations: waitBlockConfirmations,
        gasLimit: 4000000,
    })

    // Verify the deployment
    if (chainId !== 31337 && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(CommitRecover.address, args)
    }
    log("----------------------------------------------------")
}

export default deployCommitRecover
deployCommitRecover.tags = ["all", "commitRecover"]
