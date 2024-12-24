// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";
import {PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLBaseHook} from "../CLBaseHook.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEAS} from "bas-contract/contracts/IEAS.sol";
import {Attestation, EMPTY_UID, uncheckedInc} from "bas-contract/contracts/Common.sol";
import {IEASProxy} from "../../IEASProxy.sol";

/// @notice CLExchangeVolumeHook.sol.sol will check the following attestations before adding liquidity or swap:
/// 1. the spot trading volume of binance or other exchanges within 30 days
/// 2. whether has transaction(s) on BNB chain since 2024 July
contract CLExchangeVolumeHook is CLBaseHook, Ownable {
    using PoolIdLibrary for PoolKey;

    error NotEnoughAttestations();
    error NOSpot30dTradeVol();
    error NOTransactionsOnBnbChain();

    event BeforeAddLiquidity(address indexed sender);
    event BeforeSwap(address indexed sender);

    IEASProxy private _iEasProxy;
    IEAS private _eas;
    bytes32 private _schemaBytes;
    uint private _baseValue;

    constructor(
        ICLPoolManager _poolManager,
        IEASProxy iEasPrxoy,
        IEAS eas,
        bytes32 schemaBytes
    ) CLBaseHook(_poolManager) Ownable(msg.sender) {
        _iEasProxy = iEasPrxoy;
        _eas = eas;
        _schemaBytes = schemaBytes;
        _baseValue = 100; // default 100
    }

    function getHooksRegistrationBitmap()
        external
        pure
        override
        returns (uint16)
    {
        return
            _hooksRegistrationBitmapFrom(
                Permissions({
                    beforeInitialize: false,
                    afterInitialize: false,
                    beforeAddLiquidity: true,
                    afterAddLiquidity: false,
                    beforeRemoveLiquidity: false,
                    afterRemoveLiquidity: false,
                    beforeSwap: true,
                    afterSwap: false,
                    beforeDonate: false,
                    afterDonate: false,
                    beforeSwapReturnsDelta: false,
                    afterSwapReturnsDelta: false,
                    afterAddLiquidityReturnsDelta: false,
                    afterRemoveLiquidityReturnsDelta: false
                })
            );
    }

    function beforeAddLiquidity(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override poolManagerOnly returns (bytes4) {
        _checkAttestations(tx.origin);
        emit BeforeAddLiquidity(sender);

        return this.beforeAddLiquidity.selector;
    }

    function beforeSwap(
        address sender,
        PoolKey calldata key,
        ICLPoolManager.SwapParams calldata,
        bytes calldata
    )
        external
        override
        poolManagerOnly
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        _checkAttestations(tx.origin);
        emit BeforeSwap(sender);

        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _checkAttestations(address sender) internal {

    }

    /**
     * only support [op][digital], which:
     * -      op: >=, <=, !=, >, <, ==
     * - digital: [0-9]+
     */
    function _compareCondition(
        string memory condition,
        uint baseValue
    ) internal pure returns (bool) {
        bytes memory b = bytes(condition);
        if (b.length == 1) {
            return false;
        }

        uint digital_start = 1;
        if (b.length >= 3) {
            if (b[1] == "=") {
                digital_start = 2;
            }
        }

        uint value = 0;
        for (uint i = digital_start; i < b.length; i++) {
            if (b[i] >= "0" && b[i] <= "9") {
                value = value * 10 + uint8(b[i]) - 48;
            } else {
                return false;
            }
        }

        // prettier-ignore
        if (digital_start == 1) {
            // note: here is '>=/<=', not '>/<'
            // if baseValue is 100, prove >100, the value is equal to baseValue
            if (b[0] == ">") { return value >= baseValue; }
            else if (b[0] == "<") { return value <= baseValue;}
        } else {
            if (b[0] == ">") { return value >= baseValue; } 
            else if (b[0] == "<") { return value <= baseValue; } 
            else if (b[0] == "=") { return value == baseValue; } 
            else if (b[0] == "!") { return value != baseValue;}
        }

        return false;
    }

    function _compareStrings(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(bytes(a)) == keccak256(bytes(b)));
    }

    function setEasProxy(IEASProxy iEasPrxoy) external onlyOwner {
        _iEasProxy = iEasPrxoy;
    }
    function setSchemaBytes(bytes32 schemaBytes) external onlyOwner {
        _schemaBytes = schemaBytes;
    }
    function setBaseValue(uint baseValue) external onlyOwner {
        _baseValue = baseValue;
    }

    function getEasProxy() external view returns (IEASProxy) {
        return _iEasProxy;
    }
    function getSchemaBytes() external view returns (bytes32) {
        return _schemaBytes;
    }
    function getBaseValue() external view returns (uint) {
        return _baseValue;
    }
}
