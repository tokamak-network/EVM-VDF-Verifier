# Solidity API

## CRRNGCoordinator

This contract is not audited
This contract is for generating random number

### constructor

```solidity
constructor(uint256 disputePeriod, uint256 minimumDepositAmount, uint256 avgRecoveOverhead, uint256 premiumPercentage, uint256 flatFee) public
```

The deployer becomes the owner of the contract

_no zero checks_

#### Parameters

| Name                 | Type    | Description                                            |
| -------------------- | ------- | ------------------------------------------------------ |
| disputePeriod        | uint256 | The dispute period after recovery                      |
| minimumDepositAmount | uint256 | The minimum deposit amount to become operators         |
| avgRecoveOverhead    | uint256 | The average gas cost for recovery of the random number |
| premiumPercentage    | uint256 | The percentage of the premium, will be set to 0        |
| flatFee              | uint256 | The flat fee for the direct funding                    |

### setSettings

```solidity
function setSettings(uint256 disputePeriod, uint256 minimumDepositAmount, uint256 avgRecoveOverhead, uint256 premiumPercentage, uint256 flatFee) external
```

Sets the settings for the contract. The owner will be transfer to mini DAO contract in the future.

1.  only owner can set the settings<br>
2.  no safety checks for values since it is only owner

#### Parameters

| Name                 | Type    | Description                                            |
| -------------------- | ------- | ------------------------------------------------------ |
| disputePeriod        | uint256 | The dispute period after recovery                      |
| minimumDepositAmount | uint256 | The minimum deposit amount to become operators         |
| avgRecoveOverhead    | uint256 | The average gas cost for recovery of the random number |
| premiumPercentage    | uint256 | The percentage of the premium, will be set to 0        |
| flatFee              | uint256 | The flat fee for the direct funding                    |

### requestRandomWordDirectFunding

```solidity
function requestRandomWordDirectFunding(uint32 callbackGasLimit) external payable returns (uint256)
```

Consumer requests a random number, the consumer must send the cost of the request. There is refund logic in the contract to refund the excess amount sent by the consumer, so nonReentrant modifier is used to prevent reentrancy attacks.

-   checks

1. Reverts when reentrancy is detected
2. Reverts when the VDF values are not verified
3. Reverts when the number of operators is less than 2
4. Reverts when the value sent from consumer is less than the \_calculateDirectFundingPrice function result

-   effects

1. Increments the round number
   // \* 2. Sets the start time of the round
2. Sets the stage of the round to Commit, commit starts
3. Sets the msg.sender as the consumer of the round, doesn't check if the consumer is EOA or CA
4. Sets the cost of the round, derived from the \_calculateDirectFundingPrice function
5. Emits a RandomWordsRequested(round, msg.sender) event

-   interactions

1. Refunds the excess amount sent over the result of the \_calculateDirectFundingPrice function, reverts if the refund fails

#### Parameters

| Name             | Type   | Description                                                                                                       |
| ---------------- | ------ | ----------------------------------------------------------------------------------------------------------------- |
| callbackGasLimit | uint32 | Test and adjust this limit based on the processing of the callback request in your fulfillRandomWords() function. |

#### Return Values

| Name | Type    | Description                           |
| ---- | ------- | ------------------------------------- |
| [0]  | uint256 | requestId The round ID of the request |

### reRequestRandomWordAtRound

```solidity
function reRequestRandomWordAtRound(uint256 round) external
```

This function can be called by anyone to restart the commit stage of the round when commits are less than 2 after the commit stage ends

-   checks

1. Reverts when the current block timestamp is less than the start time of the round plus the commit duration, meaning the commit stage is still ongoing
2. Reverts when the number of commits is more than 1, because the recovery stage is already started

-   effects

1. Resets the stage of the round to Commit
2. Resets the start time of the round
3. ReEmits a RandomWordsRequested(round, msg.sender) event

#### Parameters

| Name  | Type    | Description                 |
| ----- | ------- | --------------------------- |
| round | uint256 | The round ID of the request |

### operatorDeposit

```solidity
function operatorDeposit() external payable
```

This function is for anyone to become an operator by depositing the minimum deposit amount, also for operators to increase their deposit amount

-   checks

1. Reverts when the deposit amount of the msg.sender plus the value sent is less than the minimum deposit amount

-   effects

1. Increments the operator count when the msg.sender was not an operator before
2. Sets the operator status of the msg.sender to true
3. Increments the deposit amount of the msg.sender

### operatorWithdraw

```solidity
function operatorWithdraw(uint256 amount) external
```

This function is for operators to withdraw their deposit amount, also for operators to decrease their deposit amount

-   checks

1. Reverts when the dispute end time of the operator is more than the current block timestamp, meaning the operator could be in a dispute
2. Reverts when the parameter amount is more than the deposit amount of the operator

-   effects

1. If the deposit amount of the operator minus the amount is less than the minimum deposit amount
   <br>&nbsp;- Sets the operator status of the operator to false
   <br>&nbsp;- Decrements the operator count
2. Decrements the deposit amount of the operator

-   interactions

1. Sends the amount to the operator, reverts if the send fails

#### Parameters

| Name   | Type    | Description            |
| ------ | ------- | ---------------------- |
| amount | uint256 | The amount to withdraw |

### disputeLeadershipAtRound

```solidity
function disputeLeadershipAtRound(uint256 round) external
```

This function is for operators who have committed to the round to dispute the leadership of the round

-   checks

1. Reverts when the operator has not committed to the round
2. Reverts when the dispute end time of the round is less than the current block timestamp, meaning the dispute period has ended
3. Reverts when the round is not completed, meaning the recovery stage is not ended
4. Reverts when the msg.sender is already the leader
5. Reverts when the keccak256(omega, msg.sender) is greater than the keccak256(omega, previousLeader)

