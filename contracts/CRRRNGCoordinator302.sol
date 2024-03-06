// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./libraries/BigNumbers.sol";
import {ICRRRNGCoordinatorDeprecated} from "./interfaces/ICRRRNGCoordinatorDeprecated.sol";
import {RNGConsumerBase} from "./RNGConsumerBase.sol";

contract CRRRNGCoordinator302 is ICRRRNGCoordinatorDeprecated {
    /* Type declaration */
    using BigNumbers for *;

    /* Constant variables */
    // uint256
    uint256 private constant MODFORHASH_LEN = 129;
    uint256 private constant T = 2097152; // 2^22
    uint256 private constant COMMITDURATION = 120;
    uint256 private constant COMMITREVEALDURATION = 240;
    uint256 private constant PROOFLASTINDEX = 21;
    uint256 private constant NBITLEN = 2048;
    uint256 private constant GBITLEN = 2046;
    uint256 private constant HBITLEN = 2047;
    // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100) and some arithmetic operations
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
    // bytes
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";
    bytes private constant NVAL =
        hex"8d00c70aeb752ef9a3815da1f487edef2000e91305bb5558ff1d6a46adcc4d3600ccc1f0b2cdc73fe9ff65263b3c489672c0b83bbd38c700de79bd05ae5548435c7608f1dbd47750a2b0535808aed8c00af62f4008fed36a8b1a1ca6f3ad5be617aa464ac715e8d39b7bd3abe3031b21d76d64e9fffde945025a42169198364402734d2f765f2c685582db3f43fc504b0c73b146ba3691d2a30d2096d566dad4874bf8cdbdc8546daa496a55195add394cf2dc29463b200f5cc638a0ead52d9f5eb28b0ea318a92d4f90a35dc13c7171ee01a569b523247fb3f0500f11bddde6b1846b58e30de21085273e87715c3c39c86f4f20025f6d5021849d77e6a3ad31";
    bytes private constant GVAL =
        hex"37ab59feab6038fd91dc6694f494d09e35721719a1c8165f9c90dd9d235378b75bca3f84e41bc476afce0b32de7427125b755cd683d5c8e872f6f469157db05ceab7457b3653ce8c0122d5d83481c7038f454ac9102ca2a1764e04a14203e78047ed820ea382c837c85060c0bcc967130e839c80ccf43131ad0e5e4be5cd881ea6c78ab2575c1863fa567786d6827c75bc5f3781aa5b043b9b15312d7be312cb623469eafb686fbe5fbe60875a5a7ea0d36de6c91db76ed8f64995d690b2b50f29ddce8e3a8572804eb54481369801b3dba12eeb6dec4fe59bb689f38ea7fc189cd002a3358fea49454a40e6351559d3fadd7bbb46ac03ce3834a2c0e432d5b6";
    bytes private constant HVAL =
        hex"76615f6f44aae7fd977de351ba2f9d8d8d55c6f3ead97503704da2f49a6e0fda5857f9fe37b5a095576482ce4a4912a543cb98edcca125c29f15d26da32c6bb68dd962a5d5a09ad6145b31fa0fd99ea6dc5017236c93a1530199f9b896ea63b8f1bb65a946f7b16cb45efbe0397f3b6474cb98106f80bdbb240a791e13ac44a8a846c4196990cc809601e9c23b1e68fd69f38ce8d0a2c9a7133df72e4e58818870fc9056a8966da9958ee7aa5197d754bc735aca7884380f0124d6f3325abbed438568d6cf45b93f63e62b8eee31220a195667760e0fa8ba7d4f44fea4ad19a1761f77036680baeb75cea1e6a9c163b5fd51711b0ab763460edd47849e444b41";

    /* State variables */
    uint256 private s_nextRound;
    mapping(uint256 round => ValueAtRound) private s_valuesAtRound;
    mapping(uint256 round => mapping(uint256 index => CommitRevealValue))
        private s_commitRevealValues;
    mapping(uint256 round => mapping(address owner => UserAtRound)) private s_userInfosAtRound;
    bool private s_reentrancyLock;
    bool private s_verified;

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
                s_valuesAtRound[round].bStar = _modHash(
                    s_valuesAtRound[round].commitsString,
                    BigNumber(NVAL, NBITLEN)
                ).val;
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
    modifier checkRecoverStage(uint256 round) {
        if (round >= s_nextRound) revert NotStartedRound();
        uint256 _startTime = s_valuesAtRound[round].startTime;
        Stages _stage = s_valuesAtRound[round].stage;
        if (_stage == Stages.Commit && block.timestamp >= _startTime + COMMITDURATION) {
            uint256 _count = s_valuesAtRound[round].count;
            if (_count > BigNumbers.UINTONE) {
                _stage = Stages.Reveal;
                s_valuesAtRound[round].numOfPariticipants = _count;
                s_valuesAtRound[round].bStar = _modHash(
                    s_valuesAtRound[round].commitsString,
                    BigNumber(NVAL, NBITLEN)
                ).val;
            } else {
                _stage = Stages.Finished;
            }
        }
        if (_stage == Stages.Reveal && block.timestamp >= _startTime + COMMITREVEALDURATION) {
            _stage = Stages.Finished;
        }
        if (_stage == Stages.Commit) revert FunctionInvalidAtThisStage();
        s_valuesAtRound[round].stage = _stage;
        _;
    }

    function initialize(VDFClaim[] memory proofList) external {
        if (s_verified) revert AlreadyVerified();
        require(proofList.length - BigNumbers.UINTONE == PROOFLASTINDEX);
        require(BigNumber(GVAL, GBITLEN).eq(proofList[BigNumbers.UINTZERO].x));
        require(BigNumber(HVAL, HBITLEN).eq(proofList[BigNumbers.UINTZERO].y));
        _verifyRecursiveHalvingProof(proofList, BigNumber(NVAL, NBITLEN));
        s_verified = true;
    }

    /* External Functions */
    function commit(uint256 round, BigNumber memory c) external checkStage(round, Stages.Commit) {
        //check
        if (c.isZero()) revert ShouldNotBeZero();
        if (s_userInfosAtRound[round][msg.sender].committed) revert AlreadyCommitted();
        //effect
        uint256 _count = s_valuesAtRound[round].count;
        bytes memory _commitsString = s_valuesAtRound[round].commitsString;
        _commitsString = bytes.concat(_commitsString, c.val);
        s_userInfosAtRound[round][msg.sender] = UserAtRound(_count, true, false);
        s_commitRevealValues[round][_count] = CommitRevealValue(
            c,
            BigNumber(BigNumbers.BYTESZERO, BigNumbers.UINTZERO),
            msg.sender
        );
        s_valuesAtRound[round].commitsString = _commitsString;
        s_valuesAtRound[round].count = _count = _unchecked_inc(_count);
        emit CommitC(_commitsString, _count, c.val);
    }

    function reveal(uint256 round, BigNumber memory a) external checkStage(round, Stages.Reveal) {
        // check
        uint256 _userIndex = s_userInfosAtRound[round][msg.sender].index;
        if (!s_userInfosAtRound[round][msg.sender].committed) revert NotCommittedParticipant();
        if (s_userInfosAtRound[round][msg.sender].revealed) revert AlreadyRevealed();
        if (
            !BigNumber(GVAL, GBITLEN).modexp(a, BigNumber(NVAL, NBITLEN)).eq(
                s_commitRevealValues[round][_userIndex].c
            )
        ) revert ModExpRevealNotMatchCommit();
        //effect
        uint256 _count;
        unchecked {
            _count = --s_valuesAtRound[round].count;
        }
        s_commitRevealValues[round][_userIndex].a = a;
        if (_count == BigNumbers.UINTZERO) {
            s_valuesAtRound[round].stage = Stages.Finished;
            s_valuesAtRound[round].isAllRevealed = true;
        }
        s_userInfosAtRound[round][msg.sender].revealed = true;
        emit RevealA(_count, a.val);
    }

    function requestRandomWord() external returns (uint256) {
        require(s_verified);
        uint256 _round = s_nextRound++;
        s_valuesAtRound[_round].startTime = block.timestamp;
        s_valuesAtRound[_round].stage = Stages.Commit;
        s_valuesAtRound[_round].consumer = msg.sender;
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

    function calculateOmega(
        uint256 round
    ) external nonReentrant checkStage(round, Stages.Finished) {
        // check
        if (!s_valuesAtRound[round].isAllRevealed) revert NotAllRevealed();
        if (s_valuesAtRound[round].isCompleted) revert OmegaAlreadyCompleted();
        uint256 _numOfPariticipants = s_valuesAtRound[round].numOfPariticipants;
        BigNumber memory _omega = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
        bytes memory _bStar = s_valuesAtRound[round].bStar;
        BigNumber memory _h = BigNumber(HVAL, HBITLEN);
        BigNumber memory _n = BigNumber(NVAL, NBITLEN);
        uint256 i;
        do {
            BigNumber memory _temp = _modHash(
                bytes.concat(s_commitRevealValues[round][i].c.val, _bStar),
                _n
            );
            _omega = _omega.modmul(
                _h.modexp(_temp, _n).modexp(s_commitRevealValues[round][i].a, _n),
                _n
            );
            i = _unchecked_inc(i);
        } while (i < _numOfPariticipants);
        s_valuesAtRound[round].omega = _omega;
        s_valuesAtRound[round].isCompleted = true;
        emit CalculateOmega(round, _omega.val);
    }

    function recover(
        uint256 round,
        VDFClaim[] memory proofs
    ) external checkRecoverStage(round) nonReentrant {
        // check
        uint256 _numOfPariticipants = s_valuesAtRound[round].numOfPariticipants;
        if (_numOfPariticipants == BigNumbers.UINTZERO) revert NoneParticipated();
        if (proofs.length - BigNumbers.UINTONE != PROOFLASTINDEX) revert InvalidProofsLength();
        if (s_valuesAtRound[round].isCompleted) revert OmegaAlreadyCompleted();
        BigNumber memory _n = BigNumber(NVAL, NBITLEN);
        bytes memory _bStar = s_valuesAtRound[round].bStar;
        _verifyRecursiveHalvingProof(proofs, _n);
        BigNumber memory _recov = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
        uint256 i;
        do {
            BigNumber memory _c = s_commitRevealValues[round][i].c;
            _recov = _recov.modmul(_c.modexp(_modHash(bytes.concat(_c.val, _bStar), _n), _n), _n);
            i = _unchecked_inc(i);
        } while (i < _numOfPariticipants);
        if (!_recov.eq(proofs[BigNumbers.UINTZERO].x)) revert RecovNotMatchX();
        // effect
        s_valuesAtRound[round].isCompleted = true;
        s_valuesAtRound[round].omega = proofs[BigNumbers.UINTZERO].y;
        s_valuesAtRound[round].stage = Stages.Finished;
        // interaction
        bytes memory callData = abi.encodeWithSelector(
            RNGConsumerBase.rawFulfillRandomWords.selector,
            round,
            proofs[BigNumbers.UINTZERO].y.val,
            proofs[BigNumbers.UINTZERO].y.bitlen
        );
        // Do not allow any non-view/non-pure coordinator functions to be called during the consumers callback code via reentrancyLock.
        s_reentrancyLock = true;
        bool success = _call(s_valuesAtRound[round].consumer, callData);
        s_reentrancyLock = false;
        emit Recovered(round, _recov.val, proofs[BigNumbers.UINTZERO].y.val, success);
    }

    function getNextRound() external view returns (uint256) {
        return s_nextRound;
    }

    function getSetUpValues()
        external
        pure
        returns (uint256, uint256, uint256, uint256, bytes memory, bytes memory, bytes memory)
    {
        return (T, NBITLEN, GBITLEN, HBITLEN, NVAL, GVAL, HVAL);
    }

    function getValuesAtRound(uint256 _round) external view returns (ValueAtRound memory) {
        return s_valuesAtRound[_round];
    }

    function getCommitRevealValues(
        uint256 _round,
        uint256 _index
    ) external view returns (CommitRevealValue memory) {
        return s_commitRevealValues[_round][_index];
    }

    function getUserInfosAtRound(
        address _owner,
        uint256 _round
    ) external view returns (UserAtRound memory) {
        return s_userInfosAtRound[_round][_owner];
    }

    function _modHash(
        bytes memory strings,
        BigNumber memory n
    ) private view returns (BigNumber memory) {
        return abi.encodePacked(keccak256(strings)).init().mod(n);
    }

    function _unchecked_inc(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + BigNumbers.UINTONE;
        }
    }

    function _verifyRecursiveHalvingProof(
        VDFClaim[] memory proofList,
        BigNumber memory n
    ) private view {
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        uint256 _T = T;
        uint i;
        do {
            BigNumber memory _y = proofList[i].y;
            BigNumber memory _r = _modHash(
                bytes.concat(proofList[i].y.val, proofList[i].v.val),
                proofList[i].x
            ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
            // if (_T & BigNumbers.UINTONE == BigNumbers.UINTONE) {
            //     unchecked {
            //         ++_T;
            //     }
            //     _y = _y.modexp(_two, n);
            // }
            if (
                !proofList[i].x.modexp(_r, n).modmul(proofList[i].v, n).eq(
                    proofList[_unchecked_inc(i)].x
                )
            ) revert XPrimeNotEqualAtIndex(i);
            if (!proofList[i].v.modexp(_r, n).modmul(_y, n).eq(proofList[_unchecked_inc(i)].y))
                revert YPrimeNotEqualAtIndex(i);
            _T = _T >> 1;
            i = _unchecked_inc(i);
        } while (i < PROOFLASTINDEX);
        if (!proofList[i].y.eq(proofList[i].x.modexp(_two, n))) revert NotVerifiedAtTOne();
        if (i != PROOFLASTINDEX || _T != BigNumbers.UINTONE) revert TOneNotAtLast();
    }

    function _call(address target, bytes memory data) private returns (bool success) {
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
            // solidity calls check that a contract actually exists at the destination, so we do the same
            if iszero(extcodesize(target)) {
                revert(0, 0)
            }
            // call and return whether we succeeded. ignore return data
            // call(gas, addr, value, argsOffset,argsLength,retOffset,retLength)
            success := call(g, target, 0, add(data, 0x20), mload(data), 0, 0)
        }
        return success;
    }
}
