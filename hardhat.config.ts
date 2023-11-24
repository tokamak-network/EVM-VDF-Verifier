import "@typechain/hardhat"
// import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-ethers"
import "hardhat-gas-reporter"
import "dotenv/config"
import "solidity-coverage"
import "hardhat-deploy"
import "@nomicfoundation/hardhat-chai-matchers"
import "hardhat-contract-sizer"
import { HardhatUserConfig } from "hardhat/config"
/** @type import('hardhat/config').HardhatUserConfig */

const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || process.env.ALCHEMY_MAINNET_RPC_URL
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || process.env.ALCHEMY_SEPOLIA_RPC_URL
const POLYGON_MAINNET_RPC_URL = process.env.POLYGON_MAINNET_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY

// Your API key for Etherscan, obtain one at https://etherscan.io/
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "Your etherscan API key"

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            // // If you want to do some forking, uncomment this
            // forking: {
            //   url: MAINNET_RPC_URL
            // }
            chainId: 31337,
            allowUnlimitedContractSize: true,
        },
        localhost: {
            chainId: 31337,
            allowUnlimitedContractSize: true,
        },
        sepolia: {
            url: SEPOLIA_RPC_URL,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            //   accounts: {
            //     mnemonic: MNEMONIC,
            //   },
            saveDeployments: true,
            chainId: 11155111,
        },
        mainnet: {
            url: MAINNET_RPC_URL,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            //   accounts: {
            //     mnemonic: MNEMONIC,
            //   },
            saveDeployments: true,
            chainId: 1,
        },
        polygon: {
            url: POLYGON_MAINNET_RPC_URL,
            accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
            saveDeployments: true,
            chainId: 137,
        },
        titangoerli: {
            url: "https://rpc.titan-goerli.tokamak.network",
            accounts: [`${process.env.PRIVATE_KEY}`],
            chainId: 5050,
            //gasPrice: 250000,
            //deploy: ['deploy_titan_goerli']
        },
        titan: {
            url: "https://rpc.titan.tokamak.network",
            accounts: [`${process.env.PRIVATE_KEY}`],
            chainId: 55004,
            //gasPrice: 250000,
            deploy: ["deploy_titan"],
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
    etherscan: {
        // npx hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
        apiKey: {
            sepolia: ETHERSCAN_API_KEY,
            goerli: ETHERSCAN_API_KEY,
            titangoerli: ETHERSCAN_API_KEY,
        },
        customChains: [
            {
                network: "titangoerli",
                chainId: 5050,
                urls: {
                    apiURL: "https://explorer.titan-goerli.tokamak.network/api",
                    browserURL: "https://explorer.titan-goerli.tokamak.network",
                },
            },
            {
                network: "titan",
                chainId: 55004,
                urls: {
                    apiURL: "https://explorer.titan.tokamak.network/api",
                    browserURL: "https://explorer.titan.tokamak.network",
                },
            },
        ],
    },
    gasReporter: {
        enabled: true,
        currency: "USD",
        outputFile: "gas-report.txt",
        noColors: true,
        gasPriceApi: "https://api.etherscan.io/api?module=proxy&action=eth_gasPrice",
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
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
        compilers: [
            {
                version: "0.8.8",
            },
            {
                version: "0.8.19",
            },
            {
                version:"0.8.17",
            }
        ],
    },
    mocha: {
        timeout: 200000, // 200 seconds max for running tests
    },
}

export default config
