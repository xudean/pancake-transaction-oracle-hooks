// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "pancake-v4-periphery/src/libraries/Planner.sol";
import {ActionConstants} from "pancake-v4-periphery/src/libraries/ActionConstants.sol";
import {Actions} from "pancake-v4-periphery/src/libraries/Actions.sol";
import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";
import {Commands} from "pancake-v4-universal-router/src/libraries/Commands.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {ICLRouterBase} from "pancake-v4-periphery/src/pool-cl/interfaces/ICLRouterBase.sol";
import {IHooks} from "pancake-v4-core/src/interfaces/IHooks.sol";
import {LiquidityAmounts} from "pancake-v4-periphery/src/pool-cl/libraries/LiquidityAmounts.sol";
import {Planner, Plan} from "pancake-v4-periphery/src/libraries/Planner.sol";
import {PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";

import {TickMath} from "pancake-v4-core/src/pool-cl/libraries/TickMath.sol";
import {UniversalRouter} from "pancake-v4-universal-router/src/UniversalRouter.sol";
import {console} from "forge-std/console.sol";

contract CLUtils {
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    CLPoolManager poolManager;
    CLPositionManager positionManager;
    UniversalRouter universalRouter;

    function getPoolKey(
        Currency currency0,
        Currency currency1,
        IHooks hook
    ) internal returns (PoolKey memory poolKey) {
        poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: hook,
            poolManager: poolManager,
            fee: uint24(3000), // 0.3% fee
            parameters: bytes32(uint256(hook.getHooksRegistrationBitmap()))
        .setTickSpacing(10) // tickSpacing: 10
        });
    }

    // prettier-ignore
    function addLiquidity(
        PoolKey memory key,
        uint128 amount0Max,
        uint128 amount1Max,
        int24 tickLower,
        int24 tickUpper,
        address recipient
    ) internal returns (uint256 tokenId) {
        tokenId = positionManager.nextTokenId();

        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());
        uint256 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount0Max,
            amount1Max
        );
//        PositionConfig memory config = PositionConfig({poolKey: key, tickLower: tickLower, tickUpper: tickUpper});
//        Plan memory planner = Planner.init().add(
//            Actions.CL_MINT_POSITION, abi.encode(config, liquidity, amount0Max, amount1Max, recipient, new bytes(0))
//        );
        Plan memory planner = Planner.init().add(
            Actions.CL_MINT_POSITION,
            abi.encode(
                key,
                tickLower,
                tickUpper,
                uint256(liquidity),
                amount0Max,
                amount1Max,
                recipient,
                new bytes(0)//hookdata
            )
        );
        bytes memory data = planner.finalizeModifyLiquidityWithClose(key);
        // positionManager.modifyLiquidities(data, block.timestamp + 1);
        positionManager.modifyLiquidities(data, block.timestamp + 100);
    }

    // prettier-ignore
    function decreaseLiquidity(
        uint256 tokenId,
        PoolKey memory key,
        uint128 amount0,
        uint128 amount1,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());
        uint256 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount0,
            amount1
        );
//        PositionConfig memory config = PositionConfig({poolKey: key, tickLower: tickLower, tickUpper: tickUpper});
//
//        // amount0Min and amount1Min is 0 as some hook takes a fee from here
//        Plan memory planner = Planner.init().add(
//            Actions.CL_DECREASE_LIQUIDITY, abi.encode(tokenId, config, liquidity, 0, 0, new bytes(0))
//        );
        //amount0?
        Plan memory planner = Planner.init().add(
            Actions.CL_DECREASE_LIQUIDITY,
            abi.encode(tokenId, amount0, liquidity, 0, 0, new bytes(0)
            ));
        bytes memory data = planner.finalizeModifyLiquidityWithClose(key);
        positionManager.modifyLiquidities(data, block.timestamp);
    }

    // prettier-ignore
    function exactInputSingle(ICLRouterBase.CLSwapExactInputSingleParams memory params) internal {
        Plan memory plan = Planner.init().add(Actions.CL_SWAP_EXACT_IN_SINGLE, abi.encode(params));
        bytes memory data = params.zeroForOne
            ? plan.finalizeSwap(params.poolKey.currency0, params.poolKey.currency1, ActionConstants.MSG_SENDER)
            : plan.finalizeSwap(params.poolKey.currency1, params.poolKey.currency0, ActionConstants.MSG_SENDER);

        bytes memory commands = abi.encodePacked(bytes1(uint8(Commands.V4_SWAP)));
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = data;

        universalRouter.execute(commands, inputs);
    }

    // prettier-ignore
    function exactOutputSingle(ICLRouterBase.CLSwapExactOutputSingleParams memory params) internal {
        Plan memory plan = Planner.init().add(Actions.CL_SWAP_EXACT_OUT_SINGLE, abi.encode(params));
        bytes memory data = params.zeroForOne
            ? plan.finalizeSwap(params.poolKey.currency0, params.poolKey.currency1, ActionConstants.MSG_SENDER)
            : plan.finalizeSwap(params.poolKey.currency1, params.poolKey.currency0, ActionConstants.MSG_SENDER);

        bytes memory commands = abi.encodePacked(bytes1(uint8(Commands.V4_SWAP)));
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = data;

        universalRouter.execute(commands, inputs);
    }
}
