// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./libraries/Strings.sol";

/* Errors */
error CommitReveal__AlreadyRevealed();
error CommitReveal__InvalidCommitValue();
error CommitReveal__ANotMatchCommit();
error CommitReveal__FunctionInvalidAtThisStage();
error CommitReveal__StageNotFinished();
error CommitReveal__HNotSet();
error CommitReveal__AllFinished();
error CommitReveal__OmegaAlreadyCompleted();

contract CommitReveal {
    /* Type declaration */
    enum Stages {
        Commit,
        Reveal,
        Finished
    }
    struct Commit {
        uint256 c;
        bool revealed;
    }

    /* State variables */
    Stages public stage;
    uint256 public startTime;
    uint256 public commitDuration;
    uint256 public commmitRevealDuration;
    uint256 public order;
    uint256 public g;
    uint256 public h;
    uint256 public omega;
    uint256 public count;
    string public commitsString;
    bytes32 public bStar;
    bool public isHSet;

    mapping(address owner => Commit commit) public commitsInfos;
    mapping(uint256 index => address owner) public commits;

    /* Events */
    event CommitC(address participant, uint256 commit, uint256 commitCount);
    event RevealA(address participant, uint256 a, uint256 omega, uint256 revealCount);

    /* Functions */
    constructor(
        uint256 _commitDuration,
        uint256 _commmitRevealDuration,
        uint256 _order,
        uint256 _g
    ) {
        stage = Stages.Commit;
        startTime = block.timestamp;
        commitDuration = _commitDuration;
        commmitRevealDuration = _commmitRevealDuration;
        order = _order;
        g = _g;
        omega = 1;
    }

    function commit(uint256 _commit) public {
        //check
        if (_commit >= order) revert CommitReveal__InvalidCommitValue();
        updateStage(Stages.Commit);
        commitsInfos[msg.sender] = Commit(_commit, false);
        commitsString = string.concat(commitsString, Strings.toString(_commit));
        count += 1;
        emit CommitC(msg.sender, _commit, count);
    }

    function reveal(uint256 _a) public {
        if (isHSet == false) revert CommitReveal__HNotSet();
        updateStage(Stages.Reveal);
        Commit memory _commit = commitsInfos[msg.sender];
        if (_commit.revealed == true) {
            revert CommitReveal__AlreadyRevealed();
        }
        if (powerModOrder(g, _a) != _commit.c) {
            revert CommitReveal__ANotMatchCommit();
        }
        omega =
            (omega *
                powerModOrder(
                    powerModOrder(h, uint256(keccak256(abi.encodePacked(_commit.c, bStar)))),
                    _a
                )) %
            order;
        commitsInfos[msg.sender].revealed = true;
        count -= 1;
        emit RevealA(msg.sender, _a, omega, count);
    }

    function recover(uint256 recov) public {
        if (stage == Stages.Commit) {
            revert CommitReveal__FunctionInvalidAtThisStage();
        }
        if (count == 0) {
            revert CommitReveal__OmegaAlreadyCompleted();
        }
        /**
         * need to verify recov
         */
        omega = mulmod(omega, recov, order);
        stage = Stages.Finished;
    }

    function start() public {
        if (stage != Stages.Finished) {
            revert CommitReveal__StageNotFinished();
        }
        stage = Stages.Commit;
        startTime = block.timestamp;
        omega = 1;
    }

    function setBStar() public {
        bStar = keccak256(abi.encodePacked(commitsString));
    }

    function setH(uint256 _h) public {
        /**
         * need to verify _h
         */
        verifyH(_h);
        isHSet = true;
        h = _h;
    }

    function updateStage(Stages _stage) public {
        Stages _currentStage = stage;
        uint256 _startTime = startTime;
        if (_currentStage == Stages.Commit && block.timestamp >= _startTime + commitDuration) {
            if (count != 0) {
                nextStage();
                if (bStar != keccak256(abi.encodePacked(commitsString))) {
                    setBStar();
                }
            } else {
                stage = Stages.Finished;
            }
        } else if (
            _currentStage == Stages.Reveal && block.timestamp >= _startTime + commmitRevealDuration
        ) {
            nextStage();
            count = 0;
            isHSet = false;
        }
        if (stage != _stage) revert CommitReveal__FunctionInvalidAtThisStage();
    }

    function verifyH(uint256 _h) public view returns (bool) {
        uint256 _g = g;
        /**
         * need to verify _h
         */
        return true;
    }

    function nextStage() internal {
        if (stage == Stages.Finished) revert CommitReveal__AllFinished();
        stage = Stages(addmod(uint256(stage), 1, 3));
    }

    function powerModOrder(uint256 a, uint256 b) internal view returns (uint256) {
        uint256 _order = order;
        uint256 result = 1;
        while (b > 0) {
            if (b & 1 == 1) {
                result = mulmod(result, a, _order);
            }
            a = mulmod(a, a, _order);
            b = b / 2;
        }
        return result;
    }
}
