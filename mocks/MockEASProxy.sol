// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEASProxy} from "../src/IEASProxy.sol";

contract MockEASProxy is IEASProxy {
    function getPadoAttestations(
        address /*user*/,
        bytes32 /*schema*/
    ) external pure returns (bytes32[] memory) {
        bytes32[] memory ret = new bytes32[](2);
        // prettier-ignore
        {
            ret[0] = 0x0000000000000000000000000000000000000000000000000000000000000001;
            ret[1] = 0x0000000000000000000000000000000000000000000000000000000000000002;
        }
        return ret;
    }
}
