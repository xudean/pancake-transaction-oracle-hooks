// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {JsonParser} from "../../src/utils/JsonParser.sol";
import {console} from "forge-std/console.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract JsonParserTest is Test {
    using JsonParser for string;
    using Strings for string;

    string public originTxt;

    //only support string : "100"
    function setUp() public {
        originTxt = "{\"condition\":{\"baseValue\":\"100\"}}";
    }

    function testParser1() public {
        string memory baseValue = originTxt.extractValue("baseValue");
        console.log("baseValue:", baseValue);
        assertTrue(baseValue.equal("100"), "baseValue is not 100");
    }
}
