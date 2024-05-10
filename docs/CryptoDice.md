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

## CryptoDice

### RoundStatus

```solidity
struct RoundStatus {
  uint256 requestId;
  uint256 totalPrizeAmount;
  uint256 prizeAmountForEachWinner;
  bool registrationStarted;
  bool randNumRequested;
  bool randNumfulfilled;
}
```

### RegistrationInProgress

```solidity
error RegistrationInProgress()
```

### RegistrationNotStarted

```solidity
error RegistrationNotStarted()
```

### RegistrationFinished

```solidity
error RegistrationFinished()
```

### InvalidDiceNum

```solidity
error InvalidDiceNum()
```

### AlreadyRegistered

```solidity
error AlreadyRegistered()
```

### InvalidBlackListLength

```solidity
error InvalidBlackListLength()
```

### RNGRequested

```solidity
error RNGRequested()
```

### NoneParticipated

```solidity
error NoneParticipated()
```

### InsufficientBalance

```solidity
error InsufficientBalance()
```

### NotParticipatedOrBlackListed

```solidity
error NotParticipatedOrBlackListed()
```

### RandNumNotFulfilled

```solidity
error RandNumNotFulfilled()
```

### YouAreNotWinner

```solidity
error YouAreNotWinner()
```

### AlreadyWithdrawn

```solidity
error AlreadyWithdrawn()
```

### AlreadyFulfilled

```solidity
error AlreadyFulfilled()
```

### RegistrationStarted

```solidity
event RegistrationStarted(uint256 diceRound)
```

### Registered

```solidity
event Registered(uint256 diceRound, address participant, uint256 diceNum)
```

### constructor

```solidity
constructor(address rngCoordinator, address airdropToken) public
```

### startRegistration

```solidity
function startRegistration(uint256 registrationDuration, uint256 totalPrizeAmount) external
```

### register

```solidity
function register(uint256 diceNum) external
```

### blackList

```solidity
function blackList(uint256 diceRound, address[] addresses) external
```

### requestRandomWord

```solidity
function requestRandomWord(uint256 round) external payable
```

### withdrawAirdropTokenOnlyOwner

```solidity
function withdrawAirdropTokenOnlyOwner() external
```

### withdrawAirdropToken

```solidity
function withdrawAirdropToken(uint256 round) external
```

### getWithdrawedRounds

```solidity
function getWithdrawedRounds(address participant) external view returns (uint256[])
```

### getDiceNumAtRound

```solidity
function getDiceNumAtRound(uint256 round, address participant) external view returns (uint256)
```

### getParticipatedRounds

```solidity
function getParticipatedRounds(address participant) external view returns (uint256[])
```

### getRoundStatus

```solidity
function getRoundStatus(uint256 round) external view returns (struct CryptoDice.RoundStatus)
```

### getRNGCoordinator

```solidity
function getRNGCoordinator() external view returns (address)
```

### getAirdropTokenAddress

```solidity
function getAirdropTokenAddress() external view returns (address)
```

### getRegistrationTimeAndDuration

```solidity
function getRegistrationTimeAndDuration() external view returns (uint256, uint256)
```

### getNextCryptoDiceRound

```solidity
function getNextCryptoDiceRound() external view returns (uint256)
```

### getRegisteredCount

```solidity
function getRegisteredCount(uint256 round) external view returns (uint256)
```

### getRandNum

```solidity
function getRandNum(uint256 round) external view returns (uint256)
```

### getWinningDiceNum

```solidity
function getWinningDiceNum(uint256 round) external view returns (uint256)
```

### getPrizeAmountForEachWinner

```solidity
function getPrizeAmountForEachWinner(uint256 round) external view returns (uint256)
```

### getDiceNumCount

```solidity
function getDiceNumCount(uint256 round, uint256 diceNum) external view returns (uint256)
```

### fulfillRandomWords

```solidity
function fulfillRandomWords(uint256 requestId, uint256 hashedOmegaVal) internal
```
