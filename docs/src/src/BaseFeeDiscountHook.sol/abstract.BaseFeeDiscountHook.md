# BaseFeeDiscountHook
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/feca97195ce7999ef87419eab15c366c609ecf4a/src/BaseFeeDiscountHook.sol)

**Inherits:**
Ownable


## State Variables
### defaultFee

```solidity
uint24 private defaultFee = 3000;
```


### baseValue

```solidity
uint24 private baseValue = 10000;
```


### iAttestationRegistry

```solidity
IAttestationRegistry internal iAttestationRegistry;
```


## Functions
### constructor


```solidity
constructor(IAttestationRegistry _iAttestationRegistry, address initialOwner) Ownable(initialOwner);
```

### getFeeDiscount


```solidity
function getFeeDiscount(address sender, PoolKey memory poolKey) internal view returns (uint24);
```

### setDefaultFee


```solidity
function setDefaultFee(uint24 fee) external onlyOwner;
```

### getDefaultFee


```solidity
function getDefaultFee() external view returns (uint24);
```

### setBaseValue


```solidity
function setBaseValue(uint24 _baseValue) external onlyOwner;
```

### getBaseValue


```solidity
function getBaseValue() external view returns (uint24);
```

### _checkAttestations


```solidity
function _checkAttestations(address sender) internal view returns (bool);
```

## Events
### BeforeAddLiquidity

```solidity
event BeforeAddLiquidity(address indexed sender);
```

### BeforeSwap

```solidity
event BeforeSwap(address indexed sender);
```

## Errors
### NotSupportedExchange

```solidity
error NotSupportedExchange();
```

### AttestationExpired

```solidity
error AttestationExpired();
```

### NoAttestationEligibility

```solidity
error NoAttestationEligibility();
```

