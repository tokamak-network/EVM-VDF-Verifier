// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ICRRRNGServiceWrapper} from "./interfaces/ICRRRNGServiceWrapper.sol";
import {ICRRRNGCoordinator} from "./interfaces/ICRRRNGCoordinator.sol";
import "./libraries/BigNumbers.sol";

abstract contract CRRRNGServiceWrapper is ICRRRNGServiceWrapper, ICRRRNGCoordinator {
    // * constant
    uint256 internal constant COMMITDURATION = 120;
    uint256 internal constant COMMITREVEALDURATION = 240;

    // * internal
    bool internal s_reentrancyLock;
    bool internal s_verified;
    uint256 internal s_nextRound;
    mapping(address operators => bool) internal s_operators;
    mapping(address operator => uint256 disputeEndTime) internal s_disputeEndTimeForOperator;
    mapping(address operator => uint256 incentive) internal s_incentiveForOperator;
    mapping(uint256 round => uint256 disputeEndTime) internal s_disputeEndTimeAtRound;
    uint256 internal s_disputePeriod;
    mapping(uint256 round => uint256 cost) internal s_cost;
    mapping(uint256 round => ValueAtRound) internal s_valuesAtRound;
    mapping(uint256 round => address) internal s_leaderAtRound;
    mapping(uint256 round => mapping(uint256 index => CommitRevealValue))
        internal s_commitRevealValues;
    mapping(uint256 round => mapping(address owner => UserAtRound)) internal s_userInfosAtRound;

    // * private
    mapping(address operator => uint256 depositAmount) private s_depositAmount;
    uint256 private s_minimumDepositAmount;
    uint256 private s_avgRecoveOverhead;
    uint256 private s_premiumPercentage;
    uint256 private s_flatFee;

    constructor(
        uint256 disputePeriod,
        uint256 minimumDepositAmount,
        uint256 avgRecoveOverhead,
        uint256 premiumPercentage,
        uint256 flatFee
    ) {
        s_disputePeriod = disputePeriod;
        s_minimumDepositAmount = minimumDepositAmount;
        s_avgRecoveOverhead = avgRecoveOverhead;
        s_premiumPercentage = premiumPercentage;
        s_flatFee = flatFee;
    }

    /* Modifiers */
    modifier nonReentrant() {
        if (s_reentrancyLock) {
            revert ReentrancyGuard();
        }
        _;
    }

    modifier checkStage(uint256 round, Stages stage) {
        if (round >= s_nextRound) revert NotStartedRound();
        uint256 _startTime = s_valuesAtRound[round].startTime;
        Stages _stage = s_valuesAtRound[round].stage;
        if (_stage == Stages.Commit && block.timestamp >= _startTime + COMMITDURATION) {
            uint256 _count = s_valuesAtRound[round].count;
            if (_count > BigNumbers.UINTONE) {
                _stage = Stages.Reveal;
                s_valuesAtRound[round].numOfPariticipants = _count;
                s_valuesAtRound[round].bStar = _hash(s_valuesAtRound[round].commitsString).val;
            } else {
                _stage = Stages.Finished;
            }
        }
        if (_stage == Stages.Reveal && block.timestamp >= _startTime + COMMITREVEALDURATION) {
            _stage = Stages.Finished;
        }
        if (_stage != stage) revert FunctionInvalidAtThisStage();
        s_valuesAtRound[round].stage = _stage;
        _;
    }

    function estimateDirectFundingPrice(
        uint32 _callbackGasLimit,
        uint256 gasPrice
    ) external view returns (uint256) {
        return _calculateDirectFundingPrice(_callbackGasLimit, gasPrice);
    }

    function calculateDirectFundingPrice(
        uint32 _callbackGasLimit
    ) external view override returns (uint256) {
        return _calculateDirectFundingPrice(_callbackGasLimit, tx.gasprice);
    }

    function requestRandomWordDirectFunding(
        uint32 _callbackGasLimit
    ) external payable nonReentrant returns (uint256) {
        if (!s_verified) revert NotVerified();
        uint256 cost = _calculateDirectFundingPrice(_callbackGasLimit, tx.gasprice);
        if (msg.value < cost) revert InsufficientAmount();

        s_reentrancyLock = true;
        bool success = send(msg.sender, gasleft(), msg.value - cost);
        s_reentrancyLock = false;

        if (!success) revert SendFailed();
        uint256 _round = s_nextRound++;
        s_valuesAtRound[_round].startTime = block.timestamp;
        s_valuesAtRound[_round].stage = Stages.Commit;
        s_valuesAtRound[_round].consumer = msg.sender;
        s_cost[_round] = cost;
        emit RandomWordsRequested(_round, msg.sender);
        return _round;
    }

    function reRequestRandomWordAtRound(uint256 round) external checkStage(round, Stages.Finished) {
        // check
        if (block.timestamp < s_valuesAtRound[round].startTime + COMMITDURATION)
            revert StillInCommitStage();
        if (s_valuesAtRound[round].isCompleted) revert OmegaAlreadyCompleted();
        if (s_valuesAtRound[round].numOfPariticipants > BigNumbers.UINTONE)
            revert TwoOrMoreCommittedPleaseRecover();
        s_valuesAtRound[round].stage = Stages.Commit;
        s_valuesAtRound[round].startTime = block.timestamp;
        emit RandomWordsRequested(round, msg.sender);
    }

    function _calculateDirectFundingPrice(
        uint32 _callbackGasLimit,
        uint256 gasPrice
    ) internal view returns (uint256) {
        return
            (((gasPrice * (_callbackGasLimit + s_avgRecoveOverhead)) *
                (s_premiumPercentage + 100)) / 100) + s_flatFee;
    }

    function operatorDeposit() external payable {
        if (s_depositAmount[msg.sender] + msg.value < s_minimumDepositAmount)
            revert InsufficientDepositAmount();
        s_operators[msg.sender] = true;
        unchecked {
            s_depositAmount[msg.sender] += msg.value;
        }
    }

    function operatorWithdraw(uint256 amount) external nonReentrant {
        //uint256 _depositAmount = s_depositAmount[msg.sender];
        if (!s_operators[msg.sender]) revert NotOperator();
        if (s_disputeEndTimeForOperator[msg.sender] > block.timestamp)
            revert DisputePeriodNotEnded();
        if (s_depositAmount[msg.sender] < amount) revert InsufficientDepositAmount();
        if (s_depositAmount[msg.sender] - amount < s_minimumDepositAmount) {
            s_operators[msg.sender] = false;
        }
        s_depositAmount[msg.sender] -= amount;
        s_reentrancyLock = true;
        bool success = send(msg.sender, gasleft(), amount);
        s_reentrancyLock = false;
        if (!success) revert SendFailed();
    }

    function disputeLeadershipAtRound(uint256 round) external {
        // check if committed
        if (!s_userInfosAtRound[round][msg.sender].committed) revert NotCommittedParticipant();
        if (s_disputeEndTimeAtRound[round] < block.timestamp) revert DisputePeriodEnded();
        if (!s_valuesAtRound[round].isCompleted) revert OmegaNotCompleted();
        if (!s_operators[msg.sender]) revert NotOperator();
        bytes memory _omega = s_valuesAtRound[round].omega.val;
        address _leader = s_leaderAtRound[round];
        if (_leader == msg.sender) revert AlreadyLeader();
        bytes32 _leaderHash = keccak256(abi.encodePacked(_omega, _leader));
        bytes32 _myHash = keccak256(abi.encodePacked(_omega, msg.sender));
        if (_myHash < _leaderHash) {
            s_leaderAtRound[round] = msg.sender;
            s_disputeEndTimeForOperator[msg.sender] = s_disputeEndTimeAtRound[round];
            s_incentiveForOperator[msg.sender] += s_cost[round];
            s_incentiveForOperator[_leader] -= s_cost[round];
        } else revert NotLeader();
    }

    function _unchecked_inc(uint256 i) internal pure returns (uint256) {
        unchecked {
            return i + BigNumbers.UINTONE;
        }
    }

    function _hash(bytes memory strings) internal view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(strings)));
    }

    /// @notice Performs a low level call without copying any returndata.
    /// @dev Passes no calldata to the call context.
    /// @param _target   Address to call
    /// @param _gas      Amount of gas to pass to the call
    /// @param _value    Amount of value to pass to the call
    function send(address _target, uint256 _gas, uint256 _value) internal returns (bool) {
        bool _success;
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                0, // inloc
                0, // inlen
                0, // outloc
                0 // outlen
            )
        }
        return _success;
    }
}
