pragma solidity ^0.4.24;
import "./SafeMath.sol";

/**
 * @title FrozenChecker
 * @dev Check account by frozen rules
 */
library FrozenChecker {

    using SafeMath for uint256;

    /**
     * Rule for each address
     */
    struct Rule {
        uint256 timeT;
        uint8 initPercent;
        uint256[] periods;
        uint8[] percents;
    }

    function check(Rule storage self, uint256 totalFrozenValue) internal view returns (uint256) {
        if (totalFrozenValue == uint256(0)) {
            return 0;
        }
        //uint8 temp = self.initPercent;
        if (self.timeT == uint256(0) || self.timeT > now) {
            return totalFrozenValue.sub(totalFrozenValue.mul(self.initPercent).div(100));
        }
        for (uint256 i = 0; i < self.periods.length.sub(1); i = i.add(1)) {
            if (now >= self.timeT.add(self.periods[i]) && now < self.timeT.add(self.periods[i.add(1)])) {
                return totalFrozenValue.sub(totalFrozenValue.mul(self.percents[i]).div(100));
            }
        }
        if (now >= self.timeT.add(self.periods[self.periods.length.sub(1)])) {
            return totalFrozenValue.sub(totalFrozenValue.mul(self.percents[self.periods.length.sub(1)]).div(100));
        }
    }

}