-   effects

1. Resets the leader of the round to the msg.sender
2. Sets the dispute end time of the operator to the dispute end time of the round, meaning the operator can't withdraw the deposit amount until the dispute period ends
3. Increments the incentive of the msg.sender by the cost of the round
4. Decrements the incentive of the previous leader by the cost of the round

#### Parameters

| Name  | Type    | Description                 |
| ----- | ------- | --------------------------- |
| round | uint256 | The round ID of the request |

### estimateDirectFundingPrice

```solidity
function estimateDirectFundingPrice(uint32 _callbackGasLimit, uint256 gasPrice) external view returns (uint256)
```

This function is for the consumer to estimate the cost of the direct funding

1. returns cost = (((gasPrice _ (\_callbackGasLimit + s_avgRecoveOverhead)) _ (s_premiumPercentage + 100)) / 100) + s_flatFee;

#### Parameters

| Name               | Type    | Description                                                                                           |
| ------------------ | ------- | ----------------------------------------------------------------------------------------------------- |
| \_callbackGasLimit | uint32  | The gas limit for the processing of the callback request in consumer's fulfillRandomWords() function. |
| gasPrice           | uint256 | The expected gas price for the callback transaction.                                                  |

#### Return Values

| Name | Type    | Description                                                 |
| ---- | ------- | ----------------------------------------------------------- |
| [0]  | uint256 | calculatedDirectFundingPrice The cost of the direct funding |

### calculateDirectFundingPrice

```solidity
function calculateDirectFundingPrice(uint32 _callbackGasLimit) external view returns (uint256)
```

This function is for the consumer to calculate the cost of the direct funding with the current gas price on-chain

1. returns cost = (((tx.gasprice _ (\_callbackGasLimit + s_avgRecoveOverhead)) _ (s_premiumPercentage + 100)) / 100) + s_flatFee;

#### Parameters

| Name               | Type   | Description                                                                                           |
| ------------------ | ------ | ----------------------------------------------------------------------------------------------------- |
| \_callbackGasLimit | uint32 | The gas limit for the processing of the callback request in consumer's fulfillRandomWords() function. |

#### Return Values

| Name | Type    | Description                                                 |
| ---- | ------- | ----------------------------------------------------------- |
| [0]  | uint256 | calculatedDirectFundingPrice The cost of the direct funding |

### getDisputeEndTimeAndLeaderAtRound

```solidity
function getDisputeEndTimeAndLeaderAtRound(uint256 round) external view returns (uint256, address)
```

This getter function is for anyone to get the dispute end time and the leader of the round

-   return order

0. dispute end time
1. leader

#### Parameters

| Name  | Type    | Description                 |
| ----- | ------- | --------------------------- |
| round | uint256 | The round ID of the request |

#### Return Values

| Name | Type    | Description                                             |
| ---- | ------- | ------------------------------------------------------- |
| [0]  | uint256 | disputeEndTimeAtRound The dispute end time of the round |
| [1]  | address | leaderAtRound The leader of the round                   |

### getDisputeEndTimeAndIncentiveOfOperator

```solidity
function getDisputeEndTimeAndIncentiveOfOperator(address operator) external view returns (uint256, uint256)
```

This getter function is for anyone to get the dispute end time and all the incentive of the operator

-   return order

0. dispute end time
1. incentive

#### Parameters

| Name     | Type    | Description          |
| -------- | ------- | -------------------- |
| operator | address | The operator address |

#### Return Values

| Name | Type    | Description                                                      |
| ---- | ------- | ---------------------------------------------------------------- |
| [0]  | uint256 | s_disputeEndTimeForOperator The dispute end time of the operator |
| [1]  | uint256 | s_incentiveForOperator The all incentive of the operator         |

### getCostAtRound

```solidity
function getCostAtRound(uint256 round) external view returns (uint256)
```

This getter function is for anyone to get the cost of the round

#### Parameters

| Name  | Type    | Description                 |
| ----- | ------- | --------------------------- |
| round | uint256 | The round ID of the request |

#### Return Values

| Name | Type    | Description                                                                                                                                 |
| ---- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| [0]  | uint256 | costOfRound The cost of the round. The cost includes the \_callbackGasLimit, recovery gas cost, premium, and flat fee. premium is set to 0. |

### getDepositAmount

```solidity
function getDepositAmount(address operator) external view returns (uint256)
```

This getter function is for anyone to get the deposit amount of the operator

#### Parameters

| Name     | Type    | Description          |
| -------- | ------- | -------------------- |
| operator | address | The operator address |

#### Return Values

| Name | Type    | Description                                      |
| ---- | ------- | ------------------------------------------------ |
| [0]  | uint256 | depositAmount The deposit amount of the operator |

### getMinimumDepositAmount

```solidity
function getMinimumDepositAmount() external view returns (uint256)
```

This getter function is for anyone to get the minimum deposit amount to become operators

#### Return Values

| Name | Type    | Description                                                         |
| ---- | ------- | ------------------------------------------------------------------- |
| [0]  | uint256 | minimumDepositAmount The minimum deposit amount to become operators |

### getNextRound

```solidity
function getNextRound() external view returns (uint256)
```

This getter function is for anyone to get the next round ID

#### Return Values

| Name | Type    | Description                 |
| ---- | ------- | --------------------------- |
| [0]  | uint256 | nextRound The next round ID |

### getValuesAtRound

```solidity
function getValuesAtRound(uint256 _round) external view returns (struct VDFCRRNG.ValueAtRound)
```

This getter function is for anyone to get the values of the round that are used for commit and recovery stages

