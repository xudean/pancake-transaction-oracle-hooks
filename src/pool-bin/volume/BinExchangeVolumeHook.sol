pragma solidity ^0.8.24;

import "../../BaseFeeDiscountHook.sol";
import "pancake-v4-core/src/pool-cl/interfaces/ICLHooks.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";
import {BinBaseHook} from "../BinBaseHook.sol";
import {BinPoolManager} from "pancake-v4-core/src/pool-bin/BinPoolManager.sol";
import {IPoolManager} from "pancake-v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {IHooks} from "pancake-v4-core/src/interfaces/IHooks.sol";
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
        poolManagerOnly
        returns (bytes4)
    {
        poolManager.updateDynamicLPFee(key, getDefaultFee());
        poolsInitialized.push(key.toId());
        return (this.afterInitialize.selector);
    }

    function beforeSwap(address, PoolKey calldata key, bool, int128, bytes calldata)
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        uint24 fee = getFeeDiscount(tx.origin, key);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee);
    }

    /*
      @dev Update fee for pool by poolKey
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
