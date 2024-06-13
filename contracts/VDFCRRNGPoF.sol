// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./libraries/BigNumbers.sol";
import {ReentrancyGuardTransient} from "./utils/ReentrancyGuardTransient.sol";
import {GetL1Fee} from "./utils/GetL1Fee.sol";
import {RNGConsumerBase} from "./RNGConsumerBase.sol";

/**
 * @title VDFCRRNG that performs commit-recover using VDF verification
 * @notice This contract is not audited
 * @author Justin G
 */
contract VDFCRRNGPoF is ReentrancyGuardTransient, GetL1Fee {
    // *** Type declarations
    /**
     * @notice Stages of the contract
     * @notice Recover can be performed in the Finished stages.
     */
    enum Stages {
        Finished,
        Commit,
        Recover
    }

    /**
     *  @notice The struct to store the values of the round
     * - [0]: startTime -> The start time of the round
     * - [1]: commitCounts -> The number of operators who have committed to the round. And this is updated real-time.
     * - [2]: consumer -> The address of the consumer of the round
     * - [3]: commitsString -> The concatenated string of the commits of the operators. This is updated when commit
     * - [4]: omega -> The omega value of the round. This is updated after recovery.
     * - [5]: stage -> The stage of the round. 0 is Recovered or NotStarted, 1 is Commit
     * - [6]: isCompleted -> The flag to check if the round is completed. This is updated after recovery.
     */
    struct ValueAtRound {
        uint256 startTime;
        uint256 requestedTime;
        uint256 commitCounts;
        address consumer;
        bytes commitsString; // concatenated string of commits
        BigNumber omega; // the random number
        Stages stage; // stage of the contract
        bool isCompleted; // the flag to check if the round is completed
        bool isVerified; // omega is verified when this is true
    }

    struct FulfillStatus {
        bool executed;
        bool succeeded;
    }

    /**
     * @dev The struct to store the commit value and the operator address
     * - [0]: commit -> The commit value of the operator
     * - [1]: operatorAddress -> The address of the operator that committed the value
     */
    struct CommitValue {
        BigNumber commit;
        address operatorAddress;
    }

    /**
     * @dev The struct to store the user status at the round
     * - [0]: index -> The key of the commitValue mapping
     * - [1]: committed -> The flag to check if the operator has committed
     */
    struct OperatorStatusAtRound {
        uint256 commitIndex;
        bool committed;
    }

    // *** State variables
    // * internal
    mapping(uint256 round => uint256 ignoredCounts) internal s_ignoredCounts;
    uint256 internal s_minimumDepositAmount;
    /// @dev The flag to check if the setUp values are verified
    bool internal s_initialized;
    uint256 internal s_operatorCount;
    uint256 internal s_penaltyPercentage;
    /// @dev The next round number
    uint256 internal s_nextRound;
    /// @dev The dispute period
    uint256 internal s_disputePeriod;
    /// @dev The mapping of the operators
    mapping(address operators => bool) internal s_operators;
    mapping(uint256 round => address[] committedOperators) internal s_committedOperatorsAtRound;
    /// @dev The mapping of the cost of the round. The cost includes _callbackGasLimit, recoveryGasOverhead, and flatFee
    mapping(uint256 round => uint256 cost) internal s_cost;
    /// @dev The mapping of the values at the round that are used for commit-recover
    mapping(uint256 round => ValueAtRound) internal s_valuesAtRound;
    /// @dev The mapping of the dispute end time at the round
    mapping(uint256 round => uint256 disputeEndTime) internal s_disputeEndTimeAtRound;
    /// @dev The mapping of the leader at the round
    mapping(uint256 round => address) internal s_leaderAtRound;
    /// @dev The mapping of the dispute end time for the operator
    mapping(address operator => uint256 disputeEndTime) internal s_disputeEndTimeForOperator;
    /// @dev The mapping of all the incentive for the operator
    mapping(address operator => uint256 depositAmount) internal s_depositedAmount;
    mapping(uint256 round => FulfillStatus fulfillStatus) internal s_fulfillStatus;
    /// @dev The mapping of the user status at the round
    mapping(uint256 round => mapping(address operator => OperatorStatusAtRound))
        internal s_operatorStatusAtRound;
    /// @dev The mapping of the commit values and the operator address
    mapping(uint256 round => mapping(uint256 index => CommitValue)) internal s_commitValues;
    mapping(uint256 round => uint32 callbackGasLimit) internal s_callbackGasLimit;
    // * internal constant
    /// @dev The duration of the commit stage, 120 seconds
    uint256 internal constant COMMITDURATION = 120;
    // * constants
    uint256 private constant L2_DISPUTERECOVER_TX_GAS = 2881159;
    uint256 private constant L2_DISPUTELEADERSHIP_TX_GAS = 94000;
    /// @dev The constant T, 2^22
    uint256 private constant T = 4194304;
    /// @dev The constant delta, 9
    uint256 private constant DELTA = 9;
    /// @dev The constant PROOFLENGTH, 13, 22 - 9
    uint256 private constant PROOFLENGTH = 13;
    /// @dev The constant EXPDELTABITLEN, 513, expDelta is 2^2^9
    uint256 private constant EXPDELTABITLEN = 513;
    uint256 private constant NBITLEN = 2047;
    uint256 private constant GBITLEN = 2046;
    uint256 private constant HBITLEN = 2044;
    /// @dev 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100) and some arithmetic operations
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
    /// @dev The constant EXPDELTA, 2^2^9
    bytes private constant EXPDELTA =
        hex"000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    bytes private constant NVAL =
        hex"4e502cc741a1a63c4ae0cea62d6eefae5d0395e137075a15b515f0ced5c811334f06272c0f1e85c1bed5445025b039e42d0a949989e2c210c9b68b9af5ada8c0f72fa445ce8f4af9a2e56478c8a6b17a6f1c389445467fe096a4c35262e4b06a6ba67a419bcca5d565e698ead674fca78e5d91fdc18f854b8e43edbca302c5d2d2d47ce49afb7405a4db2e87c98c2fd0718af32c1881e4d6d762f624de2d57663754aedfb02cbcc944812d2f8de4f694c933a1c11ecdbb2e67cf22f410487d598ef3d82190feabf11b5a83a4a058cdda1def94cd244fd30412eb8fa6d467398c21a15af04bf55078d9c73e12e3d0f5939804845b1487fae1fb526fa583e27d71";
    bytes private constant GVAL =
        hex"34bea67f7d10481d71f794f7bf849b91a460b6488fc0def25ff20b19ff63e984e88daef00289931b566f3e25121e8757751e670a04735a78ff255d804caa197aa65da842913a243add64d375e378380e818b330cc9ef2a89753046248e41eff0f87d8ef4f7764e0ed3698b7f87b07805d235627c80e695f3f6095ca6523312a2916456ed011863d5287a33bf603f495071878ebcb06b9303ffa57ac9b5a77121a20fdbe15004010935d65fc39b199692bbadf172ae84a279f63e31997865c133a6cb8ca4e6c29677a46b932c75297347c605b7fe1c292a96d6401f22b4e4ff474e47cfa59ccfef24d99c3777c98bff523f4a587d54ddc395f572bcde1ae93ba1";
    bytes private constant HVAL =
        hex"08d72e28d1cef1b56bc3047d29624445ce203a0c6de5343a5f4873b4017f479e93fc4c3179d4db28dc7e4a6c859469868e50f3347b8736da84cd0995c661b99df90afa21267a8d7588704b9fc249bac3a3087ff1372f8fbfe1f8625c1a42113ebda7fc364a27d8a0c85dab8802f1b3983e867c3b11fedab831b5d6c1d49a906dd5366dd30816c174d6d384295e0229ddb1685eb5c57b9cde512ff50d82bf659eff8b9f3c8d2f0c2737c83eb44463ca23d93e29fa9630c06809b8a6327a29468e19042a7eac025c234be9fe349a19d7b3e5e4acca63f0b4a592b1749a15a1f054689b1809a4b95b27b8513fa1639c98ca9e18113bf36d631944c37459b5575a17";

    // *** Events
    event CommitC(uint256 commitCount, bytes commitVal);
    event Recovered(uint256 round, address recoverer, bytes omega);
    event RandomWordsRequested(uint256 round, address sender);
    event FulfillRandomness(uint256 round, uint256 hashedOmega, bool success, address leader);

    // *** Errors
    error CRRNGCoordinator_InsufficientDepositAmount();
    error CRRNGCoordinator_NotOperator();
    error AlreadyVerified();
    error AlreadyCommitted();
    error NotCommittedParticipant();
    error OmegaAlreadyCompleted();
    error FunctionInvalidAtThisStage();
    error NotVerifiedAtTOne();
    error RecovNotMatchX();
    error NotEnoughParticipated();
    error ShouldNotBeZero();
    error TwoOrMoreCommittedPleaseRecover();
    error NotStartedRound();
    error NotVerified();
    error StillInCommitStage();
    error OmegaNotCompleted();
    error NotLeader();
    error CommitNotStarted();
    error DisputePeriodEnded();
    error InvalidProofLength();
    error InsufficientAmount();
    error SendFailed();
    error DisputePeriodNotEnded();
    error AlreadyLeader();
    error AlreadySucceeded();
    error NotEnoughOperators();
    error DisputePeriodNotEndedOrStarted();
    error SubmittedSameOmega();
    error NotFulfilledExecuted();
    error NotConsumer();
    error TooEarlyToRefund();
    error PreviousRoundNotRecovered();

    // *** Modifiers
    /**
     * @notice The modifier to check if the sender is the operator
     * @dev If the sender is not the operator, revert
     * @dev This modifier is used for the operator-only functions
     */
    modifier onlyOperator() {
        if (!s_operators[msg.sender]) revert CRRNGCoordinator_NotOperator();
        _;
    }

    /**
     * @notice The modifier to check the current stage of the round. * @notice Only updates the stage if the stage has changed. So the consumer that requests the random number updates the stage to Commit. And the operator that recovers the random number updates the stage to Finished.
     * @param round The round number
     * @param stage The stage to check
     */
    modifier checkStage(uint256 round, Stages stage) {
        if (round >= s_nextRound) revert NotStartedRound();
        uint256 _startTime = s_valuesAtRound[round].startTime;
        Stages _stage = s_valuesAtRound[round].stage;
        if (_stage == Stages.Commit && block.timestamp >= _startTime + COMMITDURATION) {
            uint256 _count = s_valuesAtRound[round].commitCounts - s_ignoredCounts[round];
            if (_count > BigNumbers.UINTONE) {
                _stage = Stages.Recover;
            } else if (_count == BigNumbers.UINTZERO) {
                //previous round has to be recovered
                uint256 previousRound;
                unchecked {
                    previousRound = round - BigNumbers.UINTONE;
                }
                if (s_valuesAtRound[previousRound].requestedTime > 0) {
                    if (s_valuesAtRound[previousRound].isCompleted)
                        s_valuesAtRound[round].startTime = block.timestamp;
                    else revert PreviousRoundNotRecovered();
                } else s_valuesAtRound[round].startTime = block.timestamp;
            } else {
                _stage = Stages.Finished;
            }
        }
        if (_stage != stage) revert FunctionInvalidAtThisStage();
        s_valuesAtRound[round].stage = _stage;
        _;
    }

    /**
     * @param v The proof that is array of BigNumber
     * @param x The x BigNumber value
     * @param y The y BigNumber value
     * @notice The function to verify the setUp values
     * @dev The delta is fixed to 9, so the proof length should be 13
     */
    function initialize(BigNumber[] memory v, BigNumber memory x, BigNumber memory y) external {
        if (s_initialized) revert AlreadyVerified();
        require(BigNumbers.eq(BigNumber(GVAL, GBITLEN), x));
        require(BigNumbers.eq(BigNumber(HVAL, HBITLEN), y));
        _verifyRecursiveHalvingProof(v, x, y, BigNumber(NVAL, NBITLEN));
        s_initialized = true;
    }

    /**
     * @param round The round number
     * @param c The commit value in BigNumber
     * @notice The function to commit the value
     * - checks
     * 1. The msg.sender should be the operator
     * 2. The stage should be Commit stage.
     * 3. The commit value should not be zero
     * 4. The operator should not have committed
     * - effects
     * 1. The operator's committed flag is set to true
     * 2. The operator's index is set to the count of the round
     * 3. The commit value is stored in the commitValue mapping
     * 4. The address of the operator is stored in the commitValues mapping
     * 5. The commit value is concatenated to the commitsString
     * 6. The count of the round is incremented
     * 7. The CommitC(_count, c.val) event is emitted
     */
    function commit(
        uint256 round,
        BigNumber memory c
    ) external onlyOperator checkStage(round, Stages.Commit) {
        //check
        if (BigNumbers.isZero(c)) revert ShouldNotBeZero();
        if (s_operatorStatusAtRound[round][msg.sender].committed) revert AlreadyCommitted();
        //effect
        uint256 _count = s_valuesAtRound[round].commitCounts;
        s_operatorStatusAtRound[round][msg.sender].commitIndex = _count;
        s_operatorStatusAtRound[round][msg.sender].committed = true;
        s_commitValues[round][_count].commit = c;
        s_commitValues[round][_count].operatorAddress = msg.sender;
        s_valuesAtRound[round].commitsString = bytes.concat(
            s_valuesAtRound[round].commitsString,
            c.val
        );
        s_valuesAtRound[round].commitCounts = _count = _unchecked_inc(_count);
        s_committedOperatorsAtRound[round].push(msg.sender);
        emit CommitC(_count, c.val);
    }

    function recover(
        uint256 round,
        BigNumber memory y
    ) external onlyOperator checkStage(round, Stages.Recover) nonReentrant {
        // check
        if (!s_operatorStatusAtRound[round][msg.sender].committed) revert NotCommittedParticipant();
        uint256 _commitCounts = s_valuesAtRound[round].commitCounts;
        if (_commitCounts - s_ignoredCounts[round] < BigNumbers.UINTTWO)
            revert NotEnoughParticipated();
        if (s_valuesAtRound[round].isCompleted) revert OmegaAlreadyCompleted();
        // effect
        s_valuesAtRound[round].isCompleted = true;
        s_valuesAtRound[round].omega = y;
        s_valuesAtRound[round].stage = Stages.Finished;
        s_disputeEndTimeAtRound[round] = block.timestamp + s_disputePeriod;
        s_disputeEndTimeForOperator[msg.sender] = block.timestamp + s_disputePeriod;
        s_leaderAtRound[round] = msg.sender;
        emit Recovered(round, msg.sender, y.val);
    }

    function disputeRecover(
        uint256 round,
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y
    ) external onlyOperator {
        if (s_valuesAtRound[round].isVerified) revert AlreadyVerified();
        if (BigNumbers.eq(s_valuesAtRound[round].omega, y)) revert SubmittedSameOmega();
        if (!s_valuesAtRound[round].isCompleted) revert OmegaNotCompleted();
        if (!s_operatorStatusAtRound[round][msg.sender].committed) revert NotCommittedParticipant();
        if (s_disputeEndTimeAtRound[round] < block.timestamp) revert DisputePeriodEnded();
        BigNumber memory _n = BigNumber(NVAL, NBITLEN);
        bytes memory _bStar = _hash(s_valuesAtRound[round].commitsString).val;
        _verifyRecursiveHalvingProof(v, x, y, _n);
        BigNumber memory _recov = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
        uint256 _commitCounts = s_valuesAtRound[round].commitCounts;
        for (uint256 i; i < _commitCounts; i = _unchecked_inc(i)) {
            BigNumber memory _c = s_commitValues[round][i].commit;
            _recov = BigNumbers.modmul(
                _recov,
                BigNumbers.modexp(_c, _hash(_c.val, _bStar), _n),
                _n
            );
        }
        if (!BigNumbers.eq(_recov, x)) revert RecovNotMatchX();
        uint256 _penaltyAmount = _getDisputeRecoverTxGasFee();
        s_valuesAtRound[round].omega = y;
        address previousLeader = s_leaderAtRound[round];
        s_leaderAtRound[round] = msg.sender;
        s_disputeEndTimeForOperator[msg.sender] = s_disputeEndTimeAtRound[round];
        s_disputeEndTimeForOperator[previousLeader] = 0;
        s_valuesAtRound[round].isVerified = true;
        s_depositedAmount[msg.sender] += _penaltyAmount;
        s_depositedAmount[previousLeader] -= _penaltyAmount;
        if (s_depositedAmount[previousLeader] < s_minimumDepositAmount) {
            s_operators[previousLeader] = false;
            unchecked {
                s_operatorCount--;
            }
        }
    }

    function disputeLeadershipAtRound(uint256 round) external onlyOperator {
        // check if committed
        if (!s_operatorStatusAtRound[round][msg.sender].committed) revert NotCommittedParticipant();
        if (s_disputeEndTimeAtRound[round] < block.timestamp)
            revert DisputePeriodNotEndedOrStarted();
        if (!s_fulfillStatus[round].executed) revert NotFulfilledExecuted();
        bytes memory _omega = s_valuesAtRound[round].omega.val;
        address _leader = s_leaderAtRound[round];
        if (_leader == msg.sender) revert AlreadyLeader();
        bytes32 _leaderHash = keccak256(abi.encodePacked(_omega, _leader));
        bytes32 _myHash = keccak256(abi.encodePacked(_omega, msg.sender));
        if (_myHash < _leaderHash) {
            s_leaderAtRound[round] = msg.sender;
            uint256 penalyAmount = _getDisputeLeadershipTxGasFee();
            s_depositedAmount[msg.sender] += (penalyAmount + s_cost[round]);
            s_depositedAmount[_leader] -= (penalyAmount + s_cost[round]);
        } else revert NotLeader();
    }

    function fulfillRandomness(uint256 round) external onlyOperator nonReentrant {
        if (!s_operatorStatusAtRound[round][msg.sender].committed) revert NotCommittedParticipant();
        if (s_disputeEndTimeAtRound[round] >= block.timestamp)
            revert DisputePeriodNotEndedOrStarted();
        if (!s_valuesAtRound[round].isCompleted) revert OmegaNotCompleted();
        s_depositedAmount[msg.sender] += s_cost[round];
        s_leaderAtRound[round] = msg.sender;

        // Do not allow any non-view/non-pure coordinator functions to be called during the consumers callback code via reentrancyLock.
        uint256 hashedOmega = uint256(keccak256(s_valuesAtRound[round].omega.val));
        s_disputeEndTimeAtRound[round] = block.timestamp + s_disputePeriod;
        s_disputeEndTimeForOperator[msg.sender] = block.timestamp + s_disputePeriod;
        bool success = _call(
            s_valuesAtRound[round].consumer,
            abi.encodeWithSelector(
                RNGConsumerBase.rawFulfillRandomWords.selector,
                round,
                hashedOmega
            ),
            s_callbackGasLimit[round]
        );
        s_fulfillStatus[round] = FulfillStatus(true, success);
        emit FulfillRandomness(round, hashedOmega, success, msg.sender);
    }

    function fulfillRandomnessOfFailed(uint256 round) external nonReentrant {
        if (!s_fulfillStatus[round].executed) revert NotFulfilledExecuted();
        if (s_fulfillStatus[round].succeeded) revert AlreadySucceeded();
        // Do not allow any non-view/non-pure coordinator functions to be called during the consumers callback code via reentrancyLock.
        uint256 hashedOmega = uint256(keccak256(s_valuesAtRound[round].omega.val));
        bool success = _call(
            s_valuesAtRound[round].consumer,
            abi.encodeWithSelector(
                RNGConsumerBase.rawFulfillRandomWords.selector,
                round,
                hashedOmega
            ),
            s_callbackGasLimit[round]
        );
        s_fulfillStatus[round].succeeded = success;
        emit FulfillRandomness(round, hashedOmega, success, s_leaderAtRound[round]);
    }

    /**
     * @notice The getter function to get the setup values
     * @return t The constant T
     * @return nBitLen The constant NBITLEN
     * @return gBitLen The constant GBITLEN
     * @return hBitLen The constant HBITLEN
     * @return nVal The constant NVAL
     * @return gVal The constant GVAL
     * @return hVal The constant HVAL
     */
    function getSetUpValues()
        external
        pure
        returns (uint256, uint256, uint256, uint256, bytes memory, bytes memory, bytes memory)
    {
        return (T, NBITLEN, GBITLEN, HBITLEN, NVAL, GVAL, HVAL);
    }

    function _getDisputeLeadershipTxGasFee() private view returns (uint256) {
        return (_getDisputeLeadershipTxL1GasFee() + (L2_DISPUTELEADERSHIP_TX_GAS * tx.gasprice));
    }

    function _getDisputeRecoverTxGasFee() internal view returns (uint256) {
        return
            ((_getDisputeRecoverTxL1GasFee() + (L2_DISPUTERECOVER_TX_GAS * tx.gasprice)) *
                (100 + s_penaltyPercentage)) / 100;
    }

    function _call(
        address target,
        bytes memory data,
        uint256 callbackGasLimit
    ) private returns (bool success) {
        assembly {
            let g := gas()
            // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
            // The gas actually passed to the callee is min(gasAmount, 63//64*gas available)
            // We want to ensure that we revert if gasAmount > 63//64*gas available
            // as we do not want to provide them with less, however that check itself costs
            // gas. GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able to revert
            // if gasAmount > 63//64*gas available.
            if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
                revert(0, 0)
            }
            g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
            // if g - g//64 <= gas
            // we subtract g//64 because of EIP-150
            g := sub(g, div(g, 64))
            if iszero(gt(sub(g, div(g, 64)), callbackGasLimit)) {
                revert(0, 0)
            }
            // solidity calls check that a contract actually exists at the destination, so we do the same
            if iszero(extcodesize(target)) {
                revert(0, 0)
            }
            // call and return whether we succeeded. ignore return data
            // call(gas, addr, value, argsOffset,argsLength,retOffset,retLength)
            success := call(callbackGasLimit, target, 0, add(data, 0x20), mload(data), 0, 0)
        }
        return success;
    }

    function _hash128(
        bytes memory a,
        bytes memory b,
        bytes memory c
    ) private view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(bytes.concat(a, b, c)) >> 128));
    }

    function _hash(bytes memory a, bytes memory b) private view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(bytes.concat(a, b))));
    }

    function _verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n
    ) private view {
        uint i;
        if (v.length != PROOFLENGTH) revert InvalidProofLength();
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
            }
        } while (i < PROOFLENGTH);
        if (!BigNumbers.eq(y, BigNumbers.modexp(x, BigNumber(EXPDELTA, EXPDELTABITLEN), n)))
            revert NotVerifiedAtTOne();
    }

    function _hash(bytes memory strings) private view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(strings)));
    }

    function _unchecked_inc(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + BigNumbers.UINTONE;
        }
    }
}
