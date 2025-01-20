// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {BinExchangeVolumeHook} from "../../../src/pool-bin/volume/BinExchangeVolumeHook.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {BinPoolManager} from "pancake-v4-core/src/pool-bin/BinPoolManager.sol";
import {BinPool} from "pancake-v4-core/src/pool-bin/libraries/BinPool.sol";
import {BinSlot0} from "pancake-v4-core/src/pool-bin/types/BinSlot0.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {IHooks} from "pancake-v4-core/src/interfaces/IHooks.sol";
import {IPoolManager} from "pancake-v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";

//forge script script/pool-bin/caller/CallHook.s.sol:CallHook --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
contract CallHook is Script {
    BinExchangeVolumeHook public hook;
    BinPoolManager public binPoolManager;

    function run() public {
        uint256 senderPrivateKey = vm.envUint("PRIVATE_KEY");
        address binHook = vm.envAddress("BIN_HOOK");

        hook = BinExchangeVolumeHook(address(binHook));
        binPoolManager = BinPoolManager(vm.envAddress("BIN_POOL_MANAGER"));
        vm.startBroadcast(senderPrivateKey);

        //        setBaseValue();
        setDefaultFee();
        //        setDefaultFee();
        vm.stopBroadcast();
    }

    function setDefaultFee() public {
        //        hook.setDefaultFee(400000);
        PoolId poolId = hook.poolsInitialized(0);
        PoolId[] memory poolIds = new PoolId[](1);
        poolIds[0] = poolId;
        hook.updatePoolFeeByPoolId(poolIds, 40000);
        (,, uint24 lpFee) = binPoolManager.getSlot0(poolId);
        console.log("fee from poolManager is:", lpFee);
        console.log("fee from hook is:", hook.poolFeeMapping(poolId));
    }

    function setBaseValue() public {
        hook.setBaseValue(0);
    }

    function getBaseValue() public {
        PoolId poolId = hook.poolsInitialized(0);
        bytes32 poolIdBytes = PoolId.unwrap(poolId);
        uint24 baseValue = hook.poolFeeMapping(poolId);
        console.logBytes32(poolIdBytes);
        console.log(baseValue);
    }
}
