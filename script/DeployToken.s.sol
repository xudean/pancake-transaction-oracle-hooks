// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {SortTokens} from "pancake-v4-core/test/helpers/SortTokens.sol";

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract DeployTokenScript is Script {
    function run() public {
        console.log("msg.sender %s", msg.sender);
        console.log("script %s", address(this));

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address signerAddr = vm.addr(privateKey);
        console.log("SIGNER=%s", signerAddr);

        vm.startBroadcast(privateKey);

        _deploy();

        vm.stopBroadcast();
    }

    // prettier-ignore
    function _deploy() internal {
        MockERC20 token0 = new MockERC20("token0", "T0", 18);
        MockERC20 token1 = new MockERC20("token1", "T1", 18);
        token0.mint(msg.sender, 10000000000 ether);
        token1.mint(msg.sender, 10000000000 ether);
        
        (Currency currency0, Currency currency1)= SortTokens.sort(token0, token1);
        console.log("TOKEN0=%s", Currency.unwrap(currency0));
        console.log("TOKEN1=%s", Currency.unwrap(currency1));
    }
}
/*
source .env
forge script script/DeployToken.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
*/
