# CLExchangeVolumeHook
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/d25cacf462cd44cfa2b91ac015aa755b33e6c616/src/pool-cl/volume/CLExchangeVolumeHook.sol)

**Inherits:**
[CLBaseHook](/src/pool-cl/CLBaseHook.sol/abstract.CLBaseHook.md), [BaseFeeDiscountHook](/src/BaseFeeDiscountHook.sol/abstract.BaseFeeDiscountHook.md)

CLExchangeVolumeHook.sol.sol will check the following attestations before adding liquidity or swap:
1. The attestation of binance or other exchanges within 7 days
2. If a valid attestation of address is provided, the handling fee will be discounted by 50%.


## Functions
### constructor


```solidity
constructor(ICLPoolManager _poolManager, IAttestationRegistry _attestationRegistry, address initialOwner)
    CLBaseHook(_poolManager)
    BaseFeeDiscountHook(_attestationRegistry, initialOwner);
```

### getHooksRegistrationBitmap


```solidity
function getHooksRegistrationBitmap() external pure override returns (uint16);
```

### afterInitialize


```solidity
function afterInitialize(address sender, PoolKey calldata key, uint160 sqrtPriceX96, int24 tick)
    external
    override
    poolManagerOnly
    returns (bytes4);
```

### beforeSwap


```solidity
function beforeSwap(address sender, PoolKey calldata key, ICLPoolManager.SwapParams calldata, bytes calldata)
    external
    override
    poolManagerOnly
    returns (bytes4, BeforeSwapDelta, uint24);
```

### updatePoolFeeByPoolKey


```solidity
function updatePoolFeeByPoolKey(PoolKey memory poolKey, uint24 newBaseFee) external onlyOwner;
```

### updatePoolFeeByPoolId


```solidity
function updatePoolFeeByPoolId(PoolId[] memory poolIds, uint24 newBaseFee) external onlyOwner;
```

