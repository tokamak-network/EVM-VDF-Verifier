// SPDX-License-Identifier: MIT
import "../libraries/Pietrzak_VDF.sol";
pragma solidity ^0.8.19;

interface ICommitRecover {
    function commit(uint256 _commit) external;

    function reveal(uint256 _a) external;

    function calculateOmega() external returns (uint256);

    function recover(uint256 _round, Pietrzak_VDF.VDFClaim[] calldata proofs) external;

    function start(
        uint256 _commitDuration,
        uint256 _commitRevealDuration,
        uint256 _n,
        Pietrzak_VDF.VDFClaim[] memory _proofs
    ) external;

    function checkStage() external;
}
