// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

struct Attestation {
    bytes32 attestationId;
    address recipient;
    string exchange;
    uint32 baseValue;
    uint64 timestamp;
}
