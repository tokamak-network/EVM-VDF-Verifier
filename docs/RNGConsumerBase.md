<!--
 Copyright 2024 justin

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
-->

## RNGConsumerBase

Interface for contracts using VRF randomness

\_USAGE

Consumer contracts must inherit from VRFConsumerBase, and can
initialize Coordinator address in their constructor as\_

### OnlyCoordinatorCanFulfill

```solidity
error OnlyCoordinatorCanFulfill(address have, address want)
```

### i_rngCoordinator

```solidity
contract ICRRRNGCoordinator i_rngCoordinator
```

_The RNGCoordinator contract_

### constructor

```solidity
constructor(address rngCoordinator) internal
```

#### Parameters

| Name           | Type    | Description                                |
| -------------- | ------- | ------------------------------------------ |
| rngCoordinator | address | The address of the RNGCoordinator contract |

### receive

```solidity
receive() external payable
```

_receive() external payable is required for contract to receive ETH when getting refunds from Coordinator when consumer overpays the calculatedDirectFundingPrice when requesting randomness_

### requestRandomness

```solidity
function requestRandomness(uint32 _callbackGasLimit) internal returns (uint256, uint256)
```

\_Request Randomness to the Coordinator

1. Calculate the price of the request
2. Request randomness from the Coordinator with sending the calculated price
3. Return the requestId and requestPrice\_

#### Parameters

| Name               | Type   | Description                                                                           |
| ------------------ | ------ | ------------------------------------------------------------------------------------- |
| \_callbackGasLimit | uint32 | The amount of gas for processing of the callback request in your fulfillRandomWords() |

#### Return Values

| Name | Type    | Description                                      |
| ---- | ------- | ------------------------------------------------ |
| [0]  | uint256 | requestId The ID of the request                  |
| [1]  | uint256 | requestPrice The calculated price of the request |

### getCalculatedDirectFundingPrice

```solidity
function getCalculatedDirectFundingPrice(uint32 _callbackGasLimit) external view returns (uint256)
```

#### Parameters

| Name               | Type   | Description                                                                           |
| ------------------ | ------ | ------------------------------------------------------------------------------------- |
| \_callbackGasLimit | uint32 | The amount of gas for processing of the callback request in your fulfillRandomWords() |

#### Return Values

| Name | Type    | Description                         |
| ---- | ------- | ----------------------------------- |
| [0]  | uint256 | The calculated price of the request |

### fulfillRandomWords

```solidity
function fulfillRandomWords(uint256 round, uint256 hashedOmegaVal) internal virtual
```

_Callback function for the Coordinator to call after the request is fulfilled. Override this function in your contract_

#### Parameters

| Name           | Type    | Description                           |
| -------------- | ------- | ------------------------------------- |
| round          | uint256 | The round of the randomness           |
| hashedOmegaVal | uint256 | The hashed value of the random number |

### rawFulfillRandomWords

```solidity
function rawFulfillRandomWords(uint256 round, uint256 hashedOmegaVal) external
```

_Callback function for the Coordinator to call after the request is fulfilled. This function is called by the Coordinator_

#### Parameters

| Name           | Type    | Description                           |
| -------------- | ------- | ------------------------------------- |
| round          | uint256 | The round of the randomness           |
| hashedOmegaVal | uint256 | The hashed value of the random number |
