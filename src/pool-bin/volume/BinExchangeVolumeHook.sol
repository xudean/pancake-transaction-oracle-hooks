pragma solidity ^0.8.19;

import "pancake-v4-core/src/pool-cl/interfaces/ICLHooks.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {IBinPoolManager} from "pancake-v4-core/src/pool-bin/interfaces/IBinPoolManager.sol";
import {BinPoolManager} from "pancake-v4-core/src/pool-bin/BinPoolManager.sol";
import {LPFeeLibrary} from "pancake-v4-core/src/libraries/LPFeeLibrary.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";
import {BinBaseHook} from "../BinBaseHook.sol";

contract BinExchangeVolumeHook is BinBaseHook {
    using PoolIdLibrary for PoolKey;

    constructor(IBinPoolManager poolManager) BinBaseHook(poolManager) {}


    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeMint: false,
                afterMint: true,
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

    function afterMint(address, PoolKey calldata, IBinPoolManager.MintParams calldata,  BalanceDelta balanceDelta, bytes calldata)
    external
    override
    returns (bytes4, BalanceDelta)
    {
        return (this.afterMint.selector, balanceDelta);
    }

    function beforeSwap(address, PoolKey calldata, bool, int128, bytes calldata)
    external
    override
    returns (bytes4, BeforeSwapDelta, uint24)
    {


        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }
}
