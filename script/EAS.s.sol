// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockEAS} from "../mocks/MockEAS.sol";
import {MockEASProxy} from "../mocks/MockEASProxy.sol";
import {ISchemaRegistry} from "bas-contract/contracts/ISchemaRegistry.sol";

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract EASScript is Script {
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
        // It's just a test. It doesn't matter.
        ISchemaRegistry sr = ISchemaRegistry(address(this));

        MockEAS eas = new MockEAS(sr);
        console.log("EAS=%s", address(eas));

        MockEASProxy easproxy = new MockEASProxy();
        console.log("EASPROXY=%s", address(easproxy));
    }
}
/*
source .env
forge script script/EAS.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
*/
