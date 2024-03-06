// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./libraries/BigNumbers.sol";
import {ICRRRNGCoordinatorDeprecated} from "./interfaces/ICRRRNGCoordinatorDeprecated.sol";
import {RNGConsumerBase} from "./RNGConsumerBase.sol";

contract CRRRNGCoordinator301 is ICRRRNGCoordinatorDeprecated {
    /* Type declaration */
    using BigNumbers for *;

    /* Constant variables */
    // uint256
    uint256 private constant MODFORHASH_LEN = 129;
    uint256 private constant T = 1048576; // 2^22
    uint256 private constant COMMITDURATION = 120;
    uint256 private constant COMMITREVEALDURATION = 240;
    uint256 private constant PROOFLASTINDEX = 20;
    uint256 private constant NBITLEN = 2047;
    uint256 private constant GBITLEN = 2044;
    uint256 private constant HBITLEN = 2046;
    // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100) and some arithmetic operations
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
    // bytes
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";
    bytes private constant NVAL =
        hex"729852f8d822be59248b59ec93e0d4b8f0a8da1efcb2c6d3e63667b06b478d6ccbd9cdb93f3bf45e5f018b3947f48ab81106921534d8eae23b1035a755f8d096369906a9ba5129f3c9bb79b6b081e1c2902b939e7e1bc9359108fc421d3980fcd60c8369c45ba225eb1e58a6561907b099786f1cc7812372d950352d8e7348aa45108154ee4045f97af5f09c2aefff287f3b94d45830ebd418bb27c474ee89b3347b8ad0c197cb81cc46d3b30aa7249054ee8d97e6ba3a283e471ded1589ddb8575a9be9287d79500b6f10384e82406d904e3128756672060cf771609cf48760fa606ddf19214c95dda8b14eadf7231948e440cfc29edb42565c5d6feace3867";
    bytes private constant GVAL =
        hex"0ac03fee219a29ea4bbdfdc13e22611750a55d725018cc28bc92d1aa590c52d63948c211db256d185b860f2b9cf25dbd28f65e65cb07378783404494b54a4c2f39afd98ac61bfe3ff6da48927fb9560eb0fe46ef9448c9cfa6a95b3dafde24f6edac587b11dfb4d6d8c7e4ec02f5e707d83173848f2fd4e6a9c31ad69692a14fee58da03ab001010993cd4960e1d40e0e359a351b90785bf561fe2b258d4937dda208e99fc50d0986617bea2edd1a838c47378457f0bc0d23a4559a540b6e763f43ac1ce68b74783c1766234c7746ec5a3a03b0ebd6fc00201bb6059698adc38190dfeb056f31762fe23491cf57fd055e752f820451416ab3f31460b53406a33";
    bytes private constant HVAL =
        hex"29df047178acf01f8a5553a79324981b19133e7fb0eb3a9396d1a2ca1c1bc4bde69b22f6565d4170456bbc6d9d8673d65acf79b0d1203a30a8826971f47d1d15b139a28eb6b1208794208494425be344342204c330c1ba00f8aa16c1352784a5751c20c6e29dbef66ac955ccc9abdaf015d61fa5391fb0080cb2d00c15166d3ffa668c8b8f3b64e9f5157d5f0f9b7b968e6c9962fdc6c472d8ea882670865b1e031c162b0843a14c104d4d1e7bf2db145a24989a1c79c9d3ba25ab961caa17d0f90011f502dc4fb688953e44f5139754fef3e07144f97a4a5d7d2ce116ac76a62eec8871392a270d7ea5ec0ad84129aa118af9425b556f1a9973de7c525ae826";

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
