// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEASProxy {
    function getPadoAttestations(
        address user,
        bytes32 schema
    ) external view returns (bytes32[] memory);
}
