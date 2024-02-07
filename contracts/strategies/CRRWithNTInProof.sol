// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {BigNumbers} from "../libraries/BigNumbers.sol";
import "./interfaces/ICRRWithNTInProof.sol";

contract CRRWithNTInProof is ICRRWithNTInProof {
    using BigNumbers for *;
    bytes private constant MODFORHASH =
        hex"0000000000000000000000000000000100000000000000000000000000000000";
    uint256 private constant MODFORHASH_LEN = 129;
    uint256 private constant ZERO = 0;
    uint256 private constant ONE = 1;

    /* State variables */
    uint256 private nextRound;
    mapping(uint256 round => SetUpValueAtRound) private setUpValuesAtRound;
    mapping(uint256 round => ValueAtRound) private valuesAtRound;
    mapping(uint256 round => mapping(uint256 index => CommitRevealValue))
        private commitRevealValues;
    mapping(address owner => mapping(uint256 round => UserAtRound)) private userInfosAtRound;

    function commit(uint256 _round, BigNumber memory _c) external override {
        if (_c.isZero()) revert ShouldNotBeZero();
        if (userInfosAtRound[msg.sender][_round].committed) revert AlreadyCommitted();
        checkStage(_round);
        equalStage(_round, Stages.Commit);
        uint256 _count = valuesAtRound[_round].count;
        bytes memory _commitsString = valuesAtRound[_round].commitsString;
        _commitsString = bytes.concat(_commitsString, _c.val);
        userInfosAtRound[msg.sender][_round] = UserAtRound(_count, true, false);
        commitRevealValues[_round][_count] = CommitRevealValue(_c, BigNumbers.zero(), msg.sender); //index setUps from 0, so _count -1
        valuesAtRound[_round].commitsString = _commitsString;
        valuesAtRound[_round].count = ++_count;
        emit CommitC(msg.sender, _c, _commitsString, _count, block.timestamp);
    }

    function reveal(uint256 _round, BigNumber calldata _a) external override {
        UserAtRound memory _user = userInfosAtRound[msg.sender][_round];
        if (!_user.committed) revert NotCommittedParticipant();
        if (_user.revealed) revert AlreadyRevealed();
        if (
            !(setUpValuesAtRound[_round].g.modexp(_a, setUpValuesAtRound[_round].n)).eq(
                commitRevealValues[_round][_user.index].c
            )
        ) revert ModExpRevealNotMatchCommit();
        checkStage(_round);
        equalStage(_round, Stages.Reveal);
        //uint256 _count = --count;
        uint256 _count = valuesAtRound[_round].count -= ONE;
        commitRevealValues[_round][_user.index].a = _a;
        if (_count == ZERO) {
            valuesAtRound[_round].stage = Stages.Finished;
            valuesAtRound[_round].isAllRevealed = true;
        }
        userInfosAtRound[msg.sender][_round].revealed = true;
        emit RevealA(msg.sender, _a, _count, block.timestamp);
    }

    function calculateOmega(uint256 _round) external override returns (BigNumber memory) {
        if (!valuesAtRound[_round].isAllRevealed) revert NotAllRevealed();
        if (valuesAtRound[_round].isCompleted) return valuesAtRound[_round].omega;
        checkStage(_round);
        equalStage(_round, Stages.Finished);
        uint256 _numOfParticipants = valuesAtRound[_round].numOfParticipants;
        BigNumber memory _omega = BigNumbers.one();
        bytes memory _bStar = valuesAtRound[_round].bStar;
        BigNumber memory _h = setUpValuesAtRound[_round].h;
        BigNumber memory _n = setUpValuesAtRound[_round].n;
        for (uint256 i; i < _numOfParticipants; i = unchecked_inc(i)) {
            BigNumber memory _temp = modHash(
                bytes.concat(commitRevealValues[_round][i].c.val, _bStar),
                _n
            );
            _omega = _omega.modmul(
                _h.modexp(_temp, _n).modexp(commitRevealValues[_round][i].a, _n),
                _n
            );
        }
        valuesAtRound[_round].omega = _omega;
        valuesAtRound[_round].isCompleted = true; //false when not all participants have revealed
        valuesAtRound[_round].stage = Stages.Finished;
        emit CalculatedOmega(_round, _omega, block.timestamp);
        return _omega;
    }

    function recover(uint256 _round, VDFClaim[] calldata proofs) external override {
        BigNumber memory _n = setUpValuesAtRound[_round].n;
        uint256 _proofsLastIndex = proofs.length - ONE;
        checkStage(_round);
        uint256 _numOfParticipants = valuesAtRound[_round].numOfParticipants;
        if (valuesAtRound[_round].stage == Stages.Commit) revert FunctionInvalidAtThisStage();
        if (_numOfParticipants == ZERO) revert NoneParticipated();
        bytes memory _bStar = valuesAtRound[_round].bStar;
        if (valuesAtRound[_round].isCompleted) revert OmegaAlreadyCompleted();
        if (setUpValuesAtRound[_round].proofsLastIndex != _proofsLastIndex) revert TNotMatched();
        verifyRecursiveHalvingProof(proofs, _n, _proofsLastIndex);
        BigNumber memory _recov = BigNumbers.one();
        for (uint256 i; i < _numOfParticipants; i = unchecked_inc(i)) {
            BigNumber memory _c = commitRevealValues[_round][i].c;
            _recov = _recov.modmul(_c.modexp(modHash(bytes.concat(_c.val, _bStar), _n), _n), _n);
        }
        if (!_recov.eq(proofs[ZERO].x)) revert RecovNotMatchX();
        valuesAtRound[_round].isCompleted = true;
        valuesAtRound[_round].omega = proofs[ZERO].y;
        valuesAtRound[_round].stage = Stages.Finished;
        emit Recovered(msg.sender, _recov, proofs[ZERO].y, block.timestamp);
    }

    function setUp(
        uint256 _commitDuration,
        uint256 _commitRevealDuration,
        VDFClaim[] calldata _proofs
    ) external override returns (uint256 _round) {
        _round = nextRound++;
        uint256 _proofsLastIndex = _proofs.length - ONE;
        if (_commitDuration >= _commitRevealDuration)
            revert CommitRevealDurationLessThanCommitDuration();
        verifyRecursiveHalvingProof(_proofs, _proofs[ZERO].n, _proofsLastIndex);
        setUpValuesAtRound[_round].setUpTime = block.timestamp;
        setUpValuesAtRound[_round].commitDuration = _commitDuration;
        setUpValuesAtRound[_round].commitRevealDuration = _commitRevealDuration;
        setUpValuesAtRound[_round].T = _proofs[ZERO].T;
        setUpValuesAtRound[_round].g = _proofs[ZERO].x;
        setUpValuesAtRound[_round].h = _proofs[ZERO].y;
        setUpValuesAtRound[_round].n = _proofs[ZERO].n;
        setUpValuesAtRound[_round].proofsLastIndex = _proofsLastIndex;
        valuesAtRound[_round].stage = Stages.Commit;
        valuesAtRound[_round].count = ZERO;
        valuesAtRound[_round].commitsString = "";
        emit SetUp(
            msg.sender,
            block.timestamp,
            _commitDuration,
            _commitRevealDuration,
            _proofs[ZERO].n,
            _proofs[ZERO].x,
            _proofs[ZERO].y,
            _proofs[ZERO].T,
            _round
        );
    }

    function getNextRound() external view override returns (uint256) {
        return nextRound;
    }

    function getSetUpValuesAtRound(
        uint256 _round
    ) external view override returns (SetUpValueAtRound memory) {
        return setUpValuesAtRound[_round];
    }

    function getValuesAtRound(uint256 _round) external view override returns (ValueAtRound memory) {
        return valuesAtRound[_round];
    }

    function getCommitRevealValues(
        uint256 _round,
        uint256 _index
    ) external view override returns (CommitRevealValue memory) {
        return commitRevealValues[_round][_index];
    }

    function getUserInfosAtRound(
        address _owner,
        uint256 _round
    ) external view override returns (UserAtRound memory) {
        return userInfosAtRound[_owner][_round];
    }

    /**
     * @notice checkStage function
     * @notice revert if the current stage is not the given stage
     * @notice this function is used to check if the current stage is the given stage
     * @notice it will update the stage to the next stage if needed
     */
    function checkStage(uint256 _round) private {
        uint256 _setUpTime = setUpValuesAtRound[_round].setUpTime;
        if (
            valuesAtRound[_round].stage == Stages.Commit &&
            block.timestamp >= _setUpTime + setUpValuesAtRound[_round].commitDuration
        ) {
            if (valuesAtRound[_round].count != ZERO) {
                valuesAtRound[_round].stage = Stages.Reveal;
                valuesAtRound[_round].numOfParticipants = valuesAtRound[_round].count;
                valuesAtRound[_round].bStar = modHash(
                    valuesAtRound[_round].commitsString,
                    setUpValuesAtRound[_round].n
                ).val;
            } else {
                valuesAtRound[_round].stage = Stages.Finished;
            }
        }
        if (
            valuesAtRound[_round].stage == Stages.Reveal &&
            (block.timestamp >= _setUpTime + setUpValuesAtRound[_round].commitRevealDuration)
        ) {
            valuesAtRound[_round].stage = Stages.Finished;
        }
    }

    function equalStage(uint256 _round, Stages _stage) private view {
        if (valuesAtRound[_round].stage != _stage) revert FunctionInvalidAtThisStage();
    }

    function modHash(
        bytes memory _strings,
        BigNumber memory _n
    ) private view returns (BigNumber memory) {
        return abi.encodePacked(keccak256(_strings)).init().mod(_n);
    }

    function verifyRecursiveHalvingProof(
        VDFClaim[] calldata _proofList,
        BigNumber memory _n,
        uint256 _proofsLastIndex
    ) private view {
        BigNumber memory _two = BigNumbers.two();
        uint256 i;
        for (; i < _proofsLastIndex; i = unchecked_inc(i)) {
            BigNumber memory _y = _proofList[i].y;
            BigNumber memory _r = modHash(
                bytes.concat(_proofList[i].y.val, _proofList[i].v.val),
                _proofList[i].x
            ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
            if (_proofList[i].T & ONE == ONE) _y = _y.modexp(_two, _n);
            BigNumber memory _xPrime = _proofList[i].x.modexp(_r, _n).modmul(_proofList[i].v, _n);
            if (!_xPrime.eq(_proofList[unchecked_inc(i)].x)) revert XPrimeNotEqualAtIndex(i);
            BigNumber memory _yPrime = _proofList[i].v.modexp(_r, _n);
            if (!_yPrime.modmul(_y, _n).eq(_proofList[unchecked_inc(i)].y))
                revert YPrimeNotEqualAtIndex(i);
        }
        if (!_proofList[i].y.eq(_proofList[i].x.modexp(_two, _n))) revert NotVerifiedAtTOne();
        if (i != _proofsLastIndex || _proofList[i].T != ONE) revert TOneNotAtLast();
    }

    function verifyRecursiveHalvingProofExternalForTest(
        VDFClaim[] calldata _proofList,
        BigNumber memory _n,
        uint256 _proofsLastIndex
    ) external {
        BigNumber memory _two = BigNumbers.two();
        uint256 i;
        for (; i < _proofsLastIndex; i = unchecked_inc(i)) {
            BigNumber memory _y = _proofList[i].y;
            BigNumber memory _r = modHash(
                bytes.concat(_proofList[i].y.val, _proofList[i].v.val),
                _proofList[i].x
            ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
            if (_proofList[i].T & ONE == ONE) _y = _y.modexp(_two, _n);
            BigNumber memory _xPrime = _proofList[i].x.modexp(_r, _n).modmul(_proofList[i].v, _n);
            if (!_xPrime.eq(_proofList[unchecked_inc(i)].x)) revert XPrimeNotEqualAtIndex(i);
            BigNumber memory _yPrime = _proofList[i].v.modexp(_r, _n);
            if (!_yPrime.modmul(_y, _n).eq(_proofList[unchecked_inc(i)].y))
                revert YPrimeNotEqualAtIndex(i);
        }
        if (!_proofList[i].y.eq(_proofList[i].x.modexp(_two, _n))) revert NotVerifiedAtTOne();
        if (i != _proofsLastIndex || _proofList[i].T != ONE) revert TOneNotAtLast();
    }

    event VerifyRecursiveHalvingProofGasUsed(uint256 gasUsed);

    function verifyRecursiveHalvingProofExternalForTestInternalGas(
        VDFClaim[] calldata _proofList,
        BigNumber memory _n,
        uint256 _proofsLastIndex
    ) external {
        uint256 start = gasleft();
        BigNumber memory _two = BigNumbers.two();
        uint256 i;
        for (; i < _proofsLastIndex; i = unchecked_inc(i)) {
            BigNumber memory _y = _proofList[i].y;
            BigNumber memory _r = modHash(
                bytes.concat(_proofList[i].y.val, _proofList[i].v.val),
                _proofList[i].x
            ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
            if (_proofList[i].T & ONE == ONE) _y = _y.modexp(_two, _n);
            BigNumber memory _xPrime = _proofList[i].x.modexp(_r, _n).modmul(_proofList[i].v, _n);
            if (!_xPrime.eq(_proofList[unchecked_inc(i)].x)) revert XPrimeNotEqualAtIndex(i);
            BigNumber memory _yPrime = _proofList[i].v.modexp(_r, _n);
            if (!_yPrime.modmul(_y, _n).eq(_proofList[unchecked_inc(i)].y))
                revert YPrimeNotEqualAtIndex(i);
        }
        if (!_proofList[i].y.eq(_proofList[i].x.modexp(_two, _n))) revert NotVerifiedAtTOne();
        if (i != _proofsLastIndex || _proofList[i].T != ONE) revert TOneNotAtLast();
        emit VerifyRecursiveHalvingProofGasUsed(start - gasleft());
    }

    function unchecked_inc(uint256 i) private pure returns (uint) {
        unchecked {
            return i + ONE;
        }
    }
}
