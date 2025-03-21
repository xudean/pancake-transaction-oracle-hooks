# BaseFeeDiscountHook
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/d25cacf462cd44cfa2b91ac015aa755b33e6c616/src/BaseFeeDiscountHook.sol)

**Inherits:**
Ownable


## State Variables
### defaultFee

```solidity
uint24 public defaultFee = 3000;
```


### baseValue

```solidity
uint24 public baseValue = 10000;
```


### durationOfAttestation

```solidity
uint24 public durationOfAttestation = 7;
```


### poolsInitialized

```solidity
PoolId[] public poolsInitialized;
```


### poolFeeMapping

```solidity
mapping(PoolId => uint24) public poolFeeMapping;
```


### iAttestationRegistry

```solidity
IAttestationRegistry public iAttestationRegistry;
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

### setBaseValue


```solidity
function setBaseValue(uint24 _baseValue) external onlyOwner;
```

### setDurationOfAttestation


```solidity
function setDurationOfAttestation(uint24 _durationOfAttestation) external onlyOwner;
```

### setAttestationRegistry


```solidity
function setAttestationRegistry(IAttestationRegistry _iAttestationRegistry) external onlyOwner;
```

### getInitializedPoolSize


```solidity
function getInitializedPoolSize() external view returns (uint256);
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

