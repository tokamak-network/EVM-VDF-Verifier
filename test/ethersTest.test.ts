import { BigNumberish, Contract, ContractTransactionReceipt, Log, BytesLike, hexlify, toBeHex, AbiCoder, zeroPadValue, dataLength } from "ethers"
import { testCases } from "./shared/testcases";
import { createTestCases } from "./shared/testFunctions";
import { testCases4 } from "./shared/testcases4"

function getLength(value: number): number {
    let length:number = 32;
     while (length < value) length += 32;
    return length;
}

describe("ethersTest", () => {
    it("ethersTest", async () => {
        console.log(toBeHex(9922323n));
        const created = createTestCases(testCases)
        //console.log(created[0].setupProofs);
        const abiCoder = AbiCoder.defaultAbiCoder();
        console.log(abiCoder.encode(["bytes"], [toBeHex(12)]));
        console.log(toBeHex(12, getLength(dataLength(toBeHex(12)))));
    })
})