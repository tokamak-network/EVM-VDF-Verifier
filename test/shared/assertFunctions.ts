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
import { assert, expect } from "chai"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import {
    BigNumberish,
    Contract,
    ContractTransactionReceipt,
    Log,
    BytesLike,
    toBeHex,
    dataLength,
} from "ethers"
import { network, ethers } from "hardhat"
import { VDFClaim, TestCase, BigNumber } from "./interfaces"
import { testCases } from "./testcases"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"

export const assertTestAfterDeploy = async (cRRContract: Contract) => {
    expect(cRRContract.target).to.properAddress
}
export const assertTestAfterGettingOmega = async (
    omegaContract: (BigNumberish | number)[],
    omegaTestCase: BigNumber,
    recoveredOmegaTestCase: BigNumber,
) => {
    expect(omegaContract[0]).to.equal(omegaTestCase.val)
    expect(omegaContract[1]).to.equal(omegaTestCase.bitlen)
    expect(omegaContract[0]).to.equal(recoveredOmegaTestCase.val)
    expect(omegaContract[1]).to.equal(recoveredOmegaTestCase.bitlen)
}
