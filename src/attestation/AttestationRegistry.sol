// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Attestation as PrimusAttestation} from "zkTLS-contracts/src/IPrimusZKTLS.sol";
import {Attestation} from "../types/Common.sol";
import {IAttestationRegistry} from "../IAttestationRegistry.sol";
import {IPrimusZKTLS} from "zkTLS-contracts/src/IPrimusZKTLS.sol";

contract AttestationRegistry is IAttestationRegistry {
    mapping(bytes32 => Attestation) public attestations;
    mapping(address => bytes32[]) public attestationsOfAddress;
    IPrimusZKTLS internal primusZKTLS;

    function submitAttestation(PrimusAttestation memory attestation) public returns (bytes32) {
        return bytes32(0);
    }

    function getAttestationByRecipient(address recipient) public view returns (Attestation[] memory) {
        bytes32[] memory attestationIds = attestationsOfAddress[recipient];
        Attestation[] memory myAttestations = new Attestation[](attestationIds.length);
        for (uint256 i = 0; i < attestationIds.length; i++) {
            Attestation memory myAttestation = attestations[attestationIds[i]];
            if (myAttestation.recipient == recipient) {
                myAttestations[i] = myAttestation;
            }
        }
        return myAttestations;
    }
}
