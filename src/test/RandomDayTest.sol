// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RNGConsumerBase} from "../RNGConsumerBase.sol";
import {IRNGCoordinator} from "../interfaces/IRNGCoordinator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Bitmap} from "../libraries/Bitmap.sol";

contract RandomDayTest is RNGConsumerBase, Ownable {
    using Bitmap for mapping(uint16 => uint256);
    using SafeERC20 for IERC20;

    error NotEnoughFunds();
    error EventNotStarted();
    error EventEndedOrNotStarted();
    error EventStillRunning();
    error NotEOA();

    struct RequesterInfos {
        uint256 avgNum;
        uint256[] requestIds;
        uint256[] randomNums;
    }

    struct RequestStatus {
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 randomWord;
        address requester;
    }

    mapping(uint256 => uint256) private s_ticksCount;
    mapping(uint16 => uint256) private s_tickBitmap;
    mapping(uint256 requestId => RequestStatus requestStatus) public s_requests;
    mapping(address requester => RequesterInfos requesterInfos)
        private s_requesters;
    mapping(uint256 tick => address[] requesters) public s_tickRequesters;
    mapping(address requester => uint256 index) public s_requesterIndex;

    uint256 public requestCount;
    uint256 public lastRequestId;
    uint256 public eventEndTime;
    uint256 public constant EVENTPERIOD = 864000;
    uint256 public constant FIRSTPRIZE = 550 ether;
    uint256 public constant SECONDPRIZE = 300 ether;
    uint256 public constant THIRDPRIZE = 150 ether;
    uint256 public constant TOTALPRIZE = 1000 ether;
    uint24 private constant CENTERTICK = 700;
    uint32 private CALLBACK_GAS_LIMIT = 210000;
    IERC20 private immutable i_airdropToken;
    bool private started;

    constructor(
        address coordinator,
        address airdropToken
    ) RNGConsumerBase(coordinator) Ownable(msg.sender) {
        i_airdropToken = IERC20(airdropToken);
    }

    function startEvent() external onlyOwner {
        started = true;
        eventEndTime = block.timestamp + EVENTPERIOD;
    }

    function withdrawAirdropTokenOnlyOwner() external onlyOwner {
        uint256 _balance = i_airdropToken.balanceOf(address(this));
        i_airdropToken.safeTransfer(owner(), _balance);
    }

    function requestRandomWord() external payable {
        if (tx.origin != msg.sender) revert NotEOA();
        if (block.timestamp > eventEndTime) revert EventEndedOrNotStarted();
        (uint256 requestId, uint256 requestPrice) = requestRandomness(
            CALLBACK_GAS_LIMIT
        );
        if (msg.value < requestPrice) revert NotEnoughFunds();
        s_requests[requestId].requested = true;
        s_requests[requestId].requester = msg.sender;
        s_requesters[msg.sender].requestIds.push(requestId);
        unchecked {
            requestCount++;
        }
        lastRequestId = requestId;
        if (msg.value > requestPrice) {
            (bool sent, ) = payable(msg.sender).call{
                value: msg.value - requestPrice
            }("");
            if (!sent) revert NotEnoughFunds();
        }
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256 hashedOmegaVal
    ) internal override {
        require(s_requests[requestId].requested, "Request not made");
        address requester = s_requests[requestId].requester;
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWord = hashedOmegaVal;
        uint256 modOneThousand = (hashedOmegaVal % 1000) + 1;
        s_requesters[requester].randomNums.push(modOneThousand);
        uint256 _requestCount = s_requesters[requester].requestIds.length;
        uint256 _avgNum = s_requesters[requester].avgNum;
        uint256 _newAvgNum = (_avgNum *
            (_requestCount - 1) +
            (modOneThousand)) / _requestCount;
        if (_avgNum != 0 && _avgNum != _newAvgNum) {
            if (--s_ticksCount[_avgNum] == 0) {
                s_tickBitmap.flipTick(uint24(_avgNum));
            }
            uint256 _index = s_requesterIndex[requester];
            address _lastRequester = s_tickRequesters[_avgNum][
                s_tickRequesters[_avgNum].length - 1
            ];
            s_tickRequesters[_avgNum][_index] = _lastRequester;
            s_requesterIndex[_lastRequester] = _index;
            s_tickRequesters[_avgNum].pop();
        }
        s_requesters[requester].avgNum = _newAvgNum;
        if (_avgNum != _newAvgNum) {
            if (++s_ticksCount[_newAvgNum] == 1) {
                s_tickBitmap.flipTick(uint24(_newAvgNum));
            }
            s_tickRequesters[_newAvgNum].push(requester);
            s_requesterIndex[requester] =
                s_tickRequesters[_newAvgNum].length -
                1;
        }
    }

    function blackList(address[] calldata blackListUsers) external onlyOwner {
        if (!started) revert EventNotStarted();
        if (block.timestamp < eventEndTime) revert EventStillRunning();
        for (uint256 i = 0; i < blackListUsers.length; i++) {
            address _requester = blackListUsers[i];
            uint256 _avgNum = s_requesters[_requester].avgNum;
            if (_avgNum != 0) {
                uint256 _index = s_requesterIndex[_requester];
                address _lastRequester = s_tickRequesters[_avgNum][
                    s_tickRequesters[_avgNum].length - 1
                ];
                s_tickRequesters[_avgNum][_index] = _lastRequester;
                s_requesterIndex[_lastRequester] = _index;
                s_tickRequesters[_avgNum].pop();
                if (--s_ticksCount[_avgNum] == 0) {
                    s_tickBitmap.flipTick(uint24(_avgNum));
                }
                s_requesters[_requester].avgNum = 0;
            }
        }
    }

    function finalizeRankingandSendPrize() external onlyOwner {
        if (!started) revert EventNotStarted();
        if (block.timestamp < eventEndTime) revert EventStillRunning();
        (
            uint256[4] memory rticks,
            uint256[4] memory counts
        ) = _getThreeClosestToSevenHundred();
        uint256[4] memory gaps = [uint256(1000), 1000, 1000, 1000];
        for (uint256 i = 0; i < 4; i++) {
            if (rticks[i] == 1001) continue;
            gaps[i] = rticks[i] > CENTERTICK
                ? rticks[i] - CENTERTICK
                : CENTERTICK - rticks[i];
        }
        if (gaps[0] == gaps[1]) {
            uint256 firstCount = counts[0] + counts[1];
            if (firstCount > 2) {
                uint256 eachPrize = (FIRSTPRIZE + SECONDPRIZE + THIRDPRIZE) /
                    firstCount;
                uint256 length = s_tickRequesters[rticks[0]].length;
                for (uint256 i = 0; i < length; i++) {
                    i_airdropToken.safeTransfer(
                        s_tickRequesters[rticks[0]][i],
                        eachPrize
                    );
                }
                length = s_tickRequesters[rticks[1]].length;
                for (uint256 i = 0; i < length; i++) {
                    i_airdropToken.safeTransfer(
                        s_tickRequesters[rticks[1]][i],
                        eachPrize
                    );
                }
                return;
            } else if (firstCount == 2) {
                uint256 eachPrize = (FIRSTPRIZE + SECONDPRIZE) / 2;
                i_airdropToken.safeTransfer(
                    s_tickRequesters[rticks[0]][0],
                    eachPrize
                );
                i_airdropToken.safeTransfer(
                    s_tickRequesters[rticks[1]][0],
                    eachPrize
                );

                if (gaps[2] == gaps[3]) {
                    uint256 thirdCount = counts[2] + counts[3];
                    eachPrize = THIRDPRIZE / thirdCount;
                    uint256 length = s_tickRequesters[rticks[2]].length;
                    for (uint256 i = 0; i < length; i++) {
                        i_airdropToken.safeTransfer(
                            s_tickRequesters[rticks[2]][i],
                            eachPrize
                        );
                    }
                    length = s_tickRequesters[rticks[3]].length;
                    for (uint256 i = 0; i < length; i++) {
                        i_airdropToken.safeTransfer(
                            s_tickRequesters[rticks[3]][i],
                            eachPrize
                        );
                    }
                    return;
                } else {
                    uint256 thirdCount = counts[2];
                    uint256 length = s_tickRequesters[rticks[2]].length;
                    eachPrize = THIRDPRIZE / thirdCount;
                    for (uint256 i = 0; i < length; i++) {
                        i_airdropToken.safeTransfer(
                            s_tickRequesters[rticks[2]][i],
                            eachPrize
                        );
                    }
                    return;
                }
            } // firstCount cannot be 1 or 0
        } else {
            uint256 firstCount = counts[0];
            if (firstCount > 2) {
                uint256 eachPrize = (FIRSTPRIZE + SECONDPRIZE + THIRDPRIZE) /
                    firstCount;
                uint256 length = s_tickRequesters[rticks[0]].length;
                for (uint256 i = 0; i < length; i++) {
                    i_airdropToken.safeTransfer(
                        s_tickRequesters[rticks[0]][i],
                        eachPrize
                    );
                }
                return;
            } else if (firstCount == 2) {
                uint256 eachPrize = (FIRSTPRIZE + SECONDPRIZE) / 2;
                for (uint256 i = 0; i < 2; i++) {
                    i_airdropToken.safeTransfer(
                        s_tickRequesters[rticks[0]][i],
                        eachPrize
                    );
                }
                if (gaps[1] == gaps[2]) {
                    // tie
                    uint256 secondCount = counts[1] + counts[2];
                    eachPrize = THIRDPRIZE / secondCount;
                    uint256 length = s_tickRequesters[rticks[1]].length;
                    for (uint256 i = 0; i < length; i++) {
                        i_airdropToken.safeTransfer(
                            s_tickRequesters[rticks[1]][i],
                            eachPrize
                        );
                    }
                    length = s_tickRequesters[rticks[2]].length;
                    for (uint256 i = 0; i < length; i++) {
                        i_airdropToken.safeTransfer(
                            s_tickRequesters[rticks[2]][i],
                            eachPrize
                        );
                    }
                    return;
                } else {
                    uint256 secondCount = counts[1];
                    if (secondCount > 1) {
                        eachPrize = THIRDPRIZE / secondCount;
                        uint256 length = s_tickRequesters[rticks[1]].length;
                        for (uint256 i = 0; i < length; i++) {
                            i_airdropToken.safeTransfer(
                                s_tickRequesters[rticks[1]][i],
                                eachPrize
                            );
                        }
                        return;
                    } else if (secondCount == 1) {
                        i_airdropToken.safeTransfer(
                            s_tickRequesters[rticks[1]][0],
                            THIRDPRIZE
                        );
                        return;
                    }
                }
            } else {
                i_airdropToken.safeTransfer(
                    s_tickRequesters[rticks[0]][0],
                    FIRSTPRIZE
                );
                if (gaps[1] == gaps[2]) {
                    // tie
                    uint256 secondCount = counts[1] + counts[2];
                    uint256 eachPrize = (SECONDPRIZE + THIRDPRIZE) /
                        secondCount;
                    uint256 length = s_tickRequesters[rticks[1]].length;
                    for (uint256 i = 0; i < length; i++) {
                        i_airdropToken.safeTransfer(
                            s_tickRequesters[rticks[1]][i],
                            eachPrize
                        );
                    }
                    length = s_tickRequesters[rticks[2]].length;
                    for (uint256 i = 0; i < length; i++) {
                        i_airdropToken.safeTransfer(
                            s_tickRequesters[rticks[2]][i],
                            eachPrize
                        );
                    }
                    return;
                } else {
                    uint256 secondCount = counts[1];
                    if (secondCount > 1) {
                        uint256 eachPrize = (SECONDPRIZE + THIRDPRIZE) /
                            secondCount;
                        uint256 length = s_tickRequesters[rticks[1]].length;
                        for (uint256 i = 0; i < length; i++) {
                            i_airdropToken.safeTransfer(
                                s_tickRequesters[rticks[1]][i],
                                eachPrize
                            );
                        }
                        return;
                    } else if (secondCount == 1) {
                        i_airdropToken.safeTransfer(
                            s_tickRequesters[rticks[1]][0],
                            SECONDPRIZE
                        );
                        if (gaps[2] == gaps[3]) {
                            // tie
                            uint256 thirdCount = counts[2] + counts[3];
                            uint256 eachPrize = THIRDPRIZE / thirdCount;
                            uint256 length = s_tickRequesters[rticks[2]].length;
                            for (uint256 i = 0; i < length; i++) {
                                i_airdropToken.safeTransfer(
                                    s_tickRequesters[rticks[2]][i],
                                    eachPrize
                                );
                            }
                            length = s_tickRequesters[rticks[3]].length;
                            for (uint256 i = 0; i < length; i++) {
                                i_airdropToken.safeTransfer(
                                    s_tickRequesters[rticks[3]][i],
                                    eachPrize
                                );
                            }
                            return;
                        } else {
                            uint256 thirdCount = counts[2];
                            if (thirdCount > 1) {
                                uint256 eachPrize = THIRDPRIZE / thirdCount;
                                uint256 length = s_tickRequesters[rticks[2]]
                                    .length;
                                for (uint256 i = 0; i < length; i++) {
                                    i_airdropToken.safeTransfer(
                                        s_tickRequesters[rticks[2]][i],
                                        eachPrize
                                    );
                                }
                                return;
                            } else if (thirdCount == 1) {
                                i_airdropToken.safeTransfer(
                                    s_tickRequesters[rticks[2]][0],
                                    THIRDPRIZE
                                );
                                return;
                            }
                        }
                    }
                }
            }
        }
    }

    function getRequestersInfos(
        address requester
    ) external view returns (uint256, uint256[] memory, uint256[] memory) {
        return (
            s_requesters[requester].avgNum,
            s_requesters[requester].requestIds,
            s_requesters[requester].randomNums
        );
    }

    function getThreeClosestToSevenHundred()
        external
        view
        returns (uint256[4] memory, uint256[4] memory)
    {
        return _getThreeClosestToSevenHundred();
    }

    function getRNGCoordinator() external view returns (address) {
        return address(i_rngCoordinator);
    }

    function getTickRequesters(
        uint256 tick
    ) external view returns (address[] memory) {
        return s_tickRequesters[tick];
    }

    function _getThreeClosestToSevenHundred()
        private
        view
        returns (uint256[4] memory, uint256[4] memory)
    {
        uint256[4] memory rticks = [uint256(1001), 1001, 1001, 1001];
        uint256[4] memory counts = [uint256(0), 0, 0, 0];
        uint24 currentTickLeft = 700;
        uint24 currentTickRight = 700;
        bool leftFound;
        bool rightFound;
        (currentTickLeft, leftFound) = _findNextinitializedTick(
            currentTickLeft,
            true
        );
        (currentTickRight, rightFound) = _findNextinitializedTick(
            currentTickRight,
            false
        );
        uint256 totalCount;
        if (leftFound || rightFound) {
            // count is at least 1
            (uint256 i, bool leftCount, bool rightCount) = _handleFoundTicks(
                rticks,
                counts,
                currentTickLeft,
                currentTickRight,
                0,
                leftFound,
                rightFound
            );
            if (leftCount && rightCount) {
                unchecked {
                    totalCount += counts[i - 1];
                    totalCount += counts[i - 2];
                }
            } else {
                unchecked {
                    totalCount += counts[i - 1];
                }
            }
            if (totalCount > 2) return (rticks, counts);
            if (leftCount && rightCount) {
                unchecked {
                    --currentTickLeft;
                }
                (currentTickLeft, leftFound) = _findNextinitializedTick(
                    currentTickLeft,
                    true
                );
                (currentTickRight, rightFound) = _findNextinitializedTick(
                    currentTickRight,
                    false
                );
            } else if (leftCount) {
                unchecked {
                    --currentTickLeft;
                }
                (currentTickLeft, leftFound) = _findNextinitializedTick(
                    currentTickLeft,
                    true
                );
            } else if (rightCount) {
                (currentTickRight, rightFound) = _findNextinitializedTick(
                    currentTickRight,
                    false
                );
            }
            if (leftFound || rightFound) {
                // count is at least 2
                (i, leftCount, rightCount) = _handleFoundTicks(
                    rticks,
                    counts,
                    currentTickLeft,
                    currentTickRight,
                    i,
                    leftFound,
                    rightFound
                );
                if (leftCount && rightCount) {
                    unchecked {
                        totalCount += counts[i - 1];
                        totalCount += counts[i - 2];
                    }
                } else {
                    unchecked {
                        totalCount += counts[i - 1];
                    }
                }
                if (totalCount > 2) return (rticks, counts);
                if (leftCount && rightCount) {
                    unchecked {
                        --currentTickLeft;
                    }
                    (currentTickLeft, leftFound) = _findNextinitializedTick(
                        currentTickLeft,
                        true
                    );
                    (currentTickRight, rightFound) = _findNextinitializedTick(
                        currentTickRight,
                        false
                    );
                } else if (leftCount) {
                    unchecked {
                        --currentTickLeft;
                    }
                    (currentTickLeft, leftFound) = _findNextinitializedTick(
                        currentTickLeft,
                        true
                    );
                } else if (rightCount) {
                    (currentTickRight, rightFound) = _findNextinitializedTick(
                        currentTickRight,
                        false
                    );
                }

                if (leftFound || rightFound) {
                    // count is at least 3
                    (i, leftCount, rightCount) = _handleFoundTicks(
                        rticks,
                        counts,
                        currentTickLeft,
                        currentTickRight,
                        i,
                        leftFound,
                        rightFound
                    );
                }
            }
        }
        return (rticks, counts);
    }

    function _findNextinitializedTick(
        uint24 currentTick,
        bool left
    ) private view returns (uint24, bool found) {
        while (currentTick < 1001 && currentTick > 0) {
            (uint24 nextTick, bool initialized) = s_tickBitmap
                .nextInitializedTickWithinOneWord(currentTick, left);
            if (initialized) {
                currentTick = nextTick;
                found = true;
                break;
            }
            unchecked {
                uint24 _left;
                assembly {
                    _left := left
                }
                currentTick = nextTick - _left;
            }
        }
        return (currentTick, found);
    }

    function _handleFoundTicks(
        uint256[4] memory rticks,
        uint256[4] memory counts,
        uint256 currentTickLeft,
        uint256 currentTickRight,
        uint256 i,
        bool leftFound,
        bool rightFound
    ) private view returns (uint256, bool leftCount, bool rightCount) {
        if (leftFound && rightFound) {
            uint256 leftDiff = CENTERTICK - currentTickLeft;
            uint256 rightDiff = currentTickRight - CENTERTICK;
            if (leftDiff < rightDiff) {
                unchecked {
                    counts[i] += s_ticksCount[currentTickLeft];
                }
                rticks[i] = currentTickLeft;
                leftCount = true;
            } else if (leftDiff > rightDiff) {
                unchecked {
                    counts[i] += s_ticksCount[currentTickRight];
                }
                rticks[i] = currentTickRight;
                rightCount = true;
            } else {
                unchecked {
                    counts[i] += s_ticksCount[currentTickLeft];
                }
                rticks[i] = currentTickLeft;
                unchecked {
                    counts[++i] += s_ticksCount[currentTickRight];
                }
                rticks[i] = currentTickRight;
                leftCount = true;
                rightCount = true;
            }
        } else if (leftFound) {
            unchecked {
                counts[i] += s_ticksCount[currentTickLeft];
            }
            rticks[i] = currentTickLeft;
            leftCount = true;
        } else if (rightFound) {
            unchecked {
                counts[i] += s_ticksCount[currentTickRight];
            }
            rticks[i] = currentTickRight;
            rightCount = true;
        }
        return (++i, leftCount, rightCount);
    }
}
