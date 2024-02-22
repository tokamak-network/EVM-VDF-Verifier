// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.23;

// import {BigNumbers} from "./../libraries/BigNumbers.sol";
// import "./../interfaces/ICommitRevealRecoverRNG.sol";
// import "hardhat/console.sol";

// contract CommitRevealRecoverRNGTest is ICommitRevealRecoverRNG {
//     using BigNumbers for *;
//     bytes private constant MODFORHASH =
//         hex"0000000000000000000000000000000100000000000000000000000000000000";
//     uint256 private constant MODFORHASH_LEN = 129;
//     uint256 private constant ZERO = 0;
//     uint256 private constant ONE = 1;

//     /* State variables */
//     uint256 private nextRound;
//     mapping(uint256 round => SetUpValueAtRound) private setUpValuesAtRound;
//     mapping(uint256 round => ValueAtRound) private valuesAtRound;
//     mapping(uint256 round => mapping(uint256 index => CommitRevealValue))
//         private commitRevealValues;
//     mapping(address owner => mapping(uint256 round => UserAtRound)) private userInfosAtRound;

//     event VerifyRecursiveHalvingProofGasUsed(uint256 gasUsed);

//     function verifyRecursiveHalvingProofExternalForTest(
//         VDFClaim[] calldata _proofList,
//         BigNumber memory _n,
//         uint256 _proofSize
//     ) external {
//         BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
//         uint256 i;
//         for (; i < _proofSize; i = unchecked_inc(i)) {
//             if (_proofList[i].T == ONE) {
//                 if (!_proofList[i].y.eq(_proofList[i].x.modexp(_two, _n)))
//                     revert NotVerifiedAtTOne();
//                 if (i + ONE != _proofSize) revert TOneNotAtLast();
//                 return;
//             }
//             BigNumber memory _y = _proofList[i].y;
//             BigNumber memory _r = modHash(
//                 bytes.concat(_proofList[i].y.val, _proofList[i].v.val),
//                 _proofList[i].x
//             ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
//             if (_proofList[i].T & ONE == ONE) _y = _y.modexp(_two, _n);
//             BigNumber memory _xPrime = _proofList[i].x.modexp(_r, _n).modmul(_proofList[i].v, _n);
//             if (!_xPrime.eq(_proofList[unchecked_inc(i)].x)) revert XPrimeNotEqualAtIndex(i);
//             BigNumber memory _yPrime = _proofList[i].v.modexp(_r, _n);
//             if (!_yPrime.modmul(_y, _n).eq(_proofList[unchecked_inc(i)].y))
//                 revert YPrimeNotEqualAtIndex(i);
//         }
//         if (i != _proofSize) revert iNotMatchProofSize();
//     }

//     function verifyRecursiveHalvingProofExternalForTestInternalGas(
//         VDFClaim[] calldata _proofList,
//         BigNumber memory _n,
//         uint256 _proofSize
//     ) external {
//         uint256 start = gasleft();
//         BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
//         uint256 i;
//         for (; i < _proofSize; i = unchecked_inc(i)) {
//             if (_proofList[i].T == ONE) {
//                 if (!_proofList[i].y.eq(_proofList[i].x.modexp(_two, _n)))
//                     revert NotVerifiedAtTOne();
//                 emit VerifyRecursiveHalvingProofGasUsed(start - gasleft());
//                 if (i + ONE != _proofSize) revert TOneNotAtLast();
//                 return;
//             }
//             BigNumber memory _y = _proofList[i].y;
//             BigNumber memory _r = modHash(
//                 bytes.concat(_proofList[i].y.val, _proofList[i].v.val),
//                 _proofList[i].x
//             ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
//             if (_proofList[i].T & ONE == ONE) _y = _y.modexp(_two, _n);
//             BigNumber memory _xPrime = _proofList[i].x.modexp(_r, _n).modmul(_proofList[i].v, _n);
//             if (!_xPrime.eq(_proofList[unchecked_inc(i)].x)) revert XPrimeNotEqualAtIndex(i);
//             BigNumber memory _yPrime = _proofList[i].v.modexp(_r, _n);
//             if (!_yPrime.modmul(_y, _n).eq(_proofList[unchecked_inc(i)].y))
//                 revert YPrimeNotEqualAtIndex(i);
//         }
//         if (i != _proofSize) revert iNotMatchProofSize();
//     }