-   [0]: startTime -> The start time of the round
-   [1]:numOfPariticipants -> This is the number of operators who have committed to the round. And this is updated on the recovery stage.
-   [2]: count -> The number of operators who have committed to the round. And this is updated real-time.
-   [3]: consumer -> The address of the consumer of the round
-   [4]: bStar -> The bStar value of the round. This is updated on recovery stage.
-   [5]: commitsString -> The concatenated string of the commits of the operators. This is updated when commit
-   [6]: omega -> The omega value of the round. This is updated after recovery.
-   [7]: stage -> The stage of the round. 0 is Recovered or NotStarted, 1 is Commit
-   [8]: isRecovered -> The flag to check if the round is completed. This is updated after recovery.

#### Parameters

| Name    | Type    | Description                 |
| ------- | ------- | --------------------------- |
| \_round | uint256 | The round ID of the request |

#### Return Values

| Name | Type                         | Description                                                                                                   |
| ---- | ---------------------------- | ------------------------------------------------------------------------------------------------------------- |
| [0]  | struct VDFCRRNG.ValueAtRound | The values of the round that are used for commit and recovery stages. The return value is struct ValueAtRound |

### getUserStatusAtRound

```solidity
function getUserStatusAtRound(address _operator, uint256 _round) external view returns (struct VDFCRRNG.OperatorStatusAtRound)
```

This getter function is for anyone to get the status of the operator at the round

-   [0]: index -> The index of the commitValue array of the operator
-   [1]: committed -> The flag to check if the operator has committed to the round

#### Parameters

| Name       | Type    | Description                 |
| ---------- | ------- | --------------------------- |
| \_operator | address | The operator address        |
| \_round    | uint256 | The round ID of the request |

#### Return Values

| Name | Type                                  | Description                                                                           |
| ---- | ------------------------------------- | ------------------------------------------------------------------------------------- |
| [0]  | struct VDFCRRNG.OperatorStatusAtRound | The status of the operator at the round. The return value is struct UserStatusAtRound |

### getCommitValue

```solidity
function getCommitValue(uint256 _round, uint256 _index) external view returns (struct VDFCRRNG.CommitValue)
```

This getter function is for anyone to get the commit value and the operator address of the round

-   [0]: commit -> The commit value of the operator
-   [2]: operator -> The operator address

#### Parameters

| Name    | Type    | Description                 |
| ------- | ------- | --------------------------- |
| \_round | uint256 | The round ID of the request |
| \_index | uint256 |                             |

#### Return Values

| Name | Type                        | Description                                                                                    |
| ---- | --------------------------- | ---------------------------------------------------------------------------------------------- |
| [0]  | struct VDFCRRNG.CommitValue | The commit value and the operator address of the round. The return value is struct CommitValue |

### \_calculateDirectFundingPrice

```solidity
function _calculateDirectFundingPrice(uint32 _callbackGasLimit, uint256 gasPrice) internal view returns (uint256)
```

This function is for the contract to calculate the cost of the direct funding

-   returns cost = (((gasPrice _ (\_callbackGasLimit + s_avgRecoveOverhead)) _ (s_premiumPercentage + 100)) / 100) + s_flatFee;

#### Parameters

| Name               | Type    | Description                                                                                           |
| ------------------ | ------- | ----------------------------------------------------------------------------------------------------- |
| \_callbackGasLimit | uint32  | The gas limit for the processing of the callback request in consumer's fulfillRandomWords() function. |
| gasPrice           | uint256 | The gas price for the callback transaction.                                                           |

#### Return Values

| Name | Type    | Description                                                 |
| ---- | ------- | ----------------------------------------------------------- |
| [0]  | uint256 | calculatedDirectFundingPrice The cost of the direct funding |

## VDFCRRNG

This contract is not audited

### Stages

Stages of the contract
Recover can be performed in the Finished stages.

```solidity
enum Stages {
  Finished,
  Commit
}
```

### ValueAtRound

@notice The struct to store the values of the round

-   [0]: startTime -> The start time of the round
-   [1]: commitCounts -> The number of operators who have committed to the round. And this is updated real-time.
-   [2]: consumer -> The address of the consumer of the round
-   [3]: commitsString -> The concatenated string of the commits of the operators. This is updated when commit
-   [4]: omega -> The omega value of the round. This is updated after recovery.
-   [5]: stage -> The stage of the round. 0 is Recovered or NotStarted, 1 is Commit
-   [6]: isRecovered -> The flag to check if the round is completed. This is updated after recovery.

```solidity
struct ValueAtRound {
  uint256 startTime;
  uint256 commitCounts;
  address consumer;
  bytes commitsString;
  struct BigNumber omega;
  enum VDFCRRNG.Stages stage;
  bool isRecovered;
}
```

### CommitValue

\_The struct to store the commit value and the operator address

-   [0]: commit -> The commit value of the operator
-   [1]: operatorAddress -> The address of the operator that committed the value\_

```solidity
struct CommitValue {
  struct BigNumber commit;
  address operatorAddress;
}
```

### OperatorStatusAtRound

\_The struct to store the user status at the round

-   [0]: index -> The key of the commitValue mapping
-   [1]: committed -> The flag to check if the operator has committed\_

```solidity
struct OperatorStatusAtRound {
  uint256 commitIndex;
  bool committed;
}
```

### s_initialized

```solidity
bool s_initialized
```

_The flag to check if the setUp values are verified_

### s_nextRound

```solidity
uint256 s_nextRound
```

_The next round number_

### s_disputePeriod

```solidity
uint256 s_disputePeriod
```

_The dispute period_

### s_isOperators

```solidity
mapping(address => bool) s_isOperators
```

_The mapping of the operators_

### s_cost

```solidity
mapping(uint256 => uint256) s_cost
```

