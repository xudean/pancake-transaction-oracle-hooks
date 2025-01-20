// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {LPFeeLibrary} from "pancake-v4-core/src/libraries/LPFeeLibrary.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {IAttestationRegistry} from "./IAttestationRegistry.sol";
import {Attestation} from "./types/Common.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract BaseFeeDiscountHook is Ownable {
    using LPFeeLibrary for uint24;

    error NotSupportedExchange();
    error AttestationExpired();
    error NoAttestationEligibility();

    event BeforeAddLiquidity(address indexed sender);
    event BeforeSwap(address indexed sender);

    uint24 private defaultFee = 3000;

    uint24 private baseValue = 10000;

    uint24 private durationOfAttestation = 7;

    PoolId[] public poolsInitialized;
    // AttestationRegistry
    IAttestationRegistry public iAttestationRegistry;

    constructor(IAttestationRegistry _iAttestationRegistry, address initialOwner) Ownable(initialOwner) {
        iAttestationRegistry = _iAttestationRegistry;
    }

    function getFeeDiscount(address sender, PoolKey memory poolKey) internal view returns (uint24) {
        if (_checkAttestations(sender)) {
            return (defaultFee / 2) | LPFeeLibrary.OVERRIDE_FEE_FLAG;
        }
        return defaultFee;
    }

    /*
      @dev Set default fee for pool
      @param fee
      @return
     */
    function setDefaultFee(uint24 fee) external onlyOwner {
        defaultFee = fee;
    }

    /*
      @dev Get default fee
      @return uint24
     */
    function getDefaultFee() public view returns (uint24) {
        return defaultFee;
    }

    /*
    @dev Set baseValue
      @param _baseValue
      @return
     */
    function setBaseValue(uint24 _baseValue) external onlyOwner {
        baseValue = _baseValue;
    }

    /*
      @dev Get baseValue
      @return uint24
     */
    function getBaseValue() public view returns (uint24) {
        return baseValue;
    }

    /*
      @dev Set durationOfAttestation
      @param _durationOfAttestation
      @return
     */
    function setDurationOfAttestation(uint24 _durationOfAttestation) external onlyOwner {
        durationOfAttestation = _durationOfAttestation;
    }

    /*
      @dev Get durationOfAttestation
      @return uint24
     */
    function getDurationOfAttestation() external view returns (uint24) {
        return durationOfAttestation;
    }

    /*
      @dev Get attestationRegistry
      @return IAttestationRegistry
     */
    function getAttestationRegistry() external view returns (IAttestationRegistry) {
        return iAttestationRegistry;
    }

    /*
      @dev Set attestationRegistry
     */
    function setAttestationRegistry(IAttestationRegistry _iAttestationRegistry) external onlyOwner {
        iAttestationRegistry = _iAttestationRegistry;
    }

    /*
      @dev Check the user has a attestation and the attestation is not expired
      @param sender
      @return bool , sender has valid attestation.
     */
    function _checkAttestations(address sender) internal view returns (bool) {
        // Get attestations for the sender
        Attestation[] memory attestations = iAttestationRegistry.getAttestationByRecipient(sender);
        if (attestations.length == 0) {
            return false;
        }
        // Iterate through the attestations
        for (uint256 i = attestations.length; i > 0; i--) {
            Attestation memory attestation = attestations[i - 1];
            // Ensure attestation has a valid timestamp field
            if (
                (block.timestamp - attestation.timestamp / 1000) <= durationOfAttestation * 24 * 60 * 60
                    && attestation.value >= baseValue
            ) {
                return true;
            }
        }
        // No valid attestations found
        return false;
    }
}
