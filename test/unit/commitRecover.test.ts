import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers"
// import { assert, expect } from "chai";
import { assert, expect } from "chai"
import {
    BigNumberish,
    toNumber,
    ContractTransactionReceipt,
    ContractTransactionResponse,
} from "ethers"
import { network, deployments, ethers } from "hardhat"
import { developmentChains, networkConfig } from "../../helper-hardhat-config"
import { CommitRecover, CommitRecover__factory } from "../../typechain-types"
import { simpleVDF, getRandomInt, randomNoRepeats, powerMod } from "../shared/utils"
const { time } = require("@nomicfoundation/hardhat-network-helpers")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("CommitRecover Tests", () => {
          let commitRecoverContract: CommitRecover
          let commitRecover: CommitRecover
          let accounts: SignerWithAddress[]
          let deployer: SignerWithAddress
          let order: number
          let g: number
          let h: number
          let c: number[] = []
          let a: number[] = []
          let member: number = 5
          let revealNum: number = 3
          let vdfTime: number = 10
          let round: number = 1
          let bStar: string
          let deployed: any
          let commitStartTime: number

          console.log(
              "\n   ___  _                       ___  _  __  ___       _____ \n \
    / _ )(_)______  _______  ____/ _ | |/_/ / _ ___  / ___/ \n \
   / _  / / __/ _ / __/ _ /___/ , _/>  <  / ___/ _ / /__  \n \
  /____/_/__/___/_/ /_//_/   /_/|_/_/|_| /_/   ___/___/  \n",
          )

          console.log("[+] blockchain environment:")

          describe("--setup--", () => {
              before(async () => {
                  accounts = await ethers.getSigners()
                  deployer = accounts[0]
                  deployed = await deployments.fixture(["commitRecover"])
                  commitRecoverContract = await ethers.getContract("CommitRecover")
                  commitRecover = commitRecoverContract.connect(deployer)
                  order = Number(await commitRecover.order())
                  g = Number(await commitRecover.g())
                  console.log("\t - Order of Group: ", order)
                  console.log("\t - Time Delay for VDF: ", vdfTime)
                  console.log("")
                  console.log("g is generated as ", g)
                  vdfTime = 10
                  h = simpleVDF(g, order, vdfTime)
                  console.log("h is generated as ", h)
                  console.log("")
                  console.log("[+] Number of participants: ", member)
                  console.log("")
                  for (let i = 0; i < member; i++) {
                      a.push(getRandomInt(0, order))
                      console.log(`a_${i} is generated as `, a[i])
                      c.push(powerMod(g, BigInt(a[i]), order))
                      console.log(`c_${i} is generated as `, c[i])
                  }
                  console.log("[+] Random list : ", a)
                  console.log("[+] Commit list : ", c)
                  console.log("")
              })
              describe("--constructor--", () => {
                  it("intitiallizes the startTime correctly", async () => {
                      /// check startTime
                      commitStartTime = Number(await commitRecover.startTime())
                      const deployedBlockNum: number = deployed.CommitRecover.receipt.blockNumber
                      const deployedBlock = await ethers.provider.getBlock(deployedBlockNum)
                      const deployedTimestamp = deployedBlock?.timestamp
                      console.log(
                          "contractDeployedTimestamp: ",
                          deployedTimestamp,
                          "| startTime: ",
                          commitStartTime,
                          "| get Lastest block timestamp: ",
                          await time.latest(),
                      )
                      assert.equal(
                          commitStartTime,
                          deployedTimestamp,
                          "startTime should be the same as deployedTimestamp",
                      )
                  })
                  it("intitiallizes the stage correctly", async () => {
                      /// check Stage
                      const stage = Number(await commitRecover.stage())
                      console.log("stage is ", stage, " == commit stage")
                      assert.equal(stage, 0, "stage should be 0")
                  })
                  it("intitiallizes the commitduration correctly", async () => {
                      /// check commitduration
                      const commitDuration = Number(await commitRecover.commitDuration())
                      console.log("commitDuration:", commitDuration)
                      assert.equal(
                          commitDuration,
                          networkConfig[network.config.chainId!].commitDuration,
                          "commitDuration should be the same as networkConfig[network.name].commitDuration",
                      )
                  })
                  it("intitiallizes the commitRecoverDuration correctly, should be greater than commitDuration", async () => {
                      /// check commitRevealDuration
                      const commitRecoverDuration = Number(
                          await commitRecover.commitRevealDuration(),
                      )
                      assert.equal(
                          commitRecoverDuration,
                          networkConfig[network.config.chainId!].commitRecoverDuration,
                          "commitRevealDuration should be the same as networkConfig[network.name].CommitRecoverDuration",
                      )
                      assert.isAbove(
                          commitRecoverDuration,
                          Number(await commitRecover.commitDuration()),
                      )
                      console.log("commitRecoverDuration(commit + recover):", commitRecoverDuration)
                  })
                  it("intitiallizes the order correctly", async () => {
                      /// check order
                      const order = Number(await commitRecover.order())
                      assert.equal(
                          order,
                          networkConfig[network.config.chainId!].order,
                          "order should be the same as networkConfig[network.name].order",
                      )
                      console.log("order:", order)
                  })
                  it("initializes the g correctly, should be less than order", async () => {
                      /// check g
                      assert.equal(
                          Number(await commitRecover.g()),
                          g,
                          "g should be the same as networkConfig[network.name].g",
                      )
                      assert.isBelow(g, order, "g should be less than order")
                      console.log("g:", g)
                  })
                  it("intitiallizes the omega correctly\n", async () => {
                      /// check omega
                      const omega = Number(await commitRecover.omega())
                      assert.equal(omega, 1)
                      console.log("omega:", omega)
                  })
                  it("intitiallizes the round correctly\n", async () => {
                      /// check omega
                      const round = Number(await commitRecover.round())
                      assert.equal(round, 1)
                      console.log("-----round-----:", round)
                  })
              })
          })
          let commitsStringTest: string = ""
          let commitCount: number = 0
          let tx: ContractTransactionResponse
          let txReceipt: ContractTransactionReceipt
          let commitedTimestamp: number
          for (let i = 0; i < member; i++) {
              describe(`--commit_${i}--`, async () => {
                  before(async () => {
                      console.log(
                          "committing c",
                          i,
                          "... by a member address:",
                          accounts[i + 1].address,
                      )
                      commitRecover = commitRecoverContract.connect(accounts[i + 1])
                      tx = await commitRecover.commit(c[i])
                      txReceipt = (await tx.wait(1)) as ContractTransactionReceipt
                      commitCount++
                      commitsStringTest += c[i].toString()
                      const commitedTxBlock = await ethers.provider.getBlock(
                          txReceipt?.blockNumber as number,
                      )
                      commitedTimestamp = commitedTxBlock?.timestamp as number
                  })
                  describe(`--check commit result--`, () => {
                      it("should emit CommitC event correctly", async () => {
                          await expect(txReceipt)
                              .to.emit(commitRecoverContract, "CommitC")
                              .withArgs(
                                  accounts[i + 1].address,
                                  c[i],
                                  commitsStringTest,
                                  commitCount,
                                  commitedTimestamp,
                              )
                          //console.log("commitStartedTime:", commitStartTime, `| c_${i}_commitedTimestamp, `, commitedTimestamp, "| get Lastest block timestamp: ", await time.latest());
                          console.log(
                              (commitedTimestamp as number) - commitStartTime,
                              " seconds passed since commit started",
                          )
                      })
                      it("stage should be 0", async () => {
                          /// check Stage
                          const currentStage = Number(await commitRecover.stage())
                          //console.log("current stage is ", currentStage, " == commit stage");
                          assert.equal(currentStage, 0, "stage should be 0")
                      })
                      it("update commit Info correctly", async () => {
                          /// check commit Info
                          const commitsInfos = await commitRecover.commitsInfos(
                              accounts[i + 1].address,
                              round,
                          )
                          //console.log(`member_${i}'s commited c:`, commitsInfos.c.toString());
                          assert.equal(
                              commitsInfos.c.toString(),
                              c[i].toString(),
                              `member_${i}'s commited c should be the same as c_${i}`,
                          )
                          //console.log(`member_${i}'s commit revealed?:`, commitsInfos.revealed);
                          assert.equal(
                              commitsInfos.revealed,
                              false,
                              `member_${i}'s commit should not be revealed yet`,
                          )
                      })
                      it("update commitString correctly", async () => {
                          /// check commit string
                          const commitsString = await commitRecover.commitsString()
                          assert.equal(
                              commitsStringTest,
                              commitsString,
                              "commitsString should be the same as c_0 + c_1 + ... + c_i",
                          )
                          //console.log(`${i}: commitsString:`, commitsString);
                      })
                      it("update commit count correctly", async () => {
                          /// check commit count
                          const count = Number(await commitRecover.count())
                          //console.log("commitCount:", count);
                          assert.equal(commitCount, count, "commitCount should be the same as i+1")
                          //console.log("-----------------------------------------------");
                      })
                  })
              })
          }
          let setHTimestamp: number
          describe(`put h value on chain`, () => {
              before(async () => {
                  console.log("putting h on chain...")
                  tx = await commitRecover.connect(deployer).setH(h)
                  txReceipt = (await tx.wait(1)) as ContractTransactionReceipt
                  const setHTxBlock = await ethers.provider.getBlock(
                      txReceipt?.blockNumber as number,
                  )
                  setHTimestamp = setHTxBlock?.timestamp as number
              })
              it("should emit SetH event correctly", async () => {
                  await expect(txReceipt)
                      .to.emit(commitRecover, "SetH")
                      .withArgs(deployer.address, h, setHTimestamp)
              })
              it("should set h correctly", async () => {
                  const hOnChain = Number(await commitRecover.h())
                  assert.equal(hOnChain, h, "h should be the same as hOnChain")
              })
              it("should set isHset to true", async () => {
                  const isHset = await commitRecover.isHSet()
                  assert.equal(isHset, true, "isHset should be true")
              })
          })

          let revealedTimestamp: number
          let revealCount: number = 0
          let membersToReveal: number[] = []
          let membersToNotReveal: number[] = []
          let temp: number[] = []
          let omega: number = 1
          let isOmegaCompleted: boolean = false
          for (let i = 0; i < member; i++) temp[i] = i
          let chooser = randomNoRepeats(temp)
          let i = 0
          for (; i < revealNum; i++) membersToReveal.push(chooser())
          for (; i < member; i++) membersToNotReveal.push(chooser())
          describe("time increase to reach  the reveal phase...", () => {
              it("increase time...", async () => {
                  await time.increase(networkConfig[network.config.chainId!].commitDuration)
                  bStar = ethers.solidityPackedKeccak256(["string"], [commitsStringTest])
              })
          })
          for (i = 0; i < revealNum; i++) {
              let memberToReveal = membersToReveal[i]
              describe(`--reveal_${memberToReveal}--`, () => {
                  before(async () => {
                      console.log(
                          "revealing a",
                          memberToReveal,
                          `== ${a[memberToReveal]} ... by a member address:`,
                          accounts[memberToReveal + 1].address,
                      )
                      commitRecover = commitRecoverContract.connect(accounts[memberToReveal + 1])
                      tx = await commitRecover.reveal(a[memberToReveal])
                      revealCount++
                      txReceipt = (await tx.wait(1)) as ContractTransactionReceipt
                      const revealedTxBlock = await ethers.provider.getBlock(
                          txReceipt?.blockNumber as number,
                      )
                      revealedTimestamp = revealedTxBlock?.timestamp as number
                  })
                  describe(`--reveal result--`, () => {
                      it("should emit RevealA event correctly", async () => {
                          omega =
                              (omega *
                                  powerMod(
                                      powerMod(
                                          h,
                                          BigInt(
                                              ethers.solidityPackedKeccak256(
                                                  ["uint256", "bytes32"],
                                                  [c[memberToReveal], bStar],
                                              ),
                                          ),
                                          order,
                                      ),
                                      BigInt(a[memberToReveal]),
                                      order,
                                  )) %
                              order

                          await expect(txReceipt)
                              .to.emit(commitRecoverContract, "RevealA")
                              .withArgs(
                                  accounts[memberToReveal + 1].address,
                                  a[memberToReveal],
                                  omega,
                                  commitCount - revealCount,
                                  revealedTimestamp,
                              )
                          const commitDuration = Number(await commitRecover.commitDuration())
                          console.log(
                              (revealedTimestamp as number) - (commitStartTime + commitDuration),
                              " seconds passed since reveal started",
                          )
                      })
                      it("isHSet should be still true", async () => {
                          const isHset = await commitRecover.isHSet()
                          assert.equal(isHset, true, "isHset should be true")
                      })
                      it("stage should be 1", async () => {
                          /// check Stage
                          const currentStage = Number(await commitRecover.stage())
                          //console.log("current stage is ", currentStage, " == reveal stage");
                          assert.equal(currentStage, 1, "stage should be 1")
                      })
                      it("bStar should be set keccak256(abi.encodePacked(commitsSring)) correctly", async () => {
                          /// check bStar
                          const bStarOnChain = await commitRecover.bStar()
                          bStar = ethers.solidityPackedKeccak256(["string"], [commitsStringTest])
                          assert.equal(bStar, bStarOnChain)
                      })
                      it("update commitInfos[msg.sender].revealed to true correctly", async () => {
                          /// check commit Info
                          const commitInfo = await commitRecover.commitsInfos(
                              accounts[memberToReveal + 1].address,
                              round,
                          )
                          assert.equal(commitInfo.c.toString(), c[memberToReveal].toString())
                          //console.log(`member_${memberToReveal}'s revealed a:`, revealsInfos.a.toString());
                          assert.equal(
                              commitInfo.a.toString(),
                              a[memberToReveal].toString(),
                              `member_${memberToReveal}'s revealed a should be the same as a_${memberToReveal}`,
                          )
                          //console.log(`member_${memberToReveal}'s reveal revealed?:`, revealsInfos.revealed);
                          assert.equal(
                              commitInfo.revealed,
                              true,
                              `member_${memberToReveal}'s reveal should be revealed`,
                          )
                      })
                      it("count should be commitCount - revealCount", async () => {
                          /// check commit count
                          const count = Number(await commitRecover.count())
                          //console.log("commitCount:", count);
                          assert.equal(
                              commitCount - revealCount,
                              count,
                              "commitCount should be the same as i+1",
                          )
                      })
                      it("if count == 0, then isOmegaCompleted = true", async () => {
                          /// check isOmegaCompleted
                          isOmegaCompleted = Boolean(await commitRecover.isOmegaCompleted())
                          if (commitCount - revealCount == 0) {
                              assert.equal(isOmegaCompleted, true)
                          } else {
                              assert.equal(isOmegaCompleted, false)
                          }
                      })
                      it("omega should be updated correctly", async () => {
                          /// check omega
                          const omegaOnChain = Number(await commitRecover.omega())
                          assert.equal(omegaOnChain, omega)
                          console.log("omega:", omega)
                      })
                      it("commitsInfo[sender][round].revealed should be true", async () => {
                          const commitInfo = await commitRecover.commitsInfos(
                              accounts[memberToReveal + 1].address,
                              round,
                          )
                          assert.equal(commitInfo.revealed, true)
                      })
                      it("commitsInfos[sender][round].a should be the same as a", async () => {
                          const commitInfo = await commitRecover.commitsInfos(
                              accounts[memberToReveal + 1].address,
                              round,
                          )
                          assert.equal(commitInfo.a, BigInt(a[memberToReveal]))
                      })
                  })
              })
          }
          let recov: number = 1
          let recoveredTimestamp: number
          if (isOmegaCompleted == false) {
              describe("recover...", () => {
                  before(async () => {
                      member -= i
                      for (i = 0; i < member; i++) {
                          let recovery_index = membersToNotReveal[i]
                          let temp = powerMod(
                              c[recovery_index],
                              BigInt(
                                  ethers.solidityPackedKeccak256(
                                      ["uint256", "bytes32"],
                                      [c[recovery_index], bStar],
                                  ),
                              ),
                              order,
                          )
                          recov = (recov * temp) % order
                      }
                      recov = simpleVDF(recov, order, time)
                      omega = (omega * recov) % order
                      tx = await commitRecover.connect(deployer).recover(recov)
                      txReceipt = (await tx.wait(1)) as ContractTransactionReceipt
                      const recoveredTxBlock = await ethers.provider.getBlock(
                          txReceipt?.blockNumber as number,
                      )
                      recoveredTimestamp = recoveredTxBlock?.timestamp as number
                  })
                  describe("recover result...", () => {
                      it("should emit Recover event correctly", async () => {
                          await expect(txReceipt)
                              .to.emit(commitRecoverContract, "Recovered")
                              .withArgs(deployer.address, recov, omega, recoveredTimestamp)
                          const commitDuration = Number(await commitRecover.commitDuration())
                          console.log(
                              (recoveredTimestamp as number) - (commitStartTime + commitDuration),
                              " seconds passed since reveal started",
                          )
                      })
                      it("stage should be Finished (2)", async () => {
                          /// check Stage
                          const currentStage = Number(await commitRecover.stage())
                          //console.log("current stage is ", currentStage, " == reveal stage");
                          assert.equal(currentStage, 2, "stage should be 2")
                      })
                      it("count should not be 0", async () => {
                          /// check commit count
                          const count = Number(await commitRecover.count())
                          //console.log("commitCount:", count);
                          assert.notEqual(count, 0, "commitCount should not be 0")
                      })
                      it("isOmegaCompleted should be true", async () => {
                          /// check isOmegaCompleted
                          isOmegaCompleted = Boolean(await commitRecover.isOmegaCompleted())
                          assert.equal(isOmegaCompleted, true)
                      })
                      it("omegaAtRound[round] should be the same as omega", async () => {
                          const omegaAtRound = Number(await commitRecover.omegaAtRound(round))
                          assert.equal(omegaAtRound, omega)
                      })
                  })
              })
          }
          describe("start again..", () => {
                before(async () => {
                    console.log("starting again...")
                    tx = await commitRecover.connect(deployer).start()
                    txReceipt = (await tx.wait(1)) as ContractTransactionReceipt
                })
                it("should emit Start event correctly", async () => {
                    await expect(txReceipt).to.emit(commitRecoverContract, "Start")
                })
                it("stage should be 0", async () => {
                    /// check Stage
                    const currentStage = Number(await commitRecover.stage())
                    //console.log("current stage is ", currentStage, " == reveal stage");
                    assert.equal(currentStage, 0, "stage should be 0")
                })
                it("count should be 0", async () => {
                    /// check commit count
                    const count = Number(await commitRecover.count())
                    //console.log("commitCount:", count);
                    assert.equal(count, 0, "commitCount should be 0")
                })
                it("isOmegaCompleted should be false", async () => {
                    /// check isOmegaCompleted
                    isOmegaCompleted = Boolean(await commitRecover.isOmegaCompleted())
                    assert.equal(isOmegaCompleted, false)
                })
                it("omega should be 1", async () => {
                    /// check omega
                    const omegaOnChain = Number(await commitRecover.omega())
                    assert.equal(omegaOnChain, 1)
                    console.log("omega:", omega)
                })
                it("round should be 2", async () => {
                    /// check round
                    const roundOnChain = Number(await commitRecover.round())
                    assert.equal(roundOnChain, 2)
                    console.log("round:", roundOnChain)
                })
          })
      })
