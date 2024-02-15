// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract GasTest {
    uint256 private constant ONE = 1;
    uint256 private immutable i_one = 1;
    event gasUsed(uint256);

    constructor() {
        i_one = 1;
    }

    function unchecked_incC(uint256 i) private pure returns (uint) {
        unchecked {
            return i + ONE;
        }
    }

    function unchecked_incI(uint256 i) private pure returns (uint) {
        unchecked {
            return i + i_one;
        }
    }

    function unchecked_inc1(uint256 i) private pure returns (uint) {
        unchecked {
            return i + 1;
        }
    }

    function testGasEvent() external {
        uint256 i = 0;
        uint256 start;
        start = gasleft();
        i++;
        emit gasUsed(start - gasleft());
        start = gasleft();
        i++;
        emit gasUsed(start - gasleft());
        start = gasleft();
        i++;
        emit gasUsed(start - gasleft());
    }

    function testConstantImmutable() external {
        uint256 start;
        start = gasleft();
        for (uint256 i; i < 10; i = unchecked_inc1(i)) {}
        emit gasUsed(start - gasleft());
        start = gasleft();
        for (uint256 i; i < 10; i = unchecked_incC(i)) {}
        emit gasUsed(start - gasleft());
        start = gasleft();
        for (uint256 i; i < 10; i = unchecked_incI(i)) {}
        emit gasUsed(start - gasleft());
        start = gasleft();
    }

    function testCheckedLoop() external {
        uint256 start;
        start = gasleft();
        for (uint256 i = 0; i < 10; i += 1) {}
        emit gasUsed(start - gasleft());
        start = gasleft();
        for (uint256 i = 0; i < 10; i = i + 1) {}
        emit gasUsed(start - gasleft());
        start = gasleft();
        for (uint256 i = 0; i < 10; i++) {}
        emit gasUsed(start - gasleft());
        start = gasleft();
        for (uint256 i = 0; i < 10; ++i) {}
        emit gasUsed(start - gasleft());
    }

    function testUncheckedLoop() external {
        uint256 start;
        start = gasleft();
        for (uint256 i; i < 10; i = unchecked_inc1(i)) {}
        emit gasUsed(start - gasleft());
        start = gasleft();
        for (uint256 i; i < 10; ) {
            unchecked {
                i++;
            }
        }
        emit gasUsed(start - gasleft());
        start = gasleft();
        for (uint256 i; i < 10; ) {
            unchecked {
                ++i;
            }
        }
        emit gasUsed(start - gasleft());
    }

    uint256[] public arrs;

    function setArrs() external {
        arrs = new uint256[](5);
        arrs = [0, 1, 2, 3, 4];
    }

    event msizeEvent(uint256);

    // function test() external {
    //     uint256 mSize;
    //     assembly {
    //         mSize := msize()
    //     }
    //     emit msizeEvent(mSize);
    //     for (uint i = 0; i < arrs.length; i++) {
    //         assembly {
    //             mSize := msize()
    //         }
    //         emit msizeEvent(mSize);
    //     }
    // }
    // function testMemory() external {
    //     uint256[] memory b = arrs;
    //     uint256 mSize;
    //     assembly {
    //         mSize := msize()
    //     }
    //     emit msizeEvent(mSize);
    //     for (uint i = 0; i< b.length; i++){
    //         assembly {
    //             mSize := msize()
    //         }
    //         emit msizeEvent(mSize);
    //     }
    // }
    // function testMemoryExpansion() external{
    //     uint256[] memory b = arrs;
    //     uint256 mSize;
    //     assembly {
    //         mSize := msize()
    //     }
    //     emit msizeEvent(mSize);
    //     b.length;
    //     assembly {
    //             mSize := msize()
    //         }
    //     emit msizeEvent(mSize);
    // }
    // function testStack() external view {
    //     uint length = arrs.length;
    //     for (uint i = 0; i < length; i++){

    //     }
    // }

    function while1() external pure {
        uint256 i;
        while (i < 10) {
            unchecked {
                ++i;
            }
        }
    }

    function while2() external pure {
        uint256 i;
        while (i < 10) {
            i = unchecked_inc1(i);
        }
    }
}
