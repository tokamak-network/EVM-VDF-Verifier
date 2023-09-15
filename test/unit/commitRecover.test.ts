import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { assert, expect } from "chai";
import { BigNumberish, toNumber } from "ethers";
import { network, deployments, ethers }from "hardhat";
import { developmentChains, networkConfig} from "../../helper-hardhat-config";
import { CommitRecover, CommitRecover__factory } from "../../typechain-types";
import { simpleVDF, getRandomInt } from "../shared/utils";
const { time } = require('@nomicfoundation/hardhat-network-helpers');

!developmentChains.includes(network.name) ? describe.skip : describe("CommitRecover Tests", () => {
    let commitRecoverContract: CommitRecover;
    let commitRecover: CommitRecover;
    let accounts: SignerWithAddress[];
    let deployer: SignerWithAddress;
    let order: number;
    let g: number;
    let h: number;
    let c: number[] = [];
    let a: number[] = [];
    let member:number = 3;
    let vdfTime:number = 10;
    let deployed:any;
    let commitStartTime: number;
    
    console.log('\n   ___  _                       ___  _  __  ___       _____ \n \
    / _ )(_)______  _______  ____/ _ \| |/_/ / _ \___  / ___/ \n \
   / _  / / __/ _ \/ __/ _ \/___/ , _/>  <  / ___/ _ \/ /__  \n \
  /____/_/\__/\___/_/ /_//_/   /_/|_/_/|_| /_/   \___/\___/  \n');
    
    console.log('[+] blockchain environment:');  

    before(async () => {
        accounts = await ethers.getSigners();
        deployer = accounts[0];
        deployed = await deployments.fixture(["commitRecover"]);
        commitRecoverContract = await ethers.getContract("CommitRecover");
        commitRecover = commitRecoverContract.connect(deployer);
        order = Number(await commitRecover.order());
        g = Number(await commitRecover.g());
        console.log("\t - Order of Group: ", order);
        console.log("\t - Time Delay for VDF: ", vdfTime);
        console.log("");
        console.log('g is generated as ', g);
        vdfTime = 10;
        h = simpleVDF(g, order, vdfTime);
        console.log('h is generated as ', h);
        console.log("");
        console.log("[+] Number of participants: ", member);
        console.log("");
        for (let i = 0; i < member; i++){
            a.push(getRandomInt(0, order));
            console.log(`a_${i} is generated as `, a[i]);
            c.push(simpleVDF(a[i], order, vdfTime));
            console.log(`c_${i} is generated as `, c[i]);
        }
        console.log("[+] Random list : ", a);
        console.log("[+] Commit list : ", c);
        console.log("");
    });
    describe("--constructor--", () => {
        it("intitiallizes the commitRecover contract stage correctly", async () => {
            /// check Stage
            const stage = Number(await commitRecover.stage());
            console.log("stage is ", stage, " == commit stage");
            assert.equal(stage, 0, "stage should be 0");
        });
        it("intitiallizes the commitRecover contract startTime correctly", async () => {
            /// check startTime
            commitStartTime = Number(await commitRecover.startTime());
            const deployedBlockNum: number = deployed.CommitRecover.receipt.blockNumber;
            const deployedBlock = await ethers.provider.getBlock(1);
            const deployedTimestamp = deployedBlock?.timestamp;
            console.log("deployedTimestamp: ", deployedTimestamp, "| startTime: ", commitStartTime, "| get Lastest block timestamp: ", await time.latest());
            assert.equal(commitStartTime, deployedTimestamp, "startTime should be the same as deployedTimestamp")
        });
        it("intitiallizes the commitRecover contract commitduration correctly", async () => {
            /// check commitduration
            const commitDuration = Number(await commitRecover.commitDuration());
            console.log("commitDuration:",commitDuration);
            assert.equal(commitDuration, networkConfig[network.config.chainId!].commitDuration, "commitDuration should be the same as networkConfig[network.name].commitDuration")
        });
        it("intitiallizes the commitRecover contract commitRecoverDuration correctly", async () => {
            /// check commitRevealDuration
            const commitRecoverDuration = Number(await commitRecover.commmitRevealDuration());
            assert.equal(commitRecoverDuration, networkConfig[network.config.chainId!].commitRecoverDuration, "commitRevealDuration should be the same as networkConfig[network.name].CommitRecoverDuration")
            console.log("commitRecoverDuration(commit + recover):", commitRecoverDuration);
        });
        it("intitiallizes the commitRecover contract order correctly", async () => {
            /// check order
            const order = Number(await commitRecover.order());
            assert.equal(order, networkConfig[network.config.chainId!].order, "order should be the same as networkConfig[network.name].order")
            console.log("order:", order);
        });
        it("initializes the commitRecover contract h correctly", async () => {
            /// check g
            assert.equal(Number(await commitRecover.g()), g, "g should be the same as networkConfig[network.name].g");
            console.log("g:", g);
        });
        it("intitiallizes the commitRecover contract omega correctly", async () => {
            /// check omega
            const omega = Number(await commitRecover.omega());
            assert.equal(omega, 1);
            console.log("omega:", omega);
        });
    });
});