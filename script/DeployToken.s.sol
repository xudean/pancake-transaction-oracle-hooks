// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {SortTokens} from "pancake-v4-core/test/helpers/SortTokens.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";
import {ICLPositionManager} from "pancake-v4-periphery/src/pool-cl/interfaces/ICLPositionManager.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {UniversalRouter} from "pancake-v4-universal-router/src/UniversalRouter.sol";
import {PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract DeployTokenScript is Script {
    // using Planner for Plan;
    using PoolIdLibrary for PoolKey;

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
        address _positionManager = vm.envAddress("CL_POSITION_MANAGER");
        // console.log("_positionManager=%s", _positionManager);
        address _universalRouter = vm.envAddress("UNIVERSAL_ROUTER");
        // console.log("_universalRouter=%s", _universalRouter);
        CLPositionManager positionManager =  CLPositionManager(_positionManager);
        UniversalRouter universalRouter =  UniversalRouter(payable(_universalRouter));
        IAllowanceTransfer permit2 = positionManager.permit2();

        MockERC20 token0 = new MockERC20("token0", "T0", 18);
        MockERC20 token1 = new MockERC20("token1", "T1", 18);
        token0.mint(msg.sender, 12345 ether);
        token1.mint(msg.sender, 12345 ether);

        // approve permit2 contract to transfer our funds
        token0.approve(address(permit2), type(uint256).max);
        token1.approve(address(permit2), type(uint256).max);

        permit2.approve(address(token0), address(positionManager), type(uint160).max, type(uint48).max);
        permit2.approve(address(token1), address(positionManager), type(uint160).max, type(uint48).max);

        permit2.approve(address(token0), address(universalRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(token1), address(universalRouter), type(uint160).max, type(uint48).max);

        (Currency currency0, Currency currency1)= SortTokens.sort(token0, token1);
        console.log("TOKEN0=%s", Currency.unwrap(currency0));
        console.log("TOKEN1=%s", Currency.unwrap(currency1));
    }
}
/*
source .env
forge script script/DeployToken.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
*/
