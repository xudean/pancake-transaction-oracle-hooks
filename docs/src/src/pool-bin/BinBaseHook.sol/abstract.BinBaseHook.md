# BinBaseHook
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/feca97195ce7999ef87419eab15c366c609ecf4a/src/pool-bin/BinBaseHook.sol)

**Inherits:**
IBinHooks

BaseHook abstract contract for Bin pool hooks to inherit


## State Variables
### poolManager
The address of the pool manager


```solidity
IBinPoolManager public immutable poolManager;
```


### vault
The address of the vault


```solidity
IVault public immutable vault;
```


## Functions
### constructor


```solidity
constructor(IBinPoolManager _poolManager);
```

### poolManagerOnly

*Only the pool manager may call this function*


```solidity
modifier poolManagerOnly();
```

### vaultOnly

*Only the vault may call this function*


```solidity
modifier vaultOnly();
```

### selfOnly

*Only this address may call this function*


```solidity
modifier selfOnly();
```

### onlyValidPools

*Only pools with hooks set to this contract may call this function*


```solidity
modifier onlyValidPools(IHooks hooks);
```

### lockAcquired

*Delegate calls to corresponding methods according to callback data*


```solidity
function lockAcquired(bytes calldata data) external virtual vaultOnly returns (bytes memory);
```

### beforeInitialize

The hook called before the state of a pool is initialized


```solidity
function beforeInitialize(address, PoolKey calldata, uint24) external virtual returns (bytes4);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`uint24`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|


### afterInitialize

The hook called after the state of a pool is initialized


```solidity
function afterInitialize(address, PoolKey calldata, uint24) external virtual returns (bytes4);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`uint24`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|


### beforeMint

The hook called before adding liquidity


```solidity
function beforeMint(address, PoolKey calldata, IBinPoolManager.MintParams calldata, bytes calldata)
    external
    virtual
    returns (bytes4, uint24);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`IBinPoolManager.MintParams`||
|`<none>`|`bytes`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|
|`<none>`|`uint24`|uint24 Optionally override the lp fee, only used if four conditions are met: 1) Liquidity added to active bin in different ratio from current bin (causing an internal swap) 2) the Pool has a dynamic fee, 3) the value's override flag is set to 1 i.e. vaule & OVERRIDE_FEE_FLAG = 0x400000 != 0 4) the value is less than or equal to the maximum fee (100_000) - 10%|


### afterMint

The hook called after adding liquidity


```solidity
function afterMint(address, PoolKey calldata, IBinPoolManager.MintParams calldata, BalanceDelta, bytes calldata)
    external
    virtual
    returns (bytes4, BalanceDelta);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`IBinPoolManager.MintParams`||
|`<none>`|`BalanceDelta`||
|`<none>`|`bytes`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|
|`<none>`|`BalanceDelta`|BalanceDelta The hook's delta in token0 and token1.|


### beforeBurn

The hook called before removing liquidity


```solidity
function beforeBurn(address, PoolKey calldata, IBinPoolManager.BurnParams calldata, bytes calldata)
    external
    virtual
    returns (bytes4);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`IBinPoolManager.BurnParams`||
|`<none>`|`bytes`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|


### afterBurn

The hook called after removing liquidity


```solidity
function afterBurn(address, PoolKey calldata, IBinPoolManager.BurnParams calldata, BalanceDelta, bytes calldata)
    external
    virtual
    returns (bytes4, BalanceDelta);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`IBinPoolManager.BurnParams`||
|`<none>`|`BalanceDelta`||
|`<none>`|`bytes`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|
|`<none>`|`BalanceDelta`|BalanceDelta The hook's delta in token0 and token1.|


### beforeSwap

The hook called before a swap


```solidity
function beforeSwap(address, PoolKey calldata, bool, int128, bytes calldata)
    external
    virtual
    returns (bytes4, BeforeSwapDelta, uint24);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`bool`||
|`<none>`|`int128`||
|`<none>`|`bytes`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|
|`<none>`|`BeforeSwapDelta`|BeforeSwapDelta The hook's delta in specified and unspecified currencies.|
|`<none>`|`uint24`|uint24 Optionally override the lp fee, only used if three conditions are met: 1) the Pool has a dynamic fee, 2) the value's override flag is set to 1 i.e. vaule & OVERRIDE_FEE_FLAG = 0x400000 != 0 3) the value is less than or equal to the maximum fee (100_000) - 10%|


### afterSwap

The hook called after a swap


```solidity
function afterSwap(address, PoolKey calldata, bool, int128, BalanceDelta, bytes calldata)
    external
    virtual
    returns (bytes4, int128);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`bool`||
|`<none>`|`int128`||
|`<none>`|`BalanceDelta`||
|`<none>`|`bytes`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|
|`<none>`|`int128`|int128 The hook's delta in unspecified currency|


### beforeDonate

The hook called before donate


```solidity
function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata) external virtual returns (bytes4);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`uint256`||
|`<none>`|`uint256`||
|`<none>`|`bytes`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|


### afterDonate

The hook called after donate


```solidity
function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata) external virtual returns (bytes4);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`||
|`<none>`|`PoolKey`||
|`<none>`|`uint256`||
|`<none>`|`uint256`||
|`<none>`|`bytes`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|bytes4 The function selector for the hook|


### _hooksRegistrationBitmapFrom

*Helper function to construct the hook registration map*


```solidity
function _hooksRegistrationBitmapFrom(Permissions memory permissions) internal pure returns (uint16);
```

## Errors
### NotPoolManager
The sender is not the pool manager


```solidity
error NotPoolManager();
```

### NotVault
The sender is not the vault


```solidity
error NotVault();
```

### NotSelf
The sender is not this contract


```solidity
error NotSelf();
```

### InvalidPool
The pool key does not include this hook


```solidity
error InvalidPool();
```

### LockFailure
The delegation of lockAcquired failed


```solidity
error LockFailure();
```

### HookNotImplemented
The method is not implemented


```solidity
error HookNotImplemented();
```

## Structs
### Permissions

```solidity
struct Permissions {
    bool beforeInitialize;
    bool afterInitialize;
    bool beforeMint;
    bool afterMint;
    bool beforeBurn;
    bool afterBurn;
    bool beforeSwap;
    bool afterSwap;
    bool beforeDonate;
    bool afterDonate;
    bool beforeSwapReturnsDelta;
    bool afterSwapReturnsDelta;
    bool afterMintReturnsDelta;
    bool afterBurnReturnsDelta;
}
```