_The mapping of the cost of the round. The cost includes \_callbackGasLimit, recoveryGasOverhead, and flatFee_

### s_valuesAtRound

```solidity
mapping(uint256 => struct VDFCRRNG.ValueAtRound) s_valuesAtRound
```

_The mapping of the values at the round that are used for commit-recover_

### s_disputeEndTimeAtRound

```solidity
mapping(uint256 => uint256) s_disputeEndTimeAtRound
```

_The mapping of the dispute end time at the round_

### s_leaderAtRound

```solidity
mapping(uint256 => address) s_leaderAtRound
```

_The mapping of the leader at the round_

### s_disputeEndTimeForOperator

```solidity
mapping(address => uint256) s_disputeEndTimeForOperator
```

_The mapping of the dispute end time for the operator_

### s_incentiveForOperator

```solidity
mapping(address => uint256) s_incentiveForOperator
```

_The mapping of all the incentive for the operator_

### s_operatorStatusAtRound

```solidity
mapping(uint256 => mapping(address => struct VDFCRRNG.OperatorStatusAtRound)) s_operatorStatusAtRound
```

_The mapping of the user status at the round_

### s_commitValues

```solidity
mapping(uint256 => mapping(uint256 => struct VDFCRRNG.CommitValue)) s_commitValues
```

_The mapping of the commit values and the operator address_

### COMMITDURATION

```solidity
uint256 COMMITDURATION
```

_The duration of the commit stage, 120 seconds_

### CommitC

```solidity
event CommitC(uint256 commitCount, bytes commitVal)
```

### Recovered

```solidity
event Recovered(uint256 round, bytes recov, bytes omega, bool success)
```

### RandomWordsRequested

```solidity
event RandomWordsRequested(uint256 round, address sender)
```

### CalculateOmega

```solidity
event CalculateOmega(uint256 round, bytes omega)
```

### CRRNGCoordinator_InsufficientDepositAmount

```solidity
error CRRNGCoordinator_InsufficientDepositAmount()
```

### CRRNGCoordinator_NotOperator

```solidity
error CRRNGCoordinator_NotOperator()
```

### AlreadyVerified

```solidity
error AlreadyVerified()
```

### AlreadyCommitted

```solidity
error AlreadyCommitted()
```

### NotCommittedParticipant

```solidity
error NotCommittedParticipant()
```

### OmegaAlreadyCompleted

```solidity
error OmegaAlreadyCompleted()
```

### FunctionInvalidAtThisStage

```solidity
error FunctionInvalidAtThisStage()
```

### NotVerifiedAtTOne

```solidity
error NotVerifiedAtTOne()
```

### RecovNotMatchX

```solidity
error RecovNotMatchX()
```

### NotEnoughParticipated

```solidity
error NotEnoughParticipated()
```

### ShouldNotBeZero

```solidity
error ShouldNotBeZero()
```

### TOneNotAtLast

```solidity
error TOneNotAtLast()
```

### InvalidProofsLength

```solidity
error InvalidProofsLength()
```

### TwoOrMoreCommittedPleaseRecover

```solidity
error TwoOrMoreCommittedPleaseRecover()
```

### NotStartedRound

```solidity
error NotStartedRound()
```

### NotVerified

```solidity
error NotVerified()
```

### StillInCommitPhase

```solidity
error StillInCommitPhase()
```

### OmegaNotCompleted

```solidity
error OmegaNotCompleted()
```

### NotLeader

```solidity
error NotLeader()
```

### DisputePeriodEnded

```solidity
error DisputePeriodEnded()
```

### InvalidProofLength

```solidity
error InvalidProofLength()
```

### InsufficientAmount

```solidity
error InsufficientAmount()
```

### SendFailed

```solidity
error SendFailed()
```

### DisputePeriodNotEnded

```solidity
error DisputePeriodNotEnded()
```

### AlreadyLeader

```solidity
error AlreadyLeader()
```

### NotEnoughOperators

```solidity
error NotEnoughOperators()
```

### XPrimeNotEqualAtIndex

```solidity
error XPrimeNotEqualAtIndex(uint256 index)
```

### YPrimeNotEqualAtIndex

```solidity
error YPrimeNotEqualAtIndex(uint256 index)
```

### onlyOperator

```solidity
modifier onlyOperator()
```

The modifier to check if the sender is the operator

_If the sender is not the operator, revert
This modifier is used for the operator-only functions_

### checkStage

```solidity
modifier checkStage(uint256 round, enum VDFCRRNG.Stages stage)
```

The modifier to check the current stage of the round. \* @notice Only updates the stage if the stage has changed. So the consumer that requests the random number updates the stage to Commit. And the operator that recovers the random number updates the stage to Finished.

#### Parameters

| Name  | Type                 | Description        |
| ----- | -------------------- | ------------------ |
| round | uint256              | The round number   |
| stage | enum VDFCRRNG.Stages | The stage to check |

### checkRecoverStage

```solidity
modifier checkRecoverStage(uint256 round)
```

_The modifier to check the recover stage of the round._

#### Parameters

| Name  | Type    | Description      |
| ----- | ------- | ---------------- |
| round | uint256 | The round number |

### constructor

```solidity
constructor(uint256 disputePeriod) public
```

The constructor of the contract

_The dispute period is set to s_disputePeriod_

#### Parameters

| Name          | Type    | Description        |
| ------------- | ------- | ------------------ |
| disputePeriod | uint256 | The dispute period |

### initialize

```solidity
function initialize(struct BigNumber[] v, struct BigNumber x, struct BigNumber y) external
```

The function to verify the setUp values

_The delta is fixed to 9, so the proof length should be 13_

#### Parameters

