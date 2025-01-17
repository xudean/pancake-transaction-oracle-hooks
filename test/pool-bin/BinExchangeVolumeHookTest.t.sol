// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "../../src/pool-bin/volume/BinExchangeVolumeHook.sol";
import "../pool-cl/util/MockAttestationRegistry.t.sol";
import {BinPoolManager} from "pancake-v4-core/src/pool-bin/BinPoolManager.sol";
import {BinPoolParametersHelper} from "pancake-v4-core/src/pool-bin/libraries/BinPoolParametersHelper.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {IVault} from "pancake-v4-core/src/interfaces/IVault.sol";
import {Vault} from "pancake-v4-core/src/Vault.sol";
import {Test} from "forge-std/Test.sol";

contract CLExchangeVolumeHookTest is Test {
    using BinPoolParametersHelper for bytes32;

    BinExchangeVolumeHook public binExchangeVolumeHook;
    IAttestationRegistry public iAttestationRegistry;
    IBinPoolManager public binPoolManager;

    function setUp() public {
        iAttestationRegistry = new MockAttestationRegistry();
        IVault vault = new Vault();
        binPoolManager = new BinPoolManager(vault);
        binExchangeVolumeHook = new BinExchangeVolumeHook(binPoolManager, iAttestationRegistry, msg.sender);
    }

    function testGetParameters() public {
        bytes32 parameters = bytes32(uint256(binExchangeVolumeHook.getHooksRegistrationBitmap())).setBinStep(60);
        console.log("bin parameters:");
        console.logBytes32(parameters);
    }
}
