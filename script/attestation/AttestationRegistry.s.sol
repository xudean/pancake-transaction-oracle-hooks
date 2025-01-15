// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {AttestationRegistry} from "../../src/AttestationRegistry.sol";

contract DeployAttestationRegistry is Script {
    function run() external {
        // private key from env
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // initialize variables from env
        address primusZKTLS = vm.envAddress("PRIMUS_ZKTLS"); // IPrimusZKTLS contract address
        uint256 submissionFee = vm.envUint("SUBMISSION_FEE"); // submit fee
        address payable feeRecipient = payable(vm.envAddress("FEE_RECIPIENT")); // fee recipient

        // deploy AttestationRegistry
        AttestationRegistry attestationRegistry = new AttestationRegistry(
            primusZKTLS,
            submissionFee,
            feeRecipient
        );

        console.log("AttestationRegistry deployed at:", address(attestationRegistry));

        vm.stopBroadcast();
    }
}