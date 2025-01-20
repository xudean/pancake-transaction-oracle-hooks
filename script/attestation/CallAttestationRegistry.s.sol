// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import {AttestationRegistry} from "src/attestation/AttestationRegistry.sol";

contract CallAttestationRegistry is Script {
    function run() public {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        address attestationRegistryAddr = vm.envAddress("ATTESTATION_REGISTRY");
        address primusAddr = vm.envAddress("PRIMUS_ZKTLS");
        vm.startBroadcast(senderPrivateKey);

        AttestationRegistry attReg = AttestationRegistry(address(attestationRegistryAddr));
        attReg.setPrimusZKTLS(primusAddr);

        vm.stopBroadcast();
    }
}
