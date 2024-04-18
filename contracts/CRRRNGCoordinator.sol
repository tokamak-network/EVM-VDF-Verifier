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
    uint256 private constant DEFAULTPROOFLASTINDEX = 22;
    uint256 private constant NBITLEN = 2047;
    uint256 private constant GBITLEN = 2046;
    uint256 private constant HBITLEN = 2044;
    // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100) and some arithmetic operations
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
    // bytes
    bytes private constant NVAL =
        hex"4e502cc741a1a63c4ae0cea62d6eefae5d0395e137075a15b515f0ced5c811334f06272c0f1e85c1bed5445025b039e42d0a949989e2c210c9b68b9af5ada8c0f72fa445ce8f4af9a2e56478c8a6b17a6f1c389445467fe096a4c35262e4b06a6ba67a419bcca5d565e698ead674fca78e5d91fdc18f854b8e43edbca302c5d2d2d47ce49afb7405a4db2e87c98c2fd0718af32c1881e4d6d762f624de2d57663754aedfb02cbcc944812d2f8de4f694c933a1c11ecdbb2e67cf22f410487d598ef3d82190feabf11b5a83a4a058cdda1def94cd244fd30412eb8fa6d467398c21a15af04bf55078d9c73e12e3d0f5939804845b1487fae1fb526fa583e27d71";
    bytes private constant GVAL =
        hex"34bea67f7d10481d71f794f7bf849b91a460b6488fc0def25ff20b19ff63e984e88daef00289931b566f3e25121e8757751e670a04735a78ff255d804caa197aa65da842913a243add64d375e378380e818b330cc9ef2a89753046248e41eff0f87d8ef4f7764e0ed3698b7f87b07805d235627c80e695f3f6095ca6523312a2916456ed011863d5287a33bf603f495071878ebcb06b9303ffa57ac9b5a77121a20fdbe15004010935d65fc39b199692bbadf172ae84a279f63e31997865c133a6cb8ca4e6c29677a46b932c75297347c605b7fe1c292a96d6401f22b4e4ff474e47cfa59ccfef24d99c3777c98bff523f4a587d54ddc395f572bcde1ae93ba1";
    bytes private constant HVAL =
        hex"08d72e28d1cef1b56bc3047d29624445ce203a0c6de5343a5f4873b4017f479e93fc4c3179d4db28dc7e4a6c859469868e50f3347b8736da84cd0995c661b99df90afa21267a8d7588704b9fc249bac3a3087ff1372f8fbfe1f8625c1a42113ebda7fc364a27d8a0c85dab8802f1b3983e867c3b11fedab831b5d6c1d49a906dd5366dd30816c174d6d384295e0229ddb1685eb5c57b9cde512ff50d82bf659eff8b9f3c8d2f0c2737c83eb44463ca23d93e29fa9630c06809b8a6327a29468e19042a7eac025c234be9fe349a19d7b3e5e4acca63f0b4a592b1749a15a1f054689b1809a4b95b27b8513fa1639c98ca9e18113bf36d631944c37459b5575a17";

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
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta
    ) external {
        if (s_verified) revert AlreadyVerified();
        require(BigNumbers.eq(BigNumber(GVAL, GBITLEN), x));
        require(BigNumbers.eq(BigNumber(HVAL, HBITLEN), y));
        _verifyRecursiveHalvingProof(
            v,
            x,
            y,
            BigNumber(NVAL, NBITLEN),
            bigNumTwoPowerOfDelta,
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
        if (!s_verified) revert NotVerified();
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
            _temp = _hash(s_commitRevealValues[round][i].c.val, _bStar);
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
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta
    ) external checkRecoverStage(round) nonReentrant {
        // check
        uint256 _numOfPariticipants = s_valuesAtRound[round].numOfPariticipants;
        if (_numOfPariticipants == BigNumbers.UINTZERO) revert NoneParticipated();
        if (s_valuesAtRound[round].isCompleted) revert OmegaAlreadyCompleted();
        BigNumber memory _n = BigNumber(NVAL, NBITLEN);
        bytes memory _bStar = s_valuesAtRound[round].bStar;
        _verifyRecursiveHalvingProof(v, x, y, _n, bigNumTwoPowerOfDelta, delta);
        BigNumber memory _recov = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
        for (uint256 i; i < _numOfPariticipants; i = _unchecked_inc(i)) {
            BigNumber memory _c = s_commitRevealValues[round][i].c;
            _recov = BigNumbers.modmul(
                _recov,
                BigNumbers.modexp(_c, _hash(_c.val, _bStar), _n),
                _n
            );
        }
        if (!BigNumbers.eq(_recov, x)) revert RecovNotMatchX();
        // effect
        s_valuesAtRound[round].isCompleted = true;
        s_valuesAtRound[round].omega = y;
        s_valuesAtRound[round].stage = Stages.Finished;
        // interaction
        // Do not allow any non-view/non-pure coordinator functions to be called during the consumers callback code via reentrancyLock.
        s_reentrancyLock = true;
        bool success = _call(
            s_valuesAtRound[round].consumer,
            abi.encodeWithSelector(
                RNGConsumerBase.rawFulfillRandomWords.selector,
                round,
                uint256(keccak256(y.val))
            )
        );
        s_reentrancyLock = false;
        emit Recovered(round, _recov.val, y.val, success);
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

    function _hash128(
        bytes memory a,
        bytes memory b,
        bytes memory c
    ) private view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(bytes.concat(a, b, c)) >> 128));
    }

    function _hash(bytes memory strings) private view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(strings)));
    }

    function _hash(bytes memory a, bytes memory b) private view returns (BigNumber memory) {
        return BigNumbers.init(abi.encodePacked(keccak256(bytes.concat(a, b))));
    }

    function _unchecked_inc(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + BigNumbers.UINTONE;
        }
    }

    function _verifyRecursiveHalvingProof(
        BigNumber[] memory v,
        BigNumber memory x,
        BigNumber memory y,
        BigNumber memory n,
        bytes memory bigNumTwoPowerOfDelta,
        uint256 delta
    ) private view {
        uint i;
        uint256 iMax;
        unchecked {
            iMax = DEFAULTPROOFLASTINDEX - delta;
        }
        do {
            BigNumber memory _r = _hash128(x.val, y.val, v[i].val);
            x = BigNumbers.modmul(BigNumbers.modexp(x, _r, n), v[i], n);
            y = BigNumbers.modmul(BigNumbers.modexp(v[i], _r, n), y, n);
            unchecked {
                ++i;
            }
        } while (i < iMax);
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        if (
            !BigNumbers.eq(
                y,
                BigNumbers.init(
                    BigNumbers._modexp(
                        x.val,
                        BigNumbers._modexp(
                            BigNumbers.BYTESTWO,
                            bigNumTwoPowerOfDelta,
                            BigNumbers._powModulus(_two, 2 ** delta).val
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