//     function commit(uint256 _round, BigNumber memory _c) external override {
//         if (_c.isZero()) revert ShouldNotBeZero();
//         if (userInfosAtRound[msg.sender][_round].committed) revert AlreadyCommitted();
//         checkStage(_round);
//         equalStage(_round, Stages.Commit);
//         uint256 _count = valuesAtRound[_round].count;
//         bytes memory _commitsString = valuesAtRound[_round].commitsString;
//         _commitsString = bytes.concat(_commitsString, _c.val);
//         userInfosAtRound[msg.sender][_round] = UserAtRound(_count, true, false);
//         commitRevealValues[_round][_count] = CommitRevealValue(_c, BigNumber(BigNumbers.BYTESZERO, BigNumbers.UINTZERO), msg.sender); //index setUps from 0, so _count -1
//         valuesAtRound[_round].commitsString = _commitsString;
//         valuesAtRound[_round].count = ++_count;
//         emit CommitC(msg.sender, _c, _commitsString, _count, block.timestamp);
//     }

//     function reveal(uint256 _round, BigNumber calldata _a) external override {
//         UserAtRound memory _user = userInfosAtRound[msg.sender][_round];
//         if (!_user.committed) revert NotCommittedParticipant();
//         if (_user.revealed) revert AlreadyRevealed();
//         if (
//             !(setUpValuesAtRound[_round].g.modexp(_a, setUpValuesAtRound[_round].n)).eq(
//                 commitRevealValues[_round][_user.index].c
//             )
//         ) revert ModExpRevealNotMatchCommit();
//         checkStage(_round);
//         equalStage(_round, Stages.Reveal);
//         //uint256 _count = --count;
//         uint256 _count = valuesAtRound[_round].count -= ONE;
//         commitRevealValues[_round][_user.index].a = _a;
//         if (_count == ZERO) {
//             valuesAtRound[_round].stage = Stages.Finished;
//             valuesAtRound[_round].isAllRevealed = true;
//         }
//         userInfosAtRound[msg.sender][_round].revealed = true;
//         emit RevealA(msg.sender, _a, _count, block.timestamp);
//     }

//     function calculateOmega(uint256 _round) external override returns (BigNumber memory) {
//         if (!valuesAtRound[_round].isAllRevealed) revert NotAllRevealed();
//         if (valuesAtRound[_round].isCompleted) return valuesAtRound[_round].omega;
//         checkStage(_round);
//         equalStage(_round, Stages.Finished);
//         uint256 _numOfParticipants = valuesAtRound[_round].numOfParticipants;
//         BigNumber memory _omega = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
//         bytes memory _bStar = valuesAtRound[_round].bStar;
//         BigNumber memory _h = setUpValuesAtRound[_round].h;
//         BigNumber memory _n = setUpValuesAtRound[_round].n;
//         for (uint256 i; i < _numOfParticipants; i = unchecked_inc(i)) {
//             BigNumber memory _temp = modHash(
//                 bytes.concat(commitRevealValues[_round][i].c.val, _bStar),
//                 _n
//             );
//             _omega = _omega.modmul(
//                 _h.modexp(_temp, _n).modexp(commitRevealValues[_round][i].a, _n),
//                 _n
//             );
//         }
//         valuesAtRound[_round].omega = _omega;
//         valuesAtRound[_round].isCompleted = true; //false when not all participants have revealed
//         valuesAtRound[_round].stage = Stages.Finished;
//         emit CalculatedOmega(_round, _omega, block.timestamp);
//         return _omega;
//     }

