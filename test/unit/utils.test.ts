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
import { BigNumber, TestCaseJson, VDFClaim, TestCase } from "../shared/interfaces"
import { testCases } from "../shared/testcases"
import fs from "fs"

export const createTestCases2 = () => {
    const result: TestCase[] = []
    const testData: TestCaseJson = JSON.parse(
        fs.readFileSync(__dirname + "/../shared/newTestData.json", "utf8"),
    )
    let ts: TestCase
    let setUpProofs: VDFClaim[] = []
    let recoveryProofs: VDFClaim[] = []
    let randomList: BigNumber[] = []
    let commitList: BigNumber[] = []
    for (let i = 0; i < (testData.setupProofs as []).length; i++) {
        setUpProofs.push({
            n: {
                //val: toBeHex(testcase[4][i][0]),
                val: toBeHex(
                    testData.setupProofs[i].n,
                    getLength(dataLength(toBeHex(testData.setupProofs[i].n))),
                ),
                bitlen: getBitLenth2(testData.setupProofs[i].n),
            },
            x: {
                //val: toBeHex(testcase[4][i][1]),
                val: toBeHex(
                    testData.setupProofs[i].x,
                    getLength(dataLength(toBeHex(testData.setupProofs[i].x))),
                ),
                bitlen: getBitLenth2(testData.setupProofs[i].x),
            },
            y: {
                //val: toBeHex(testcase[4][i][2]),
                val: toBeHex(
                    testData.setupProofs[i].y,
                    getLength(dataLength(toBeHex(testData.setupProofs[i].y))),
                ),
                bitlen: getBitLenth2(testData.setupProofs[i].y),
            },
            T: testData.setupProofs[i].T,
            v: {
                //val: toBeHex(testcase[4][i][4]),
                val: toBeHex(
                    testData.setupProofs[i].v,
                    getLength(dataLength(toBeHex(testData.setupProofs[i].v))),
                ),
                bitlen: getBitLenth2(testData.setupProofs[i].v),
            },
        })
    }
    for (let i = 0; i < (testData.recoveryProofs as []).length; i++) {
        recoveryProofs.push({
            n: {
                //val: toBeHex(testcase[9][i][0]),
                val: toBeHex(
                    testData.recoveryProofs[i].n,
                    getLength(dataLength(toBeHex(testData.recoveryProofs[i].n))),
                ),
                bitlen: getBitLenth2(testData.recoveryProofs[i].n),
            },
            x: {
                //val: toBeHex(testcase[9][i][1]),
                val: toBeHex(
                    testData.recoveryProofs[i].x,
                    getLength(dataLength(toBeHex(testData.recoveryProofs[i].x))),
                ),
                bitlen: getBitLenth2(testData.recoveryProofs[i].x),
            },
            y: {
                //val: toBeHex(testcase[9][i][2]),
                val: toBeHex(
                    testData.recoveryProofs[i].y,
                    getLength(dataLength(toBeHex(testData.recoveryProofs[i].y))),
                ),
                bitlen: getBitLenth2(testData.recoveryProofs[i].y),
            },
            T: testData.recoveryProofs[i].T,
            v: {
                //val: toBeHex(testcase[9][i][4]),
                val: toBeHex(
                    testData.recoveryProofs[i].v,
                    getLength(dataLength(toBeHex(testData.recoveryProofs[i].v))),
                ),
                bitlen: getBitLenth2(testData.recoveryProofs[i].v),
            },
        })
    }
    for (let i = 0; i < (testData.randomList as []).length; i++) {
        randomList.push({
            //val: toBeHex(testcase[5][i]),
            val: toBeHex(
                testData.randomList[i],
                getLength(dataLength(toBeHex(testData.randomList[i]))),
            ),
            bitlen: getBitLenth2(testData.randomList[i]),
        })
    }
    for (let i = 0; i < (testData.commitList as []).length; i++) {
        //commitList.push(testcase[6][i])
        commitList.push({
            //val: toBeHex(testcase[6][i]),
            val: toBeHex(
                testData.commitList[i],
                getLength(dataLength(toBeHex(testData.commitList[i]))),
            ),
            bitlen: getBitLenth2(testData.commitList[i]),
        })
    }
    result.push({
        //n: { val: toBeHex(testcase[0]), neg: false, bitlen: getBitLenth2(testcase[0]) },
        n: {
            val: toBeHex(testData.n, getLength(dataLength(toBeHex(testData.n)))),
            bitlen: getBitLenth2(testData.n),
        },
        //g: { val: toBeHex(testcase[1]), neg: false, bitlen: getBitLenth2(testcase[1]) },
        g: {
            val: toBeHex(testData.g, getLength(dataLength(toBeHex(testData.g)))),
            bitlen: getBitLenth2(testData.g),
        },
        //h: { val: toBeHex(testcase[2]), neg: false, bitlen: getBitLenth2(testcase[2]) },
        h: {
            val: toBeHex(testData.h, getLength(dataLength(toBeHex(testData.h)))),
            bitlen: getBitLenth2(testData.h),
        },
        T: testData.T,
        setupProofs: setUpProofs,
        randomList: randomList,
        commitList: commitList,
        //omega: { val: toBeHex(testcase[7]), neg: false, bitlen: getBitLenth2(testcase[7]) },
        omega: {
            val: toBeHex(testData.omega, getLength(dataLength(toBeHex(testData.omega)))),
            bitlen: getBitLenth2(testData.omega),
        },
        recoveredOmega: {
            //val: toBeHex(testcase[8]),
            val: toBeHex(
                testData.recoveredOmega,
                getLength(dataLength(toBeHex(testData.recoveredOmega))),
            ),
            bitlen: getBitLenth2(testData.recoveredOmega),
        },
        recoveryProofs: recoveryProofs,
    })

    return result
}

const getBitLenth2 = (num: BigNumberish): BigNumberish => {
    return BigInt(num).toString(2).length
}

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}

describe("ethersTest", () => {
    it("ethersTest", async () => {
        console.log(process.cwd())
        let a = createTestCases2()
        console.log(a[0].setupProofs)
        console.log(a[0].randomList)
        console.log(a[0].commitList)
        console.log(a[0].recoveryProofs)
        //console.log(testCases2[0].setupProofs);
        const val =
            "0x4ddb381e3bd62b7c00f5de6743c033fa257f6b75ce0a2c826a33af07419211a948fda3ea70c9c70e2c63f0dd145808360afd6ff2768c838c213064bcc407b1af34321859e9ad81e4e6427b482f1270c0e66bbffc3518651b2223494dcfd3e0efbe7022b9dc95624d6f59ada69722806563d88554225a82bb6a62d90f1426e52b6d666fd7bf9b5556d2d5715b5d602bd8f2ad74b7a5fb785942816ae45943320b88a55dd27209bd3b9ceecce4e38ba4857a743cace8e66c1c8bc6a7cd7aebdf5ec927a3ff703c52cac119752fc03ec40dadf23ca2e58815205cd83ce41aec9f61d5539ae75d2b64057ec89a369c7eb686d2a32b2bcdb2948af8017de17ef2f035"
        console.log(BigInt(val).toString(2).length)
        console.log(
            toBeHex(
                340282366920938463463374607431768211456n,
                getLength(dataLength(toBeHex(340282366920938463463374607431768211456n))),
            ),
        )
        console.log(getBitLenth2(340282366920938463463374607431768211456n))
    })
})
