// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract DRBCoordinatorStorage {
    /// **** Type Declarations ****
    struct RequestInfo {
        address consumer;
        uint256 requestedTime;
        uint256 cost;
        uint256 callbackGasLimit;
    }

    struct RoundInfo {
        uint256 commitEndTime;
        uint256 randomNumber;
        bool fulfillSucceeded;
    }

    /// *** State variables ***
    mapping(uint256 round => address[] activatedOperators)
        internal s_activatedOperatorsAtRound;
    mapping(uint256 round => mapping(address operator => uint256))
        internal s_activatedOperatorOrderAtRound;
    mapping(uint256 round => RequestInfo requestInfo) internal s_requestInfo;
    mapping(uint256 round => RoundInfo roundInfo) internal s_roundInfo;
    mapping(uint256 round => bytes32[] commits) internal s_commits;
    mapping(uint256 round => bytes32[] reveals) internal s_reveals;

    mapping(address operator => uint256 depositAmount) internal s_depositAmount;
    mapping(address operator => uint256) internal s_activatedOperatorOrder;
    mapping(uint256 round => mapping(address operator => uint256))
        internal s_commitOrder;
    mapping(uint256 round => mapping(address operator => uint256))
        internal s_revealOrder;

    address[] internal s_activatedOperators;

    uint256 internal s_currentRound;
    uint256 internal s_nextRound;
    uint256 internal s_premiumPercentage;
    uint256 internal s_flatFee;

    uint256 internal s_minDeposit;

    /// *** Constants ***
    uint256 internal constant COMMIT_DURATION = 120; // 2 minutes
    uint256 internal constant REVEAL_DURATION = 240; // 4 minutes
    uint256 internal constant CALLDATA_SIZE_BYTES_PER_ROUND = 3200;
    uint256 internal constant L2_GASUSED_PER_ROUND = 1_000_000;
    /// @dev 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100) and some arithmetic operations
    uint256 internal constant GAS_FOR_CALL_EXACT_CHECK = 5_000;

    /// *** Errors ***
    error InsufficientAmount();
    error InsufficientDeposit();
    error NotEnoughActivatedOperators();
    error AlreadyActivated();
    error AlreadyDeactivated();
    error NotActivatedOperator();
    error NotCommitted();
    error WasNotActivated();
    error CommitPhaseOver();
    error NotRevealPhase();
    error AlreadyCommitted();
    error RevealValueMismatch();
    error AlreadyRevealed();

    /// *** Events ***
    event RandomNumberRequested(uint256 round);
    event Activated(address operator);
    event DeActivated(address operator);

    /// *** Getter Functions ***
    function getDurations()
        external
        pure
        returns (uint256 commitDuration, uint256 revealDuration)
    {
        return (COMMIT_DURATION, REVEAL_DURATION);
    }

    /// ** s_depositAmount
    function getDepositAmount(
        address operator
    ) external view returns (uint256) {
        return s_depositAmount[operator];
    }

    /// ** s_activatedOperatorOrder
    function getActivatedOperatorIndex(
        address operator
    ) external view returns (uint256) {
        return s_activatedOperatorOrder[operator];
    }

    /// ** s_activatedOperators
    function getActivatedOperators() external view returns (address[] memory) {
        return s_activatedOperators;
    }

    /// ** s_requestInfo
    function getRequestInfo(
        uint256 round
    ) external view returns (RequestInfo memory) {
        return s_requestInfo[round];
    }

    /// ** s_activatedOperatorsAtRound
    function getActivatedOperatorsAtRound(
        uint256 round
    ) external view returns (address[] memory) {
        return s_activatedOperatorsAtRound[round];
    }

    /// ** s_roundInfo
    function getRoundInfo(
        uint256 round
    ) external view returns (RoundInfo memory) {
        return s_roundInfo[round];
    }

    /// ** s_commits
    function getCommits(
        uint256 round
    ) external view returns (bytes32[] memory) {
        return s_commits[round];
    }

    /// ** s_commitOrder
    function getCommitOrder(
        uint256 round,
        address operator
    ) external view returns (uint256) {
        return s_commitOrder[round][operator];
    }

    /// ** s_reveals
    function getReveals(
        uint256 round
    ) external view returns (bytes32[] memory) {
        return s_reveals[round];
    }

    /// ** s_revealOrder
    function getRevealOrder(
        uint256 round,
        address operator
    ) external view returns (uint256) {
        return s_revealOrder[round][operator];
    }
}