//     function recover(uint256 _round, VDFClaim[] calldata proofs) external override {
//         BigNumber memory _n = setUpValuesAtRound[_round].n;
//         uint256 _proofsLastIndex = proofs.length;
//         checkStage(_round);
//         uint256 _numOfParticipants = valuesAtRound[_round].numOfParticipants;
//         if (valuesAtRound[_round].stage == Stages.Commit) revert FunctionInvalidAtThisStage();
//         if (_numOfParticipants == ZERO) revert NoneParticipated();
//         bytes memory _bStar = valuesAtRound[_round].bStar;
//         if (valuesAtRound[_round].isCompleted) revert OmegaAlreadyCompleted();
//         if (
//             setUpValuesAtRound[_round].T != proofs[ZERO].T ||
//             setUpValuesAtRound[_round].proofSize != _proofsLastIndex
//         ) revert TNotMatched();
//         verifyRecursiveHalvingProof(proofs, _n, _proofsLastIndex);
//         BigNumber memory _recov = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
//         for (uint256 i; i < _numOfParticipants; i = unchecked_inc(i)) {
//             BigNumber memory _c = commitRevealValues[_round][i].c;
//             _recov = _recov.modmul(_c.modexp(modHash(bytes.concat(_c.val, _bStar), _n), _n), _n);
//         }
//         if (!_recov.eq(proofs[ZERO].x)) revert RecovNotMatchX();
//         valuesAtRound[_round].isCompleted = true;
//         valuesAtRound[_round].omega = proofs[ZERO].y;
//         valuesAtRound[_round].stage = Stages.Finished;
//         emit Recovered(msg.sender, _recov, proofs[ZERO].y, block.timestamp);
//     }

//     function setUp(
//         uint256 _commitDuration,
//         uint256 _commitRevealDuration,
//         BigNumber calldata _n,
//         VDFClaim[] calldata _proofs
//     ) external override returns (uint256 _round) {
//         _round = nextRound++;
//         uint256 _proofsLastIndex = _proofs.length;
//         if (_commitDuration >= _commitRevealDuration)
//             revert CommitRevealDurationLessThanCommitDuration();
//         verifyRecursiveHalvingProof(_proofs, _n, _proofsLastIndex);
//         setUpValuesAtRound[_round].setUpTime = block.timestamp;
//         setUpValuesAtRound[_round].commitDuration = _commitDuration;
//         setUpValuesAtRound[_round].commitRevealDuration = _commitRevealDuration;
//         setUpValuesAtRound[_round].T = _proofs[ZERO].T;
//         setUpValuesAtRound[_round].g = _proofs[ZERO].x;
//         setUpValuesAtRound[_round].h = _proofs[ZERO].y;
//         setUpValuesAtRound[_round].n = _n;
//         setUpValuesAtRound[_round].proofSize = _proofsLastIndex;
//         valuesAtRound[_round].stage = Stages.Commit;
//         valuesAtRound[_round].count = ZERO;
//         valuesAtRound[_round].commitsString = "";
//         emit SetUp(
//             msg.sender,
//             block.timestamp,
//             _commitDuration,
//             _commitRevealDuration,
//             _n,
//             _proofs[ZERO].x,
//             _proofs[ZERO].y,
//             _proofs[ZERO].T,
//             _round
//         );
//     }

//     function getNextRound() external view override returns (uint256) {
//         return nextRound;
//     }

//     function getSetUpValuesAtRound(
//         uint256 _round
//     ) external view override returns (SetUpValueAtRound memory) {
//         return setUpValuesAtRound[_round];
//     }

//     function getValuesAtRound(uint256 _round) external view override returns (ValueAtRound memory) {
//         return valuesAtRound[_round];
//     }

//     function getCommitRevealValues(
//         uint256 _round,
//         uint256 _index
//     ) external view override returns (CommitRevealValue memory) {
//         return commitRevealValues[_round][_index];
//     }

