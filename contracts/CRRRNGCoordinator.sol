// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./libraries/BigNumbers.sol";
import {ICRRRNGCoordinator} from "./interfaces/ICRRRNGCoordinator.sol";
import {RNGConsumerBase} from "./RNGConsumerBase.sol";

contract CRRRNGCoordinator is ICRRRNGCoordinator {
    /* Type declaration */

    /* Constant variables */
    // uint256
    uint256 private constant T = 4194304; // 2^22
    uint256 private constant COMMITDURATION = 120;
    uint256 private constant COMMITREVEALDURATION = 240;
    uint256 private constant PROOFLASTINDEX = 22;
    uint256 private constant NBITLEN = 2048;
    uint256 private constant GBITLEN = 2047;
    uint256 private constant HBITLEN = 2047;
    // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100) and some arithmetic operations
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
    // bytes
    bytes private constant NVAL =
        hex"84fc05d1050f4a0a93e13f6f8cadaebded77ca89d3d29ad57aef6af6055f76e6b7e806205195a4b717058f865ce0c7c7e5f733c2f4d8270238cf127f0532f2260854b8d688b97f5dd0d435302c1d90c9fe6645c22e6b61802b95fb64565877abd821ae0e162377197a6d4cf7a9639f6b0cdd03f07df49a1269a4b48d163b58323f8a0b61a68cdf006cd1274b13a328e02a0bcb3a86968636e3211468993dabced34a68e907648d5996478ec07831282d9b11a6c1be26eddc6be0c2bebc89655955de18789c192f8b630e729510cfc7edd9d22a13a2a1f2b8be4839a207cce02ae59faf6b20fda5cc8572c9b6f048ce8811288068d787cbd1682d2ba8fd0546b5";
    bytes private constant GVAL =
        hex"635dfea702e324f9c6deddb44625cdcb782680120a2756ec78c39b59540a6a5cd81d774011e877f54413565b4491f2b30dede36dc6bccfb71bacb5d4deeefe743a1097d5106bf2f195ca83e6760ddfa8993659a1d912da3f2c4cb4b055e0c21b9b54cb4f7b45f02cc8ce8ec9b5b2b700a4b719620c254bf71355e58f5874860dfa0e988f066f8c98e0a261b0de924bdabb53c5029631f2b78cb6d7e7e9e18ef419dffb09f25042cb31d751d45842bf52d81630811a950e1ff9a103f3071b22863606fbb3ae11a3e8a08e7f5911c395c6bfeb8d391b871a5d2e372de52d7781615c610f8d44e86d355d2cc8fa1ed95990476e4ed41ff2910ffa7961b4d2895345";
    bytes private constant HVAL =
        hex"48250b8eea437c276608d6921f2fa8e3d9504bf0a006830704ec45121475ef9ca020391797ef2949982a354d8ac8ef3edc244566855b0d0d5cd425b7b4cc944d8e0a6d16077e84a3d2fe1bcff494b0937d95e73da5711a72becc31db1baf38abc1c970862797b2fe03e10e35eac2d627912fa5f4bea912da8f7fb1d409eb0201fbf53a1cf1b036d601a9896853b50f2b03ce14b8ba5a0273259fe2ab79fe95efd955ced4f736307427f9b21a81c30fdff6c24239b51f08ceb89c69e8545e97797cee195e40211bb1e72d8c1d9c75e2d3b33b5a9d61a35a66058d25a2f597b44657616a4d02532000aa1721d9ceda2765d2d40c4f84b79cf58f0fc8fba5eea479";

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
    modifier checkRecoverStage(uint256 round) {
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
        if (_stage == Stages.Commit) revert FunctionInvalidAtThisStage();
        s_valuesAtRound[round].stage = _stage;
        _;
    }

    function initialize(
        VDFClaim[] memory proofList,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta
    ) external {
        if (s_verified) revert AlreadyVerified();
        require(BigNumbers.eq(BigNumber(GVAL, GBITLEN), proofList[BigNumbers.UINTZERO].x));
        require(BigNumbers.eq(BigNumber(HVAL, HBITLEN), proofList[BigNumbers.UINTZERO].y));
        _verifyRecursiveHalvingProof(
            proofList,
            BigNumber(NVAL, NBITLEN),
            bigNumTwoPowerOfDelta,
            2 ** delta,
            delta
        );
        s_verified = true;
    }

    /* External Functions */
    function commit(uint256 round, BigNumber memory c) external checkStage(round, Stages.Commit) {
        //check
        if (BigNumbers.isZero(c)) revert ShouldNotBeZero();
        if (s_userInfosAtRound[round][msg.sender].committed) revert AlreadyCommitted();
        //effect
        uint256 _count = s_valuesAtRound[round].count;
        s_userInfosAtRound[round][msg.sender].index = _count;
        s_userInfosAtRound[round][msg.sender].committed = true;
        s_commitRevealValues[round][_count].c = c;
        s_commitRevealValues[round][_count].participantAddress = msg.sender;
        s_valuesAtRound[round].commitsString = bytes.concat(
            s_valuesAtRound[round].commitsString,
            c.val
        );
        s_valuesAtRound[round].count = _count = _unchecked_inc(_count);
        emit CommitC(_count, c.val);
    }

    function reveal(uint256 round, BigNumber memory a) external checkStage(round, Stages.Reveal) {
        // check
        uint256 _userIndex = s_userInfosAtRound[round][msg.sender].index;
        if (!s_userInfosAtRound[round][msg.sender].committed) revert NotCommittedParticipant();
        if (s_userInfosAtRound[round][msg.sender].revealed) revert AlreadyRevealed();
        if (
            !BigNumbers.eq(
                BigNumbers.modexp(BigNumber(GVAL, GBITLEN), a, BigNumber(NVAL, NBITLEN)),
                s_commitRevealValues[round][_userIndex].c
            )
        ) revert ModExpRevealNotMatchCommit();
        //effect
        uint256 _count;
        unchecked {
            _count = --s_valuesAtRound[round].count;
        }
        if (_count == BigNumbers.UINTZERO) {
            s_valuesAtRound[round].stage = Stages.Finished;
            s_valuesAtRound[round].isAllRevealed = true;
        }
        s_commitRevealValues[round][_userIndex].a = a;
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
        BigNumber memory _temp;
        for (uint256 i; i < _numOfPariticipants; i = _unchecked_inc(i)) {
            _temp = _hash(bytes.concat(s_commitRevealValues[round][i].c.val, _bStar));
            _temp = BigNumbers.modexp(
                BigNumbers.modexp(_h, _temp, _n),
                s_commitRevealValues[round][i].a,
                _n
            );
            _omega = BigNumbers.modmul(_omega, _temp, _n);
        }
        s_valuesAtRound[round].omega = _omega;
        s_valuesAtRound[round].isCompleted = true;
        emit CalculateOmega(round, _omega.val);
    }

    function recover(
        uint256 round,
        VDFClaim[] memory proofs,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta
    ) external checkRecoverStage(round) nonReentrant {
        // check
        uint256 _numOfPariticipants = s_valuesAtRound[round].numOfPariticipants;
        if (_numOfPariticipants == BigNumbers.UINTZERO) revert NoneParticipated();
        if (s_valuesAtRound[round].isCompleted) revert OmegaAlreadyCompleted();
        BigNumber memory _n = BigNumber(NVAL, NBITLEN);
        bytes memory _bStar = s_valuesAtRound[round].bStar;
        _verifyRecursiveHalvingProof(proofs, _n, bigNumTwoPowerOfDelta, 2 ** delta, delta);
        BigNumber memory _recov = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
        for (uint256 i; i < _numOfPariticipants; i = _unchecked_inc(i)) {
            BigNumber memory _c = s_commitRevealValues[round][i].c;
            _recov = BigNumbers.modmul(
                _recov,
                BigNumbers.modexp(_c, _hash(bytes.concat(_c.val, _bStar)), _n),
                _n
            );
        }
        if (!BigNumbers.eq(_recov, proofs[BigNumbers.UINTZERO].x)) revert RecovNotMatchX();
        // effect
        s_valuesAtRound[round].isCompleted = true;
        s_valuesAtRound[round].omega = proofs[BigNumbers.UINTZERO].y;
        s_valuesAtRound[round].stage = Stages.Finished;
        // interaction
        // Do not allow any non-view/non-pure coordinator functions to be called during the consumers callback code via reentrancyLock.
        s_reentrancyLock = true;
        bool success = _call(
            s_valuesAtRound[round].consumer,
            abi.encodeWithSelector(
                RNGConsumerBase.rawFulfillRandomWords.selector,
                round,
                proofs[BigNumbers.UINTZERO].y.val,
                proofs[BigNumbers.UINTZERO].y.bitlen
            )
        );
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

    function _modHashMod128(
        bytes memory strings,
        BigNumber memory n
    ) private view returns (BigNumber memory) {
        return
            BigNumbers.init(
                abi.encodePacked(
                    (bytes32(
                        BigNumbers.mod(BigNumbers.init(abi.encodePacked(keccak256(strings))), n).val
                    ) >> 128)
                )
            );
    }

    function _hash(bytes memory strings) private view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(strings)));
    }

    function _unchecked_inc(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + BigNumbers.UINTONE;
        }
    }

    function _verifyRecursiveHalvingProof(
        VDFClaim[] memory proofList,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 twoPowerOfDelta,
        uint256 delta
    ) private view {
        uint i;
        uint256 iMax = PROOFLASTINDEX - delta;
        do {
            BigNumber memory _r = _modHashMod128(
                bytes.concat(proofList[i].y.val, proofList[i].v.val),
                proofList[i].x
            );
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].x, _r, n), proofList[i].v, n),
                    proofList[_unchecked_inc(i)].x
                )
            ) revert XPrimeNotEqualAtIndex(i);
            if (
                !BigNumbers.eq(
                    BigNumbers.modmul(BigNumbers.modexp(proofList[i].v, _r, n), proofList[i].y, n),
                    proofList[_unchecked_inc(i)].y
                )
            ) revert YPrimeNotEqualAtIndex(i);
            i = _unchecked_inc(i);
        } while (i < iMax);
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        if (
            !BigNumbers.eq(
                proofList[i].y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        proofList[i].x.val,
                        BigNumbers._modexp(
                            _two.val,
                            bigNumTwoPowerOfDelta,
                            BigNumbers._powModulus(_two, twoPowerOfDelta).val
                        ),
                        n.val
                    )
                )
            )
        ) revert NotVerifiedAtTOne();
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
