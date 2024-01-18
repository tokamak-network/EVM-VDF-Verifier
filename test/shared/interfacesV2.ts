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
import {
    ICommitRevealRecoverRNG,
    BigNumberStruct,
    CommitRevealRecoverRNG,
} from "../../typechain-types/CommitRevealRecoverRNG"
import { BigNumberish } from "ethers"

export const LAMDAs: string[] = ["λ1024", "λ2048", "λ3072"]
export const Ts: string[] = ["T2^20", "T2^21", "T2^22", "T2^23", "T2^24", "T2^25"]
export const JsonNames: string[] = ["one", "two", "three", "four", "five"]

export interface GasReportsObject {
    [key: string]: GasReports[]
}

export interface GasReports {
    setUpGas: BigNumberish
    recoverGas: BigNumberish
    commitGas: BigNumberish[]
    revealGas: BigNumberish[]
    calculateOmegaGas: BigNumberish
    verifyRecursiveHalvingProofForSetup: BigNumberish
    verifyRecursiveHalvingProofForRecovery: BigNumberish
}

export interface TestCase {
    n: BigNumberStruct
    g: BigNumberStruct
    h: BigNumberStruct
    T: BigNumberish
    setupProofs: ICommitRevealRecoverRNG.VDFClaimStruct[]
    randomList: BigNumberStruct[]
    commitList: BigNumberStruct[]
    omega: BigNumberStruct
    recoveredOmega: BigNumberStruct
    recoveryProofs: ICommitRevealRecoverRNG.VDFClaimStruct[]
}