| Name | Type               | Description                          |
| ---- | ------------------ | ------------------------------------ |
| v    | struct BigNumber[] | The proof that is array of BigNumber |
| x    | struct BigNumber   | The x BigNumber value                |
| y    | struct BigNumber   | The y BigNumber value                |

### commit

```solidity
function commit(uint256 round, struct BigNumber c) external
```

The function to commit the value

-   checks

1. The msg.sender should be the operator
2. The stage should be Commit stage.
3. The commit value should not be zero
4. The operator should not have committed

-   effects

1. The operator's committed flag is set to true
2. The operator's index is set to the count of the round
3. The commit value is stored in the commitValue mapping
4. The address of the operator is stored in the commitValues mapping
5. The commit value is concatenated to the commitsString
6. The count of the round is incremented
7. The CommitC(\_count, c.val) event is emitted

#### Parameters

| Name  | Type             | Description                   |
| ----- | ---------------- | ----------------------------- |
| round | uint256          | The round number              |
| c     | struct BigNumber | The commit value in BigNumber |

### recover

```solidity
function recover(uint256 round, struct BigNumber[] v, struct BigNumber x, struct BigNumber y) external
```

The function to recover the value and call fulfillRandomwords to the consumer contract

-   checks

1. The msg.sender should be the operator
2. The stage should be Finished stage, which means the recovery stage
3. NonReentrant
4. The operator should have committed
5. The round should have at least 2 participants
6. The round should not have been completed
7. Verify recursive halving proof
8. The calculated recov value should be equal to x

-   effects

1. The round is set to completed
2. The omega value is set to y
3. The stage is set to Finished
4. The dispute end time of this round is set to the current time + dispute period
5. The dispute end time of the operator is set to the current time + dispute period
6. The incentive of the operator is increased by the cost of the round. The cost includes \_callbackGasLimit, recoveryGasOverhead, and flatFee
7. The operator is set to the leader of the round

-   interaction

1. Call the consumer contract's fulfillRandomWords function and emit Recovered(round, x.val, y.val, success) event. The success is true if the call is successful.

#### Parameters

| Name  | Type               | Description                          |
| ----- | ------------------ | ------------------------------------ |
| round | uint256            | The round number                     |
| v     | struct BigNumber[] | The proof that is array of BigNumber |
| x     | struct BigNumber   | The x BigNumber value                |
| y     | struct BigNumber   | The y BigNumber value                |

### getSetUpValues

```solidity
function getSetUpValues() external pure returns (uint256, uint256, uint256, uint256, bytes, bytes, bytes)
```

The getter function to get the setup values

#### Return Values

| Name | Type    | Description                  |
| ---- | ------- | ---------------------------- |
| [0]  | uint256 | t The constant T             |
| [1]  | uint256 | nBitLen The constant NBITLEN |
| [2]  | uint256 | gBitLen The constant GBITLEN |
| [3]  | uint256 | hBitLen The constant HBITLEN |
| [4]  | bytes   | nVal The constant NVAL       |
| [5]  | bytes   | gVal The constant GVAL       |
| [6]  | bytes   | hVal The constant HVAL       |

## ICRRRNGCoordinator

This contract is for generating random number

1. Finished: round not Started | recover the random number
2. Commit: participants commit their value

### requestRandomWordDirectFunding

```solidity
function requestRandomWordDirectFunding(uint32 _callbackGasLimit) external payable returns (uint256)
```

### calculateDirectFundingPrice

```solidity
function calculateDirectFundingPrice(uint32 _callbackGasLimit) external view returns (uint256)
```

## BigNumber

```solidity
struct BigNumber {
  bytes val;
  uint256 bitlen;
}
```

## BigNumbers

BigNumbers library for Solidity.

### BigNumbers\_\_ShouldNotBeZero

```solidity
error BigNumbers__ShouldNotBeZero()
```

### BYTESZERO

```solidity
bytes BYTESZERO
```

the value for number 0 of a BigNumber instance.

### BYTESONE

```solidity
bytes BYTESONE
```

the value for number 1 of a BigNumber instance.

### BYTESTWO

```solidity
bytes BYTESTWO
```

the value for number 2 of a BigNumber instance.

### UINTZERO

```solidity
uint256 UINTZERO
```

### UINTONE

```solidity
uint256 UINTONE
```

### UINTTWO

```solidity
uint256 UINTTWO
```

### UINT32

```solidity
uint256 UINT32
```

### INTZERO

```solidity
int256 INTZERO
```

### INTONE

```solidity
int256 INTONE
```

### INTMINUSONE

```solidity
int256 INTMINUSONE
```

### eq

```solidity
function eq(struct BigNumber a, struct BigNumber b) internal pure returns (bool)
```

BigNumber equality

_eq: returns true if a==b. sign always considered._

#### Parameters

| Name | Type             | Description |
| ---- | ---------------- | ----------- |
| a    | struct BigNumber | BigNumber   |
| b    | struct BigNumber | BigNumber   |

#### Return Values

| Name | Type | Description    |
| ---- | ---- | -------------- |
| [0]  | bool | boolean result |

### init

```solidity
function init(bytes val) internal view returns (struct BigNumber)
```

initialize a BN instance
@dev wrapper function for \_init. initializes from bytes value.

@param val BN value. may be of any size.
@return BigNumber instance

### isZero

```solidity
function isZero(struct BigNumber a) internal pure returns (bool)
```

BigNumber full zero check

_isZero: checks if the BigNumber is in the default zero format for BNs (ie. the result from zero())._

#### Parameters

| Name | Type             | Description |
| ---- | ---------------- | ----------- |
| a    | struct BigNumber | BigNumber   |

#### Return Values

