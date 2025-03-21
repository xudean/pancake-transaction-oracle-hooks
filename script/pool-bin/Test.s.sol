// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {BinPoolManager} from "pancake-v4-core/src/pool-bin/BinPoolManager.sol";
import {BinPositionManager} from "pancake-v4-periphery/src/pool-bin/BinPositionManager.sol";
import {UniversalRouter} from "pancake-v4-universal-router/src/UniversalRouter.sol";
import {Constants} from "pancake-v4-core/test/pool-cl/helpers/Constants.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {IHooks} from "pancake-v4-core/src/interfaces/IHooks.sol";
import {IBinRouterBase} from "pancake-v4-periphery/src/pool-bin/interfaces/IBinRouterBase.sol";

import {BinUtils} from "./utils/BinUtils.sol";
import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";
import {BinPoolManager} from "pancake-v4-core/src/pool-bin/BinPoolManager.sol";
import {BinExchangeVolumeHook} from "../../src/pool-bin/volume/BinExchangeVolumeHook.sol";

contract TestBase is Script, BinUtils {
    using PoolIdLibrary for PoolKey;

    Currency currency0;
    Currency currency1;
    PoolKey key;
    IHooks hook;

    function setUp() public {
        address _poolManager = vm.envAddress("BIN_POOL_MANAGER");
        console.log("_poolManager=%s", _poolManager);

        address payable _positionManager = payable(vm.envAddress("BIN_POSITION_MANAGER"));
        console.log("_positionManager=%s", _positionManager);
        address _universalRouter = vm.envAddress("UNIVERSAL_ROUTER");
        console.log("_universalRouter=%s", _universalRouter);

        address _token0 = vm.envAddress("TOKEN0");
        console.log("_token0=%s", _token0);
        address _token1 = vm.envAddress("TOKEN1");
        console.log("_token1=%s", _token1);

        address _hook = vm.envAddress("BIN_HOOK");
        console.log("_hook=%s", _hook);

        poolManager = BinPoolManager(_poolManager);
        positionManager = BinPositionManager(_positionManager);
        universalRouter = UniversalRouter(payable(_universalRouter));
        currency0 = Currency.wrap(_token0);
        currency1 = Currency.wrap(_token1);
        hook = IHooks(_hook);
        key = getPoolKey(currency0, currency1, hook);
    }

    function run() public {
        console.log("msg.sender %s", msg.sender);
        console.log("script %s", address(this));

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address signerAddr = vm.addr(privateKey);
        console.log("SIGNER=%s", signerAddr);

        vm.startBroadcast(privateKey);

        _test();

        vm.stopBroadcast();
    }

    function _test() public virtual {}
}

contract TestInitializeScript is TestBase {
    function _test() public override {
        console.log("init start!");
        poolManager.initialize(key, BIN_ID_1_1);
        console.log("init end!");
    }
}

contract TestAddLiquidityScript is TestBase {
    function _test() public override {
        addLiquidity(key, 1 ether, 1 ether, -60, 60, msg.sender);
    }
}

contract TestSetHookFee is TestBase{
    function _test() public override{
        address _hook = vm.envAddress("BIN_HOOK");
        // id should set manual
        PoolId poolId = PoolId.wrap(bytes32(hex"103be6854baf1f2cb8f8fd0b43eb9ae4b6045988fa4dbca8310778d8a4709832"));
        BinExchangeVolumeHook(_hook).setHookFeeEnabled(poolId, true);
        BinExchangeVolumeHook(_hook).setHookFee(poolId, 10);
    }
}

contract TestSwapScript is TestBase {
    function _test() public override {
//        MockERC20(Currency.unwrap(currency0)).mint(msg.sender, 0.01 ether);
        exactInputSingle(
            IBinRouterBase.BinSwapExactInputSingleParams({
                poolKey: key,
                swapForY: true,
                amountIn: 0.01e18,
                amountOutMinimum: 0,
                hookData: new bytes(0)
            })
        );
    }
}

/*
source .env
forge script script/Test.s.sol:TestInitializeScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
forge script script/Test.s.sol:TestAddLiquidityScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
forge script script/Test.s.sol:TestSwapScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
*/
