// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Bitmap} from "../libraries/Bitmap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GetClosestTickTest {
    using SafeERC20 for IERC20;
    using Bitmap for mapping(uint16 => uint256);
    mapping(uint256 => uint256) private s_ticksCount;
    mapping(uint16 => uint256) private s_tickBitmap;
    mapping(uint256 tick => address[] requesters) public s_tickRequesters;
    uint24 public constant CENTERTICK = 700;

    uint256 public constant FIRSTPRIZE = 550 ether;
    uint256 public constant SECONDPRIZE = 300 ether;
    uint256 public constant THIRDPRIZE = 150 ether;
    uint256 public constant TOTALPRIZE = 1000 ether;
    IERC20 public immutable i_airdropToken;
    uint256 public s_count = 0;

    constructor(address airdropToken) {
        i_airdropToken = IERC20(airdropToken);
    }

    function setTicks(uint256 num) external {
        if (++s_ticksCount[num] == 1) s_tickBitmap.flipTick(uint24(num));
        s_tickRequesters[num].push(address(uint160(++s_count)));
    }

    function finalizeRankingandSendPrize() external {
        (
            uint256[4] memory rticks,
            uint256[4] memory counts
        ) = getThreeClosestToSevenHundred();
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

    function getThreeClosestToSevenHundred()
        public
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
