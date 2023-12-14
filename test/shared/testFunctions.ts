import { assert, expect } from "chai"
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
import {
    BigNumberish,
    Contract,
    ContractTransactionReceipt,
    Log,
    BytesLike,
    toBeHex,
    dataLength,
} from "ethers"
import { network, ethers } from "hardhat"
import {
    VDFClaim,
    TestCase,
    BigNumber,
    StartParams,
    CommitParams,
    RevealParams,
    TestCaseJson,
    VDFClaimJson,
} from "./interfaces"
import { testCases } from "./testcases"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import fs from "fs"

export const createTestCases2 = () => {
    const result: TestCase[] = []
    const testData: TestCaseJson = JSON.parse(
        fs.readFileSync(__dirname + "/../shared/data_20231212_150019.json", "utf8"),
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

const getBitLenth = (num: bigint): BigNumberish => {
    return num.toString(2).length
}

function getLength(value: number): number {
    let length: number = 32
    while (length < value) length += 32
    return length
}
export const createTestCases = (testcases: any[]) => {
    const result: TestCase[] = []
    testcases.forEach((testcase) => {
        let ts: TestCase
        let setUpProofs: VDFClaim[] = []
        let recoveryProofs: VDFClaim[] = []
        let randomList: BigNumber[] = []
        let commitList: BigNumber[] = []
        for (let i = 0; i < (testcase[4] as []).length; i++) {
            setUpProofs.push({
                n: {
                    //val: toBeHex(testcase[4][i][0]),
                    val: toBeHex(
                        testcase[4][i][0],
                        getLength(dataLength(toBeHex(testcase[4][i][0]))),
                    ),
                    bitlen: getBitLenth(testcase[4][i][0]),
                },
                x: {
                    //val: toBeHex(testcase[4][i][1]),
                    val: toBeHex(
                        testcase[4][i][1],
                        getLength(dataLength(toBeHex(testcase[4][i][1]))),
                    ),
                    bitlen: getBitLenth(testcase[4][i][1]),
                },
                y: {
                    //val: toBeHex(testcase[4][i][2]),
                    val: toBeHex(
                        testcase[4][i][2],
                        getLength(dataLength(toBeHex(testcase[4][i][2]))),
                    ),
                    bitlen: getBitLenth(testcase[4][i][2]),
                },
                T: testcase[4][i][3],
                v: {
                    //val: toBeHex(testcase[4][i][4]),
                    val: toBeHex(
                        testcase[4][i][4],
                        getLength(dataLength(toBeHex(testcase[4][i][4]))),
                    ),
                    bitlen: getBitLenth(testcase[4][i][4]),
                },
            })
        }
        for (let i = 0; i < (testcase[9] as []).length; i++) {
            recoveryProofs.push({
                n: {
                    //val: toBeHex(testcase[9][i][0]),
                    val: toBeHex(
                        testcase[9][i][0],
                        getLength(dataLength(toBeHex(testcase[9][i][0]))),
                    ),
                    bitlen: getBitLenth(testcase[9][i][0]),
                },
                x: {
                    //val: toBeHex(testcase[9][i][1]),
                    val: toBeHex(
                        testcase[9][i][1],
                        getLength(dataLength(toBeHex(testcase[9][i][1]))),
                    ),
                    bitlen: getBitLenth(testcase[9][i][1]),
                },
                y: {
                    //val: toBeHex(testcase[9][i][2]),
                    val: toBeHex(
                        testcase[9][i][2],
                        getLength(dataLength(toBeHex(testcase[9][i][2]))),
                    ),
                    bitlen: getBitLenth(testcase[9][i][2]),
                },
                T: testcase[9][i][3],
                v: {
                    //val: toBeHex(testcase[9][i][4]),
                    val: toBeHex(
                        testcase[9][i][4],
                        getLength(dataLength(toBeHex(testcase[9][i][4]))),
                    ),
                    bitlen: getBitLenth(testcase[9][i][4]),
                },
            })
        }
        for (let i = 0; i < (testcase[5] as []).length; i++) {
            randomList.push({
                //val: toBeHex(testcase[5][i]),
                val: toBeHex(testcase[5][i], getLength(dataLength(toBeHex(testcase[5][i])))),
                bitlen: getBitLenth(testcase[5][i]),
            })
        }
        for (let i = 0; i < (testcase[6] as []).length; i++) {
            //commitList.push(testcase[6][i])
            commitList.push({
                //val: toBeHex(testcase[6][i]),
                val: toBeHex(testcase[6][i], getLength(dataLength(toBeHex(testcase[6][i])))),
                bitlen: getBitLenth(testcase[6][i]),
            })
        }
        result.push({
            //n: { val: toBeHex(testcase[0]), neg: false, bitlen: getBitLenth(testcase[0]) },
            n: {
                val: toBeHex(testcase[0], getLength(dataLength(toBeHex(testcase[0])))),
                bitlen: getBitLenth(testcase[0]),
            },
            //g: { val: toBeHex(testcase[1]), neg: false, bitlen: getBitLenth(testcase[1]) },
            g: {
                val: toBeHex(testcase[1], getLength(dataLength(toBeHex(testcase[1])))),
                bitlen: getBitLenth(testcase[1]),
            },
            //h: { val: toBeHex(testcase[2]), neg: false, bitlen: getBitLenth(testcase[2]) },
            h: {
                val: toBeHex(testcase[2], getLength(dataLength(toBeHex(testcase[2])))),
                bitlen: getBitLenth(testcase[2]),
            },
            T: testcase[3],
            setupProofs: setUpProofs,
            randomList: randomList,
            commitList: commitList,
            //omega: { val: toBeHex(testcase[7]), neg: false, bitlen: getBitLenth(testcase[7]) },
            omega: {
                val: toBeHex(testcase[7], getLength(dataLength(toBeHex(testcase[7])))),
                bitlen: getBitLenth(testcase[7]),
            },
            recoveredOmega: {
                //val: toBeHex(testcase[8]),
                val: toBeHex(testcase[8], getLength(dataLength(toBeHex(testcase[8])))),
                bitlen: getBitLenth(testcase[8]),
            },
            recoveryProofs: recoveryProofs,
        })
    })
    return result
}
export const deployCommitRecover = async () => {
    let commitRecoverContract = await ethers.deployContract("CommitRecover")
    commitRecoverContract = await commitRecoverContract.waitForDeployment()
    let tx = commitRecoverContract.deploymentTransaction()
    let receipt = await tx?.wait()
    return { commitRecoverContract, receipt }
}

export const startCommitRecoverRound = async (
    commitRevealContract: Contract,
    params: StartParams,
) => {
    const startTx = await commitRevealContract.start(
        params.commitDuration,
        params.commitRevealDuration,
        params.n,
        params.setupProofs,
    )
    const receipt = await startTx.wait()
    return { commitRevealContract, receipt }
}

export const commit = async (
    commitRecoverContract: Contract,
    signer: SignerWithAddress,
    params: CommitParams,
) => {
    const tx = await (commitRecoverContract.connect(signer) as Contract).commit(
        params.round,
        params.commit,
    )
    const receipt = await tx.wait()
    return { commitRecoverContract, receipt }
}

export const reveal = async (
    commitRecoverContract: Contract,
    signer: SignerWithAddress,
    params: RevealParams,
) => {
    const tx = await (commitRecoverContract.connect(signer) as Contract).reveal(
        params.round,
        params.reveal,
    )
    const receipt = await tx.wait()
    return { commitRecoverContract, receipt }
}

export const deployAndStartCommitRevealContract = async (params: any) => {
    let commitRecover = await ethers.deployContract("CommitRecover", [])
    commitRecover = await commitRecover.waitForDeployment()
    const tx = commitRecover.deploymentTransaction()
    let receipt = await tx?.wait()
    console.log("deploy gas used: ", receipt?.gasUsed?.toString())
    const startTx = await commitRecover.start(...params)
    receipt = await startTx.wait()
    console.log("start gas used: ", receipt?.gasUsed?.toString())
    return { commitRecover, receipt }
}

export const deployFirstTestCaseCommitRevealContract = async () => {
    const testcases = createTestCases(testCases)
    const testcaseNum = 0
    let params = [
        networkConfig[network.config.chainId!].commitDuration,
        networkConfig[network.config.chainId!].commitRevealDuration,
        testcases[testcaseNum].n,
        testcases[testcaseNum].setupProofs,
    ]
    const { commitRecover, receipt } = await deployAndStartCommitRevealContract(params)
    //get states
    // const {
    //     stage,
    //     commitStartTime,
    //     commitDuration,
    //     commitRevealDuration,
    //     n,
    //     g,
    //     h,
    //     T,
    //     round,
    //     deployedEvent,
    //     deployedBlockNum,
    //     deployedTimestamp,
    // } = await getStatesAfterDeployment(commitRecover, receipt as ContractTransactionReceipt)
    //return states
    return {
        commitRecover,
        receipt,
        testcases,
        params,
        // stage,
        // commitStartTime,
        // commitDuration,
        // commitRevealDuration,
        // n,
        // g,
        // h,
        // T,
        // round,
        // deployedEvent,
        // deployedBlockNum,
        // deployedTimestamp,
    }
}

export const getStatesAfterDeployment = async (
    commitRevealContract: Contract,
    receipt: ContractTransactionReceipt,
) => {
    // contract states
    const stage = await commitRevealContract.stage()
    const commitStartTime = await commitRevealContract.startTime()
    const commitDuration = await commitRevealContract.commitDuration()
    const commitRevealDuration = await commitRevealContract.commitRevealDuration()
    const round = await commitRevealContract.round()
    //console.log("round", round)
    const valuesAtRound = await commitRevealContract.valuesAtRound(round)
    const n = valuesAtRound.n
    const g = valuesAtRound.g
    const h = valuesAtRound.h
    const T = valuesAtRound.T

    // event
    const topic = commitRevealContract.interface.getEvent("Start")
    const log = receipt.logs.find((x) => x.topics.indexOf(topic?.topicHash!) >= 0)
    const deployedEvent = commitRevealContract.interface.parseLog({
        topics: log?.topics! as string[],
        data: log?.data!,
    })

    // others
    const deployedBlockNum = receipt.blockNumber
    const deployedBlock = await ethers.provider.getBlock(deployedBlockNum)
    const deployedTimestamp = deployedBlock?.timestamp

    return {
        stage,
        commitStartTime,
        commitDuration,
        commitRevealDuration,
        n,
        g,
        h,
        T,
        round,
        deployedEvent,
        deployedBlockNum,
        deployedTimestamp,
    }
}

export const initializedContractCorrectly = async (
    commitRevealContract: Contract,
    receipt: ContractTransactionReceipt,
    testcase: TestCase,
) => {
    const {
        stage,
        commitStartTime,
        commitDuration,
        commitRevealDuration,
        n,
        g,
        h,
        T,
        round,
        deployedEvent,
        deployedBlockNum,
        deployedTimestamp,
    } = await getStatesAfterDeployment(commitRevealContract, receipt)

    assert.equal(
        commitStartTime,
        deployedTimestamp,
        "commitStartTime should be equal to deployedTimestamp",
    )
    assert.equal(commitStartTime, deployedEvent!.args?.startTime)
    assert.equal(stage, 0, "stage should be 0")
    assert.equal(
        commitDuration,
        networkConfig[network.config.chainId!].commitDuration,
        "commitDuration should be equal to networkConfig",
    )
    assert.equal(
        commitDuration,
        deployedEvent!.args?.commitDuration,
        "commitDuration should be equal to deployedEvent",
    )
    assert.equal(commitRevealDuration, networkConfig[network.config.chainId!].commitRevealDuration)
    assert.equal(
        commitRevealDuration,
        deployedEvent!.args?.commitRevealDuration,
        "commitRevealDuration should be equal to deployedEvent",
    )
    assert.isAbove(
        commitRevealDuration,
        commitDuration,
        "commitRevealDuration should be greater than commitDuration",
    )
    // console.log(n);
    // console.log(deployedEvent!.args?.n);
    // assert.equal(n, deployedEvent!.args?.n, "n should be equal to deployedEvent")
    // assert.equal(n, testcase.n, "n should be equal to testcase")
    // assert.equal(g, deployedEvent!.args?.g, "g should be equal to deployedEvent")
    // assert.equal(g, testcase.g, "g should be equal to testcase")
    // assert.equal(T, deployedEvent!.args?.T, "T should be equal to deployedEvent")
    // assert.equal(T, testcase.T, "T should be equal to testcase")
    // assert.equal(h, deployedEvent!.args?.h, "h should be equal to deployedEvent")
    // assert.equal(h, testcase.h, "h should be equal to testcase")
    // assert.equal(round, 1, "round should be 1")
    // assert.equal(round, deployedEvent!.args?.round, "round should be equal to deployedEvent")
}

interface CommitRevealValue {
    c: BigNumberish
    a: BigNumberish
    participantAddress: string
}
interface UserAtRound {
    index: BigNumberish
    committed: boolean
    revealed: boolean
}

export const getStatesAfterCommitOrReveal = async (
    commitRevealContract: Contract,
    receipt: ContractTransactionReceipt,
    signer: SignerWithAddress,
    i: number,
) => {
    //contract states
    const count = await commitRevealContract.count()
    const stage = await commitRevealContract.stage()
    const commitsString = await commitRevealContract.commitsString()
    const round = await commitRevealContract.round()
    const valuesAtRound = await commitRevealContract.valuesAtRound(round)
    const userInfosAtRound: UserAtRound = await commitRevealContract.userInfosAtRound(
        signer.address,
        round,
    )
    const commitRevealValue: CommitRevealValue = await commitRevealContract.commitRevealValues(
        round,
        i,
    )
    return {
        count,
        stage,
        commitsString,
        round,
        valuesAtRound,
        userInfosAtRound,
        commitRevealValue,
    }
}

export const revealCheck = async (
    commitRevealContract: Contract,
    receipt: ContractTransactionReceipt,
    random: BigNumber,
    signer: SignerWithAddress,
    i: number,
    roundTest: number,
) => {
    const ii = ethers.toBigInt(i)
    //get states
    // const {
    //     count,
    //     stage,
    //     commitsString,
    //     round,
    //     valuesAtRound,
    //     userInfosAtRound,
    //     commitRevealValue,
    // } = await getStatesAfterCommitOrReveal(commitRevealContract, receipt, signer, i)
    //console.log("valuesAtRoundvaluesAtRound, ", valuesAtRound)
    //const { omega, bStar, numOfParticipants, isCompleted } = valuesAtRound
}

let commitsStringTest: string
export const commitCheck = async (
    commitRevealContract: Contract,
    receipt: ContractTransactionReceipt,
    commit: BigNumber,
    signer: SignerWithAddress,
    i: number,
    roundTest: number,
) => {
    //if (i == 0) commitsStringTest = ""
    const ii = ethers.toBigInt(i)
    //get states
    // const {
    //     count,
    //     stage,
    //     commitsString,
    //     round,
    //     valuesAtRound,
    //     userInfosAtRound,
    //     commitRevealValue,
    // } = await getStatesAfterCommitOrReveal(commitRevealContract, receipt, signer, i)
    //assert.equal(ii + BigInt(1), count, "count should be equal to i")
    // assert.equal(stage, 0, "stage should be 0")
    // assert.equal(round, 1, "round should be 1")
    // // commitsStringTest += commit.toString()
    // // assert.equal(
    // //     commitsStringTest,
    // //     commitsString,
    // //     "commitsString should be equal to commitsStringTest",
    // // )
    // assert.equal(roundTest, round, "round should be equal to roundTest")
    // const { omega, bStar, numOfParticipants, isCompleted } = valuesAtRound
    // assert.equal(omega, 0, "omega should be 0")
    // assert.equal(bStar, 0, "bStar should be 0")
    // assert.equal(numOfParticipants, 0, "numOfParticipants should be 0")
    // assert.equal(isCompleted, false, "isCompleted should be false")
    // const { index, committed, revealed } = userInfosAtRound
    // //assert.equal(index, ii, "index should be equal to i")
    // assert.equal(committed, true, "committed should be true")
    // assert.equal(revealed, false, "revealed should be false")
    //     assert.equal(commitRevealValue.c, commit, "commitRevealValue.c should be equal to commit")
    //     assert.equal(commitRevealValue.participantAddress, signer.address)
    //     assert.equal(commitRevealValue.a, 0, "commitRevealValue.a should be 0")
}
