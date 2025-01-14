// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "openzeppelin/contracts/utils/Strings.sol";

library StringToUintExtension {
    /// @dev string trans to uint
    /// @param s input string
    /// @return result  uint
    function stringToUint(string memory s) internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        result = 0;

        for (uint256 i = 0; i < b.length; i++) {
            require(b[i] >= 0x30 && b[i] <= 0x39, "Invalid character: must be 0-9");
            result = result * 10 + (uint8(b[i]) - 48);
        }
    }
}
