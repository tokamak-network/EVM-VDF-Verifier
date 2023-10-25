// import { DeployFunction } from "hardhat-deploy/dist/types"
// import { HardhatRuntimeEnvironment } from "hardhat/types"

// import { networkConfig, VERIFICATION_BLOCK_CONFIRMATIONS } from "../helper-hardhat-config"
// import verify from "../utils/verify"

// const generatorList = [
//     5, 6, 11, 14, 17, 18, 20, 24, 31, 43, 44, 45, 46, 50, 53, 56, 58, 65, 68, 72, 77, 78, 80, 93,
//     94, 96, 97, 98, 99, 101, 103, 105, 107, 110, 111, 114, 115, 119, 124, 126, 127, 134, 135, 137,
//     140, 142, 143, 150, 151, 153, 158, 162, 163, 166, 167, 170, 172, 174, 176, 178, 179, 180, 181,
//     183, 184, 197, 199, 200, 205, 209, 212, 219, 221, 224, 227, 231, 232, 233, 234, 246, 253, 257,
//     259, 260, 263, 266, 271, 272,
// ]

// const gGen = () => {
//     const index = Math.floor(Math.random() * generatorList.length)
//     return generatorList[index]
// }

// const deployCommitRecover: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
//     const { deployments, getNamedAccounts, network, ethers } = hre
//     const { deploy, log, get } = deployments
//     const { deployer } = await getNamedAccounts()
//     const chainId = network.config.chainId

//     const waitBlockConfirmations = chainId === 31337 ? 1 : VERIFICATION_BLOCK_CONFIRMATIONS

//     log("----------------------------------------------------")
//     const args: any[] = [
//         {
//             commitDuration: networkConfig[chainId!].commitDuration,
//             commitRevealDuration: networkConfig[chainId!].commitRevealDuration,
//             N: networkConfig[chainId!].N,
//             g: gGen(),
//         },
//     ]
//     const CommitRecover = await deploy("CommitRecover", {
//         from: deployer,
//         args: args,
//         log: true,
//         waitConfirmations: waitBlockConfirmations,
//         gasLimit: 4000000,
//     })

//     // Verify the deployment
//     if (chainId !== 31337 && process.env.ETHERSCAN_API_KEY) {
//         log("Verifying...")
//         await verify(CommitRecover.address, args)
//     }
//     log("----------------------------------------------------")
// }

// export default deployCommitRecover
// deployCommitRecover.tags = ["all", "commitRecover"]
