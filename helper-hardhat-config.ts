//import {ethers} from 'hardhat'

export interface networkConfigItem {
    name?: string
    commitDuration: number
    CommitRecoverDuration: number
    order: number
  }
  
export interface networkConfigInfo {
    [key: number]: networkConfigItem
}


export const networkConfig: networkConfigInfo = {
    31337: {
        name: "localhost",
        commitDuration: 60,
        CommitRecoverDuration: 120,
        order: 277,
    },
    11155111: {
        name: "sepolia",
        commitDuration: 60,
        CommitRecoverDuration: 120,
        order: 277,
    },
    1: {
        name: "mainnet",
        commitDuration: 60,
        CommitRecoverDuration: 120,
        order: 277,
    },
}

export const developmentChains = ["hardhat", "localhost"]
export const VERIFICATION_BLOCK_CONFIRMATIONS = 6