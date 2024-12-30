// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {LPFeeLibrary} from "pancake-v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {IAttestationRegistry} from "./IAttestationRegistry.sol";

abstract contract BaseFeeDiscountHook{
    using LPFeeLibrary for uint24;

    error NotEnoughAttestations();
    error NOSpot30dTradeVol();
    error NOTransactionsOnBnbChain();
    error NotSupportedExchange();
    error AttestationExpired();
    //No proof of eligibility
    error NoAttestationEligibility();


    event BeforeAddLiquidity(address indexed sender);
    event BeforeSwap(address indexed sender);

    mapping(PoolId => uint24) public poolFeeMapping;
    // AttestationRegistry
    IAttestationRegistry internal  iAttestationRegistry;

    //Use mapping for efficiency
    mapping(string => bool) private supportedExchangesMapping;

    //attestation will expired in 7 days
    uint private defaultValidityOfAttestation = 7 * 24 * 60 * 60;

    constructor(IAttestationRegistry _iAttestationRegistry) {
        iAttestationRegistry = _iAttestationRegistry;
        supportedExchangesMapping["okx"] = true;
        supportedExchangesMapping["binance"] = true;
    }

    function initPoolFeeDiscount(PoolKey memory poolKey, bytes[] memory parameters) internal {
        //todo
        PoolId id = poolKey.toId();
    }

    function getFeeDiscount(address sender, PoolKey memory poolKey) internal view returns (uint24) {
        uint24 poolFee = poolFeeMapping[poolKey.toId()];
        if (!_checkAttestations(sender)) {
            //no discount
            return poolFee | LPFeeLibrary.OVERRIDE_FEE_FLAG;
        }else{
            //There is a 50% discount on the handling fee for eligible certificates
            return (poolFee / 2) | LPFeeLibrary.OVERRIDE_FEE_FLAG;
        }
    }

    /*
     * @dev Check the user has a attestation and the attestation is not expired
     * @param sender
     * @return bool , sender has valid attestation.
     */
    function _checkAttestations(address sender) internal view returns (bool) {
        //todo
        return true;
    }

    /**
     * only support [op][digital], which:
     * -      op: >=, <=, !=, >, <, ==
     * - digital: [0-9]+
     */
    function _compareCondition(string memory condition, uint256 baseValue) internal pure returns (bool) {
        bytes memory b = bytes(condition);
        if (b.length == 1) {
            return false;
        }

        uint256 digital_start = 1;
        if (b.length >= 3) {
            if (b[1] == "=") {
                digital_start = 2;
            }
        }

        uint256 value = 0;
        for (uint256 i = digital_start; i < b.length; i++) {
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
            if (b[0] == ">") return value >= baseValue;
            else if (b[0] == "<") return value <= baseValue;
        } else {
            if (b[0] == ">") return value >= baseValue;
            else if (b[0] == "<") return value <= baseValue;
            else if (b[0] == "=") return value == baseValue;
            else if (b[0] == "!") return value != baseValue;
        }

        return false;
    }

    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(bytes(a)) == keccak256(bytes(b)));
    }
}
