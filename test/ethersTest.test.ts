import { BigNumberish, Contract, ContractTransactionReceipt, Log, BytesLike, hexlify, toBeHex, AbiCoder, zeroPadValue, dataLength } from "ethers"
import { BigNumber } from "./shared/testcases";
import { testCases3 } from "./shared/testcases3"

export interface VDFClaim {
    n: BytesLike
    x: BytesLike
    y: BytesLike
    T: number
    v: BytesLike
}

export interface TestCase {
    n: BytesLike
    g: BytesLike
    h: BytesLike
    T: number
    setupProofs: VDFClaim[]
    randomList: BytesLike[]
    commitList: BytesLike[]
    omega: BytesLike
    recoveredOmega: BytesLike
    recoveryProofs: VDFClaim[]
}

function getLength(value: number): number {
    let length:number = 32;
     while (length < value) length += 32;
    return length;
}

const getBitLenth = (num: bigint): BigNumberish => {
    return num.toString(2).length
}
const createTestCases2 = (testcases: any[]) => {
   const result: TestCase[] = []
    testcases.forEach((testcase) => {
        let ts: TestCase
        let setUpProofs: VDFClaim[] = []
        let recoveryProofs: VDFClaim[] = []
        let randomList: BytesLike[] = []
        let commitList: BytesLike[] = []
        for (let i = 0; i < (testcase[4] as []).length; i++) {
            setUpProofs.push({
                n: 
                    //val: toBeHex(testcase[4][i][0]),
                    toBeHex(
                        testcase[4][i][0],
                        getLength(dataLength(toBeHex(testcase[4][i][0]))),
                    )
                ,
                x: 
                     toBeHex(
                        testcase[4][i][1],
                        getLength(dataLength(toBeHex(testcase[4][i][1]))),
                    )
                ,
                y: 
                    //val: toBeHex(testcase[4][i][2]),
                    toBeHex(
                        testcase[4][i][2],
                        getLength(dataLength(toBeHex(testcase[4][i][2]))),
                    )
                ,
                T: Number(testcase[4][i][3]),
                v: 
                    //val: toBeHex(testcase[4][i][4]),
                    toBeHex(
                        testcase[4][i][4],
                        getLength(dataLength(toBeHex(testcase[4][i][4]))),
                    )
                ,
            })
        }
        for (let i = 0; i < (testcase[9] as []).length; i++) {
            recoveryProofs.push({
                n: 
                    //val: toBeHex(testcase[9][i][0]),
                    toBeHex(
                        testcase[9][i][0],
                        getLength(dataLength(toBeHex(testcase[9][i][0]))),
                    )
                ,
                x: 
                    //val: toBeHex(testcase[9][i][1]),
                    toBeHex(
                        testcase[9][i][1],
                        getLength(dataLength(toBeHex(testcase[9][i][1]))),
                    )
                ,
                y: 
                    //val: toBeHex(testcase[9][i][2]),
                    toBeHex(
                        testcase[9][i][2],
                        getLength(dataLength(toBeHex(testcase[9][i][2]))),
                    )
                ,
                T: Number(testcase[9][i][3]),
                v: 
                    //val: toBeHex(testcase[9][i][4]),
                    toBeHex(
                        testcase[9][i][4],
                        getLength(dataLength(toBeHex(testcase[9][i][4]))),
                    )
                ,
            })
        }
        for (let i = 0; i < (testcase[5] as []).length; i++) {
            randomList.push(
                //val: toBeHex(testcase[5][i]),
                toBeHex(testcase[5][i], getLength(dataLength(toBeHex(testcase[5][i])))),
            )
        }
        for (let i = 0; i < (testcase[6] as []).length; i++) {
            //commitList.push(testcase[6][i])
            commitList.push(
                //val: toBeHex(testcase[6][i]),
                toBeHex(testcase[6][i], getLength(dataLength(toBeHex(testcase[6][i])))),
            )
        }
        result.push({
            //n: { val: toBeHex(testcase[0]), neg: false, bitlen: getBitLenth(testcase[0]) },
            n: 
                toBeHex(testcase[0], getLength(dataLength(toBeHex(testcase[0]))))
            ,
            //g: { val: toBeHex(testcase[1]), neg: false, bitlen: getBitLenth(testcase[1]) },
            g: 
                toBeHex(testcase[1], getLength(dataLength(toBeHex(testcase[1]))))
            ,
            //h: { val: toBeHex(testcase[2]), neg: false, bitlen: getBitLenth(testcase[2]) },
            h: 
                toBeHex(testcase[2], getLength(dataLength(toBeHex(testcase[2]))))
            ,
            T: Number(testcase[3]),
            setupProofs: setUpProofs,
            randomList: randomList,
            commitList: commitList,
            //omega: { val: toBeHex(testcase[7]), neg: false, bitlen: getBitLenth(testcase[7]) },
            omega: 
                toBeHex(testcase[7], getLength(dataLength(toBeHex(testcase[7])))),
            recoveredOmega: 
                //val: toBeHex(testcase[8]),
                toBeHex(testcase[8], getLength(dataLength(toBeHex(testcase[8])))),
            recoveryProofs: recoveryProofs,
        })
    })
    return result
}


describe("ethersTest", () => {
    it("ethersTest", async () => {
        //console.log(toBeHex(toBeHex(9922323n), 32));
        let testCases2 = createTestCases2(testCases3);
        console.log(testCases2[0]);
        //console.log(testCases2[0].setupProofs);
        
    })
})