// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CLExchangeVolumeHook} from "../../../src/pool-cl/volume/CLExchangeVolumeHook.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";
import {CLPool} from "pancake-v4-core/src/pool-cl/libraries/CLPool.sol";
import {CLSlot0} from "pancake-v4-core/src/pool-cl/types/CLSlot0.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {IHooks} from "pancake-v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "pancake-v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";

//forge script script/pool-cl/caller/CallHook.s.sol:CallHook --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
contract CallHook is Script {
    CLExchangeVolumeHook public hook;
    CLPoolManager public clPoolManager;

    function run() public {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        address clHook = vm.envAddress("CL_HOOK");

        hook = CLExchangeVolumeHook(address(clHook));
        clPoolManager = CLPoolManager(vm.envAddress("CL_POOL_MANAGER"));
        vm.startBroadcast(senderPrivateKey);

        // setBaseValue();
        getBaseValue();
        vm.stopBroadcast();
    }

    function setDefaultFee() public {
        //        hook.setDefaultFee(400000);
        PoolId poolId = hook.poolsInitialized(0);
        PoolId[] memory poolIds = new PoolId[](1);
        poolIds[0] = poolId;
        hook.updatePoolFeeByPoolId(poolIds, 40000);
        (,,, uint24 lpFee) = clPoolManager.getSlot0(poolId);
        console.log("fee from poolManager is:", lpFee);
        console.log("fee from hook is:", hook.poolFeeMapping(poolId));
    }

    function setBaseValue() public {
        hook.setBaseValue(3000);
    }

    function getBaseValue() public {
        PoolId poolId = hook.poolsInitialized(0);
        bytes32 poolIdBytes = PoolId.unwrap(poolId);
        uint24 baseValue = hook.poolFeeMapping(poolId);
        console.logBytes32(poolIdBytes);
        console.log(baseValue);
    }
}
