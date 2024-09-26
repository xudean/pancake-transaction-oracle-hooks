// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";
import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";
import {UniversalRouter} from "pancake-v4-universal-router/src/UniversalRouter.sol";
import {Constants} from "pancake-v4-core/test/pool-cl/helpers/Constants.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {IHooks} from "pancake-v4-core/src/interfaces/IHooks.sol";
import {ICLRouterBase} from "pancake-v4-periphery/src/pool-cl/interfaces/ICLRouterBase.sol";

import {CLUtils} from "./utils/CLUtils.sol";
import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract TestBase is Script, CLUtils {
    using PoolIdLibrary for PoolKey;

    Currency currency0;
    Currency currency1;
    PoolKey key;
    IHooks hook;
    function setUp() public {
        address _poolManager = vm.envAddress("CL_POOL_MANAGER");
        console.log("_poolManager=%s", _poolManager);

        address _positionManager = vm.envAddress("CL_POSITION_MANAGER");
        console.log("_positionManager=%s", _positionManager);
        address _universalRouter = vm.envAddress("UNIVERSAL_ROUTER");
        console.log("_universalRouter=%s", _universalRouter);

        address _token0 = vm.envAddress("TOKEN0");
        console.log("_token0=%s", _token0);
        address _token1 = vm.envAddress("TOKEN1");
        console.log("_token1=%s", _token1);

        address _hook = vm.envAddress("HOOK");
        console.log("_hook=%s", _hook);

        poolManager = CLPoolManager(_poolManager);
        positionManager = CLPositionManager(_positionManager);
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
        poolManager.initialize(key, Constants.SQRT_RATIO_1_1, new bytes(0));
    }
}
contract TestAddLiquidityScript is TestBase {
    function _test() public override {
        addLiquidity(key, 10 ether, 10 ether, -60, 60, msg.sender);
    }
}
contract TestSwapScript is TestBase {
    function _test() public override {
        MockERC20(Currency.unwrap(currency0)).mint(msg.sender, 0.01 ether);
        exactInputSingle(
            ICLRouterBase.CLSwapExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                amountIn: 0.01 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0,
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
