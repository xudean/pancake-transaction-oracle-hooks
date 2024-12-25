// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IEASProxy.sol";
import {LPFeeLibrary} from "pancake-v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {IEAS} from "bas-contract/contracts/IEAS.sol";
import {Attestation, EMPTY_UID, uncheckedInc} from "bas-contract/contracts/Common.sol";

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

    // poolId => (baseValue => feeDiscount)
    // mapping(PoolId => mapping(uint32=>uint24)) public poolFeeDiscountMapping;
    //poolId=>feeDiscount
    // baseValue=50% * fee
    mapping(PoolId => uint24) public poolFeeDiscountMapping;
    // AttestationRegistry
    IEASProxy public easProxy;
    bytes32 public schemaBytes;
    IEAS public eas;

    //Use mapping for efficiency
    mapping(string => bool) private supportedExchangesMapping;
    //attestation will expired in 7 days
    uint private defaultValidityOfAttestation = 7 * 24 * 60 * 60;

    constructor(IEASProxy _easProxy, IEAS _eas, bytes32 _schemaBytes) {
        easProxy = _easProxy;
        eas = _eas;
        schemaBytes = _schemaBytes;
        supportedExchangesMapping["okx"] = true;
        supportedExchangesMapping["binance"] = true;
    }

    function initPoolFeeDiscount(PoolKey memory poolKey, bytes[] memory parameters) internal {
        PoolId id = poolKey.toId();
    }

    function getFeeDiscount(address user, PoolKey memory poolKey) internal view returns (uint24) {
        //Check the address has a attestation and the attestation is not expired
        uint24 lpFee = poolKey.fee.getInitialLPFee();
        return 0;
    }

    function _checkAttestations(address sender) internal view returns (uint24) {
        bytes32[] memory uids = easProxy.getPadoAttestations(sender, schemaBytes);
        bool hasValidAttestation = false;
        for (uint256 i = 0; i < uids.length; i = uncheckedInc(i)) {
            Attestation memory ats = eas.getAttestation(uids[i]);
            // prettier-ignore
            (
                string memory proofType,
                string memory source,
                string memory content,
                string memory condition,
                bytes32 sourceUserIdHash,
                bool result,
                uint64 timestamp,
                bytes32 userIdHash
            ) = abi.decode(ats.data, (string, string, string, string, bytes32, bool, uint64, bytes32));
            if (!_compareStrings(content, "Spot 30-Day Trade Volume")) {
                continue;
            }
            if (!supportedExchangesMapping[source]) {
                revert NotSupportedExchange();
            }
            //check timestamp in 7 days
            if (block.timestamp - timestamp > defaultValidityOfAttestation) {
                revert AttestationExpired();
            }
            //condition , base value ,such 100
            hasValidAttestation = true;
            break;
        }
        if(!hasValidAttestation){
            revert NoAttestationEligibility();
        }
        //todo means 50%
        return 50000;
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
