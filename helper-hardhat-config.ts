//import {ethers} from 'hardhat'

export interface networkConfigItem {
    name?: string
    commitDuration: number
    commitRevealDuration: number
}

export interface networkConfigInfo {
    [key: number]: networkConfigItem
}

export const networkConfig: networkConfigInfo = {
    31337: {
        name: "localhost",
        commitDuration: 60,
        commitRevealDuration: 120,
    },
    11155111: {
        name: "sepolia",
        commitDuration: 60,
        commitRevealDuration: 120,
    },
    1: {
        name: "mainnet",
        commitDuration: 60,
        commitRevealDuration: 120,
    },
}

export const developmentChains = ["hardhat", "localhost"]
export const VERIFICATION_BLOCK_CONFIRMATIONS = 6
