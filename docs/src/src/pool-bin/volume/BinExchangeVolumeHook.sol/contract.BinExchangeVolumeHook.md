# BinExchangeVolumeHook
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/feca97195ce7999ef87419eab15c366c609ecf4a/src/pool-bin/volume/BinExchangeVolumeHook.sol)

**Inherits:**
[BinBaseHook](/src/pool-bin/BinBaseHook.sol/abstract.BinBaseHook.md)


## Functions
### constructor


```solidity
constructor(IBinPoolManager poolManager) BinBaseHook(poolManager);
```

### getHooksRegistrationBitmap


```solidity
function getHooksRegistrationBitmap() external pure override returns (uint16);
```

### afterMint


```solidity
function afterMint(
    address,
    PoolKey calldata,
    IBinPoolManager.MintParams calldata,
    BalanceDelta balanceDelta,
    bytes calldata
) external override returns (bytes4, BalanceDelta);
```

### beforeSwap


```solidity
function beforeSwap(address, PoolKey calldata, bool, int128, bytes calldata)
    external
    override
    returns (bytes4, BeforeSwapDelta, uint24);
```

