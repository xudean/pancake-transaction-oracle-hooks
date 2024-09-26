// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";
import {Vault} from "pancake-v4-core/src/Vault.sol";
import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {UniversalRouter, RouterParameters} from "pancake-v4-universal-router/src/UniversalRouter.sol";

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract CLManagerScript is Script {
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
        Vault vault = new Vault();
        console.log("VAULT=%s", address(vault));

        CLPoolManager poolManager = new CLPoolManager(vault, 500000);
        console.log("CL_POOL_MANAGER=%s", address(poolManager));
        vault.registerApp(address(poolManager));

        address _permit2 = vm.envAddress("PERMIT2");
        // console.log("_permit2=%s", _permit2);
        IAllowanceTransfer permit2 = IAllowanceTransfer(_permit2);
        CLPositionManager positionManager = new CLPositionManager(
            vault,
            poolManager,
            permit2
        );
        console.log("CL_POSITION_MANAGER=%s", address(positionManager));

        RouterParameters memory params = RouterParameters({
            permit2: address(permit2),
            weth9: address(0),
            v2Factory: address(0),
            v3Factory: address(0),
            v3Deployer: address(0),
            v2InitCodeHash: bytes32(0),
            v3InitCodeHash: bytes32(0),
            stableFactory: address(0),
            stableInfo: address(0),
            v4Vault: address(vault),
            v4ClPoolManager: address(poolManager),
            v4BinPoolManager: address(0),
            v3NFTPositionManager: address(0),
            v4ClPositionManager: address(positionManager),
            v4BinPositionManager: address(0)
        });
        UniversalRouter universalRouter = new UniversalRouter(params);
        console.log("UNIVERSAL_ROUTER=%s", address(universalRouter));
    }
}
/*
source .env
forge script script/CLManager.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
*/
