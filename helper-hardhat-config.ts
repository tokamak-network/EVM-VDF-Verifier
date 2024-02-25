//import {ethers} from 'hardhat'

export interface networkConfigItem {
    name?: string
    commitDuration: number
    commitRevealDuration: number
    tonAddress: string
}

export interface networkConfigInfo {
    [key: number]: networkConfigItem
}

export const networkConfig: networkConfigInfo = {
    31337: {
        name: "localhost",
        commitDuration: 60,
        commitRevealDuration: 120,
        tonAddress: "0x",
    },
    11155111: {
        name: "sepolia",
        commitDuration: 60,
        commitRevealDuration: 120,
        tonAddress: "0xa30fe40285b8f5c0457dbc3b7c8a280373c40044",
    },
    1: {
        name: "mainnet",
        commitDuration: 60,
        commitRevealDuration: 120,
        tonAddress: "0x2be5e8c109e2197D077D13A82dAead6a9b3433C5",
    },
    5050: {
        name: "titan-goerli",
        commitDuration: 60,
        commitRevealDuration: 120,
        tonAddress: "0xFa956eB0c4b3E692aD5a6B2f08170aDE55999ACa",
    },
    55004: {
        name: "titan",
        commitDuration: 60,
        commitRevealDuration: 120,
        tonAddress: "0x7c6b91D9Be155A6Db01f749217d76fF02A7227F2",
    },
    5: {
        name: "goerli",
        commitDuration: 60,
        commitRevealDuration: 120,
        tonAddress: "0x68c1F9620aeC7F2913430aD6daC1bb16D8444F00",
    },
}

export const developmentChains = ["hardhat", "localhost"]
export const VERIFICATION_BLOCK_CONFIRMATIONS = 6
