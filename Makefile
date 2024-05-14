# Copyright 2024 justin
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

-include .env
.PHONY: all settingsForAnvil

settingsForAnvil: deployContracts fiveOperatorDeposits

deployContracts:; npx hardhat deploy --network anvil --reset

fiveOperatorDeposits:; npx hardhat run scripts/2-fiveOperatorsDeposit.ts --network anvil

randomWordsRequestedEvent: startRegistration transferTon participantsRegister requestRandomWord



startRegistration:; npx hardhat run scripts/3-startRegistration.ts --network anvil
transferTon:; npx hardhat run scripts/4-transferTokenToAirdropConsumer.ts --network anvil
participantsRegister:; npx hardhat run scripts/5-participantsRegister.ts --network anvil
requestRandomWord:; npx hardhat run scripts/6-requestRandomWord.ts --network anvil

oneCommit:; npx hardhat run scripts/7-operatorCommits.ts --network anvil

commit10:; npx hardhat run scripts/7-operatorCommit10.ts --network anvil

threeCommit:; npx hardhat run scripts/7-operatorCommits.ts --network anvil; npx hardhat run scripts/7-operatorCommits.ts --network anvil; npx hardhat run scripts/7-operatorCommits.ts --network anvil

recover:; npx hardhat run scripts/8-recoverNewData.ts --network anvil
