// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract TransferScript is Script {
    function run() public {
        console.log("msg.sender %s", msg.sender);
        console.log("script %s", address(this));

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address signerAddr = vm.addr(privateKey);
        console.log("SIGNER=%s", signerAddr);

        vm.startBroadcast(privateKey);

        _run();

        vm.stopBroadcast();
    }

    // prettier-ignore
    function _run() internal {
        address _token0 = vm.envAddress("TOKEN0");
        console.log("_token0=%s", _token0);
        address _token1 = vm.envAddress("TOKEN1");
        console.log("_token1=%s", _token1);
        address receiver = vm.envAddress("RECEIVER");
        console.log("_receiver=%s", receiver);

        uint256 amount = 100 ether;

        console.log("1 balanceOf TOKEN0: %d", MockERC20(_token0).balanceOf(receiver));
        console.log("1 balanceOf TOKEN1: %d", MockERC20(_token1).balanceOf(receiver));

        MockERC20(_token0).transfer(receiver, amount);
        MockERC20(_token1).transfer(receiver, amount);

        console.log("2 balanceOf TOKEN0: %d", MockERC20(_token0).balanceOf(receiver));
        console.log("2 balanceOf TOKEN1: %d", MockERC20(_token1).balanceOf(receiver));
    }
}
/*
source .env
export RECEIVER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
forge script script/Transfer.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
*/
