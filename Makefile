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

.PHONY: all test clean deploy help install snapshot format anvil

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
			@echo "Usage:"
			@echo " make deploy [ARGS=...]\n	example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install OpenZeppelin/openzeppelin-contracts --no-commit && forge install Cyfrin/foundry-devops --no-commit

# Update Dependencies
update :; forge update

build :; forge build

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif
ifeq ($(findstring --network titan,$(ARGS)),--network titan)
	NETWORK_ARGS := --rpc-url $(TITAN_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif
ifeq ($(findstring --network titansepolia,$(ARGS)),--network titansepolia)
	NETWORK_ARGS := --rpc-url $(TITAN_SEPOLIA_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif
ifeq ($(findstring --network opsepolia,$(ARGS)),--network opsepolia)
	NETWORK_ARGS := --rpc-url $(OP_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(OP_ETHERSCAN_API_KEY) -vvvv
endif
ifeq ($(findstring --network thanossepolia,$(ARGS)), --network thanossepolia)
	NETWORK_ARGS := --rpc-url $(THANOS_SEPOLIA_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --verifier blockscout --verifier-url https://explorer.thanos-sepolia.tokamak.network/api --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

deploy: deploy-rng deploy-consumer-example deploy-random-day

deploy-rng:
	@forge script script/DeployRNGCoordinatorPoF.s.sol:DeployRNGCoordinatorPoF $(NETWORK_ARGS)

deploy-consumer-example:
	@forge script script/DeployConsumerExample.s.sol:DeployConsumerExample $(NETWORK_ARGS)

deploy-random-day:
	@forge script script/DeployRandomDay.s.sol:DeployRandomDay $(NETWORK_ARGS)

five-operators-deposit-anvil:
	@forge script script/Interactions.s.sol:FiveOperatorsDepositAnvil $(NETWORK_ARGS)

start-randomday-event:
	@forge script script/Interactions.s.sol:StartRandomdayEvent $(NETWORK_ARGS)

consumer-example-request:
	@forge script script/Interactions.s.sol:ConsumerExampleRequestWord $(NETWORK_ARGS)

randomday-request:
	@forge script script/Interactions.s.sol:RandomDayRequestWord $(NETWORK_ARGS)

ROUND_ARG := $()

re-request-round:
	@forge script script/Interactions.s.sol:ReRequestRandomWord $(NETWORK_ARGS)

verify-randomday:
	@CONSTRUCTOR_ARGS=$$(cast abi-encode "constructor(address,address)" 0x819B9E61F02Bdb8841e90Af300d5064AD1a30D84 0x2b69EAB0d5e93edcc9F9c0d0acEc7f2F4f273cBb) \
	forge verify-contract --constructor-args CONSTRUCTOR_ARGS --verifier blockscout --verifier-url https://explorer.thanos-sepolia.tokamak.network/api --rpc-url $(THANOS_SEPOLIA_URL) 0xb215a3844823B8f3115dE7c39E00eCF6A7275b57 RandomDay