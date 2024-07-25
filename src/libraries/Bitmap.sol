// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BitMath} from "./BitMath.sol";

library Bitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(
        uint24 tick
    ) internal pure returns (uint16 wordPos, uint8 bitPos) {
        assembly {
            // signed arithmetic shift right
            wordPos := shr(8, tick)
            bitPos := and(tick, 0xff) // % 256
        }
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    function flipTick(
        mapping(uint16 => uint256) storage self,
        uint24 tick
    ) internal {
        // Equivalent to the following Solidity:
        //     if (tick % tickSpacing != 0) revert TickMisaligned(tick, tickSpacing);
        //     (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        //     uint256 mask = 1 << bitPos;
        //     self[wordPos] ^= mask;
        assembly ("memory-safe") {
            // calculate the storage slot corresponding to the tick
            // wordPos = tick >> 8
            mstore(0, shr(8, tick))
            mstore(0x20, self.slot)
            // the slot of self[wordPos] is keccak256(abi.encode(wordPos, self.slot))
            let slot := keccak256(0, 0x40)
            // mask = 1 << bitPos = 1 << (tick % 256)
            // self[wordPos] ^= mask
            sstore(slot, xor(sload(slot), shl(and(tick, 0xff), 1)))
        }
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(uint16 => uint256) storage self,
        uint24 tick,
        bool lte
    ) internal view returns (uint24 next, bool initialized) {
        unchecked {
            if (lte) {
                (uint16 wordPos, uint8 bitPos) = position(tick);
                // all the 1s at or to the right of the current bitPos
                uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
                uint256 masked = self[wordPos] & mask;

                // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (tick -
                        uint24(bitPos - BitMath.mostSignificantBit(masked)))
                    : (tick - uint24(bitPos));
            } else {
                // start from the word of the next tick, since the current tick state doesn't matter
                (uint16 wordPos, uint8 bitPos) = position(++tick);
                // all the 1s at or to the left of the bitPos
                uint256 mask = ~((1 << bitPos) - 1);
                uint256 masked = self[wordPos] & mask;

                // if there are no initialized ticks to the left of the current tick, return leftmost in the word
                initialized = masked != 0;
                // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
                next = initialized
                    ? (tick +
                        uint24(BitMath.leastSignificantBit(masked) - bitPos))
                    : (tick + uint24(type(uint8).max - bitPos));
            }
        }
    }
}
