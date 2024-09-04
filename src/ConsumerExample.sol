// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
import {DRBConsumerBase} from "./DRBConsumerBase.sol";

contract ConsumerExample is DRBConsumerBase {
    struct RequestStatus {
        bool requested; // whether the request has been made
        bool fulfilled; // whether the request has been successfully fulfilled
        uint256 randomNumber;
    }

    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // past requests Id.
    uint256[] public requestIds;
    uint256 public requestCount;
    uint256 public lastRequestId;

    uint32 public constant CALLBACK_GAS_LIMIT = 83011;

    constructor(address coordinator) DRBConsumerBase(coordinator) {}

    function requestRandomNumber() external payable {
        uint256 requestId = _requestRandomNumber(CALLBACK_GAS_LIMIT);
        s_requests[requestId].requested = true;
        requestIds.push(requestId);
        unchecked {
            requestCount++;
        }
        lastRequestId = requestId;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256 hashedOmegaVal
    ) internal override {
        require(s_requests[requestId].requested, "Request not made");
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomNumber = hashedOmegaVal;
    }

    function getRNGCoordinator() external view returns (address) {
        return address(i_drbCoordinator);
    }

    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool, bool, uint256) {
        RequestStatus memory request = s_requests[_requestId];
        return (request.requested, request.fulfilled, request.randomNumber);
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}
