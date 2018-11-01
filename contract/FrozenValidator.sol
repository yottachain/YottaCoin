pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "./FrozenChecker.sol";

library FrozenValidator {
    
    using SafeMath for uint256;
    using FrozenChecker for FrozenChecker.Rule;

    struct Validator {
        mapping(address => IndexValue) data;
        KeyFlag[] keys;
        uint256 size;
    }

    struct IndexValue {
        uint256 keyIndex; 
        FrozenChecker.Rule rule;
        mapping (address => uint256) frozenBalances;
    }

    struct KeyFlag { 
        address key; 
        bool deleted; 
    }

    function addRule(Validator storage self, address key, uint8 initPercent, uint256[] periods, uint8[] percents) internal returns (bool replaced) {
        //require(self.size <= 10);
        require(key != address(0));
        require(periods.length == percents.length);
        require(periods.length > 0);
        require(periods[0] == uint256(0));
        require(initPercent <= percents[0]);
        for (uint256 i = 1; i < periods.length; i = i.add(1)) {
            require(periods[i.sub(1)] < periods[i]);
            require(percents[i.sub(1)] <= percents[i]);
        }
        require(percents[percents.length.sub(1)] == 100);
        FrozenChecker.Rule memory rule = FrozenChecker.Rule(0, initPercent, periods, percents);
        uint256 keyIndex = self.data[key].keyIndex;
        self.data[key].rule = rule;
        if (keyIndex > 0) {
            return true;
        } else {
            keyIndex = self.keys.length++;
            self.data[key].keyIndex = keyIndex.add(1);
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function removeRule(Validator storage self, address key) internal returns (bool success) {
        uint256 keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0) {
            return false;
        }
        delete self.data[key];
        self.keys[keyIndex.sub(1)].deleted = true;
        self.size--;
        return true;
    }

    function containRule(Validator storage self, address key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function addTimeT(Validator storage self, address addr, uint256 timeT) internal returns (bool) {
        require(timeT > now);
        self.data[addr].rule.timeT = timeT;
        return true;
    }

    function addFrozenBalance(Validator storage self, address from, address to, uint256 value) internal returns (uint256) {
        self.data[from].frozenBalances[to] = self.data[from].frozenBalances[to].add(value);
        return self.data[from].frozenBalances[to];
    }

    function validate(Validator storage self, address addr) internal view returns (uint256) {
        uint256 frozenTotal = 0;
        for (uint256 i = iterateStart(self); iterateValid(self, i); i = iterateNext(self, i)) {
            address ruleaddr = iterateGet(self, i);
            FrozenChecker.Rule storage rule = self.data[ruleaddr].rule;
            frozenTotal = frozenTotal.add(rule.check(self.data[ruleaddr].frozenBalances[addr]));
        }
        return frozenTotal;
    }


    function iterateStart(Validator storage self) internal view returns (uint256 keyIndex) {
        return iterateNext(self, uint256(-1));
    }

    function iterateValid(Validator storage self, uint256 keyIndex) internal view returns (bool) {
        return keyIndex < self.keys.length;
    }

    function iterateNext(Validator storage self, uint256 keyIndex) internal view returns (uint256) {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted) {
            keyIndex++;
        }
        return keyIndex;
    }

    function iterateGet(Validator storage self, uint256 keyIndex) internal view returns (address) {
        return self.keys[keyIndex].key;
    }
}
