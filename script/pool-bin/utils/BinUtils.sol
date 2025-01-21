// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "pancake-v4-periphery/src/libraries/Planner.sol";
import {ActionConstants} from "pancake-v4-periphery/src/libraries/ActionConstants.sol";
import {Actions} from "pancake-v4-periphery/src/libraries/Actions.sol";
import {BinPoolManager} from "pancake-v4-core/src/pool-bin/BinPoolManager.sol";
import {BinPoolParametersHelper} from "pancake-v4-core/src/pool-bin/libraries/BinPoolParametersHelper.sol";
import {BinPositionManager} from "pancake-v4-periphery/src/pool-bin/BinPositionManager.sol";
import {IBinPositionManager} from "pancake-v4-periphery/src/pool-bin/interfaces/IBinPositionManager.sol";
import {Commands} from "pancake-v4-universal-router/src/libraries/Commands.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {IBinRouterBase} from "pancake-v4-periphery/src/pool-bin/interfaces/IBinRouterBase.sol";
import {IHooks} from "pancake-v4-core/src/interfaces/IHooks.sol";
import {LiquidityAmounts} from "pancake-v4-periphery/src/pool-cl/libraries/LiquidityAmounts.sol";
import {Planner, Plan} from "pancake-v4-periphery/src/libraries/Planner.sol";
import {PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {Constants} from "pancake-v4-core/src/pool-bin/libraries/Constants.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {LPFeeLibrary} from "pancake-v4-core/src/libraries/LPFeeLibrary.sol";

import {TickMath} from "pancake-v4-core/src/pool-cl/libraries/TickMath.sol";
import {UniversalRouter} from "pancake-v4-universal-router/src/UniversalRouter.sol";
import {console} from "forge-std/console.sol";

contract BinUtils {
    uint24 constant BIN_ID_1_1 = 2 ** 23;

    using Planner for Plan;
    using PoolIdLibrary for PoolKey;
    using BinPoolParametersHelper for bytes32;

    BinPoolManager poolManager;
    BinPositionManager positionManager;
    UniversalRouter universalRouter;

    function getPoolKey(Currency currency0, Currency currency1, IHooks hook)
        internal
        returns (PoolKey memory poolKey)
    {
        poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: hook,
            poolManager: poolManager,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG, // Dynamic fee
            parameters: bytes32(uint256(hook.getHooksRegistrationBitmap())).setBinStep(60)
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
    ) internal {
        uint256 numBins = 1;
        int256[] memory deltaIds = new int256[](numBins);
        deltaIds[0] = 0;
        uint256[] memory distributionX = new uint256[](numBins);
        distributionX[0] = Constants.PRECISION;
        uint256[] memory distributionY = new uint256[](numBins);
        distributionY[0] = Constants.PRECISION;
        IBinPositionManager.BinAddLiquidityParams memory params = IBinPositionManager.BinAddLiquidityParams({
            poolKey: key,
            amount0: amount0Max,
            amount1: amount1Max,
            amount0Max: amount0Max,
            amount1Max: amount1Max,
            activeIdDesired: BIN_ID_1_1,
            idSlippage: 0,
            deltaIds: deltaIds,
            distributionX: distributionX,
            distributionY: distributionY,
            to: recipient,
            hookData: new bytes(0)
        });
        console.log("addLiquidity");
        Plan memory planner = Planner.init().add(Actions.BIN_ADD_LIQUIDITY, abi.encode(params));
        bytes memory data = planner.finalizeModifyLiquidityWithClose(params.poolKey);
        console.log("addLiquidity2");
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
        uint256 numBins = 1;
        int256[] memory deltaIds = new int256[](numBins);
        deltaIds[0] = 0;
        uint256[] memory distributionX = new uint256[](numBins);
        distributionX[0] = Constants.PRECISION;
        uint256[] memory distributionY = new uint256[](numBins);
        distributionY[0] = Constants.PRECISION;
        IBinPositionManager.BinAddLiquidityParams memory params = IBinPositionManager.BinAddLiquidityParams({
            poolKey: key,
            amount0: 0.01e18,
            amount1: 0.01e18,
            amount0Max: 0.01e18,
            amount1Max: 0.01e18,
            activeIdDesired: BIN_ID_1_1,
            idSlippage: 0,
            deltaIds: deltaIds,
            distributionX: distributionX,
            distributionY: distributionY,
            to: address(this),
            hookData: new bytes(0)
        });
        Plan memory planner = Planner.init().add(Actions.BIN_REMOVE_LIQUIDITY, abi.encode(params));
        bytes memory data = planner.finalizeModifyLiquidityWithClose(params.poolKey);

        positionManager.modifyLiquidities(data, block.timestamp);
    }

    // prettier-ignore
    function exactInputSingle(IBinRouterBase.BinSwapExactInputSingleParams memory params) internal {
        Plan memory planner = Planner.init().add(Actions.BIN_SWAP_EXACT_IN_SINGLE, abi.encode(params));
        Currency inputCurrency = params.swapForY ? params.poolKey.currency0 : params.poolKey.currency1;
        Currency outputCurrency = params.swapForY ? params.poolKey.currency1 : params.poolKey.currency0;
        bytes memory data = planner.finalizeSwap(inputCurrency, outputCurrency, msg.sender);

        bytes memory commands = abi.encodePacked(bytes1(uint8(Commands.V4_SWAP)));
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = data;

        universalRouter.execute(commands, inputs);
    }
}
