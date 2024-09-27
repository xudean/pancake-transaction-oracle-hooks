// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "pancake-v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "pancake-v4-core/src/types/BeforeSwapDelta.sol";
import {PoolId, PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLBaseHook} from "./CLBaseHook.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IEAS} from "bas-contract/contracts/IEAS.sol";
import {Attestation, EMPTY_UID, uncheckedInc} from "bas-contract/contracts/Common.sol";
import {IEASProxy} from "../IEASProxy.sol";

/// @notice CLOffchainTransactionHook will check the spot trading volume
/// of binance or other exchanges within 30 days before adding liquidity or swap.
contract CLOffchainTransactionHook is CLBaseHook, Ownable {
    using PoolIdLibrary for PoolKey;

    error NOSpot30dTradeVol();

    event BeforeAddLiquidity(address indexed sender);
    event BeforeSwap(address indexed sender);

    IEASProxy private _iEasProxy;
    IEAS private _eas;
    bytes32 private _schemaSpot30dTradeVol;
    uint private _baseValue;

    constructor(
        ICLPoolManager _poolManager,
        IEASProxy iEasPrxoy,
        IEAS eas,
        bytes32 schemaSpot30dTradeVol
    ) CLBaseHook(_poolManager) Ownable(msg.sender) {
        _iEasProxy = iEasPrxoy;
        _eas = eas;
        _schemaSpot30dTradeVol = schemaSpot30dTradeVol;
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
        if (!_checkSpot30dTradeVolResult(tx.origin)) {
            revert NOSpot30dTradeVol();
        }
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
        if (!_checkSpot30dTradeVolResult(tx.origin)) {
            revert NOSpot30dTradeVol();
        }
        emit BeforeSwap(sender);

        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _checkSpot30dTradeVolResult(
        address sender
    ) internal view returns (bool) {
        bytes32[] memory uids = _iEasProxy.getPadoAttestations(
            sender,
            _schemaSpot30dTradeVol
        );
        if (uids.length < 2) {
            return false;
        }

        bool _spot30DayTradeVol = false;
        bool _hasTransactionOnBnbChain = false;
        for (uint256 i = 0; i < uids.length; i = uncheckedInc(i)) {
            if (_spot30DayTradeVol && _hasTransactionOnBnbChain) {
                return true;
            }

            Attestation memory ats = _eas.getAttestation(uids[i]);
            // prettier-ignore
            (
                string memory ProofType,
                string memory Source,
                string memory Content,
                string memory Condition,
                /*bytes32 SourceUserIdHash*/,
                bool Result,
                /*uint64 Timestamp*/,
                /*bytes32 UserIdHash*/
            ) = abi.decode(ats.data, (string, string, string, string, bytes32, bool, uint64, bytes32));

            if (
                !_spot30DayTradeVol &&
                _compareStrings(ProofType, "Assets") &&
                (_compareStrings(Source, "binance") ||
                    _compareStrings(Source, "okx")) &&
                _compareStrings(Content, "Spot 30-Day Trade Volume") &&
                _compareCondition(Condition, _baseValue) &&
                Result
            ) {
                _spot30DayTradeVol = true;
            } else if (
                !_hasTransactionOnBnbChain &&
                _compareStrings(ProofType, "Web3 Wallet") &&
                _compareStrings(Source, "Brevis") &&
                _compareStrings(Content, "Has transactions on BNB Chain") &&
                _compareStrings(Condition, "since 2024 July") &&
                Result
            ) {
                _hasTransactionOnBnbChain = true;
            }
        }

        return _spot30DayTradeVol && _hasTransactionOnBnbChain;
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
    function setSchemaSpot30dTradeVol(
        bytes32 schemaSpot30dTradeVol
    ) external onlyOwner {
        _schemaSpot30dTradeVol = schemaSpot30dTradeVol;
    }
    function setBaseValue(uint baseValue) external onlyOwner {
        _baseValue = baseValue;
    }

    function getEasProxy() external view returns (IEASProxy) {
        return _iEasProxy;
    }
    function getSchemaSpot30dTradeVol() external view returns (bytes32) {
        return _schemaSpot30dTradeVol;
    }
    function getBaseValue() external view returns (uint) {
        return _baseValue;
    }
}