| Name | Type | Description     |
| ---- | ---- | --------------- |
| [0]  | bool | boolean result. |

### mod

```solidity
function mod(struct BigNumber a, struct BigNumber n) internal view returns (struct BigNumber)
```

BigNumber modulus: a % n.

_mod: takes a BigNumber and modulus BigNumber (a,n), and calculates a % n.
modexp precompile is used to achieve a % n; an exponent of value '1' is passed._

#### Parameters

| Name | Type             | Description       |
| ---- | ---------------- | ----------------- |
| a    | struct BigNumber | BigNumber         |
| n    | struct BigNumber | modulus BigNumber |

#### Return Values

| Name | Type             | Description        |
| ---- | ---------------- | ------------------ |
| [0]  | struct BigNumber | r result BigNumber |

### modinvVerify

```solidity
function modinvVerify(struct BigNumber a, struct BigNumber n, struct BigNumber r) internal view returns (bool)
```

modular inverse verification: Verifies that (a\*r) % n == 1.

_modinvVerify: Takes BigNumbers for base, modulus, and result, verifies (base\*result)%modulus==1, and returns result.
Similar to division, it's far cheaper to verify an inverse operation on-chain than it is to calculate it, so we allow the user to pass their own result._

#### Parameters

| Name | Type             | Description       |
| ---- | ---------------- | ----------------- |
| a    | struct BigNumber | base BigNumber    |
| n    | struct BigNumber | modulus BigNumber |
| r    | struct BigNumber | result BigNumber  |

#### Return Values

| Name | Type | Description    |
| ---- | ---- | -------------- |
| [0]  | bool | boolean result |

### modexp

```solidity
function modexp(struct BigNumber a, struct BigNumber e, struct BigNumber n) internal view returns (struct BigNumber)
```

BigNumber modular exponentiation: a^e mod n.

_modexp: takes base, exponent, and modulus, internally computes base^exponent % modulus using the precompile at address 0x5, and creates new BigNumber.
this function is overloaded: it assumes the exponent is positive. if not, the other method is used, whereby the inverse of the base is also passed._

#### Parameters

| Name | Type             | Description        |
| ---- | ---------------- | ------------------ |
| a    | struct BigNumber | base BigNumber     |
| e    | struct BigNumber | exponent BigNumber |
| n    | struct BigNumber | modulus BigNumber  |

#### Return Values

| Name | Type             | Description      |
| ---- | ---------------- | ---------------- |
| [0]  | struct BigNumber | result BigNumber |

### modmul

```solidity
function modmul(struct BigNumber a, struct BigNumber b, struct BigNumber n) internal view returns (struct BigNumber)
```

modular multiplication: (a\*b) % n.

_modmul: Takes BigNumbers for a, b, and modulus, and computes (a\*b) % modulus
We call mul for the two input values, before calling modexp, passing exponent as 1.
Sign is taken care of in sub-functions._

#### Parameters

| Name | Type             | Description       |
| ---- | ---------------- | ----------------- |
| a    | struct BigNumber | BigNumber         |
| b    | struct BigNumber | BigNumber         |
| n    | struct BigNumber | Modulus BigNumber |

#### Return Values

| Name | Type             | Description      |
| ---- | ---------------- | ---------------- |
| [0]  | struct BigNumber | result BigNumber |

### sub

```solidity
function sub(struct BigNumber a, struct BigNumber b) internal pure returns (struct BigNumber r)
```

BigNumber subtraction: a - b.

\_sub: Initially prepare BigNumbers for subtraction operation; internally calls actual addition/subtraction,
depending on inputs.

          This function discovers the sign of the result based on the inputs, and calls the correct operation._

#### Parameters

| Name | Type             | Description |
| ---- | ---------------- | ----------- |
| a    | struct BigNumber | first BN    |
| b    | struct BigNumber | second BN   |

#### Return Values

| Name | Type             | Description                      |
| ---- | ---------------- | -------------------------------- |
| r    | struct BigNumber | result - subtraction of a and b. |

### mul

```solidity
function mul(struct BigNumber a, struct BigNumber b) internal view returns (struct BigNumber r)
```

BigNumber multiplication: a \* b.

_mul: takes two BigNumbers and multiplys them. Order is irrelevant.
multiplication achieved using modexp precompile:
(a \* b) = ((a + b)**2 - (a - b)**2) / 4_

#### Parameters

| Name | Type             | Description |
| ---- | ---------------- | ----------- |
| a    | struct BigNumber | first BN    |
| b    | struct BigNumber | second BN   |

#### Return Values

| Name | Type             | Description                         |
| ---- | ---------------- | ----------------------------------- |
| r    | struct BigNumber | result - multiplication of a and b. |

### isOdd

```solidity
function isOdd(struct BigNumber a) internal pure returns (bool r)
```

BigNumber odd number check

_isOdd: returns 1 if BigNumber value is an odd number and 0 otherwise._

#### Parameters

| Name | Type             | Description |
| ---- | ---------------- | ----------- |
| a    | struct BigNumber | BigNumber   |

#### Return Values

| Name | Type | Description    |
| ---- | ---- | -------------- |
| r    | bool | Boolean result |

### cmp

```solidity
function cmp(struct BigNumber a, struct BigNumber b) internal pure returns (int256)
```

BigNumber comparison

_cmp: Compares BigNumbers a and b. 'signed' parameter indiciates whether to consider the sign of the inputs.
'trigger' is used to decide this -
if both negative, invert the result;
if both positive (or signed==false), trigger has no effect;
if differing signs, we return immediately based on input.
returns -1 on a<b, 0 on a==b, 1 on a>b._

#### Parameters

| Name | Type             | Description |
| ---- | ---------------- | ----------- |
| a    | struct BigNumber | BigNumber   |
| b    | struct BigNumber | BigNumber   |

