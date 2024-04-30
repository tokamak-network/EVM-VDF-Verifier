import "@typechain/hardhat"
// import "@nomiclabs/hardhat-waffle"
import "@nomicfoundation/hardhat-chai-matchers"
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-etherscan"
import "dotenv/config"
import "hardhat-contract-sizer"
import "hardhat-deploy"
import "hardhat-gas-reporter"
import { HardhatUserConfig } from "hardhat/config"
import "solidity-coverage"
/** @type import('hardhat/config').HardhatUserConfig */

const optimizerSettings = {
    viaIR: true,
    optimizer: {
        enabled: true,
        runs: 4294967295,
        details: {
            yul: true,
        },
    },
}
const optimizerEnabledFalse = {
    optimizer: {
        enabled: false,
    },
}
const DEFAULT_COMPILER_SETTINGS = {
    version: "0.8.23",
    settings: optimizerSettings,
}
const LOW_OPTIMIZER_COMPILER_SETTINGS = {
    version: "0.8.23",
    settings: optimizerEnabledFalse,
}

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            // // If you want to do some forking, uncomment this
            // forking: {
            //   url: MAINNET_RPC_URL
            // }
            chainId: 31337,
            allowUnlimitedContractSize: false,
            accounts: {
                count: 500,
            },
        },
        localhost: {
            chainId: 31337,
            allowUnlimitedContractSize: true,
        },
        anvil: {
            chainId: 31337,
            allowUnlimitedContractSize: true,
            url: "http://127.0.0.1:8545",
        },
        titangoerli: {
            url: "https://rpc.titan-goerli.tokamak.network",
            //accounts: [`${process.env.PRIVATE_KEY}`],
            chainId: 5050,
            //gasPrice: 250000,
            //deploy: ['deploy_titan_goerli']
        },
        titan: {
            url: "https://rpc.titan.tokamak.network",
            //accounts: [`${process.env.PRIVATE_KEY}`],
            chainId: 55004,
            //gasPrice: 250000,
            //deploy: ["deploy_titan"],
        },
    },
    deterministicDeployment: (network: string) => {
        // Skip on hardhat's local network.
        if (network === "31337") {
            return undefined
        } else {
            return {
                factory: "0x4e59b44847b379578588920ca78fbf26c0b4956c",
                deployer: "0x3fab184622dc19b6109349b94811493bf2a45362",
                funding: "10000000000000000",
                signedTx: "0x00",
            }
        }
    },
    namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
        player: {
            default: 1,
        },
    },
    solidity: {
        compilers: [DEFAULT_COMPILER_SETTINGS],
        overrides: {
            "contracts/strategies/CRRWithNTInProofVerifyAndProcessSeparateFileSeparateWithoutOptimizer.sol":
                LOW_OPTIMIZER_COMPILER_SETTINGS,
            "contracts/strategies/interfaces/ICRRWithNTInProofVerifyAndProcessSeparateFileSeparateWithoutOptimizer.sol":
                LOW_OPTIMIZER_COMPILER_SETTINGS,
            "contracts/strategies/libraries/Pietrzak_VDFWithoutOptimizer.sol":
                LOW_OPTIMIZER_COMPILER_SETTINGS,
            "contracts/strategies/libraries/BigNumbersWithoutOptimizer.sol":
                LOW_OPTIMIZER_COMPILER_SETTINGS,
        },
    },
    mocha: {
        timeout: 2000000, // 2000 seconds max for running tests
    },
}

export default config
