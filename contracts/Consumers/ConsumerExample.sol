// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {RNGConsumerBase} from "../RNGConsumerBase.sol";
import {ICRRRNGCoordinator} from "../interfaces/ICRRRNGCoordinator.sol";

contract ConsumerExample is RNGConsumerBase {
    struct RequestStatus {
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 randomWord;
    }

    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public requestCount;
    uint256 public lastRequestId;

    uint32 public constant CALLBACK_GAS_LIMIT = 83011;

    constructor(address coordinator) RNGConsumerBase(coordinator) {}

    function requestRandomWord() external payable {
        (uint256 requestId, ) = requestRandomness(CALLBACK_GAS_LIMIT);
        s_requests[requestId].requested = true;
        requestIds.push(requestId);
        unchecked {
            requestCount++;
        }
        lastRequestId = requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256 hashedOmegaVal) internal override {
        require(s_requests[requestId].requested, "Request not made");
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWord = hashedOmegaVal;
    }

    function getRNGCoordinator() external view returns (address) {
        return address(i_rngCoordinator);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool, bool, uint256) {
        RequestStatus memory request = s_requests[_requestId];
        return (request.requested, request.fulfilled, request.randomWord);
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}
