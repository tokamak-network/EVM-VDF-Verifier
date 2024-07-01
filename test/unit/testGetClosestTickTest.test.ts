// Copyright 2024 justin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers"
import { expect } from "chai"
import { ethers } from "hardhat"
import { GetClosestTickTest } from "../../typechain-types"

describe("Bitmap Test", function () {
    let getClosestTickTest: GetClosestTickTest
    async function deployGetClosestTickTest() {
        const getClosestTickTest = await ethers.deployContract("GetClosestTickTest")

        // Fixtures can return anything you consider useful for your tests
        return getClosestTickTest
    }
    beforeEach("deploy GetClosestTickTest", async function () {
        getClosestTickTest = await loadFixture(deployGetClosestTickTest)
    })
    it("set tick 700 750 820", async () => {
        const gasUsedOfSettingTicks = await getClosestTickTest.setTicks.estimateGas(700)
        await getClosestTickTest.setTicks(700)
        await getClosestTickTest.setTicks(750)
        await getClosestTickTest.setTicks(820)
        const gasUsedOfGettingClosestTick =
            await getClosestTickTest.getThreeClosestToSevenHundred.estimateGas()
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        console.log(returnValue)
        console.log("gasUsedOfSettingTicks", gasUsedOfSettingTicks)
        console.log("gasUsedOfGettingClosestTick", gasUsedOfGettingClosestTick)
    })
    it("#testcase1", async () => {
        const testCases = [700, 700, 701]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 701n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([2n, 1n, 0n, 0n])
    })
    it("#testcase2", async () => {
        const testCases = [701, 702, 703]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([701n, 702n, 703n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })
    it("#testcase3", async () => {
        const testCases = [698, 699, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 698n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })
    it("#testcase4", async () => {
        const testCases = [698, 699, 700, 700, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([3n, 0n, 0n, 0n])
    })
    it("#testcase5", async () => {
        const testCases = [698, 699, 699, 700, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([2n, 2n, 0n, 0n])
    })
    it("#testcase6", async () => {
        const testCases = [700, 699, 701]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })
    it("#testcase7", async () => {
        const testCases = [700, 699, 702, 698, 702, 698]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 698n, 702n])
        expect(returnValue[1]).to.eql([1n, 1n, 2n, 2n])
    })
    it("#testcase8", async () => {
        const testCases = [256, 256, 257]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([257n, 256n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([1n, 2n, 0n, 0n])
    })

    it("#testcase9", async () => {
        const testCases = [256, 512, 768]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([768n, 512n, 256n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase10", async () => {
        const testCases = [512, 513, 514]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([514n, 513n, 512n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase11", async () => {
        const testCases = [700, 512, 768]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 768n, 512n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase12", async () => {
        const testCases = [600, 650, 800, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 650n, 600n, 800n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 1n])
    })

    it("#testcase13", async () => {
        const testCases = [300, 500, 256, 600, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 600n, 500n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase14", async () => {
        const testCases = [900, 850, 750, 950]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([750n, 850n, 900n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase15", async () => {
        const testCases = [699, 701, 702, 698]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([699n, 701n, 698n, 702n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 1n])
    })

    it("#testcase16", async () => {
        const testCases = [700, 700, 700, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([4n, 0n, 0n, 0n])
    })

    it("#testcase17", async () => {
        const testCases = [700, 699, 701, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([2n, 1n, 1n, 0n])
    })
    it("#testcase18", async () => {
        const testCases = [1, 1000, 500, 250, 750, 700, 800, 256, 300, 650]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 650n, 750n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase19", async () => {
        const testCases = [
            1000, 900, 850, 950, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710,
        ]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 701n, 702n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase20", async () => {
        const testCases = [
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
            25, 700, 701, 702, 703, 704, 705, 1000, 999, 998, 997, 996,
        ]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 701n, 702n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase21", async () => {
        const testCases = [
            1, 256, 512, 768, 1024, 700, 699, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710,
        ]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase22", async () => {
        const testCases = [1, 256, 512, 768, 1024, 700, 256, 512, 768, 700, 700, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([4n, 0n, 0n, 0n])
    })

    it("#testcase23", async () => {
        const testCases = [699, 698, 697, 696, 695, 701, 702, 703, 704, 705]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([699n, 701n, 698n, 702n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 1n])
    })

    it("#testcase24", async () => {
        const testCases = [256, 256, 256, 257, 257, 257, 258, 258, 258, 700, 701, 699, 698, 702]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase25", async () => {
        const testCases = [1, 1000, 999, 2, 3, 4, 5, 6, 7, 700, 700, 700, 700, 700, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([6n, 0n, 0n, 0n])
    })

    it("#testcase26", async () => {
        const testCases = [
            500, 600, 650, 675, 680, 690, 695, 700, 710, 720, 730, 740, 750, 760, 770, 780, 790,
        ]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 695n, 690n, 710n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 1n])
    })

    it("#testcase27", async () => {
        const testCases = [
            1, 2, 3, 4, 5, 1000, 999, 998, 997, 996, 750, 751, 752, 753, 754, 700, 699, 698, 697,
            701, 702, 703,
        ]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase28", async () => {
        const testCases = [1, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 600n, 800n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase29", async () => {
        const testCases = [350, 450, 550, 650, 700, 750, 850, 900, 950]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 650n, 750n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })
    it("#testcase30", async () => {
        const testCases = [700, 699, 701, 702, 703, 698, 704]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase31", async () => {
        const testCases = [698, 699, 701, 700, 702, 703, 704, 705, 706]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase32", async () => {
        const testCases = [700, 700, 700, 700, 700, 700, 700, 700, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([9n, 0n, 0n, 0n])
    })

    it("#testcase33", async () => {
        const testCases = [1, 256, 512, 768, 1024, 700, 1000, 999, 998, 997, 996, 995]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 768n, 512n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase35", async () => {
        const testCases = [700, 699, 698, 697, 696, 701, 702, 703, 704, 705]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase36", async () => {
        const testCases = [600, 800, 750, 850, 650, 750, 650, 850, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 650n, 750n, 1001n])
        expect(returnValue[1]).to.eql([1n, 2n, 2n, 0n])
    })

    it("#testcase37", async () => {
        const testCases = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 600n, 800n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase38", async () => {
        const testCases = [50, 150, 250, 350, 450, 550, 650, 750, 850, 950]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([650n, 750n, 550n, 850n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 1n])
    })

    it("#testcase39", async () => {
        const testCases = [500, 700, 800, 600, 1000, 900, 300, 200, 100, 50, 30, 20]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 600n, 800n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase40", async () => {
        const testCases = [698, 698, 699, 699, 700, 700, 701, 701, 702, 702]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([2n, 2n, 2n, 0n])
    })

    it("#testcase41", async () => {
        const testCases = [700, 500, 700, 300, 700, 100, 700, 50, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([5n, 0n, 0n, 0n])
    })

    it("#testcase42", async () => {
        const testCases = [1, 1000, 256, 512, 768, 700, 650, 800, 750, 900, 850]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 650n, 750n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })
    it("#testcase43", async () => {
        const testCases = [700, 699, 701, 700, 698, 702, 699, 700, 701]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([3n, 0n, 0n, 0n])
    })

    it("#testcase44", async () => {
        const testCases = [256, 512, 768, 700, 700, 700, 256, 512, 768]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([3n, 0n, 0n, 0n])
    })

    it("#testcase45", async () => {
        const testCases = [100, 200, 300, 400, 500, 600, 700, 701, 702]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 701n, 702n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase46", async () => {
        const testCases = [650, 750, 800, 850, 900, 950, 1000, 650, 750, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 650n, 750n, 1001n])
        expect(returnValue[1]).to.eql([1n, 2n, 2n, 0n])
    })

    it("#testcase47", async () => {
        const testCases = [1, 256, 512, 768, 1024, 700, 1000, 999, 998, 997, 996, 995]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 768n, 512n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase48", async () => {
        const testCases = [700, 500, 300, 100, 50, 30, 20, 10, 5, 1]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 500n, 300n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase49", async () => {
        const testCases = [
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,
            25, 26, 27, 28, 29, 30, 700, 701, 702,
        ]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 701n, 702n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase50", async () => {
        const testCases = [700, 699, 701, 698, 702, 703, 704, 705]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase51", async () => {
        const testCases = [699, 698, 700, 701, 702, 700, 699, 700, 701, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([4n, 0n, 0n, 0n])
    })

    it("#testcase52", async () => {
        const testCases = [1000, 999, 998, 997, 996, 995, 994, 993, 992, 991, 990, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 990n, 991n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })
    it("#testcase53", async () => {
        const testCases = [1, 2, 3, 700, 699, 701, 702]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 699n, 701n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase54", async () => {
        const testCases = [100, 300, 500, 700, 900]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 500n, 900n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase55", async () => {
        const testCases = [650, 650, 650, 700, 750, 750, 750]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 650n, 750n, 1001n])
        expect(returnValue[1]).to.eql([1n, 3n, 3n, 0n])
    })

    it("#testcase56", async () => {
        const testCases = [100, 200, 300, 400, 500, 600, 700, 700, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([3n, 0n, 0n, 0n])
    })

    it("#testcase57", async () => {
        const testCases = [990, 991, 992, 993, 994, 995, 996, 997, 998, 999, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 990n, 991n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase58", async () => {
        const testCases = [700, 699, 701, 698, 702, 700, 701, 699, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([3n, 0n, 0n, 0n])
    })

    it("#testcase59", async () => {
        const testCases = [1, 700, 2, 700, 3, 700, 4, 700, 5, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 1001n, 1001n, 1001n])
        expect(returnValue[1]).to.eql([5n, 0n, 0n, 0n])
    })

    it("#testcase60", async () => {
        const testCases = [400, 500, 600, 700, 800, 900, 1000]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 600n, 800n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase61", async () => {
        const testCases = [100, 200, 300, 400, 500, 600, 601, 602, 603, 604, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 604n, 603n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase62", async () => {
        const testCases = [700, 600, 500, 400, 300, 200, 100]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 600n, 500n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase63", async () => {
        const testCases = [999, 1000, 998, 997, 996, 995, 994, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 994n, 995n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })

    it("#testcase64", async () => {
        const testCases = [500, 600, 700, 800, 900, 1000, 700]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([700n, 600n, 800n, 1001n])
        expect(returnValue[1]).to.eql([2n, 1n, 1n, 0n])
    })

    it("#testcase65", async () => {
        const testCases = [1, 2, 3, 4]
        for (const testCase of testCases) {
            await getClosestTickTest.setTicks(testCase)
        }
        const returnValue = await getClosestTickTest.getThreeClosestToSevenHundred()
        expect(returnValue[0]).to.eql([4n, 3n, 2n, 1001n])
        expect(returnValue[1]).to.eql([1n, 1n, 1n, 0n])
    })
})