//     function getUserInfosAtRound(
//         address _owner,
//         uint256 _round
//     ) external view override returns (UserAtRound memory) {
//         return userInfosAtRound[_owner][_round];
//     }

//     /**
//      * @notice checkStage function
//      * @notice revert if the current stage is not the given stage
//      * @notice this function is used to check if the current stage is the given stage
//      * @notice it will update the stage to the next stage if needed
//      */
//     function checkStage(uint256 _round) private {
//         uint256 _setUpTime = setUpValuesAtRound[_round].setUpTime;
//         if (
//             valuesAtRound[_round].stage == Stages.Commit &&
//             block.timestamp >= _setUpTime + setUpValuesAtRound[_round].commitDuration
//         ) {
//             if (valuesAtRound[_round].count != ZERO) {
//                 valuesAtRound[_round].stage = Stages.Reveal;
//                 valuesAtRound[_round].numOfParticipants = valuesAtRound[_round].count;
//                 valuesAtRound[_round].bStar = modHash(
//                     valuesAtRound[_round].commitsString,
//                     setUpValuesAtRound[_round].n
//                 ).val;
//             } else {
//                 valuesAtRound[_round].stage = Stages.Finished;
//             }
//         }
//         if (
//             valuesAtRound[_round].stage == Stages.Reveal &&
//             (block.timestamp >= _setUpTime + setUpValuesAtRound[_round].commitRevealDuration)
//         ) {
//             valuesAtRound[_round].stage = Stages.Finished;
//         }
//     }

//     function equalStage(uint256 _round, Stages _stage) private view {
//         if (valuesAtRound[_round].stage != _stage) revert FunctionInvalidAtThisStage();
//     }

//     function modHash(
//         bytes memory _strings,
//         BigNumber memory _n
//     ) private view returns (BigNumber memory) {
//         return abi.encodePacked(keccak256(_strings)).init().mod(_n);
//     }

//     function verifyRecursiveHalvingProof(
//         VDFClaim[] calldata _proofList,
//         BigNumber memory _n,
//         uint256 _proofSize
//     ) private view {
//         BigNumber memory _two = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
//         uint256 i;
//         for (; i < _proofSize; i = unchecked_inc(i)) {
//             if (_proofList[i].T == ONE) {
//                 if (!_proofList[i].y.eq(_proofList[i].x.modexp(_two, _n)))
//                     revert NotVerifiedAtTOne();
//                 if (i + ONE != _proofSize) revert TOneNotAtLast();
//                 return;
//             }
//             BigNumber memory _y = _proofList[i].y;
//             BigNumber memory _r = modHash(
//                 bytes.concat(_proofList[i].y.val, _proofList[i].v.val),
//                 _proofList[i].x
//             ).mod(BigNumber(MODFORHASH, MODFORHASH_LEN));
//             if (_proofList[i].T & ONE == ONE) _y = _y.modexp(_two, _n);
//             BigNumber memory _xPrime = _proofList[i].x.modexp(_r, _n).modmul(_proofList[i].v, _n);
//             if (!_xPrime.eq(_proofList[unchecked_inc(i)].x)) revert XPrimeNotEqualAtIndex(i);
//             BigNumber memory _yPrime = _proofList[i].v.modexp(_r, _n);
//             if (!_yPrime.modmul(_y, _n).eq(_proofList[unchecked_inc(i)].y))
//                 revert YPrimeNotEqualAtIndex(i);
//         }
//         if (i != _proofSize) revert iNotMatchProofSize();
//     }

//     function unchecked_inc(uint256 i) private pure returns (uint) {
//         unchecked {
//             return i + ONE;
//         }
//     }

//     function unchecked_dec(uint256 i) private pure returns (uint) {
//         unchecked {
//             return i - ONE;
//         }
//     }

