// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {DRBConsumerBase} from "../DRBConsumerBase.sol";

/**
 * @title DRBConsumerExample
 * @dev A contract that gets random values from VDF DRB
 * @notice This is an example contract that uses hardcoded values for clarity. This is an example contract that uses un-audited code. Do not use this code in production.
 */
contract DRBConsumerExample is DRBConsumerBase {
    struct RequestInfo {
        bool requested;
        uint256 randomNumber;
    }

    mapping(uint256 requestId => RequestInfo requestInfo)
        public s_requestsInfos;

    //////////////////////////////////////////////////////////////*/
    /// @notice The DirectFundingCost is influenced by the security level and the callbackGasLimit.Increasing either of these parameters will result in a higher DirectFundingCost.
    ///
    /// @dev Default is 0, but can be increased as needed for higher security. The higher the security level, the longer the time required to generate the random number.
    uint16 public constant SECURITY = 0;
    /// @dev The Random Number Generation mode
    /// 0 - Pietrzak Proof of Fraud (PoF)
    /// 1 - Pietrzak Proof of Validity (PoV)
    /// 2 - Wesolowski Proof of Fraud (PoF)
    uint16 public constant MODE = 0;
    /// @dev The gas limit for the callback function fulfillRandomWords. Storing random word costs about 20,000 gas, so 100,000 is a safe default for this example contract. Test and adjust this limit based on the processing of the callback request in the fulfillRandomWords function.
    /// If the gasUsed varies each time the `fulfillRandomWords` function is called, the callbackGasLimit must be able to be calculated in advance and passed as a parameter to the requestRandomness function.
    /// Do not implement a callback function `fulfillRandomWords` that cannot anticipate the gas limit.
    uint32 public constant CALLBACK_GAS_LIMIT = 100000;
    //////////////////////////////////////////////////////////////*/

    event ReturnedRandomness(uint256 requestId, uint256 randomNumber);

    /**
     * @notice Constructor inherits DRBConsumerBase
     * @param coordinator The address of the DRBCoordinator contract, set the DRBCoordinatorMock address for local testing
     */
    constructor(address coordinator) DRBConsumerBase(coordinator) {}

    /**
     * @notice Requests Randomness, 'Word' refers to unit of data in Computer Science
     */
    function requestRandomWord() external payable returns (uint256 requestId) {
        requestId = requestRandomness(SECURITY, MODE, CALLBACK_GAS_LIMIT);
        s_requestsInfos[requestId].requested = true;
    }

    /**
     * @notice Callback function used by the Coordinator to return the random number
     * @param requestId of the request
     * @param randomNumber random result from the coordinator
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256 randomNumber
    ) internal override {
        s_requestsInfos[requestId].randomNumber = randomNumber;
        emit ReturnedRandomness(requestId, randomNumber);
    }
}
