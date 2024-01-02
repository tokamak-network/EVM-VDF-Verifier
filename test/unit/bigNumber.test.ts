import {
    BigNumberish,
    Contract,
    ContractTransactionReceipt,
    Log,
    BytesLike,
    hexlify,
    toBeHex,
    AbiCoder,
    zeroPadValue,
    dataLength,
} from "ethers"
import { ethers } from "hardhat"

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
    })
})