//     bytes1 constant ZEROBYTE1 = hex"00";
//     bytes1 constant ONEMASK = hex"01";
//     bytes1 constant TWOMASK = hex"02";
//     bytes1 constant THREEMASK = hex"04";
//     bytes1 constant FOURMASK = hex"08";
//     bytes1 constant FIVEMASK = hex"10";
//     bytes1 constant SIXMASK = hex"20";
//     bytes1 constant SEVENMASK = hex"40";
//     bytes1 constant EIGHTMASK = hex"80";

//     bytes constant MASKS =
//         abi.encodePacked(
//             EIGHTMASK,
//             SEVENMASK,
//             SIXMASK,
//             FIVEMASK,
//             FOURMASK,
//             THREEMASK,
//             TWOMASK,
//             ONEMASK
//         );

//     function multiExpGas(
//         BigNumber memory _a,
//         BigNumber memory _b,
//         BigNumber memory _x,
//         BigNumber memory _y,
//         BigNumber memory _n
//     ) external returns (BigNumber memory) {
//         uint256 startGas = gasleft();
//         _x.modexp(_a, _n);
//         console.log("gas used for modexp _x^_a %_n:", startGas - gasleft());
//         startGas = gasleft();
//         _x.modexp(_y, _n);
//         console.log("gas used for modexp _x^_y %_n:", startGas - gasleft());
//         startGas = gasleft();
//         _x.modmul(_a, _n);
//         console.log("gas used for modmul _x*_a %_n:", startGas - gasleft());
//         startGas = gasleft();
//         _x.modmul(_y, _n);
//         console.log("gas used for modmul _x*_y%_n:", startGas - gasleft());
//         return _x.modexp(_a, _n).modmul(_y.modexp(_b, _n), _n);
//     }

//     function multiExp(
//         BigNumber memory _a,
//         BigNumber memory _b,
//         BigNumber memory _x,
//         BigNumber memory _y,
//         BigNumber memory _n
//     ) external returns (BigNumber memory) {
//         return _x.modexp(_a, _n).modmul(_y.modexp(_b, _n), _n);
//     }

//     function multiExpView(
//         BigNumber memory _a,
//         BigNumber memory _b,
//         BigNumber memory _x,
//         BigNumber memory _y,
//         BigNumber memory _n
//     ) external view returns (BigNumber memory) {
//         return _x.modexp(_a, _n).modmul(_y.modexp(_b, _n), _n);
//     }

//     function dimitrovMultiExp(
//         BigNumber memory _a,
//         BigNumber memory _b,
//         BigNumber memory _x,
//         BigNumber memory _y,
//         BigNumber memory _n
//     ) external returns (BigNumber memory) {
//         uint256 _h = _a.bitlen;
//         BigNumber memory _z = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
//         BigNumber memory _q = _x.modmul(_y, _n);
//         uint256 _pad = (_h / 8) % 32;
//         _pad = _pad % 2 == 0 ? _pad : _pad + 1;

//         bytes1 tempA = _a.val[_pad];
//         bytes1 tempB = _b.val[_pad];
//         bool _aBool;
//         bool _bBool;
//         for (uint256 j = 8 - (((_h - 1) % 8) + 1); j < 8; j++) {
//             _z = _z.modmul(_z, _n);
//             _aBool = tempA & MASKS[j] > ZEROBYTE1;
//             _bBool = tempB & MASKS[j] > ZEROBYTE1;
//             if (_aBool && _bBool) {
//                 _z = _z.modmul(_q, _n);
//             } else if (_aBool) {
//                 _z = _z.modmul(_x, _n);
//             } else if (_bBool) {
//                 _z = _z.modmul(_y, _n);
//             }
//         }
//         uint iMax = ((_h + 7) / 8) + _pad;
//         for (uint256 i = 1 + _pad; i < iMax; i = unchecked_inc(i)) {
//             tempA = _a.val[i];
//             tempB = _b.val[i];
//             for (uint256 j; j < 8; j++) {
//                 _z = _z.modmul(_z, _n);
//                 _aBool = tempA & MASKS[j] > ZEROBYTE1;
//                 _bBool = tempB & MASKS[j] > ZEROBYTE1;
//                 if (_aBool && _bBool) {
//                     _z = _z.modmul(_q, _n);
//                 } else if (_aBool) {
//                     _z = _z.modmul(_x, _n);
//                 } else if (_bBool) {
//                     _z = _z.modmul(_y, _n);
//                 }
//             }
//         }
//         return _z;
//     }

