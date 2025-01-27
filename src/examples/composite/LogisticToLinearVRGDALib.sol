// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {wadLn, unsafeDiv, unsafeWadDiv, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

import {LogisticVRGDALib} from "../../lib/LogisticVRGDALib.sol";
import {VRGDALib, VRGDAx} from "../../lib/VRGDALib.sol";

struct LogisticToLinearVRGDAx {
    VRGDAx vrgda;
    int256 logisticLimit;
    int256 timeScale;
    int256 soldBySwitch;
    int256 switchTime;
    int256 perTimeUnit;
}

/// @title Linear Variable Rate Gradual Dutch Auction
/// @author transmissions11 <t11s@paradigm.xyz>
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @author saucepoint
/// @notice VRGDA with a linear issuance curve.
library LogisticToLinearVRGDALib {

    /// @notice Create a Linear VRGDA using specified parameters.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    /// @param _perTimeUnit The number of tokens to target sell in 1 full unit of time, scaled by 1e18.
    /// @return logToLinearVRGDA The created Linear VRGDA (of type struct LogisticToLinearVRGDAx).
    function createLogisticToLinearVRGDA(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _logisticAsymptote,
        int256 _timeScale,
        int256 _soldBySwitch,
        int256 _switchTime,
        int256 _perTimeUnit
    ) internal pure returns (LogisticToLinearVRGDAx memory logToLinearVRGDA) {
        logToLinearVRGDA = LogisticToLinearVRGDAx(
            VRGDALib.createVRGDA(_targetPrice, _priceDecayPercent),
            _logisticAsymptote + 1e18,  // add 1 wad to make the limit inclusive
            _timeScale,
            _soldBySwitch,
            _switchTime,
            _perTimeUnit
        );
    }

    /*//////////////////////////////////////////////////////////////
                              PRICING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param self a VRGDA represented as the LogisticToLinearVRGDAx struct
    /// @param timeSinceStart Units of time passed since the VRGDA began, scaled by 1e18.
    /// @param sold The number of tokens sold so far, scaled by 1e18.
    /// @return uint256 The price of a token according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(LogisticToLinearVRGDAx memory self, int256 timeSinceStart, uint256 sold)
        internal
        pure
        returns (uint256)
    {
        int256 timeDelta;
        unchecked {
            timeDelta = timeSinceStart - getTargetSaleTime(
                self.logisticLimit,
                self.timeScale,
                self.soldBySwitch,
                self.switchTime,
                self.perTimeUnit,
                toWadUnsafe(sold + 1)
            );
        }
        return VRGDALib.getVRGDAPrice(self.vrgda.targetPrice, self.vrgda.decayConstant, timeDelta);
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return int256 The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(LogisticToLinearVRGDAx memory self, int256 sold) internal pure returns (int256) {
        // If we've not yet reached the number of sales required for the switch
        // to occur, we'll continue using the standard logistic VRGDA schedule.
        if (sold < self.soldBySwitch) return LogisticVRGDALib.getTargetSaleTime(self.logisticLimit, self.timeScale, sold);
        
        unchecked {
            return unsafeWadDiv(sold - self.soldBySwitch, self.perTimeUnit) + self.switchTime;
        }
    }

    function getTargetSaleTime(int256 logisticLimit, int256 timeScale, int256 soldBySwitch, int256 switchTime, int256 perTimeUnit, int256 sold) internal pure returns (int256) {
        // If we've not yet reached the number of sales required for the switch
        // to occur, we'll continue using the standard logistic VRGDA schedule.
        if (sold < soldBySwitch) return LogisticVRGDALib.getTargetSaleTime(logisticLimit, timeScale, sold);
        
        unchecked {
            return unsafeWadDiv(sold - soldBySwitch, perTimeUnit) + switchTime;
        }
    }
}
