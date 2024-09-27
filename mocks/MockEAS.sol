// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// prettier-ignore
import {
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    DelegatedAttestationRequest,
    DelegatedRevocationRequest,
    IEAS,
    MultiAttestationRequest,
    MultiDelegatedAttestationRequest,
    MultiDelegatedRevocationRequest,
    MultiRevocationRequest,
    RevocationRequest,
    RevocationRequestData
} from "bas-contract/contracts/IEAS.sol";
import {ISchemaRegistry} from "bas-contract/contracts/ISchemaRegistry.sol";

/**
 * @title EAS - Ethereum Attestation Service
 */
contract MockEAS is IEAS {
    using Address for address payable;

    // The global schema registry.
    ISchemaRegistry private immutable _schemaRegistry;

    // The global mapping between attestations and their UIDs.
    mapping(bytes32 uid => Attestation attestation) private _db;

    // The global mapping between data and their timestamps.
    mapping(bytes32 data => uint64 timestamp) private _timestamps;

    // The global mapping between data and their revocation timestamps.
    mapping(address revoker => mapping(bytes32 data => uint64 timestamp) timestamps)
        private _revocationsOffchain;

    /**
     * @dev Creates a new EAS instance.
     *
     * @param registry The address of the global schema registry.
     */
    constructor(ISchemaRegistry registry) {
        _schemaRegistry = registry;
    }

    /**
     * @inheritdoc IEAS
     */
    function getSchemaRegistry() external view returns (ISchemaRegistry) {
        return _schemaRegistry;
    }

    /**
     * @inheritdoc IEAS
     */
    function attest(
        AttestationRequest calldata /*request*/
    ) external payable returns (bytes32) {
        bytes32 a;
        return a;
    }

    /**
     * @inheritdoc IEAS
     */
    function attestByDelegation(
        DelegatedAttestationRequest calldata /*delegatedRequest*/
    ) external payable returns (bytes32) {
        bytes32 a;
        return a;
    }

    /**
     * @inheritdoc IEAS
     */
    function multiAttest(
        MultiAttestationRequest[] calldata /*multiRequests*/
    ) external payable returns (bytes32[] memory) {
        bytes32[] memory ret = new bytes32[](2);
        return ret;
    }

    /**
     * @inheritdoc IEAS
     */
    function multiAttestByDelegation(
        MultiDelegatedAttestationRequest[] calldata /*multiDelegatedRequests*/
    ) external payable returns (bytes32[] memory) {
        bytes32[] memory ret = new bytes32[](2);
        return ret;
    }

    /**
     * @inheritdoc IEAS
     */
    function revoke(RevocationRequest calldata /*request*/) external payable {}

    /**
     * @inheritdoc IEAS
     */
    function revokeByDelegation(
        DelegatedRevocationRequest calldata /*delegatedRequest*/
    ) external payable {}

    /**
     * @inheritdoc IEAS
     */
    function multiRevoke(
        MultiRevocationRequest[] calldata /*multiRequests*/
    ) external payable {}

    /**
     * @inheritdoc IEAS
     */
    function multiRevokeByDelegation(
        MultiDelegatedRevocationRequest[] calldata /*multiDelegatedRequests*/
    ) external payable {}

    /**
     * @inheritdoc IEAS
     */
    function timestamp(bytes32 /*data*/) external view returns (uint64) {
        uint64 time = _time();
        return time;
    }

    /**
     * @inheritdoc IEAS
     */
    function revokeOffchain(bytes32 /*data*/) external view returns (uint64) {
        uint64 time = _time();
        return time;
    }

    /**
     * @inheritdoc IEAS
     */
    function multiRevokeOffchain(
        bytes32[] calldata /*data*/
    ) external view returns (uint64) {
        uint64 time = _time();
        return time;
    }

    /**
     * @inheritdoc IEAS
     */
    function multiTimestamp(
        bytes32[] calldata /*data*/
    ) external view returns (uint64) {
        uint64 time = _time();
        return time;
    }

    /**
     * @inheritdoc IEAS
     */
    function getAttestation(
        bytes32 uid
    ) external pure returns (Attestation memory) {
        // fakes an attestation
        address addr;
        bytes32 b32 = 0x5569a35483840767334b19c6f28d1347dad8ec4521859a1742d2175898489752;
        Attestation memory attestation;

        // prettier-ignore
        if (uid == 0x0000000000000000000000000000000000000000000000000000000000000001){
            // string ProofType,string Source,string Content,string Condition,bytes32 SourceUserIdHash,bool Result,uint64 Timestamp,bytes32 UserIdHash
            bytes memory dummy_data = abi.encode("Assets", "okx", "Spot 30-Day Trade Volume", ">100", b32, true, 0, b32);
            attestation = Attestation({
                uid: b32,
                schema: b32,
                refUID: b32,
                time: 0,
                expirationTime: 0,
                revocationTime: 0,
                recipient: addr,
                attester: addr,
                revocable: false,
                data: dummy_data
            });
        }else{
            bytes memory dummy_data = abi.encode("Web3 Wallet", "Brevis", "Has transactions on BNB Chain", "since 2024 July", b32, true, 0, b32);
            attestation = Attestation({
                uid: b32,
                schema: b32,
                refUID: b32,
                time: 0,
                expirationTime: 0,
                revocationTime: 0,
                recipient: addr,
                attester: addr,
                revocable: false,
                data: dummy_data
            });
        }

        return attestation;
    }

    /**
     * @inheritdoc IEAS
     */
    function isAttestationValid(bytes32 uid) public view returns (bool) {
        return _db[uid].uid != 0;
    }

    /**
     * @inheritdoc IEAS
     */
    function getTimestamp(bytes32 data) external view returns (uint64) {
        return _timestamps[data];
    }

    /**
     * @inheritdoc IEAS
     */
    function getRevokeOffchain(
        address revoker,
        bytes32 data
    ) external view returns (uint64) {
        return _revocationsOffchain[revoker][data];
    }

    /**
     * @dev Calculates a UID for a given attestation.
     *
     * @param attestation The input attestation.
     * @param bump A bump value to use in case of a UID conflict.
     *
     * @return Attestation UID.
     */
    function _getUID(
        Attestation memory attestation,
        uint32 bump
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    attestation.schema,
                    attestation.recipient,
                    attestation.attester,
                    attestation.time,
                    attestation.expirationTime,
                    attestation.revocable,
                    attestation.refUID,
                    attestation.data,
                    bump
                )
            );
    }

    /**
     * @dev Refunds remaining ETH amount to the attester.
     *
     * @param remainingValue The remaining ETH amount that was not sent to the resolver.
     */
    function _refund(uint256 remainingValue) private {
        if (remainingValue > 0) {
            // Using a regular transfer here might revert, for some non-EOA attesters, due to exceeding of the 2300
            // gas limit which is why we're using call instead (via sendValue), which the 2300 gas limit does not
            // apply for.
            payable(msg.sender).sendValue(remainingValue);
        }
    }

    /**
     * @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
     * current block time.
     */
    function _time() internal view virtual returns (uint64) {
        return uint64(block.timestamp);
    }
}
