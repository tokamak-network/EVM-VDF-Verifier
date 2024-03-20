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
import { assert, expect } from "chai"
import { dataLength, toBeHex } from "ethers"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { Exp } from "../../typechain-types"
interface BigNumber {
    val: string
    bitlen: number
}
// bitlen : 2046
// base hex : 0x3237a29cc9a41fbbb03e6c326d001516c5c8eca55584981b3005141d277f6ece1859841a5029e02319cd860167e52fbe61d66a1e09d8c858b14dadaf3a8f270cfbe2625398ad141d7f34cfde7c8ab4788a938dc6a641af81afa402debb20ac7b5c3d655ee3db11f535d3f75de5fcd93c293e304592439239704c4890807210aa64b422dd162c43cb6f89b71236a4e44caeee475925fab5fee8a82e3515441d43dcfa276db2263ae761024dee07c113cac079f4d709390ada0e0c7919c6f06b30ce3ba7a17d7d61ed979571d82bff342c72938c20d8d555b00c2efe40ee5d8306dc8ed6ed49421259266612b9adf9e37902914acae00b973552231f8715f188a0
// base decimal : 6339349990340949992039718022538548809911404110448648885355891692184774247137059387322767978053819654317607482045276207727122259749170947541905787083129186376251154619838878954337522877789827544904893837121821582253983733158444857694647840549548946397590986252766873727728518501994225714726803418478460981636629853703158036565533688553574440581077231729336810741105671180600222982553174808023973188542091940210157175115911320127043781729223178764576040965776992069319801983374996986774943908950089253219983298418826547613621548129133858584315255798679747859722790866944849958207640841316758439469746078261216520800416

// exp : 2^1, 2^10, 2^100, 2^1000, 2^10000
// exp binary : 10, 10000000000, 10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000, 10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000, 10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
const getBitLenth = (num: bigint): number => {
    return num.toString(2).length
}

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
function getFirstByteIndexOptimized(bitlen: number): number {
    return 31 - ((bitlen - 1) % 256 >> 3) // Calculate from the left in a 32-byte array
}

