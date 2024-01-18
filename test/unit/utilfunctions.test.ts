import { BigNumberish, toBeHex, dataLength } from "ethers"
import { ethers } from "hardhat"
import fs from "fs"

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
})
