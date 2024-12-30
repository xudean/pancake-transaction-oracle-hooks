// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";
import {PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLBaseHook} from "../CLBaseHook.sol";
import {IAttestationRegistry} from "../../IAttestationRegistry.sol";
import {BaseFeeDiscountHook} from "../../BaseFeeDiscountHook.sol";

/// @notice CLExchangeVolumeHook.sol.sol will check the following attestations before adding liquidity or swap:
/// 1. the spot trading volume of binance or other exchanges within 30 days
/// 2. whether has transaction(s) on BNB chain since 2024 July
contract CLExchangeVolumeHook is CLBaseHook , BaseFeeDiscountHook{
    using PoolIdLibrary for PoolKey;

    constructor(
        ICLPoolManager _poolManager,
        IAttestationRegistry _attestationRegistry
    ) CLBaseHook(_poolManager) BaseFeeDiscountHook(_attestationRegistry){

    }

    function getHooksRegistrationBitmap()
        external
        pure
        override
        returns (uint16)
    {
        return
            _hooksRegistrationBitmapFrom(
                Permissions({
                    beforeInitialize: false,
                    afterInitialize: false,
                    beforeAddLiquidity: true,
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

    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        emit BeforeAddLiquidity(sender);

        return this.beforeAddLiquidity.selector;
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.SwapParams calldata,
        bytes calldata
    )
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 fee = getFeeDiscount(tx.origin,key);
        emit BeforeSwap(sender);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee);
    }

    function getAttestationRegistry() external view returns (IAttestationRegistry) {
        return iAttestationRegistry;
    }
}
