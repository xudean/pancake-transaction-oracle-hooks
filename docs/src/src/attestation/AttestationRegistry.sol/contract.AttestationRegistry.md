# AttestationRegistry
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/d25cacf462cd44cfa2b91ac015aa755b33e6c616/src/attestation/AttestationRegistry.sol)

**Inherits:**
Ownable, [IAttestationRegistry](/src/IAttestationRegistry.sol/interface.IAttestationRegistry.md)


## State Variables
### attestationsOfAddress

```solidity
mapping(address => Attestation[]) public attestationsOfAddress;
```


### cexInfoMapping

```solidity
mapping(string => CexInfo) public cexInfoMapping;
```


### primusZKTLS

```solidity
IPrimusZKTLS internal primusZKTLS;
```


### submissionFee

```solidity
uint256 public submissionFee;
```


### feeRecipient

```solidity
address payable public feeRecipient;
```


## Functions
### constructor

*Constructor*


```solidity
constructor(address _primusZKTLS, uint256 _submissionFee, address payable _feeRecipient) Ownable(msg.sender);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_primusZKTLS`|`address`|The address of the IPrimusZKTLS contract|
|`_submissionFee`|`uint256`|The submission fee|
|`_feeRecipient`|`address payable`|The fee recipient|


### setPrimusZKTLS

*set IPrimusZKTLS contract instance*


```solidity
function setPrimusZKTLS(address _primusZKTLS) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_primusZKTLS`|`address`|The address of the IPrimusZKTLS contract|


### setSubmissionFee

*set submissionFee*


```solidity
function setSubmissionFee(uint256 _submissionFee) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_submissionFee`|`uint256`|The submission fee|


### setFeeRecipient

*set feeRecipient*


```solidity
function setFeeRecipient(address payable _feeRecipient) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_feeRecipient`|`address payable`|The fee recipient|


### setCexAndJsonPath

*setCexAndJsonPath*


```solidity
function setCexAndJsonPath(string[] memory _cexUrls, string[] memory _cexNames, string[] memory _jsonPaths)
    external
    onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cexUrls`|`string[]`|The cex URL addresses|
|`_cexNames`|`string[]`|The cex names such as "binance" "okx" etc.|
|`_jsonPaths`|`string[]`|The json paths|


### getCexInfoDetail

*getCexInfoDetail*


```solidity
function getCexInfoDetail(string memory _cexUrl) external view returns (CexInfo memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cexUrl`|`string`|The cex URL address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`CexInfo`|CexInfo|


### addUrlToCexInfo

*Add or update the mapping of URL to exchange name and parsePath*


```solidity
function addUrlToCexInfo(string memory _cexUrl, string memory _cexName, string memory _jsonPath) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cexUrl`|`string`|The cex URL address|
|`_cexName`|`string`|The cex name such as "binance" "okx" etc.|
|`_jsonPath`|`string`|The parsing path|


### removeUrlToCexInfo

*Remove the mapping of URL to cex info*


```solidity
function removeUrlToCexInfo(string memory _cexUrl) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_cexUrl`|`string`|The cex URL address|


### submitAttestation

*submit attestation*


```solidity
function submitAttestation(PrimusAttestation calldata _attestation) public payable returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_attestation`|`PrimusAttestation`|The attestation data to be verified|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|attestationId The attestationId of the submitted attestation|


### getAttestationByRecipient

*Get attestations by recipient*


```solidity
function getAttestationByRecipient(address recipient) public view returns (Attestation[] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|The recipient address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Attestation[]`|Attestation[] memory|


### extractBaseUrl

*Extract the base URL (ignoring query parameters)*


```solidity
function extractBaseUrl(string memory url) internal pure returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`url`|`string`|The full URL|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The base URL without query parameters|


## Events
### AttestationSubmitted

```solidity
event AttestationSubmitted(address recipient, string cexName, uint256 value, uint256 timestamp);
```

### FeeReceived

```solidity
event FeeReceived(address sender, uint256 amount);
```

### UrlToCexInfoAdded

```solidity
event UrlToCexInfoAdded(string indexed cexUrl, string cexName);
```

### UrlToCexInfoRemoved

```solidity
event UrlToCexInfoRemoved(string indexed cexUrl);
```

