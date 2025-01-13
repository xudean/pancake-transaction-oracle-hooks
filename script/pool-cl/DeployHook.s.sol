// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";

import {CLExchangeVolumeHook} from "../../src/pool-cl/volume/CLExchangeVolumeHook.sol";
import {IAttestationRegistry} from "../../src/IAttestationRegistry.sol";

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract DeployHookScript is Script {
    function run() public {
        console.log("msg.sender %s", msg.sender);
        console.log("script %s", address(this));

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address signerAddr = vm.addr(privateKey);
        console.log("SIGNER=%s", signerAddr);

        vm.startBroadcast(privateKey);

        _deploy();

        vm.stopBroadcast();
    }

    function _deploy() internal {
        address _poolManager = vm.envAddress("CL_POOL_MANAGER");
        console.log("_poolManager=%s", _poolManager);

        address _eas = vm.envAddress("EAS");
        console.log("_eas=%s", _eas);

        bytes32 schema = vm.envBytes32("SCHEMA_BYTES");
        IAttestationRegistry attestationRegistry = IAttestationRegistry(address(_eas));
        CLPoolManager poolManager = CLPoolManager(_poolManager);
        CLExchangeVolumeHook hook = new CLExchangeVolumeHook(poolManager, attestationRegistry, msg.sender);
        console.log("HOOK=%s", address(hook));
    }
}
/*
source .env
forge script script/DeployHook.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
*/
