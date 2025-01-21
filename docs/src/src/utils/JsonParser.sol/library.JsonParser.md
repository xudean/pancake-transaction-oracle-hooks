# JsonParser
[Git Source](https://github.com/WuEcho/pancake-transaction-oracle-hooks/blob/d25cacf462cd44cfa2b91ac015aa755b33e6c616/src/utils/JsonParser.sol)


## Functions
### extractValue

*Extracts the value of a given key from a JSON string, supports nested keys.*


```solidity
function extractValue(string memory json, string memory key) internal pure returns (string memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`json`|`string`|The JSON string to parse.|
|`key`|`string`|The key whose value needs to be extracted.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The value associated with the given key.|


### isMatch

*Checks if the given key matches the JSON substring at the specified position.*


```solidity
function isMatch(bytes memory jsonBytes, bytes memory keyBytes, uint256 start) internal pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`jsonBytes`|`bytes`|The JSON string as bytes.|
|`keyBytes`|`bytes`|The key as bytes.|
|`start`|`uint256`|The starting index to compare.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the key matches, false otherwise.|


