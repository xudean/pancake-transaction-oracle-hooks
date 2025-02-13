// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

struct Attestation {
    // The address of the user who made the attestation
    address recipient;
    // The cex name(such as binance, okex, ) of the attestation
    string exchange;
    // The value of the attestation
    uint32 value;
    // The timestamp of the attestation in milliseconds
    uint256 timestamp;
}
