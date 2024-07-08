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
import axios from "axios"
const subgraph_url = "https://thegraph.titan.tokamak.network/subgraphs/name/drb-subgraph"
const query = `query MyQuery {
  ownershipTransferreds {
    id
  }
  operatorNumberChangeds {
    id
  }
}`
describe("Axios Test", function () {
    it("query", async function () {
        const result = await axios.post(subgraph_url, { query: query })
        console.log(result.data.data)
    })
})
