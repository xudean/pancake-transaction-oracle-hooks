# IAttestationRegistry
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/d25cacf462cd44cfa2b91ac015aa755b33e6c616/src/IAttestationRegistry.sol)


## Functions
### submitAttestation


```solidity
function submitAttestation(PrimusAttestation memory attestation) external payable returns (bool);
```

### getAttestationByRecipient


```solidity
function getAttestationByRecipient(address recipient) external view returns (Attestation[] memory);
```

