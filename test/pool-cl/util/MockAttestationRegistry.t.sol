// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Attestation as PrimusAttestation} from "zkTLS-contracts/src/IPrimusZKTLS.sol";
import {Attestation} from "../../../src/types/Common.sol";
import {IAttestationRegistry} from "../../../src/IAttestationRegistry.sol";
import {console} from "forge-std/console.sol";

contract MockAttestationRegistry is IAttestationRegistry {
    mapping(bytes32 => Attestation) public attestations;
    mapping(address => bytes32[]) public attestationsOfAddress;

    function submitAttestation(PrimusAttestation memory attestation) public payable returns (bool) {
        return true;
    }

    function addAttestation(Attestation memory attestation) public {
        bytes32 uid = keccak256(abi.encode(attestation));
        attestations[uid] = attestation;
        console.log("addAttestation recipient", attestation.recipient);
        attestationsOfAddress[attestation.recipient].push(uid);
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