#### Return Values

| Name | Type   | Description   |
| ---- | ------ | ------------- |
| [0]  | int256 | int256 result |

### add

```solidity
function add(struct BigNumber a, struct BigNumber b) internal pure returns (struct BigNumber r)
```

BigNumber addition: a + b.

_add: Initially prepare BigNumbers for addition operation; internally calls actual addition/subtraction,
depending on inputs.
In order to do correct addition or subtraction we have to handle the sign.
This function discovers the sign of the result based on the inputs, and calls the correct operation._

#### Parameters

| Name | Type             | Description |
| ---- | ---------------- | ----------- |
| a    | struct BigNumber | first BN    |
| b    | struct BigNumber | second BN   |

#### Return Values

| Name | Type             | Description                   |
| ---- | ---------------- | ----------------------------- |
| r    | struct BigNumber | result - addition of a and b. |

### \_shr

```solidity
function _shr(struct BigNumber bn, uint256 bits) internal view returns (struct BigNumber)
```

right shift BigNumber memory 'dividend' by 'bits' bits.

\__shr: Shifts input value in-place, ie. does not create new memory. shr function does this.
right shift does not necessarily have to copy into a new memory location. where the user wishes the modify
the existing value they have in place, they can use this._

#### Parameters

| Name | Type             | Description                |
| ---- | ---------------- | -------------------------- |
| bn   | struct BigNumber | value to shift             |
| bits | uint256          | amount of bits to shift by |

#### Return Values

| Name | Type             | Description |
| ---- | ---------------- | ----------- |
| [0]  | struct BigNumber | r result    |

### \_powModulus

```solidity
function _powModulus(struct BigNumber a, uint256 e) internal pure returns (struct BigNumber)
```

gets the modulus value necessary for calculating exponetiation.

\__powModulus: we must pass the minimum modulus value which would return JUST the a^b part of the calculation
in modexp. the rationale here is:
if 'a' has n bits, then a^e has at most n\*e bits.
using this modulus in exponetiation will result in simply a^e.
therefore the value may be many words long.
This is done by: - storing total modulus byte length - storing first word of modulus with correct bit set - updating the free memory pointer to come after total length._

#### Parameters

| Name | Type             | Description      |
| ---- | ---------------- | ---------------- |
| a    | struct BigNumber | BigNumber base   |
| e    | uint256          | uint256 exponent |

#### Return Values

| Name | Type             | Description              |
| ---- | ---------------- | ------------------------ |
| [0]  | struct BigNumber | BigNumber modulus result |

### \_modexp

```solidity
function _modexp(bytes _b, bytes _e, bytes _m) internal view returns (bytes r)
```

Modular Exponentiation: Takes bytes values for base, exp, mod and calls precompile for (base^exp)%^mod

_modexp: Wrapper for built-in modexp (contract 0x5) as described here:
https://github.com/ethereum/EIPs/pull/198_

#### Parameters

| Name | Type  | Description        |
| ---- | ----- | ------------------ |
| \_b  | bytes | bytes base         |
| \_e  | bytes | bytes base_inverse |
| \_m  | bytes | bytes exponent     |

### \_shl

```solidity
function _shl(struct BigNumber bn, uint256 bits) internal view returns (struct BigNumber r)
```

## ReentrancyGuardTransient

\_Variant of {ReentrancyGuard} that uses transient storage.

NOTE: This variant only works on networks where EIP-1153 is available.\_

### ReentrancyGuardReentrantCall

```solidity
error ReentrancyGuardReentrantCall()
```

_Unauthorized reentrant call._

### nonReentrant

```solidity
modifier nonReentrant()
```

_Prevents a contract from calling itself, directly or indirectly.
Calling a `nonReentrant` function from another `nonReentrant`
function is not supported. It is possible to prevent this from happening
by making the `nonReentrant` function external, and making it call a
`private` function that does the actual work._

### \_reentrancyGuardEntered

```solidity
function _reentrancyGuardEntered() internal view returns (bool)
```

_Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
`nonReentrant` function in the call stack._

## StorageSlot

\_Library for reading and writing primitive types to specific storage slots.

Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
This library helps with reading and writing to such slots without the need for inline assembly.

The functions in this library return Slot structs that contain a `value` member that can be used to read or write.

Example usage to set ERC-1967 implementation slot:

```solidity
contract ERC1967 {
    // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address newImplementation) internal {
        require(newImplementation.code.length > 0);
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }
}
```

Since version 5.1, this library also support writing and reading value types to and from transient storage.

-   Example using transient storage:

```solidity
contract Lock {
    // Define the slot. Alternatively, use the SlotDerivation library to derive the slot.
    bytes32 internal constant _LOCK_SLOT = 0xf4678858b2b588224636b8522b729e7722d32fc491da849ed75b3fdf3c84f542;

    modifier locked() {
        require(!_LOCK_SLOT.asBoolean().tload());

        _LOCK_SLOT.asBoolean().tstore(true);
        _;
        _LOCK_SLOT.asBoolean().tstore(false);
    }
}
```

TIP: Consider using this library along with {SlotDerivation}.\_

### AddressSlot

```solidity
struct AddressSlot {
  address value;
}
```

### BooleanSlot

```solidity
struct BooleanSlot {
  bool value;
}
```

### Bytes32Slot

```solidity
struct Bytes32Slot {
  bytes32 value;
}
```

### Uint256Slot

```solidity
struct Uint256Slot {
  uint256 value;
}
```

### Int256Slot

```solidity
struct Int256Slot {
  int256 value;
}
```

### StringSlot

```solidity
struct StringSlot {
  string value;
}
```

### BytesSlot

