// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import "./types/Common.sol";
import {Attestation as PrimusAttestation} from "zkTLS-contracts/src/IPrimusZKTLS.sol";

interface IAttestationRegistry {
    function submitAttestation(PrimusAttestation memory attestation) external payable returns (bool);
    function getAttestationByRecipient(address recipient) external view returns (Attestation[] memory);
}
