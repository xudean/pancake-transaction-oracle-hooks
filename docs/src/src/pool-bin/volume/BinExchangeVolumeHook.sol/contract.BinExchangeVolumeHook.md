# BinExchangeVolumeHook
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/d25cacf462cd44cfa2b91ac015aa755b33e6c616/src/pool-bin/volume/BinExchangeVolumeHook.sol)

**Inherits:**
[BinBaseHook](/src/pool-bin/BinBaseHook.sol/abstract.BinBaseHook.md), [BaseFeeDiscountHook](/src/BaseFeeDiscountHook.sol/abstract.BaseFeeDiscountHook.md)


## Functions
### constructor


```solidity
constructor(IBinPoolManager poolManager, IAttestationRegistry _attestationRegistry, address initialOwner)
    BinBaseHook(poolManager)
    BaseFeeDiscountHook(_attestationRegistry, initialOwner);
```

### getHooksRegistrationBitmap


```solidity
function getHooksRegistrationBitmap() external pure override returns (uint16);
```

### afterInitialize


```solidity
function afterInitialize(address sender, PoolKey calldata key, uint24 activeId)
    external
    override
    poolManagerOnly
    returns (bytes4);
```

### beforeSwap


```solidity
function beforeSwap(address, PoolKey calldata key, bool, int128, bytes calldata)
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

