// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./libraries/BigNumbers.sol";
import {ICRRRNGCoordinator} from "./interfaces/ICRRRNGCoordinator.sol";
import {RNGConsumerBase} from "./RNGConsumerBase.sol";

contract CRRRNGCoordinator is ICRRRNGCoordinator {
    /* Type declaration */
    using BigNumbers for *;

    /* Constant variables */
    // uint256
    uint256 private constant MODFORHASH_LEN = 129;
    uint256 private constant T = 4194304; // 2^22
    uint256 private constant COMMITDURATION = 120;
    uint256 private constant COMMITREVEALDURATION = 240;
    uint256 private constant PROOFLASTINDEX = 22;
    uint256 private constant NBITLEN = 2047;
    uint256 private constant GBITLEN = 2046;
    uint256 private constant HBITLEN = 2043;
    // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100) and some arithmetic operations
    uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
    // bytes
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";
    bytes private constant NVAL =
        hex"45d416e8be4f61d58a3390edb1949059f4f3f728a9d300a405123226fec1861139b1f5bc4d0f24ba1f115217cf41c4a28f1c0c7d0291f29f89b63f0f87a84668cef76b56f969c23494439f07e0895ee44257b6123341cf27bcfc085434225ea08b06cdb8d67ad2cc7d80fb8f96cd18b248e62f241892a0696233006e4d467fac5d5128b58b20b72ff17956c6f86cbd00bb7847218a9ec2b333ac20e33a0d1a4959feb3a151b26898b4123e5e05b682b9a18f230133f28703c954177498bc6c6203a3ca1467cb4eb7caf79c644ab898ef751ba4663a06f4a67c7ccfff781eff04b1713ca98ddedf1347e893c7eb4ef90e2a67d659ad74c546714b9e78e0bc0281";
    bytes private constant GVAL =
        hex"3237a29cc9a41fbbb03e6c326d001516c5c8eca55584981b3005141d277f6ece1859841a5029e02319cd860167e52fbe61d66a1e09d8c858b14dadaf3a8f270cfbe2625398ad141d7f34cfde7c8ab4788a938dc6a641af81afa402debb20ac7b5c3d655ee3db11f535d3f75de5fcd93c293e304592439239704c4890807210aa64b422dd162c43cb6f89b71236a4e44caeee475925fab5fee8a82e3515441d43dcfa276db2263ae761024dee07c113cac079f4d709390ada0e0c7919c6f06b30ce3ba7a17d7d61ed979571d82bff342c72938c20d8d555b00c2efe40ee5d8306dc8ed6ed49421259266612b9adf9e37902914acae00b973552231f8715f188a0";
    bytes private constant HVAL =
        hex"040fe0b9b8cd0bdd26fb05a5e45126265e34aefea81e7a8b6f6862d6f64ddcbe9f1bd821657dc4227cd0121e36d391669787aedbc969b6487d22690d91347b6473735439c34d640baccc145bc8d935415417f2e098493f6a8d6f869243722d0b9baebc399244dec31fc8935785832fb41d6fae424a2a2b6b8594ff47eed03b7430195a53046eabfb11ed0784ab91b0e8c1277ec4f12d6d940980fc6075b6f96679c691d525a65eba59a81c42ebe6b28b9beb66ccd9792771c483d11ceee27fc00bb8bf391c397af80371fcc31765ef95fef9bbc0fd1ad0fcd1e29bbf684390d0491762d0992d2e0bccd829af2ba9810b1b5edc3ff4e1075db8d81b5590d0b124";

    /* State variables */
    uint256 private s_nextRound;
    mapping(uint256 round => ValueAtRound) private s_valuesAtRound;
    mapping(uint256 round => mapping(uint256 index => CommitRevealValue))
        private s_commitRevealValues;
    mapping(uint256 round => mapping(address owner => UserAtRound)) private s_userInfosAtRound;
    bool private s_reentrancyLock;

    constructor(VDFClaim[] memory proofList) {
        BigNumber memory n = BigNumber(NVAL, NBITLEN);
        BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO); //BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
        uint256 _T = T;
        uint i;
        uint256 _proofsLastIndex = proofList.length - BigNumbers.UINTONE;
        require(_proofsLastIndex == PROOFLASTINDEX);
        require(BigNumber(GVAL, GBITLEN).eq(proofList[BigNumbers.UINTZERO].x));
        require(BigNumber(HVAL, HBITLEN).eq(proofList[BigNumbers.UINTZERO].y));
        do {
            BigNumber memory _y = proofList[i].y;
            BigNumber memory _r = _modHash(
                bytes.concat(proofList[i].y.val, proofList[i].v.val),
                proofList[i].x
            ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
            if (_T & BigNumbers.UINTONE == BigNumbers.UINTONE) {
                unchecked {
                    ++_T;
                }
                _y = _y.modexp(_two, n);
            }
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

    /* External Functions */
    function commit(uint256 round, BigNumber calldata c) external checkStage(round, Stages.Commit) {
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

    function reveal(uint256 round, BigNumber calldata a) external checkStage(round, Stages.Reveal) {
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
        uint256 _round = s_nextRound++;
        s_valuesAtRound[_round].startTime = block.timestamp;
        s_valuesAtRound[_round].stage = Stages.Commit;
        s_valuesAtRound[_round].consumer = msg.sender;
        emit RandomWordsRequested(_round, msg.sender);
        return _round;
    }

    function reRequestRandomWordAtRound(uint256 round) external checkStage(round, Stages.Finished) {
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
        VDFClaim[] calldata proofs
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
        returns (uint256, uint256, uint256, bytes memory, bytes memory, bytes memory)
    {
        return (NBITLEN, GBITLEN, HBITLEN, NVAL, GVAL, HVAL);
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
        VDFClaim[] calldata proofList,
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
            if (_T & BigNumbers.UINTONE == BigNumbers.UINTONE) {
                unchecked {
                    ++_T;
                }
                _y = _y.modexp(_two, n);
            }
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