//     function dimitrovMultiExpView(
//         BigNumber memory _a,
//         BigNumber memory _b,
//         BigNumber memory _x,
//         BigNumber memory _y,
//         BigNumber memory _n
//     ) external view returns (BigNumber memory) {
//         uint256 _h = _a.bitlen > _b.bitlen ? _a.bitlen : _b.bitlen;
//         BigNumber memory _z = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
//         BigNumber memory _q = _x.modmul(_y, _n);

//         bytes1 tempA = _a.val[0];
//         bytes1 tempB = _b.val[0];
//         for (uint256 j = 8 - (((_h - 1) % 8) + 1); j < 8; j++) {
//             _z = _z.modmul(_z, _n);
//             bool _aBool = tempA & MASKS[j] > ZEROBYTE1;
//             bool _bBool = tempB & MASKS[j] > ZEROBYTE1;
//             if (_aBool && _bBool) {
//                 _z = _z.modmul(_q, _n);
//             } else if (_aBool) {
//                 _z = _z.modmul(_x, _n);
//             } else if (_bBool) {
//                 _z = _z.modmul(_y, _n);
//             }
//         }
//         for (uint256 i = 1; i < (_h + 7) / 8; i = unchecked_inc(i)) {
//             tempA = _a.val[i];
//             tempB = _b.val[i];
//             for (uint256 j; j < 8; j++) {
//                 _z = _z.modmul(_z, _n);
//                 bool _aBool = tempA & MASKS[j] > ZEROBYTE1;
//                 bool _bBool = tempB & MASKS[j] > ZEROBYTE1;
//                 if (_aBool && _bBool) {
//                     _z = _z.modmul(_q, _n);
//                 } else if (_aBool) {
//                     _z = _z.modmul(_x, _n);
//                 } else if (_bBool) {
//                     _z = _z.modmul(_y, _n);
//                 }
//             }
//         }
//         return _z;
//     }

//     function dimitrovMultiExpView3ForLoopCount(
//         BigNumber memory _a,
//         BigNumber memory _x,
//         BigNumber memory _y,
//         BigNumber memory _n
//     ) external view returns (BigNumber memory) {
//         BigNumber memory _z = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
//         uint256 _pad = (_a.bitlen / 8) % 32;
//         _pad = _pad % 2 == 0 ? _pad : _pad + 1;
//         uint256 count;
//         console.log(8 - (((_a.bitlen - 1) % 8) + 1));
//         for (uint256 j = 8 - (((_a.bitlen - 1) % 8) + 1); j < 8; j++) {
//             // first 1 byte
//             count++;
//         }
//         uint iMax = ((_a.bitlen + 7) / 8) + _pad;
//         for (uint256 i = 1 + _pad; i < iMax; i = unchecked_inc(i)) {
//             for (uint256 j; j < 8; j = unchecked_inc(j)) {
//                 count++;
//             }
//         }
//         console.log("count:", count);
//         return _z;
//     }

