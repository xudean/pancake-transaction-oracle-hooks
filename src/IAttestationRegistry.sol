// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "./types/Common.sol";
import {Attestation as PrimusAttestation} from  "zkTLS-contracts/src/IPrimusZKTLS.sol";
interface IAttestationRegistry{
    function submitAttestation(PrimusAttestation memory attestation) external returns(bytes32);
    function getAttestationByRecipient(address recipient) external view returns(Attestation[] memory);
}
