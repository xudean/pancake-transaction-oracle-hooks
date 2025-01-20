// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import {AttestationRegistry} from "src/attestation/AttestationRegistry.sol";

contract CallAttestationRegistry is Script {
    function run() public {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        //address senderAddress = vm.addr(senderPrivateKey);
        vm.startBroadcast(senderPrivateKey);

        AttestationRegistry attReg = AttestationRegistry(address(0x9109Ea5A8Af5c3c5600F6E8213bd83348C81a573));
        attReg.setPrimusZKTLS(address(0x6F6120c4A784641D882306900945877cdce726A0));

        vm.stopBroadcast();
    }
}
