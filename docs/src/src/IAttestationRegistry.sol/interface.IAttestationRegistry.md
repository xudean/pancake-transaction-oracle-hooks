# IAttestationRegistry
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/feca97195ce7999ef87419eab15c366c609ecf4a/src/IAttestationRegistry.sol)


## Functions
### submitAttestation


```solidity
function submitAttestation(PrimusAttestation memory attestation) external payable returns (bool);
```

### getAttestationByRecipient


```solidity
function getAttestationByRecipient(address recipient) external view returns (Attestation[] memory);
```

