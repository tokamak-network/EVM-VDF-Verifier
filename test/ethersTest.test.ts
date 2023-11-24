import { BigNumberish, Contract, ContractTransactionReceipt, Log, BytesLike, hexlify, toBeHex } from "ethers"
import { testCases } from "./shared/testcases";
import { createTestCases } from "./shared/testFunctions";

describe("ethersTest", () => {
    it("ethersTest", async () => {
        console.log(toBeHex(9922323n));
        const created = createTestCases(testCases)
        console.log(created[0].setupProofs);
    })
})