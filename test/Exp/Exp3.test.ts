// Copyright 2024 justin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { assert } from "chai"
import { dataLength, toBeHex } from "ethers"
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { Exp } from "../../typechain-types"
interface BigNumber {
    val: string
    bitlen: number
}
const getBitLenth = (num: bigint): number => {
    return num.toString(2).length
}

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Exp Test3", () => {
          let expContract: Exp
          const base2048: BigNumber = {
              val: "0x3237a29cc9a41fbbb03e6c326d001516c5c8eca55584981b3005141d277f6ece1859841a5029e02319cd860167e52fbe61d66a1e09d8c858b14dadaf3a8f270cfbe2625398ad141d7f34cfde7c8ab4788a938dc6a641af81afa402debb20ac7b5c3d655ee3db11f535d3f75de5fcd93c293e304592439239704c4890807210aa64b422dd162c43cb6f89b71236a4e44caeee475925fab5fee8a82e3515441d43dcfa276db2263ae761024dee07c113cac079f4d709390ada0e0c7919c6f06b30ce3ba7a17d7d61ed979571d82bff342c72938c20d8d555b00c2efe40ee5d8306dc8ed6ed49421259266612b9adf9e37902914acae00b973552231f8715f188a0",
              bitlen: 2046,
          }

          const n2048: BigNumber = {
              val: "0x45d416e8be4f61d58a3390edb1949059f4f3f728a9d300a405123226fec1861139b1f5bc4d0f24ba1f115217cf41c4a28f1c0c7d0291f29f89b63f0f87a84668cef76b56f969c23494439f07e0895ee44257b6123341cf27bcfc085434225ea08b06cdb8d67ad2cc7d80fb8f96cd18b248e62f241892a0696233006e4d467fac5d5128b58b20b72ff17956c6f86cbd00bb7847218a9ec2b333ac20e33a0d1a4959feb3a151b26898b4123e5e05b682b9a18f230133f28703c954177498bc6c6203a3ca1467cb4eb7caf79c644ab898ef751ba4663a06f4a67c7ccfff781eff04b1713ca98ddedf1347e893c7eb4ef90e2a67d659ad74c546714b9e78e0bc0281",
              bitlen: 2047,
          }

          const y2048: BigNumber = {
              val: "0x040fe0b9b8cd0bdd26fb05a5e45126265e34aefea81e7a8b6f6862d6f64ddcbe9f1bd821657dc4227cd0121e36d391669787aedbc969b6487d22690d91347b6473735439c34d640baccc145bc8d935415417f2e098493f6a8d6f869243722d0b9baebc399244dec31fc8935785832fb41d6fae424a2a2b6b8594ff47eed03b7430195a53046eabfb11ed0784ab91b0e8c1277ec4f12d6d940980fc6075b6f96679c691d525a65eba59a81c42ebe6b28b9beb66ccd9792771c483d11ceee27fc00bb8bf391c397af80371fcc31765ef95fef9bbc0fd1ad0fcd1e29bbf684390d0491762d0992d2e0bccd829af2ba9810b1b5edc3ff4e1075db8d81b5590d0b124",
              bitlen: 2043,
          }

          const base3072: BigNumber = {
              val: "0x316dcab3aebf5d6c2f2e3f7d53acb04d32868c9d6af2818da3821bbbe2fcba96e3832e05fe69de331843ce221f268f70be189c45ea2f86dca53447e805586fdd561f5e47bdd1102b884916a257264e1a165f54243df8540d3e3bf250d84ec2cd752a052a69df564b4668e2e3f13c49b0119f9455dcf352ab4d1db097c51d4255296a4c8995e33c576b5f36a536ffb168652c44120649b59d52905c23285c41b396359ae85c191e6347c12aa4c1159a76d7b6250db659db8269ff63f57745a534e68ff5100547c7b7c4adfb091cfc5cef5b589b21493eb713045e6ecc37d9f565502c8c40b8bd6692c5799187c44047bdedc696e26d324ff86d58ba11007421430be939e4dc1f012458989814f55f1cd23d4a8f460515bd51328a8100d09870fc827d12ff85fc7ffcc387687e3e55d48b71da9fb94e95c38b8d3d4fbb04fe90e7e8fcefa70b59a9d2c8a54e799f70ecc3457be88494d759f5608c1e45c0f544e659aa143f6956344b5810de67669c8a03faeeba14059d678efeaeb4fcf00c5211",
              bitlen: 3070,
          }
          const n3072: BigNumber = {
              val: "0x455707b7673d6d79fe996f8e71944812638628c16001168787762487f778ab0e80455b67e8901f18fd442fcdbab1fa84965ce3179c2bdbfac2a7950154f39e138e8d02a76fd92ad3bcba5ef9b7891fa3092a5333a8d86ab2bb838b16a29525e02c1300cb2978e5fd7a1423684c5ca4e2693ee71c64bf2b012a6e280f753a97cc7be64833238cdd4bc768c29fa126e93291963e0e978ccbca2e37999aab0c699412f034bc1d483495054cff5aacde7c97a9229ef278d5cd34f15fe85154ee6b8e279f56f0dcabbb34b250a7b32e10ea35bdd64fdfe9288ee720eb817f5adf3953cd9d3246e33e4e397137dccad17f24c3e3950ec6ae0d71ced63e1be2e0c02a2570f3c47d4e4d949d97405872732cad2d62f147671058af8da5806f05589ce208bb61fa367d0ae762e9a66bb79b0774f8c49f6ac598911efc38b99d85437c71af94e60e92e1ae875e5e0052fa126a9945dab1c5b4d90fbbd4359d338952002af7b9003d1e188cfad9fb1079321a951012f38415234b58a107f19207c5d6be430d",
              bitlen: 3071,
          }
          const y3072: BigNumber = {
              val: "0x04e1548b62d39f92bda4efa8d8f4c860dfdbfcaabe548f84b92420f2dba609e0f5027de2709e5ddd35831a49d716ac5de5854c324d51a563baf59a0188331b966f9d4040b7dfdaec501ff1baea5afab96ddafd874a6acdaebc965650ac4991b8046bec960c0cd945cc84d6abc90ec1e8882ce8bc2d94539040f263e196b21355a786cf1a16067a13920ded6b5ee5bb90e0433d88f577068f2e25169a2823163e21a7100de50006ac3e7cfaa204ac6a84095443ed63666330bfc80fccbe6ac6a22cbc776080958372bb7e278961d6fcb8f529a23dc61adcb9956f297c92ec421721f4ae3ac0cd63a53cc29f30d2e757e8d76182048ef7b65f9c71807df633922ce2045409b77847a86ba43ff6e7e7a7b38de839c94656628fed06aecdb963dd7e7a7f5a2446f3ec80e635ffdccba2fbfd81894951de99cf1f46a534e7f2aae84c82223c023f16634155f5501bd3281a8b7ba2f7df9ae68e35979e1257ddd50ffbf2e00d0bd66dbe8984dc9affc0ea4c9c80bc1055a62df7a1b55ebedc4d1c1891",
              bitlen: 3067,
          }

          async function deployEXPContract() {
              const expContract = await ethers.deployContract("Exp")
              return expContract
          }
          it("Exponentiation 2048", async () => {
              const expContract = await loadFixture(deployEXPContract)
              const exps: bigint[] = [
                  2n ** 2n,
                  2n ** 4n,
                  2n ** 8n,
                  2n ** 16n,
                  2n ** 32n,
                  2n ** 64n,
                  2n ** 128n,
                  2n ** 256n,
                  2n ** 512n,
                  2n ** 1024n,
                  2n ** 2048n,
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
              const data = []
              for (let i = 0; i < exps.length; i++) {
                  const _a: bigint = exps[i]
                  const a: BigNumber = {
                      val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                      bitlen: getBitLenth(_a),
                  }
                  const exp_by_square_iterative =
                      await expContract.bigNumber_exp_by_squaring_iterative_mod(base2048, a, n2048)
                  const exp_by_square_and_multiply =
                      await expContract.bigNumber_exp_by_squaring_and_multiply_mod(
                          base2048,
                          a,
                          n2048,
                      )
                  const precompileModExp = await expContract.modexpExternal(
                      base2048.val,
                      a.val,
                      n2048.val,
                  )
                  assert.equal(exp_by_square_iterative[0], exp_by_square_and_multiply[0])
                  assert.equal(exp_by_square_and_multiply[0], precompileModExp)
                  const exp_by_square_iterative_gasestimate =
                      await expContract.bigNumber_exp_by_squaring_iterative_mod.estimateGas(
                          base2048,
                          a,
                          n2048,
                      )
                  const exp_by_square_and_multiply_gasestimate =
                      await expContract.bigNumber_exp_by_squaring_and_multiply_mod.estimateGas(
                          base2048,
                          a,
                          n2048,
                      )
                  const precompileModExpGasEstimate = await expContract.modexpExternal.estimateGas(
                      base2048.val,
                      a.val,
                      n2048.val,
                  )
                  //   console.log("x^(", expsString[i], ")")
                  //   console.log(
                  //       "exp_by_square_iterative_gasestimate",
                  //       exp_by_square_iterative_gasestimate,
                  //   )
                  //   console.log(
                  //       "exp_by_square_and_multiply_gasestimate",
                  //       exp_by_square_and_multiply_gasestimate,
                  //   )
                  //   console.log("precompileModExpGasEstimate", precompileModExpGasEstimate)
                  data.push([
                      `x^(${expsString[i]})`,
                      exp_by_square_iterative_gasestimate,
                      exp_by_square_and_multiply_gasestimate,
                      precompileModExpGasEstimate,
                  ])
              }
              console.log(data)
          })
          it("Exponentiation 3072", async () => {
              const expContract = await loadFixture(deployEXPContract)
              const exps: bigint[] = [
                  2n ** 2n,
                  2n ** 4n,
                  2n ** 8n,
                  2n ** 16n,
                  2n ** 32n,
                  2n ** 64n,
                  2n ** 128n,
                  2n ** 256n,
                  2n ** 512n,
                  2n ** 1024n,
                  2n ** 2048n,
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
                  const _a: bigint = exps[i]
                  const a: BigNumber = {
                      val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                      bitlen: getBitLenth(_a),
                  }
                  const exp_by_square_iterative =
                      await expContract.bigNumber_exp_by_squaring_iterative_mod(base3072, a, n3072)
                  const exp_by_square_and_multiply =
                      await expContract.bigNumber_exp_by_squaring_and_multiply_mod(
                          base3072,
                          a,
                          n3072,
                      )
                  const precompileModExp = await expContract.modexpExternal(
                      base3072.val,
                      a.val,
                      n3072.val,
                  )
                  assert.equal(exp_by_square_iterative[0], exp_by_square_and_multiply[0])
                  assert.equal(exp_by_square_and_multiply[0], precompileModExp)
                  const exp_by_square_iterative_gasestimate =
                      await expContract.bigNumber_exp_by_squaring_iterative_mod.estimateGas(
                          base3072,
                          a,
                          n3072,
                      )
                  const exp_by_square_and_multiply_gasestimate =
                      await expContract.bigNumber_exp_by_squaring_and_multiply_mod.estimateGas(
                          base3072,
                          a,
                          n3072,
                      )
                  const precompileModExpGasEstimate = await expContract.modexpExternal.estimateGas(
                      base3072.val,
                      a.val,
                      n3072.val,
                  )
                  console.log("x^(", expsString[i], ")")
                  console.log(
                      "exp_by_square_iterative_gasestimate",
                      exp_by_square_iterative_gasestimate,
                  )
                  console.log(
                      "exp_by_square_and_multiply_gasestimate",
                      exp_by_square_and_multiply_gasestimate,
                  )
                  console.log("precompileModExpGasEstimate", precompileModExpGasEstimate)
              }
          })
          it("MultiExponentiation 2048", async () => {
              const expContract = await loadFixture(deployEXPContract)
              const exps: bigint[] = [
                  2n ** 2n,
                  2n ** 4n,
                  2n ** 8n,
                  2n ** 16n,
                  2n ** 32n,
                  2n ** 64n,
                  2n ** 128n,
                  2n ** 256n,
                  2n ** 512n,
                  2n ** 1024n,
                  2n ** 2048n,
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
                  const _a: bigint = exps[i]
                  const a: BigNumber = {
                      val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                      bitlen: getBitLenth(_a),
                  }
                  const result = await expContract.dimitrovMultiExpFixedB2(
                      a,
                      base2048,
                      y2048,
                      n2048,
                  )
                  const estimateGasResult = await expContract.dimitrovMultiExpFixedB2.estimateGas(
                      a,
                      base2048,
                      y2048,
                      n2048,
                  )
                  const resultPrecompile = await expContract.precompileMultiExpFixedB2(
                      a,
                      base2048,
                      y2048,
                      n2048,
                  )
                  const estimateGasResultPrecompile =
                      await expContract.precompileMultiExpFixedB2.estimateGas(
                          a,
                          base2048,
                          y2048,
                          n2048,
                      )
                  assert.equal(result[0], resultPrecompile[0])
                  assert.equal(result[1], resultPrecompile[1])
                  console.log("x^(", expsString[i], ") * y^(2^1)")
                  console.log("dimitrov estimateGasResult", estimateGasResult)
                  console.log("precompile estimateGasResult", estimateGasResultPrecompile)
              }
          })
          it("MultiExponentiation 3072", async () => {
              const expContract = await loadFixture(deployEXPContract)
              const exps: bigint[] = [
                  2n ** 2n,
                  2n ** 4n,
                  2n ** 8n,
                  2n ** 16n,
                  2n ** 32n,
                  2n ** 64n,
                  2n ** 128n,
                  2n ** 256n,
                  2n ** 512n,
                  2n ** 1024n,
                  2n ** 2048n,
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
                  const _a: bigint = exps[i]
                  const a: BigNumber = {
                      val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                      bitlen: getBitLenth(_a),
                  }
                  const result = await expContract.dimitrovMultiExpFixedB2(
                      a,
                      base3072,
                      y3072,
                      n3072,
                  )
                  const estimateGasResult = await expContract.dimitrovMultiExpFixedB2.estimateGas(
                      a,
                      base3072,
                      y3072,
                      n3072,
                  )
                  const resultPrecompile = await expContract.precompileMultiExpFixedB2(
                      a,
                      base3072,
                      y3072,
                      n3072,
                  )
                  const estimateGasResultPrecompile =
                      await expContract.precompileMultiExpFixedB2.estimateGas(
                          a,
                          base3072,
                          y3072,
                          n3072,
                      )
                  assert.equal(result[0], resultPrecompile[0])
                  assert.equal(result[1], resultPrecompile[1])
                  console.log("x^(", expsString[i], ") * y^(2^1)")
                  console.log("dimitrov estimateGasResult", estimateGasResult)
                  console.log("precompile estimateGasResult", estimateGasResultPrecompile)
              }
          })
      })
