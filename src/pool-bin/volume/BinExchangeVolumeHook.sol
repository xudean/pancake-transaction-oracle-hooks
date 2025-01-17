pragma solidity ^0.8.24;

import "../../BaseFeeDiscountHook.sol";
import "pancake-v4-core/src/pool-cl/interfaces/ICLHooks.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";
import {BinBaseHook} from "../BinBaseHook.sol";
import {BinPoolManager} from "pancake-v4-core/src/pool-bin/BinPoolManager.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {IBinPoolManager} from "pancake-v4-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {LPFeeLibrary} from "pancake-v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolId, PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";

contract BinExchangeVolumeHook is BinBaseHook, BaseFeeDiscountHook {
    using PoolIdLibrary for PoolKey;

    constructor(IBinPoolManager poolManager, IAttestationRegistry _attestationRegistry, address initialOwner)
        BinBaseHook(poolManager)
        BaseFeeDiscountHook(_attestationRegistry, initialOwner)
    {}

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: true,
                beforeMint: false,
                afterMint: false,
                beforeBurn: false,
                afterBurn: false,
                beforeSwap: true,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterMintReturnsDelta: false,
                afterBurnReturnsDelta: false
            })
        );
    }

    function afterInitialize(address sender, PoolKey calldata key, uint24 activeId)
        external
        override
        returns (bytes4)
    {
        poolManager.updateDynamicLPFee(key, getDefaultFee());
        return (this.afterInitialize.selector);
    }

    function beforeSwap(address, PoolKey calldata key, bool, int128, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 fee = getFeeDiscount(tx.origin, key);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee);
    }
}
