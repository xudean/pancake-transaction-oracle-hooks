// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";
import {Vault} from "pancake-v4-core/src/Vault.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {SortTokens} from "pancake-v4-core/test/helpers/SortTokens.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";
import {ICLPositionManager} from "pancake-v4-periphery/src/pool-cl/interfaces/ICLPositionManager.sol";
import {ICLRouterBase} from "pancake-v4-periphery/src/pool-cl/interfaces/ICLRouterBase.sol";
import {PositionConfig} from "pancake-v4-periphery/src/pool-cl/libraries/PositionConfig.sol";
import {Planner, Plan} from "pancake-v4-periphery/src/libraries/Planner.sol";
import {Actions} from "pancake-v4-periphery/src/libraries/Actions.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {UniversalRouter, RouterParameters} from "pancake-v4-universal-router/src/UniversalRouter.sol";
import {Commands} from "pancake-v4-universal-router/src/libraries/Commands.sol";
import {ActionConstants} from "pancake-v4-periphery/src/libraries/ActionConstants.sol";
import {LiquidityAmounts} from "pancake-v4-periphery/src/pool-cl/libraries/LiquidityAmounts.sol";
import {TickMath} from "pancake-v4-core/src/pool-cl/libraries/TickMath.sol";
import {PoolId, PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";

import {console} from "forge-std/console.sol";
import "forge-std/Script.sol";

contract TokensScript is Script {
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;

    Vault vault;
    CLPoolManager poolManager;
    CLPositionManager positionManager;
    IAllowanceTransfer permit2;
    UniversalRouter universalRouter;
    Currency currency0;
    Currency currency1;

    function run() public {
        console.log("msg.sender %s", msg.sender);
        console.log("script %s", address(this));

        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address signerAddr = vm.addr(privateKey);
        console.log("SIGNER%s", signerAddr);

        vm.startBroadcast(privateKey);

        (currency0, currency1) = deployContractsWithTokens();
        address token0 = Currency.unwrap(currency0);
        address token1 = Currency.unwrap(currency1);
        console.log("TOKEN0=%s", token0);
        console.log("TOKEN1=%s", token1);

        vm.stopBroadcast();
    }

    // prettier-ignore
    function deployContractsWithTokens() internal returns (Currency, Currency) {
        address _permit2 = vm.envAddress("PERMIT2");
        console.log("_permit2=%s", _permit2);
        address _vault = vm.envAddress("VAULT");
        console.log("_vault=%s", _vault);
        address _poolManager = vm.envAddress("CL_POOL_MANAGER");
        console.log("_poolManager=%s", _poolManager);

        vault = Vault(_vault);
        poolManager = CLPoolManager(_poolManager);
        permit2 = IAllowanceTransfer(_permit2);
        positionManager = new CLPositionManager(vault, poolManager, permit2);

        RouterParameters memory params = RouterParameters({
            permit2: address(permit2),
            weth9: address(0),
            v2Factory: address(0),
            v3Factory: address(0),
            v3Deployer: address(0),
            v2InitCodeHash: bytes32(0),
            v3InitCodeHash: bytes32(0),
            stableFactory: address(0),
            stableInfo: address(0),
            v4Vault: address(vault),
            v4ClPoolManager: address(poolManager),
            v4BinPoolManager: address(0),
            v3NFTPositionManager: address(0),
            v4ClPositionManager: address(positionManager),
            v4BinPositionManager: address(0)
        });
        universalRouter = new UniversalRouter(params);
        console.log("CL_POSITION_MANAGER=%s", address(positionManager));
        console.log("UNIVERSAL_ROUTER=%s", address(universalRouter));

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

        return SortTokens.sort(token0, token1);
    }
}
/*
source .env
forge script script/Currency.s.sol \
  --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
  --broadcast
*/
