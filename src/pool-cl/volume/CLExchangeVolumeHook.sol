// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";
import {PoolIdLibrary,PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {IPoolManager} from "pancake-v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {IHooks} from "pancake-v4-core/src/interfaces/IHooks.sol";
import {CLBaseHook} from "../CLBaseHook.sol";
import {IAttestationRegistry} from "../../IAttestationRegistry.sol";
import {BaseFeeDiscountHook} from "../../BaseFeeDiscountHook.sol";

/// @notice CLExchangeVolumeHook.sol.sol will check the following attestations before adding liquidity or swap:
/// 1. The attestation of binance or other exchanges within 7 days
/// 2. If a valid attestation of address is provided, the handling fee will be discounted by 50%.
contract CLExchangeVolumeHook is CLBaseHook, BaseFeeDiscountHook {
    using PoolIdLibrary for PoolKey;

    constructor(ICLPoolManager _poolManager, IAttestationRegistry _attestationRegistry, address initialOwner)
        CLBaseHook(_poolManager)
        BaseFeeDiscountHook(_attestationRegistry, initialOwner)
    {}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: true,
                beforeAddLiquidity: false,
                afterAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterAddLiquidityReturnsDelta: false,
                afterRemoveLiquidityReturnsDelta: false
            })
        );
    }

    function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
        external
        override
        poolManagerOnly
        returns (bytes4)
    {
        poolManager.updateDynamicLPFee(key, getDefaultFee());
        poolsInitialized.push(key.toId());
        return (this.afterInitialize.selector);
    }

    function beforeSwap(address sender, PoolKey calldata key, ICLPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 fee = getFeeDiscount(tx.origin, key);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee);
    }


    /*
      @dev Set default fee for pool
      @param fee
      @return
     */
    function updatePoolFeeByPoolKey(PoolKey memory poolKey ,uint24 newBaseFee) external onlyOwner {
        poolManager.updateDynamicLPFee(poolKey, newBaseFee);
    }

    /*
      @dev Update fee for pool by poolId
      @param fee
      @return
     */
    function updatePoolFeeByPoolId(PoolId[] memory poolIds ,uint24 newBaseFee) external onlyOwner {
        for (uint256 i = 0; i < poolIds.length; i++) {
            (Currency currency0, Currency currency1, IHooks hooks, IPoolManager manager, uint24 fee, bytes32 parameters) = poolManager.poolIdToPoolKey(poolIds[i]);
            poolManager.updateDynamicLPFee(PoolKey(currency0, currency1, hooks, manager, fee, parameters), newBaseFee);
        }
    }
}
