// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {AttestationRegistry} from "src/attestation/AttestationRegistry.sol";
import {console} from "forge-std/console.sol";
import {Attestation} from "../../src/types/Common.sol";
//forge script script/attestation/CallAttestationRegistry.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

contract CallAttestationRegistry is Script {
    function run() public {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        address attestationRegistryAddr = vm.envAddress("ATTESTATION_REGISTRY");
        AttestationRegistry attReg = AttestationRegistry(address(attestationRegistryAddr));

        vm.startBroadcast(senderPrivateKey);

        getAttestation(attReg);

        vm.stopBroadcast();
    }

    function setPrimusZkTLS(AttestationRegistry attReg) public {
        address primusAddr = vm.envAddress("PRIMUS_ZKTLS");
        attReg.setPrimusZKTLS(primusAddr);
    }

    function getAttestation(AttestationRegistry attReg) public {
        Attestation[] memory attestations = attReg.getAttestationByRecipient(0x6b28B1D10D45fD811a9fb48Ed60E394f7cB8D34f);
        for (uint256 i = 0; i < attestations.length; i++) {
            Attestation memory attestation = attestations[i];
            console.log("Attestation %d:", i);
            console.log("  { recipient: %s,", attestation.recipient);
            console.log("    exchange: %s,", attestation.exchange);
            console.log("    value: %d,", attestation.value);
            console.log("    timestamp: %d }", attestation.timestamp);
        }
    }
}
