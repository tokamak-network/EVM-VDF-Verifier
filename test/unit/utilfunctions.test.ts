import {
    BigNumberish,
    toBeHex,
    dataLength,
    ContractTransactionReceipt,
    ContractTransactionResponse,
} from "ethers"
import { ethers } from "hardhat"
import fs from "fs"
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { createTestCase, deployCommitRevealRecoverRNGFixture } from "../shared/testFunctionsV2"
import { BigNumberStruct } from "../../typechain-types/interfaces/ICommitRevealRecoverRNG"
import { get } from "http"

const getBitLenth = (num: bigint): BigNumberish => {
    return num.toString(2).length
}

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}

const arrayToBigNumberStruct = (array: any[]): any => {
    const struct = {
        val: toBeHex(array[0], getLength(dataLength(toBeHex(array[0])))),
        neg: array[1],
        bitlen: array[2],
    }
    return struct
}

const ZEROBYTE1 = "0x00"
const ONEMASK = "0x01"
const TWOMASK = "0x02"
const THREEMASK = "0x04"
const FOURMASK = "0x08"
const FIVEMASK = "0x10"
const SIXMASK = "0x20"
const SEVENMASK = "0x40"
const EIGHTMASK = "0x80"

const masksArray = [EIGHTMASK, SEVENMASK, SIXMASK, FIVEMASK, FOURMASK, THREEMASK, TWOMASK, ONEMASK]

const dimitrovMultiExpTypescript = (
    _x: BigNumberStruct,
    _y: BigNumberStruct,
    _a: BigNumberStruct,
    _b: BigNumberStruct,
    _n: BigNumberStruct,
): BigNumberStruct => {
    const h = _a.bitlen > _b.bitlen ? _a.bitlen : _b.bitlen
    let count = 0
    let z = 1n
    const q =
        (BigInt(_x.val as BigNumberish) * BigInt(_y.val as BigNumberish)) %
        BigInt(_n.val as BigNumberish)
    const pad =
        ((BigInt(h) / 4n) % 64n) % 2n === 0n
            ? (BigInt(h) / 4n) % 64n
            : ((BigInt(h) / 4n) % 64n) + 1n
    let tempA = toBeHex("0x" + _a.val.toString().substring(Number(pad) + 2, Number(pad) + 4))
    let tempB = toBeHex("0x" + _b.val.toString().substring(Number(pad) + 2, Number(pad) + 4))
    for (let j: bigint = 8n - (((BigInt(h) - 1n) % 8n) + 1n); j < 8n; j = j + 1n) {
        z = (z * z) % BigInt(_n.val as BigNumberish)
        count++
        const aBool = (BigInt(tempA) & BigInt(masksArray[Number(j)])) > 0n
        const bBool = (BigInt(tempB) & BigInt(masksArray[Number(j)])) > 0n
        if (aBool && bBool) {
            z = (z * q) % BigInt(_n.val as BigNumberish)
        } else if (aBool) {
            z = (z * BigInt(_x.val as BigNumberish)) % BigInt(_n.val as BigNumberish)
        } else if (bBool) {
            z = (z * BigInt(_y.val as BigNumberish)) % BigInt(_n.val as BigNumberish)
        }
    }
    for (let i: bigint = pad + 4n; i < ((BigInt(h) + 7n) / 8n) * 2n + 2n + pad; i = i + 2n) {
        tempA = toBeHex("0x" + _a.val.toString().substring(Number(i), Number(i) + 2))
        tempB = toBeHex("0x" + _b.val.toString().substring(Number(i), Number(i) + 2))
        for (let j: bigint = 0n; j < 8n; j = j + 1n) {
            z = (z * z) % BigInt(_n.val as BigNumberish)
            count++
            const aBool = (BigInt(tempA) & BigInt(masksArray[Number(j)])) > 0n
            const bBool = (BigInt(tempB) & BigInt(masksArray[Number(j)])) > 0n
            if (aBool && bBool) {
                z = (z * q) % BigInt(_n.val as BigNumberish)
            } else if (aBool) {
                z = (z * BigInt(_x.val as BigNumberish)) % BigInt(_n.val as BigNumberish)
            } else if (bBool) {
                z = (z * BigInt(_y.val as BigNumberish)) % BigInt(_n.val as BigNumberish)
            }
        }
    }
    console.log("count: ", count)
    return {
        val: toBeHex(z, getLength(dataLength(toBeHex(z)))),
        bitlen: getBitLenth(z),
    }
}