function dimitrovTypescriptDefault(a: bigint, base: bigint, y: bigint, n: bigint): bigint {
    return ((base ** a % n) * (y ** 2n % n)) % n
}
function dimitrovTypescript(
    a: bigint,
    b: bigint,
    x: bigint,
    y: bigint,
    n: bigint,
    aBitlen: bigint,
    bBitlen: bigint,
): bigint {
    let z: bigint = 1n
    const q: bigint = (x * y) % n
    let aBinary = a.toString(2)
    let bBinary = b.toString(2)
    if (aBitlen > bBitlen) {
        while (aBitlen > bBitlen) {
            bBinary = "0" + bBinary
            bBitlen++
        }
    }
    if (bBitlen > aBitlen) {
        while (bBitlen > aBitlen) {
            aBinary = "0" + aBinary
            aBitlen++
        }
    }
    for (let i = 0; i < aBitlen; i++) {
        z = (z * z) % n
        if (aBinary[i] == "1" && bBinary[i] == "1") {
            z = (z * q) % n
        } else if (aBinary[i] == "1") {
            z = (z * x) % n
        } else if (bBinary[i] == "1") {
            z = (z * y) % n
        }
    }
    return z
}
function dimitrovTypescriptFixedB2(
    a: bigint,
    base: bigint,
    y: bigint,
    n: bigint,
    aBitlen: bigint,
): bigint {
    let z: bigint = 1n
    const b: bigint = 2n
    const q: bigint = (base * y) % n
    const aBinary = a.toString(2)
    let bBinary = b.toString(2)
    // left pad bBinary with 0s
    let bBinaryLength = bBinary.length
    while (bBinaryLength < aBitlen) {
        bBinary = "0" + bBinary
        bBinaryLength++
    }
    for (let i = 0; i < aBitlen; i++) {
        z = (z * z) % n
        if (aBinary[i] == "1" && bBinary[i] == "1") {
            z = (z * q) % n
        } else if (aBinary[i] == "1") {
            z = (z * base) % n
        } else if (bBinary[i] == "1") {
            z = (z * y) % n
        }
    }
    return z
}

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Exp Test1", () => {
          let expContract: Exp
          const base: BigNumber = {
              val: "0x3237a29cc9a41fbbb03e6c326d001516c5c8eca55584981b3005141d277f6ece1859841a5029e02319cd860167e52fbe61d66a1e09d8c858b14dadaf3a8f270cfbe2625398ad141d7f34cfde7c8ab4788a938dc6a641af81afa402debb20ac7b5c3d655ee3db11f535d3f75de5fcd93c293e304592439239704c4890807210aa64b422dd162c43cb6f89b71236a4e44caeee475925fab5fee8a82e3515441d43dcfa276db2263ae761024dee07c113cac079f4d709390ada0e0c7919c6f06b30ce3ba7a17d7d61ed979571d82bff342c72938c20d8d555b00c2efe40ee5d8306dc8ed6ed49421259266612b9adf9e37902914acae00b973552231f8715f188a0",
              bitlen: 2046,
          }

          const n: BigNumber = {
              val: "0x45d416e8be4f61d58a3390edb1949059f4f3f728a9d300a405123226fec1861139b1f5bc4d0f24ba1f115217cf41c4a28f1c0c7d0291f29f89b63f0f87a84668cef76b56f969c23494439f07e0895ee44257b6123341cf27bcfc085434225ea08b06cdb8d67ad2cc7d80fb8f96cd18b248e62f241892a0696233006e4d467fac5d5128b58b20b72ff17956c6f86cbd00bb7847218a9ec2b333ac20e33a0d1a4959feb3a151b26898b4123e5e05b682b9a18f230133f28703c954177498bc6c6203a3ca1467cb4eb7caf79c644ab898ef751ba4663a06f4a67c7ccfff781eff04b1713ca98ddedf1347e893c7eb4ef90e2a67d659ad74c546714b9e78e0bc0281",
              bitlen: 2047,
          }
          it("Should deploy Exp contract", async () => {
              const ExpContractFactory = await ethers.getContractFactory("Exp")
              expContract = (await ExpContractFactory.deploy()) as Exp
              await expContract.waitForDeployment()
              expect(await expContract.getAddress()).to.properAddress
          })
          it("Exp", async () => {
              const exps: bigint[] = [
                  2n ** 300n,
                  2n ** 600n,
                  2n ** 900n,
                  2n ** 1200n,
                  2n ** 1500n,
                  2n ** 1800n,
                  2n ** 2100n,
                  2n ** 2400n,
                  2n ** 2700n,
                  2n ** 3000n,
              ]
              const expsString: string[] = [
                  "2^2",
                  "2^4",
                  "2^8",
                  "2^16",
                  "2^32",
                  "2^64",
                  "2^128",
                  "2^256",
                  "2^512",
                  "2^1024",
                  "2^2048",
              ]
              for (let i = 0; i < exps.length; i++) {
                  console.log("x^(", expsString[i], ")")
                  const _a: bigint = exps[i]
                  const a: BigNumber = {
                      val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                      bitlen: getBitLenth(_a),
                  }
                  const exp_by_square_iterative =
                      await expContract.bigNumber_exp_by_squaring_iterative_mod(base, a, n)
                  const exp_by_square_and_multiply =
                      await expContract.bigNumber_exp_by_squaring_and_multiply_mod(base, a, n)
                  const precompileModExp = await expContract.modexpExternal(base.val, a.val, n.val)

                  const exp_by_square_iterative_gasestimate =
                      await expContract.bigNumber_exp_by_squaring_iterative_mod.estimateGas(
                          base,
                          a,
                          n,
                      )
                  const exp_by_square_and_multiply_gasestimate =
                      await expContract.bigNumber_exp_by_squaring_and_multiply_mod.estimateGas(
                          base,
                          a,
                          n,
                      )
                  const precompileModExpGasEstimate = await expContract.modexpExternal.estimateGas(
                      base.val,
                      a.val,
                      n.val,
                  )
                  console.log(
                      "exp_by_square_iterative_gasestimate",
                      exp_by_square_iterative_gasestimate,
                  )
                  console.log(
                      "exp_by_square_and_multiply_gasestimate",
                      exp_by_square_and_multiply_gasestimate,
                  )
                  console.log("precompileModExpGasEstimate", precompileModExpGasEstimate)

                  assert.equal(exp_by_square_iterative[0], exp_by_square_and_multiply[0])
                  assert.equal(exp_by_square_and_multiply[0], precompileModExp)
              }
          })
          it("multiExp, x^a * y^b", async () => {
              const y: BigNumber = {
                  val: "0x040fe0b9b8cd0bdd26fb05a5e45126265e34aefea81e7a8b6f6862d6f64ddcbe9f1bd821657dc4227cd0121e36d391669787aedbc969b6487d22690d91347b6473735439c34d640baccc145bc8d935415417f2e098493f6a8d6f869243722d0b9baebc399244dec31fc8935785832fb41d6fae424a2a2b6b8594ff47eed03b7430195a53046eabfb11ed0784ab91b0e8c1277ec4f12d6d940980fc6075b6f96679c691d525a65eba59a81c42ebe6b28b9beb66ccd9792771c483d11ceee27fc00bb8bf391c397af80371fcc31765ef95fef9bbc0fd1ad0fcd1e29bbf684390d0491762d0992d2e0bccd829af2ba9810b1b5edc3ff4e1075db8d81b5590d0b124",
                  bitlen: 2043,
              }
              const exps: bigint[] = [
                  2n ** 1n,
                  2n ** 300n,
                  2n ** 600n,
                  2n ** 900n,
                  2n ** 1200n,
                  2n ** 1500n,
                  2n ** 1800n,
                  2n ** 2100n,
                  2n ** 2400n,
                  2n ** 2700n,
                  2n ** 3000n,
              ]
              const expsString: string[] = [
                  "2^1",
                  "2^300",
                  "2^600",
                  "2^900",
                  "2^1200",
                  "2^1500",
                  "2^1800",
                  "2^2100",
                  "2^2400",
                  "2^2700",
                  "2^3000",
              ]
              for (let i: number = 0; i < exps.length; i++) {
                  const _a: bigint = exps[i]
                  const _b: bigint = exps[0]
                  console.log("x^(", expsString[i], ") * y^(", expsString[0], ")")
                  const a: BigNumber = {
                      val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                      bitlen: getBitLenth(_a),
                  }
                  const b: BigNumber = {
                      val: toBeHex(_b, getLength(dataLength(toBeHex(_b)))),
                      bitlen: getBitLenth(_b),
                  }
                  const result = await expContract.dimitrovMultiExp(a, b, base, y, n)
                  const estimateGasResult = await expContract.dimitrovMultiExp.estimateGas(
                      a,
                      b,
                      base,
                      y,
                      n,
                  )
                  const resultPrecompile = await expContract.precompileMultiExp(a, b, base, y, n)
                  const estimateGasResultPrecompile =
                      await expContract.precompileMultiExp.estimateGas(a, b, base, y, n)
                  console.log("dimitrov estimateGasResult", estimateGasResult)
                  console.log("precompile estimateGasResult", estimateGasResultPrecompile)
                  const resultTypescript = dimitrovTypescript(
                      BigInt(a.val),
                      BigInt(b.val),
                      BigInt(base.val),
                      BigInt(y.val),
                      BigInt(n.val),
                      BigInt(a.bitlen),
                      BigInt(b.bitlen),
                  )
                  const resultTypescriptHex = toBeHex(
                      resultTypescript,
                      getLength(dataLength(toBeHex(resultTypescript))),
                  )
                  const resultTypescriptHexLength = BigInt(getBitLenth(resultTypescript))
                  assert.equal(result[0], resultTypescriptHex)
                  assert.equal(result[1], resultTypescriptHexLength)
                  assert.equal(resultPrecompile[0], resultTypescriptHex)
                  assert.equal(resultPrecompile[1], resultTypescriptHexLength)
              }
              for (let i: number = 0; i < exps.length; i++) {
                  const _a: bigint = exps[i]
                  const _b: bigint = exps[i]
                  console.log("x^(", expsString[i], ") * y^(", expsString[i], ")")
                  const a: BigNumber = {
                      val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                      bitlen: getBitLenth(_a),
                  }
                  const b: BigNumber = {
                      val: toBeHex(_b, getLength(dataLength(toBeHex(_b)))),
                      bitlen: getBitLenth(_b),
                  }
                  const result = await expContract.dimitrovMultiExp(a, b, base, y, n)
                  const estimateGasResult = await expContract.dimitrovMultiExp.estimateGas(
                      a,
                      b,
                      base,
                      y,
                      n,
                  )
                  const resultPrecompile = await expContract.precompileMultiExp(a, b, base, y, n)
                  const estimateGasResultPrecompile =
                      await expContract.precompileMultiExp.estimateGas(a, b, base, y, n)
                  console.log("dimitrov estimateGasResult", estimateGasResult)
                  console.log("precompile estimateGasResult", estimateGasResultPrecompile)
                  const resultTypescript = dimitrovTypescript(
                      BigInt(a.val),
                      BigInt(b.val),
                      BigInt(base.val),
                      BigInt(y.val),
                      BigInt(n.val),
                      BigInt(a.bitlen),
                      BigInt(b.bitlen),
                  )
                  const resultTypescriptHex = toBeHex(
                      resultTypescript,
                      getLength(dataLength(toBeHex(resultTypescript))),
                  )
                  const resultTypescriptHexLength = BigInt(getBitLenth(resultTypescript))
                  assert.equal(result[0], resultTypescriptHex)
                  assert.equal(result[1], resultTypescriptHexLength)
                  assert.equal(resultPrecompile[0], resultTypescriptHex)
                  assert.equal(resultPrecompile[1], resultTypescriptHexLength)
              }
              for (let i: number = 1; i < exps.length; i++) {
                  const _a: bigint = exps[i]
                  const _b: bigint = exps[i - 1]
                  console.log("x^(", expsString[i], ") * y^(", expsString[i - 1], ")")
                  const a: BigNumber = {
                      val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                      bitlen: getBitLenth(_a),
                  }
                  const b: BigNumber = {
                      val: toBeHex(_b, getLength(dataLength(toBeHex(_b)))),
                      bitlen: getBitLenth(_b),
                  }
                  const result = await expContract.dimitrovMultiExp(a, b, base, y, n)
                  const estimateGasResult = await expContract.dimitrovMultiExp.estimateGas(
                      a,
                      b,
                      base,
                      y,
                      n,
                  )
                  const resultPrecompile = await expContract.precompileMultiExp(a, b, base, y, n)
                  const estimateGasResultPrecompile =
                      await expContract.precompileMultiExp.estimateGas(a, b, base, y, n)
                  console.log("dimitrov estimateGasResult", estimateGasResult)
                  console.log("precompile estimateGasResult", estimateGasResultPrecompile)
                  const resultTypescript = dimitrovTypescript(
                      BigInt(a.val),
                      BigInt(b.val),
                      BigInt(base.val),
                      BigInt(y.val),
                      BigInt(n.val),
                      BigInt(a.bitlen),
                      BigInt(b.bitlen),
                  )
                  const resultTypescriptHex = toBeHex(
                      resultTypescript,
                      getLength(dataLength(toBeHex(resultTypescript))),
                  )
                  const resultTypescriptHexLength = BigInt(getBitLenth(resultTypescript))
                  assert.equal(result[0], resultTypescriptHex)
                  assert.equal(result[1], resultTypescriptHexLength)
                  assert.equal(resultPrecompile[0], resultTypescriptHex)
                  assert.equal(resultPrecompile[1], resultTypescriptHexLength)
              }
          })
          it("multiExp, x^a * y^b, Fixed b=2", async () => {
              const exps: bigint[] = [
                  2n ** 32n,
                  2n ** 64n,
                  2n ** 128n,
                  2n ** 256n,
                  2n ** 512n,
                  2n ** 1024n,
                  2n ** 2048n,
              ]
              const expsString: string[] = [
                  "2^32",
                  "2^64",
                  "2^128",
                  "2^256",
                  "2^512",
                  "2^1024",
                  "2^2048",
              ]
              //   console.log(toBeHex(1n, getLength(dataLength(toBeHex(1n)))), getBitLenth(1n))
              // testcases
              const y: BigNumber = {
                  val: "0x040fe0b9b8cd0bdd26fb05a5e45126265e34aefea81e7a8b6f6862d6f64ddcbe9f1bd821657dc4227cd0121e36d391669787aedbc969b6487d22690d91347b6473735439c34d640baccc145bc8d935415417f2e098493f6a8d6f869243722d0b9baebc399244dec31fc8935785832fb41d6fae424a2a2b6b8594ff47eed03b7430195a53046eabfb11ed0784ab91b0e8c1277ec4f12d6d940980fc6075b6f96679c691d525a65eba59a81c42ebe6b28b9beb66ccd9792771c483d11ceee27fc00bb8bf391c397af80371fcc31765ef95fef9bbc0fd1ad0fcd1e29bbf684390d0491762d0992d2e0bccd829af2ba9810b1b5edc3ff4e1075db8d81b5590d0b124",
                  bitlen: 2043,
              }
              for (let i = 0; i < exps.length; i++) {
                  console.log("x^(", expsString[i], ") * y^(2^1)")
                  const _a: bigint = exps[i]
                  const a: BigNumber = {
                      val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                      bitlen: getBitLenth(_a),
                  }
                  const result = await expContract.dimitrovMultiExpFixedB2(a, base, y, n)
                  const estimateGasResult = await expContract.dimitrovMultiExpFixedB2.estimateGas(
                      a,
                      base,
                      y,
                      n,
                  )
                  const resultPrecompile = await expContract.precompileMultiExpFixedB2(
                      a,
                      base,
                      y,
                      n,
                  )
                  const estimateGasResultPrecompile =
                      await expContract.precompileMultiExpFixedB2.estimateGas(a, base, y, n)

                  console.log("dimitrov estimateGasResult", estimateGasResult)
                  console.log("precompile estimateGasResult", estimateGasResultPrecompile)
                  const resultTypescript = dimitrovTypescriptFixedB2(
                      BigInt(a.val),
                      BigInt(base.val),
                      BigInt(y.val),
                      BigInt(n.val),
                      BigInt(a.bitlen),
                  )

                  const resultTypescriptHex = toBeHex(
                      resultTypescript,
                      getLength(dataLength(toBeHex(resultTypescript))),
                  )
                  //   const resultTypescriptDefault = dimitrovTypescriptDefault(
                  //       BigInt(a.val),
                  //       BigInt(base.val),
                  //       BigInt(y.val),
                  //       BigInt(n.val),
                  //   )
                  //   const resultTypescriptHexDefault = toBeHex(
                  //       resultTypescriptDefault,
                  //       getLength(dataLength(toBeHex(resultTypescriptDefault))),
                  //   )
                  //   const resultTypescriptHexLengthDefault = BigInt(
                  //       getBitLenth(resultTypescriptDefault),
                  //   )
                  //   console.log(resultTypescriptHexDefault, resultTypescriptHexLengthDefault)
                  const resultTypescriptHexLength = BigInt(getBitLenth(resultTypescript))
                  //console.log("result", result)
                  //console.log("resultTypescript", resultTypescriptHex, resultTypescriptHexLength)
                  assert.equal(result[0], resultTypescriptHex)
                  assert.equal(result[1], resultTypescriptHexLength)
                  assert.equal(resultPrecompile[0], resultTypescriptHex)
                  assert.equal(resultPrecompile[1], resultTypescriptHexLength)
              }
          })
      })
