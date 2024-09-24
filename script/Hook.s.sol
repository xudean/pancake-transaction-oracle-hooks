// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Constants} from "pancake-v4-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {ICLRouterBase} from "pancake-v4-periphery/src/pool-cl/interfaces/ICLRouterBase.sol";

import {console} from "forge-std/console.sol";

import {MockEAS} from "../../mocks/MockEAS.sol";
import {MockEASProxy} from "../../mocks/MockEASProxy.sol";
import {ISchemaRegistry} from "bas-contract/contracts/ISchemaRegistry.sol";
import {IEAS} from "bas-contract/contracts/IEAS.sol";
import {IEASProxy} from "../../src/IEASProxy.sol";

import {CLOffchainTransactionHook} from "../../src/pool-cl/CLOffchainTransactionHook.sol";

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract HookScript is Script {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    CLPoolManager poolManager;
    CLOffchainTransactionHook hook;
    Currency currency0;
    Currency currency1;
    PoolKey key;

    function run() public {
        console.log("msg.sender %s", msg.sender);
        console.log("script %s", address(this));

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address signerAddr = vm.addr(privateKey);
        console.log("SIGNER%s", signerAddr);

        vm.startBroadcast(privateKey);

        _deploy();

        vm.stopBroadcast();
    }

    function _deploy() internal {
        address _poolManager = vm.envAddress("CL_POOL_MANAGER");
        console.log("_poolManager=%s", _poolManager);

        address _eas = vm.envAddress("EAS");
        console.log("_eas=%s", _eas);
        address _easproxy = vm.envAddress("EASPROXY");
        console.log("_easproxy=%s", _easproxy);

        address _token0 = vm.envAddress("TOKEN0");
        console.log("_token0=%s", _token0);
        address _token1 = vm.envAddress("TOKEN1");
        console.log("_token1=%s", _token1);

        bytes32 schema = vm.envBytes32("SCHEMA_SPOT_30_TRADE_VOL");
        currency0 = Currency.wrap(_token0);
        currency1 = Currency.wrap(_token1);
        IEAS eas = IEAS(_eas);
        IEASProxy easproxy = IEASProxy(_easproxy);
        poolManager = CLPoolManager(_poolManager);
        hook = new CLOffchainTransactionHook(
            poolManager,
            easproxy,
            eas,
            schema
        );
        console.log("HOOK=%s", address(hook));

        // create the pool key
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: hook,
            poolManager: poolManager,
            fee: uint24(3000), // 0.3% fee
            // tickSpacing: 10
            parameters: bytes32(uint256(hook.getHooksRegistrationBitmap()))
                .setTickSpacing(10)
        });

        // initialize pool at 1:1 price point (assume stablecoin pair)
        poolManager.initialize(key, Constants.SQRT_RATIO_1_1, new bytes(0));
    }
}
/*
source .env
forge script script/Hook.s.sol \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  --broadcast
*/
