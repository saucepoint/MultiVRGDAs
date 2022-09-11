// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {LinearVRGDALib, LinearVRGDAx} from "../lib/LinearVRGDALib.sol";
import {LogisticVRGDALib, LogisticVRGDAx} from "../lib/LogisticVRGDALib.sol";
import {toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

/// @title Simple example of adding multiple VRGDAs to a contract
/// @author saucepoint
/// @notice Example contract using BOTH Linear VRGDA and Logistic VRGDA.
/// @dev This is an example. It's not very useful for anything.
contract Contract {
    using LinearVRGDALib for LinearVRGDAx;
    using LogisticVRGDALib for LogisticVRGDAx;

    uint256 startTime = block.timestamp;

    // dummy counters to represent "purchases"
    uint256 resourceA;  // priced via Linear VRGDA
    uint256 resourceB;  // priced via Logistic VRGDA

    // define 2 VRGDAs to price the resources
    LinearVRGDAx internal linearAuction;
    LogisticVRGDAx internal logAuction;

    constructor () {
        // initialize the VRGDAs
        linearAuction = LinearVRGDALib.createLinearVRGDA(1e18, 0.2e18, 1e18);
        logAuction = LogisticVRGDALib.createLogisticVRGDA(1e18, 0.2e18, 1000e18, 1000e18);
    }

    // purchase resourceA, according to the linear VRGDA
    function buyLinear(uint256 amount) public payable {
        int256 timeSinceStart = toWadUnsafe(block.timestamp - startTime);
        uint256 price = linearAuction.getVRGDAPrice(timeSinceStart, resourceA);
        require(msg.value >= (price * amount), "Not enough ETH");
        
        unchecked { resourceA += amount; }
    }

    // purchase resourceB, according to the logistic VRGDA
    function buyLogistic(uint256 amount) public payable {
        int256 timeSinceStart = toWadUnsafe(block.timestamp - startTime);
        uint256 price = logAuction.getVRGDAPrice(timeSinceStart, resourceB);
        require(msg.value >= (price * amount), "Not enough ETH");
        
        unchecked { resourceB += amount; }
    }

    // view function for getting the price of resourceA
    function getPriceLinear() public view returns (uint256) {
        int256 timeSinceStart = toWadUnsafe(block.timestamp - startTime);
        return linearAuction.getVRGDAPrice(timeSinceStart, resourceA);
    }

    // view function for getting the price of resourceB
    function getPriceLogistic() public view returns (uint256) {
        int256 timeSinceStart = toWadUnsafe(block.timestamp - startTime);
        return logAuction.getVRGDAPrice(timeSinceStart, resourceB);
    }
}