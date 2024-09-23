// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEASProxy} from "../src/IEASProxy.sol";

contract MockEASProxy is IEASProxy {
    function getPadoAttestations(
        address /*user*/,
        bytes32 /*schema*/
    ) external pure returns (bytes32[] memory) {
        bytes32[] memory ret = new bytes32[](2);
        return ret;
    }
}
