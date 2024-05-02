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
import { dataLength, toBeHex } from "ethers"
import { ethers } from "hardhat"
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

describe("MontogomeryExp", () => {
    const base2048: BigNumber = {
        val: "0x08d72e28d1cef1b56bc3047d29624445ce203a0c6de5343a5f4873b4017f479e93fc4c3179d4db28dc7e4a6c859469868e50f3347b8736da84cd0995c661b99df90afa21267a8d7588704b9fc249bac3a3087ff1372f8fbfe1f8625c1a42113ebda7fc364a27d8a0c85dab8802f1b3983e867c3b11fedab831b5d6c1d49a906dd5366dd30816c174d6d384295e0229ddb1685eb5c57b9cde512ff50d82bf659eff8b9f3c8d2f0c2737c83eb44463ca23d93e29fa9630c06809b8a6327a29468e19042a7eac025c234be9fe349a19d7b3e5e4acca63f0b4a592b1749a15a1f054689b1809a4b95b27b8513fa1639c98ca9e18113bf36d631944c37459b5575a17",
        bitlen: 2044,
    }
    const n2048: BigNumber = {
        val: "0x34bea67f7d10481d71f794f7bf849b91a460b6488fc0def25ff20b19ff63e984e88daef00289931b566f3e25121e8757751e670a04735a78ff255d804caa197aa65da842913a243add64d375e378380e818b330cc9ef2a89753046248e41eff0f87d8ef4f7764e0ed3698b7f87b07805d235627c80e695f3f6095ca6523312a2916456ed011863d5287a33bf603f495071878ebcb06b9303ffa57ac9b5a77121a20fdbe15004010935d65fc39b199692bbadf172ae84a279f63e31997865c133a6cb8ca4e6c29677a46b932c75297347c605b7fe1c292a96d6401f22b4e4ff474e47cfa59ccfef24d99c3777c98bff523f4a587d54ddc395f572bcde1ae93ba1",
        bitlen: 2046,
    }
    const y2048: BigNumber = {
        val: "0x040fe0b9b8cd0bdd26fb05a5e45126265e34aefea81e7a8b6f6862d6f64ddcbe9f1bd821657dc4227cd0121e36d391669787aedbc969b6487d22690d91347b6473735439c34d640baccc145bc8d935415417f2e098493f6a8d6f869243722d0b9baebc399244dec31fc8935785832fb41d6fae424a2a2b6b8594ff47eed03b7430195a53046eabfb11ed0784ab91b0e8c1277ec4f12d6d940980fc6075b6f96679c691d525a65eba59a81c42ebe6b28b9beb66ccd9792771c483d11ceee27fc00bb8bf391c397af80371fcc31765ef95fef9bbc0fd1ad0fcd1e29bbf684390d0491762d0992d2e0bccd829af2ba9810b1b5edc3ff4e1075db8d81b5590d0b124",
        bitlen: 2043,
    }
    const R: BigNumber = {
        val: "0x80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        bitlen: 2048,
    }
    const RInv: BigNumber = {
        val: "0x33ED0A00DD06DF56E48DFAA1626F7076ADED5D9E9B905D254B7BCB97ECF74B139AEBC51C9DBF313884F6E180170CB39C609E7840A1F8A3B988D9E36F032E09F3C57519835ECC48490ACB275EC6637227C66793D234C0799AF7FD5D404B11A168E39F27AA03CD49F27B71676852A271170A7D2281879BD784519B9E9F7A8DE33B3217FA193F61443631590B93D2FFF26373F013E81F80DD9ACBD0C936EB9369D1A4A1625D68403D353CA043F959F4D7CDC728DCF7FA6D2F7A77F8B54CB00FA04342AAF3F8ABCB2118D99528D27973FEB1D3731C9F04F56BA4A39DADE65A02AAC728B254C11C4C79EB3B3E8817077171E5E90B5FCB8CB8BAAFB2B03D644647DA6D",
        bitlen: 2046,
    }

    const nInv: BigNumber = {
        val: "0x01FCAE5DD880C6C4150BE1E18C90AAC2860184BFC5513FF8271A937B5F7C7BE468B9CD6672B2F48A0910A4C3F87F214DC1053727D7C8D979DB8681C21ACB9163C1DD9DC35F86250C4C27C03C0E8C1452B5383BF2563932A3AC39D0D41E3F18E22189C07DD5FDDC2E119B442EA18EC84BC3A10F873B158AC601C5BC4ACD6E66041AFD429829E1E0C3F2D74C4984416F2EFC3BA3829A8A3E047865857C0449024B9ED7F559DC7CB4F5AE2F14956B002755B53E0475C8CB0EF09E26625009E2F386A70D0EB7579C258594FC4FE1103E5510EBFC85741E414825D4E44D2501801B05A78FC0AE645572B92ED7213387A2101E6120F891C2595685A6890B90EC076861",
        bitlen: 2041,
    }
    async function deployEXPContract() {
        const expContract = await ethers.deployContract("Exp")
        return expContract
    }
    async function deployMontgomeryExp() {
        const montgomeryExp = await ethers.deployContract("MontgomeryExp")
        return montgomeryExp
    }
    it("test base^y mod n", async () => {
        const expContract = await loadFixture(deployEXPContract)
        const precompileModExp = await expContract.modexpExternal(
            base2048.val,
            y2048.val,
            n2048.val,
        )
        console.log(precompileModExp)
    })
    it("test R", async () => {
        const montgomeryExp = await loadFixture(deployMontgomeryExp)
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
        for (let i = 0; i < exps.length - 4; i++) {
            const _a: bigint = exps[i]
            const y: BigNumber = {
                val: toBeHex(_a, getLength(dataLength(toBeHex(_a)))),
                bitlen: getBitLenth(_a),
            }
            const result = await montgomeryExp.montgomeryExponentation(
                base2048,
                y,
                n2048,
                R,
                RInv,
                nInv,
            )
            const gasUsed = await montgomeryExp.montgomeryExponentation.estimateGas(
                base2048,
                y,
                n2048,
                R,
                RInv,
                nInv,
            )
            console.log(expsString[i], gasUsed)
        }
    })
})