```solidity
struct BytesSlot {
  bytes value;
}
```

### getAddressSlot

```solidity
function getAddressSlot(bytes32 slot) internal pure returns (struct StorageSlot.AddressSlot r)
```

_Returns an `AddressSlot` with member `value` located at `slot`._

### getBooleanSlot

```solidity
function getBooleanSlot(bytes32 slot) internal pure returns (struct StorageSlot.BooleanSlot r)
```

_Returns an `BooleanSlot` with member `value` located at `slot`._

### getBytes32Slot

```solidity
function getBytes32Slot(bytes32 slot) internal pure returns (struct StorageSlot.Bytes32Slot r)
```

_Returns an `Bytes32Slot` with member `value` located at `slot`._

### getUint256Slot

```solidity
function getUint256Slot(bytes32 slot) internal pure returns (struct StorageSlot.Uint256Slot r)
```

_Returns an `Uint256Slot` with member `value` located at `slot`._

### getInt256Slot

```solidity
function getInt256Slot(bytes32 slot) internal pure returns (struct StorageSlot.Int256Slot r)
```

_Returns an `Int256Slot` with member `value` located at `slot`._

### getStringSlot

```solidity
function getStringSlot(bytes32 slot) internal pure returns (struct StorageSlot.StringSlot r)
```

_Returns an `StringSlot` with member `value` located at `slot`._

### getStringSlot

```solidity
function getStringSlot(string store) internal pure returns (struct StorageSlot.StringSlot r)
```

_Returns an `StringSlot` representation of the string storage pointer `store`._

### getBytesSlot

```solidity
function getBytesSlot(bytes32 slot) internal pure returns (struct StorageSlot.BytesSlot r)
```

_Returns an `BytesSlot` with member `value` located at `slot`._

### getBytesSlot

```solidity
function getBytesSlot(bytes store) internal pure returns (struct StorageSlot.BytesSlot r)
```

_Returns an `BytesSlot` representation of the bytes storage pointer `store`._

### AddressSlotType

### asAddress

```solidity
function asAddress(bytes32 slot) internal pure returns (StorageSlot.AddressSlotType)
```

_Cast an arbitrary slot to a AddressSlotType._

### BooleanSlotType

### asBoolean

```solidity
function asBoolean(bytes32 slot) internal pure returns (StorageSlot.BooleanSlotType)
```

_Cast an arbitrary slot to a BooleanSlotType._

### Bytes32SlotType

### asBytes32

```solidity
function asBytes32(bytes32 slot) internal pure returns (StorageSlot.Bytes32SlotType)
```

_Cast an arbitrary slot to a Bytes32SlotType._

### Uint256SlotType

### asUint256

```solidity
function asUint256(bytes32 slot) internal pure returns (StorageSlot.Uint256SlotType)
```

_Cast an arbitrary slot to a Uint256SlotType._

### Int256SlotType

### asInt256

```solidity
function asInt256(bytes32 slot) internal pure returns (StorageSlot.Int256SlotType)
```

_Cast an arbitrary slot to a Int256SlotType._

### tload

```solidity
function tload(StorageSlot.AddressSlotType slot) internal view returns (address value)
```

_Load the value held at location `slot` in transient storage._

### tstore

```solidity
function tstore(StorageSlot.AddressSlotType slot, address value) internal
```

_Store `value` at location `slot` in transient storage._

### tload

```solidity
function tload(StorageSlot.BooleanSlotType slot) internal view returns (bool value)
```

_Load the value held at location `slot` in transient storage._

### tstore

```solidity
function tstore(StorageSlot.BooleanSlotType slot, bool value) internal
```

_Store `value` at location `slot` in transient storage._

### tload

```solidity
function tload(StorageSlot.Bytes32SlotType slot) internal view returns (bytes32 value)
```

_Load the value held at location `slot` in transient storage._

### tstore

```solidity
function tstore(StorageSlot.Bytes32SlotType slot, bytes32 value) internal
```

_Store `value` at location `slot` in transient storage._

### tload

```solidity
function tload(StorageSlot.Uint256SlotType slot) internal view returns (uint256 value)
```

_Load the value held at location `slot` in transient storage._

### tstore

```solidity
function tstore(StorageSlot.Uint256SlotType slot, uint256 value) internal
```

_Store `value` at location `slot` in transient storage._

### tload

```solidity
function tload(StorageSlot.Int256SlotType slot) internal view returns (int256 value)
```

_Load the value held at location `slot` in transient storage._

### tstore

```solidity
function tstore(StorageSlot.Int256SlotType slot, int256 value) internal
```

_Store `value` at location `slot` in transient storage._

## ConsumerExample

### RequestStatus

```solidity
struct RequestStatus {
  bool requested;
  bool fulfilled;
  uint256 randomWord;
}
```

### s_requests

```solidity
mapping(uint256 => struct ConsumerExample.RequestStatus) s_requests
```

### requestIds

```solidity
uint256[] requestIds
```

### requestCount

```solidity
uint256 requestCount
```

### lastRequestId

```solidity
uint256 lastRequestId
```

### CALLBACK_GAS_LIMIT

```solidity
uint32 CALLBACK_GAS_LIMIT
```

### constructor

```solidity
constructor(address coordinator) public
```

### requestRandomWord

```solidity
function requestRandomWord() external payable
```

### fulfillRandomWords

```solidity
function fulfillRandomWords(uint256 requestId, uint256 hashedOmegaVal) internal
```

### getRNGCoordinator

```solidity
function getRNGCoordinator() external view returns (address)
```

### getRequestStatus

```solidity
function getRequestStatus(uint256 _requestId) external view returns (bool, bool, uint256)
```

## TonToken

### constructor

```solidity
constructor() public
```
