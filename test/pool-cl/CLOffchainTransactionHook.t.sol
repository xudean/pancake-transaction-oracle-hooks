// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Constants} from "pancake-v4-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {CLTestUtils} from "./utils/CLTestUtils.sol";
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

contract CLOffchainTransactionHookTest is Test, CLTestUtils {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    CLOffchainTransactionHook hook;
    Currency currency0;
    Currency currency1;
    PoolKey key;

    ////////////////////
    function deployEAS() internal returns (IEAS, IEASProxy) {
        // It's just a test. It doesn't matter.
        ISchemaRegistry sr = ISchemaRegistry(address(this));

        MockEAS eas = new MockEAS(sr);
        console.log("EAS=%s", address(eas));

        MockEASProxy easproxy = new MockEASProxy();
        console.log("EASPROXY=%s", address(easproxy));

        return (eas, easproxy);
    }
    ///////////////////////////

    function setUp() public {
        (currency0, currency1) = deployContractsWithTokens();
        (IEAS eas, IEASProxy easproxy) = deployEAS();
        bytes32 schemaSpot30dTradeVol = 0x5f868b117fd34565f3626396ba91ef0c9a607a0e406972655c5137c6d4291af9;
        hook = new CLOffchainTransactionHook(
            poolManager,
            easproxy,
            eas,
            schemaSpot30dTradeVol
        );
        // hook.setBaseValue(100);
        // hook.setBaseValue(101);
        hook.setBaseValue(99);

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

    function testLiquidityCallback() public {
        MockERC20(Currency.unwrap(currency0)).mint(address(this), 1 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 1 ether);
        addLiquidity(key, 1 ether, 1 ether, -60, 60, address(this));
    }

    function testSwapCallback() public {
        MockERC20(Currency.unwrap(currency0)).mint(address(this), 1 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 1 ether);
        addLiquidity(key, 1 ether, 1 ether, -60, 60, address(this));

        MockERC20(Currency.unwrap(currency0)).mint(address(this), 0.1 ether);
        exactInputSingle(
            ICLRouterBase.CLSwapExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                amountIn: 0.1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0,
                hookData: new bytes(0)
            })
        );
    }
}
