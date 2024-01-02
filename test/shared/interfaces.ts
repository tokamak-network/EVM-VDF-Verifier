// Copyright 2023 justin
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
import { BigNumberish, BytesLike } from "ethers"
export interface BigNumber {
    val: BytesLike
    bitlen: BigNumberish
}

export interface VDFClaim {
    x: BigNumber
    y: BigNumber
    v: BigNumber
    T: BigNumberish
}

export interface VDFClaimJson {
    x: BigNumberish
    y: BigNumberish
    T: BigNumberish
    v: BigNumberish
}

export interface TestCaseJson {
    n: BigNumberish
    g: BigNumberish
    h: BigNumberish
    T: BigNumberish
    setupProofs: VDFClaimJson[]
    randomList: BigNumberish[]
    commitList: BigNumberish[]
    omega: BigNumberish
    recoveredOmega: BigNumberish
    recoveryProofs: VDFClaimJson[]
}

export interface TestCase {
    n: BigNumber
    g: BigNumber
    h: BigNumber
    T: BigNumberish
    setupProofs: VDFClaim[]
    randomList: BigNumber[]
    commitList: BigNumber[]
    omega: BigNumber
    recoveredOmega: BigNumber
    recoveryProofs: VDFClaim[]
}

export interface SetUpParams {
    commitDuration: number
    commitRevealDuration: number
    n: BigNumber
    setupProofs: VDFClaim[]
}

export interface CommitParams {
    round: number
    commit: BigNumber
}

export interface RevealParams {
    round: number
    reveal: BigNumber
}