//     function dimitrovMultiExpView2(
//         BigNumber memory _a,
//         BigNumber memory _x,
//         BigNumber memory _y,
//         BigNumber memory _n
//     ) external view returns (BigNumber memory) {
//         BigNumber memory _z = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
//         BigNumber memory _b = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
//         BigNumber memory _q = _x.modmul(_y, _n);
//         uint256 _pad = (_a.bitlen / 8) % 32;
//         _pad = _pad % 2 == 0 ? _pad : _pad + 1;
//         bytes1 tempA = _a.val[_pad];
//         bytes1 tempB = _b.val[_pad];
//         bool _aBool;
//         bool _bBool;
//         for (uint256 j = 8 - (((_a.bitlen - 1) % 8) + 1); j < 8; j++) {
//             // first 1 byte
//             _z = _z.modmul(_z, _n);
//             _aBool = tempA & MASKS[j] > ZEROBYTE1;
//             _bBool = tempB & MASKS[j] > ZEROBYTE1;
//             if (_aBool && _bBool) {
//                 _z = _z.modmul(_q, _n);
//             } else if (_aBool) {
//                 _z = _z.modmul(_x, _n);
//             } else if (_bBool) {
//                 _z = _z.modmul(_y, _n);
//             }
//         }
//         uint iMax = ((_a.bitlen + 7) / 8) + _pad;
//         for (uint256 i = 1 + _pad; i < iMax; i = unchecked_inc(i)) {
//             tempA = _a.val[i];
//             tempB = _b.val[i];
//             for (uint256 j; j < 8; j = unchecked_inc(j)) {
//                 _z = _z.modmul(_z, _n);
//                 _aBool = tempA & MASKS[j] > ZEROBYTE1;
//                 _bBool = tempB & MASKS[j] > ZEROBYTE1;
//                 if (_aBool && _bBool) {
//                     _z = _z.modmul(_q, _n);
//                 } else if (_aBool) {
//                     _z = _z.modmul(_x, _n);
//                 } else if (_bBool) {
//                     _z = _z.modmul(_y, _n);
//                 }
//             }
//         }
//         return _z;
//     }

//     function dimitrovMultiExp2(
//         BigNumber memory _a,
//         BigNumber memory _x,
//         BigNumber memory _y,
//         BigNumber memory _n
//     ) external returns (BigNumber memory) {
//         BigNumber memory _z = BigNumber(BigNumbers.BYTESONE, BigNumbers.UINTONE);
//         BigNumber memory _b = BigNumber(BigNumbers.BYTESTWO, BigNumbers.UINTTWO);
//         BigNumber memory _q = _x.modmul(_y, _n);
//         uint256 _pad = (_a.bitlen / 8) % 32;
//         _pad = _pad % 2 == 0 ? _pad : _pad + 1;
//         bytes1 tempA = _a.val[_pad];
//         bytes1 tempB = _b.val[_pad];
//         bool _aBool;
//         bool _bBool;
//         for (uint256 j = 8 - (((_a.bitlen - 1) % 8) + 1); j < 8; j++) {
//             // first 1 byte
//             _z = _z.modmul(_z, _n);
//             _aBool = tempA & MASKS[j] > ZEROBYTE1;
//             _bBool = tempB & MASKS[j] > ZEROBYTE1;
//             if (_aBool && _bBool) {
//                 _z = _z.modmul(_q, _n);
//             } else if (_aBool) {
//                 _z = _z.modmul(_x, _n);
//             } else if (_bBool) {
//                 _z = _z.modmul(_y, _n);
//             }
//         }
//         uint iMax = ((_a.bitlen + 7) / 8) + _pad;
//         for (uint256 i = 1 + _pad; i < iMax; i = unchecked_inc(i)) {
//             tempA = _a.val[i];
//             tempB = _b.val[i];
//             for (uint256 j; j < 8; j = unchecked_inc(j)) {
//                 _z = _z.modmul(_z, _n);
//                 _aBool = tempA & MASKS[j] > ZEROBYTE1;
//                 _bBool = tempB & MASKS[j] > ZEROBYTE1;
//                 if (_aBool && _bBool) {
//                     _z = _z.modmul(_q, _n);
//                 } else if (_aBool) {
//                     _z = _z.modmul(_x, _n);
//                 } else if (_bBool) {
//                     _z = _z.modmul(_y, _n);
//                 }
//             }
//         }
//         return _z;
//     }
// }
