// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Bitmap} from "../libraries/Bitmap.sol";

contract GetClosestTickTest {
    using Bitmap for mapping(uint16 => uint256);
    mapping(uint256 => uint256) private s_ticksCount;
    mapping(uint16 => uint256) private s_tickBitmap;
    uint24 public constant CENTERTICK = 700;

    function setTicks(uint256 num) external {
        if (++s_ticksCount[num] == 1) s_tickBitmap.flipTick(uint24(num));
    }

    function getThreeClosestToSevenHundred()
        external
        view
        returns (uint256[4] memory, uint256[4] memory)
    {
        uint256[4] memory rticks = [uint256(1001), 1001, 1001, 1001];
        uint256[4] memory counts = [uint256(0), 0, 0, 0];
        uint24 currentTickLeft = 700;
        uint24 currentTickRight = 700;
        bool leftFound;
        bool rightFound;
        (currentTickLeft, leftFound) = _findNextinitializedTick(currentTickLeft, true);
        (currentTickRight, rightFound) = _findNextinitializedTick(currentTickRight, false);
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
                (currentTickLeft, leftFound) = _findNextinitializedTick(currentTickLeft, true);
                (currentTickRight, rightFound) = _findNextinitializedTick(currentTickRight, false);
            } else if (leftCount) {
                unchecked {
                    --currentTickLeft;
                }
                (currentTickLeft, leftFound) = _findNextinitializedTick(currentTickLeft, true);
            } else if (rightCount) {
                (currentTickRight, rightFound) = _findNextinitializedTick(currentTickRight, false);
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
                    (currentTickLeft, leftFound) = _findNextinitializedTick(currentTickLeft, true);
                    (currentTickRight, rightFound) = _findNextinitializedTick(
                        currentTickRight,
                        false
                    );
                } else if (leftCount) {
                    unchecked {
                        --currentTickLeft;
                    }
                    (currentTickLeft, leftFound) = _findNextinitializedTick(currentTickLeft, true);
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
            (uint24 nextTick, bool initialized) = s_tickBitmap.nextInitializedTickWithinOneWord(
                currentTick,
                left
            );
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
