// Copyright 2024 justin
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import { ethers, network } from "hardhat"
import { developmentChains } from "../../helper-hardhat-config"
import { UnpackOnApproveData } from "../../typechain-types"

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Unpack OnApprove Data", () => {
          it("test", async () => {
              const UnpackONApproveData = await ethers.getContractFactory("UnpackOnApproveData")
              const unpackONApproveData: UnpackOnApproveData = await UnpackONApproveData.deploy()
              await unpackONApproveData.waitForDeployment()
              console.log(await unpackONApproveData.unpackOnApproveData("0x12"))
              console.log(await unpackONApproveData.unpackOnApproveData("0x1212"))
              console.log(await unpackONApproveData.unpackOnApproveData("0x121212"))
              console.log(await unpackONApproveData.unpackOnApproveData("0x12121212"))
              console.log("-----------------------------------")
              const encoder = ethers.AbiCoder.defaultAbiCoder()
              console.log(encoder.encode(["uint32", "bytes"], ["0x12", "0x12"]))
              const calldata = encoder.encode(["uint32", "bytes"], ["0x12", "0x12"])
              //   console.log(await unpackONApproveData.decodeOnApporveData("0x12"))
              //   console.log(await unpackONApproveData.decodeOnApporveData("0x1212"))
              //   console.log(await unpackONApproveData.decodeOnApporveData("0x121212"))
              console.log(await unpackONApproveData.decodeOnApporveData(calldata))

              console.log(await unpackONApproveData.unpackOnApproveData(calldata))
          })
      })
