// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {RNGConsumerBase} from "./RNGConsumerBase.sol";
import {ICRRRNGCoordinator} from "./interfaces/ICRRRNGCoordinator.sol";

contract RandomDay is RNGConsumerBase, Ownable {
    error NotEnoughFunds();
    error EventEndedOrNotStarted();

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
    mapping(address => uint256) public s_deposits;
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    mapping(address => RequesterInfos) public s_requesters; /* requester --> RequesterInfos */

    uint256 public requestCount;
    uint256 public lastRequestId;
    uint256 public eventEndTime;
    uint256 public constant EVENTPERIOD = 1 days;

    uint32 public constant CALLBACK_GAS_LIMIT = 100000;

    constructor(address coordinator) RNGConsumerBase(coordinator) Ownable(msg.sender) {}

    function startEvent() external onlyOwner {
        eventEndTime = block.timestamp + EVENTPERIOD;
    }

    function requestRandomWord() external payable {
        if (block.timestamp > eventEndTime) revert EventEndedOrNotStarted();
        s_deposits[msg.sender] += msg.value;
        (uint256 requestId, uint256 requestPrice) = requestRandomness(CALLBACK_GAS_LIMIT);
        if (s_deposits[msg.sender] < requestPrice) revert NotEnoughFunds();
        s_deposits[msg.sender] -= requestPrice;
        s_requests[requestId].requested = true;
        s_requests[requestId].requester = msg.sender;
        s_requesters[msg.sender].requestIds.push(requestId);
        unchecked {
            requestCount++;
        }
        lastRequestId = requestId;
    }

    function withdraw() external {
        uint256 amount = s_deposits[msg.sender];
        s_deposits[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function fulfillRandomWords(uint256 requestId, uint256 hashedOmegaVal) internal override {
        require(s_requests[requestId].requested, "Request not made");
        address requester = s_requests[requestId].requester;
        s_requests[requestId].fulfilled = true;
        s_requests[requestId].randomWord = hashedOmegaVal;
        s_requesters[requester].randomNums.push(hashedOmegaVal % 1001);
        uint256 _requestCount = s_requesters[requester].requestIds.length;
        s_requesters[requester].avgNum =
            (s_requesters[requester].avgNum * (_requestCount - 1) + (hashedOmegaVal % 1001)) /
            _requestCount;
    }

    function getRNGCoordinator() external view returns (address) {
        return address(i_rngCoordinator);
    }
}