describe("BigNumberTest", () => {
    it("sub and cmp", async () => {
        const a = {
            val: toBeHex(1n, getLength(dataLength(toBeHex(1n)))),
            neg: false,
            bitlen: getBitLenth(1n),
        }
        const b = {
            val: toBeHex(3n, getLength(dataLength(toBeHex(3n)))),
            neg: false,
            bitlen: getBitLenth(3n),
        }
        // get BigNumberTest contract
        const BigNumbersTest = await ethers.getContractFactory("BigNumbersTest")
        const bigNumbersTest = await BigNumbersTest.deploy()
        await bigNumbersTest.waitForDeployment()
        // test sub
        const subResult = arrayToBigNumberStruct(await bigNumbersTest.sub(a, b))
        console.log("subResult: ", subResult)
        // test cmp
        // returns -1 on a<b, 0 on a==b, 1 on a>b.
        const cmpResult1 = await bigNumbersTest.cmp(a, subResult, false) //-1
        console.log(cmpResult1)
        const cmpResult2 = await bigNumbersTest.cmp(a, subResult, true) // 1
        console.log(cmpResult2)

        const FILE_DIR_NAME =
            __dirname + `/gasReports/${new Date().toISOString().slice(0, 19)}` + ".json"
        // if (!fs.existsSync(FILE_DIR_NAME)) {
        //     fs.mkdirSync(FILE_DIR_NAME)
        // }
        console.log(fs.existsSync(FILE_DIR_NAME))
        if (!fs.existsSync(__dirname + `/gasReports/${new Date().toISOString().slice(0, 19)}`)) {
            console.log("what")
            fs.writeFileSync(FILE_DIR_NAME, JSON.stringify({}))
        }
        const jsonGasCostsCommitRevealCalculateOmega = JSON.parse(
            fs.readFileSync(FILE_DIR_NAME, "utf-8"),
        )
        const temp = {
            "λ1024T2^20": [
                {
                    setUpGas: "2627774",
                    recoverGas: 0,
                    commitGas: [Array],
                    revealGas: [Array],
                    calculateOmegaGas: "689794",
                    verifyRecursiveHalvingProofForSetup: "2050690",
                    verifyRecursiveHalvingProofForRecovery: 0,
                },
                {
                    setUpGas: "2609273",
                    recoverGas: 0,
                    commitGas: [Array],
                    revealGas: [Array],
                    calculateOmegaGas: "687892",
                    verifyRecursiveHalvingProofForSetup: "2049285",
                    verifyRecursiveHalvingProofForRecovery: 0,
                },
                {
                    setUpGas: "2601661",
                    recoverGas: 0,
                    commitGas: [Array],
                    revealGas: [Array],
                    calculateOmegaGas: "688633",
                    verifyRecursiveHalvingProofForSetup: "2041681",
                    verifyRecursiveHalvingProofForRecovery: 0,
                },
                {
                    setUpGas: "2606791",
                    recoverGas: 0,
                    commitGas: [Array],
                    revealGas: [Array],
                    calculateOmegaGas: "688619",
                    verifyRecursiveHalvingProofForSetup: "2046809",
                    verifyRecursiveHalvingProofForRecovery: 0,
                },
                {
                    setUpGas: "2607894",
                    recoverGas: 0,
                    commitGas: [Array],
                    revealGas: [Array],
                    calculateOmegaGas: "688275",
                    verifyRecursiveHalvingProofForSetup: "2047912",
                    verifyRecursiveHalvingProofForRecovery: 0,
                },
            ],
        }

        jsonGasCostsCommitRevealCalculateOmega["gasCostsCommitRevealCalculateOmega"] = [
            [temp, temp, temp, temp, temp, temp],
            [temp, temp, temp, temp, temp, temp],
            [temp, temp, temp, temp, temp, temp],
        ]
        console.log(jsonGasCostsCommitRevealCalculateOmega)
        fs.writeFileSync(FILE_DIR_NAME, JSON.stringify(jsonGasCostsCommitRevealCalculateOmega))
        console.log(fs.existsSync(FILE_DIR_NAME))
    })
    it("multi exponentiation test", async () => {
        const { commitRevealRecoverRNG } = await loadFixture(deployCommitRevealRecoverRNGFixture)
        const _x: BigNumberStruct = {
            val: "0x25df08a2173ed753d6c5e35eb93619c2819478bb8e9e7ef732bbf1338cb9920edca2f307b09727813c64ada854e9c4aa93c339ee006e4a257e57e0d7f1282d4e6b86cb45e9b1f0fa9f7bb28c1ea41b8f685682654d55bd7e5b05d9bd95455792c40f9acc0f472626a6f9bfc10d0ec4c20f9e5d2ad37effb28d3f79976f04a7a406da2dc54b675110026cbf647b378796bf0aed62505cc7ee8f3aa9b551f8eb3778c0d6c30e22fb8088c5604d7e4764f55dca346f214f821c698063a77755f2281e84f443afc32580759e1d9963dc7dcc9344d978c091bd76339396eabd3783aeba1b3aef7d45a12d3648a409ee775662441a3e6b313c00bcdae9b6f7c7766820",
            bitlen: 2046,
        }
        const _y: BigNumberStruct = {
            val: "0x1fba152daf6405c8e8bebedec21c6c08b0836eca6be7771649570f464987aea3cb36945ca33fd341da9dbabc122d78680b12a0fdbb7e430a03e4e1c3c16225db5a6bc03e608e208eff8948df572d57fee096f26999af84aefba9c0c47c088f691afc24412af238a60db74ee9165b64d293b0b057365f6e4fea67e12aabc3fa2f10d5a4bd5bc48770be5a386af3c94261ca05f2184072c6a256f50cc854c37a66f0dfd8046dbec92b0e6506c26f00846a9c1853208a760d73eac989bcfb5da63de048445e6a3f7617c734a0bd2874a21b1dc6aa30005e44ce05eb823c382ea8ae15cc2bdf0503ab872f47b5b8ff1ae3870f0a062af30b7bbdb4a8ebe2ea382910",
            bitlen: 2045,
        }
        const _a: BigNumberStruct = {
            val: toBeHex(
                BigInt(
                    "0x25df08a2173ed753d6c5e35eb93619c2819478bb8e9e7ef732bbf1338cb9920edca2f307b09727813c64ada854e9c4aa93c339ee006e4a257e57e0d7f1282d4e6b86cb45e9b1f0fa9f7bb28c1ea41b8f685682654d55bd7e5b05d9bd95455792c40f9acc0f472626a6f9bfc10d0ec4c20f9e5d2ad37effb28d3f79976f04a7a406da2dc54b675110026cbf647b378796bf0aed62505cc7ee8f3aa9b551f8eb3778c0d6c30e22fb8088c5604d7e4764f55dca346f214f821c698063a77755f2281e84f443afc32580759e1d9963dc7dcc9344d978c091bd76339396eabd3783aeba1b3aef7d45a12d3648a409ee775662441a3e6b313c00bcdae9b6f7c7766820",
                ) % BigInt("0x100000000000000000000000000000000"),
                getLength(
                    dataLength(
                        toBeHex(
                            BigInt(
                                "0x25df08a2173ed753d6c5e35eb93619c2819478bb8e9e7ef732bbf1338cb9920edca2f307b09727813c64ada854e9c4aa93c339ee006e4a257e57e0d7f1282d4e6b86cb45e9b1f0fa9f7bb28c1ea41b8f685682654d55bd7e5b05d9bd95455792c40f9acc0f472626a6f9bfc10d0ec4c20f9e5d2ad37effb28d3f79976f04a7a406da2dc54b675110026cbf647b378796bf0aed62505cc7ee8f3aa9b551f8eb3778c0d6c30e22fb8088c5604d7e4764f55dca346f214f821c698063a77755f2281e84f443afc32580759e1d9963dc7dcc9344d978c091bd76339396eabd3783aeba1b3aef7d45a12d3648a409ee775662441a3e6b313c00bcdae9b6f7c7766820",
                            ) % BigInt("0x100000000000000000000000000000000"),
                        ),
                    ),
                ),
            ),
            bitlen: getBitLenth(
                BigInt(
                    "0x25df08a2173ed753d6c5e35eb93619c2819478bb8e9e7ef732bbf1338cb9920edca2f307b09727813c64ada854e9c4aa93c339ee006e4a257e57e0d7f1282d4e6b86cb45e9b1f0fa9f7bb28c1ea41b8f685682654d55bd7e5b05d9bd95455792c40f9acc0f472626a6f9bfc10d0ec4c20f9e5d2ad37effb28d3f79976f04a7a406da2dc54b675110026cbf647b378796bf0aed62505cc7ee8f3aa9b551f8eb3778c0d6c30e22fb8088c5604d7e4764f55dca346f214f821c698063a77755f2281e84f443afc32580759e1d9963dc7dcc9344d978c091bd76339396eabd3783aeba1b3aef7d45a12d3648a409ee775662441a3e6b313c00bcdae9b6f7c7766820",
                ) % BigInt("0x100000000000000000000000000000000"),
            ),
        }
        const _b: BigNumberStruct = {
            val: toBeHex("0x02", getLength(dataLength(toBeHex("0x02")))),
            bitlen: getBitLenth(2n),
        }
        const _n: BigNumberStruct = {
            val: "0x4a42c5faf090217458c56a3534e1ded806556f28bbdbd3fc91c631607147c7575f67fe204991c864388a1ecebbd8f50c0381678be728ed4ae4c0bfca02b08c159c1ab0b34abfa880ea70c2adcc29ef4c5a852b1702c73f9ca201166da8564b3ee42acfcd237149a8c5ea4298e28c41a58380d6c6d9df106c007b73a7fc8c9e0a6e83d058eb168601c1b23319fe7e67e9f40f27b284414bbade3a71aba38ee544dd29fd0b6abb9481d0be0c0cab9400b86d316113a6968f5bb73d9f1d194d4821571d0a7058021ac58200072130e2fcb16cd78d03788348232e595861653304bc1506394e3c795b54dc933c56aa199de25e9250c0e0dd1c311bc07a89696267ad",
            bitlen: 2047,
        }
        console.log(_a, _b)
        console.log("-----------")
        let tx: ContractTransactionResponse = await commitRevealRecoverRNG.multiExp(
            _a,
            _b,
            _x,
            _y,
            _n,
        )
        let receipt: ContractTransactionReceipt | null = await tx.wait()
        console.log("Contract Call multiExpView")
        console.log(await commitRevealRecoverRNG.multiExpView(_a, _b, _x, _y, _n))
        console.log(receipt?.gasUsed)
        console.log("-----------")
        console.log("typecript dimitrovMultiExpTypescript")
        console.log(dimitrovMultiExpTypescript(_x, _y, _a, _b, _n))
        // console.log(
        //     toBeHex(
        //         ((BigInt(_x.val as BigNumberish) ** BigInt(_a.val as BigNumberish) %
        //             BigInt(_n.val as BigNumberish)) *
        //             (BigInt(_y.val as BigNumberish) ** BigInt(_b.val as BigNumberish) %
        //                 BigInt(_n.val as BigNumberish))) %
        //             BigInt(_n.val as BigNumberish),
        //     ),
        // )
        console.log("------------------")
        tx = await commitRevealRecoverRNG.multiExpGas(_a, _b, _x, _y, _n)
        receipt = await tx.wait()
        console.log("------------------")
        await commitRevealRecoverRNG.dimitrovMultiExpView3ForLoopCount(_a, _x, _y, _n)
        console.log("dimitrovMultiExpView3ForLoopCount")
        console.log("------------------")

        console.log(_a, _b)
        tx = await commitRevealRecoverRNG.dimitrovMultiExp2(_a, _x, _y, _n)
        receipt = await tx.wait()
        console.log("dimitrovMultiExpView")
        console.log(await commitRevealRecoverRNG.dimitrovMultiExpView2(_a, _x, _y, _n))
        console.log(receipt?.gasUsed)
    })
})
