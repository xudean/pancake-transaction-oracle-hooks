// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";
import {PoolIdLibrary, PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {IPoolManager} from "pancake-v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {IHooks} from "pancake-v4-core/src/interfaces/IHooks.sol";
import {CLBaseHook} from "../CLBaseHook.sol";
import {IAttestationRegistry} from "../../IAttestationRegistry.sol";
import {BaseFeeDiscountHook} from "../../BaseFeeDiscountHook.sol";
import {BalanceDelta} from "pancake-v4-core/src/types/BalanceDelta.sol";
import {SafeCast} from "pancake-v4-core/src/libraries/SafeCast.sol";
import {CurrencyLibrary} from "pancake-v4-core/src/types/Currency.sol";

/// @notice CLExchangeVolumeHook.sol.sol will check the following attestations before adding liquidity or swap:
/// 1. The attestation of binance or other exchanges within 7 days
/// 2. If a valid attestation of address is provided, the handling fee will be discounted by 50%.
contract CLExchangeVolumeHook is CLBaseHook, BaseFeeDiscountHook {
    using PoolIdLibrary for PoolKey;
    using SafeCast for uint256;
    using SafeCast for int128;
    using CurrencyLibrary for Currency;

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
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: true,
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
        //TODO add event for PoolKey
        poolManager.updateDynamicLPFee(key, defaultFee);
        poolFeeMapping[key.toId()] = defaultFee;
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

    function afterSwap(address sender, PoolKey calldata key, ICLPoolManager.SwapParams calldata params, BalanceDelta delta, bytes calldata hookData)
    external
    override
    poolManagerOnly
    returns (bytes4, int128)
    {
        // Take a fee from the unspecified
        // zeroForOne + amount < 0 -> amount0 is specified, amount1 is unspecified
        // zeroForOne + amount > 0 -> amount1 is specified, amount0 is unspecified
        // oneForZero + amount < 0 -> amount1 is specified, amount0 is unspecified
        // oneForZero + amount > 0 -> amount0 is specified, amount1 is unspecified
        bool specifiedTokenIs0 = (params.amountSpecified < 0 == params.zeroForOne);
        (Currency feeCurrency, int128 swapAmount) =
            (specifiedTokenIs0) ? (key.currency1, delta.amount1()) : (key.currency0, delta.amount0());
        // if fee is on output, get the absolute output amount
        if (swapAmount < 0) swapAmount = -swapAmount;
        //TODO hookFee default 0.01% now
        uint256 feeAmount = uint256(uint128(swapAmount)) * 1 / TOTAL_FEE_BIPS;
        vault.mint(address(this), feeCurrency, feeAmount);

        return (this.afterSwap.selector, feeAmount.toInt128());
    }



    function withdrawHookFee(address recipient, Currency currency) external onlyOwner returns (uint256 amount) {
        return _withdrawHookFee(vault,recipient,currency);
    }

    /*
      @dev Set default fee for pool
      @param fee
      @return
     */
    function updatePoolFeeByPoolKey(PoolKey memory poolKey, uint24 newBaseFee) external onlyOwner {
        poolManager.updateDynamicLPFee(poolKey, newBaseFee);
        poolFeeMapping[poolKey.toId()] = newBaseFee;
    }

    /*
      @dev Update fee for pool by poolId
      @param fee
      @return
     */
    function updatePoolFeeByPoolId(PoolId[] memory poolIds, uint24 newBaseFee) external onlyOwner {
        for (uint256 i = 0; i < poolIds.length; i++) {
            (Currency currency0, Currency currency1, IHooks hooks, IPoolManager manager, uint24 fee, bytes32 parameters)
            = poolManager.poolIdToPoolKey(poolIds[i]);
            poolManager.updateDynamicLPFee(PoolKey(currency0, currency1, hooks, manager, fee, parameters), newBaseFee);
            poolFeeMapping[poolIds[i]] = newBaseFee;
        }
    }
}
