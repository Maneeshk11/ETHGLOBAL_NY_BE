// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {RetailContract} from "../src/RetailContract.sol";

contract InitStoreByOwnerScript is Script {
	function run() public {
		uint256 pk = vm.envUint("PRIVATE_KEY");
		address store = vm.envAddress("RETAIL_STORE_ADDRESS");
		address router = vm.envAddress("UNISWAP_V2_ROUTER");
		address pyusd = vm.envAddress("PYUSD_ADDRESS");

		string memory storeName = vm.envOr("STORE_NAME", string("My Retail Store"));
		string memory storeDesc = vm.envOr("STORE_DESC", string("A retail store initialized by owner script"));
		string memory tokenName = vm.envOr("TOKEN_NAME", string("Store Token"));
		string memory tokenSymbol = vm.envOr("TOKEN_SYMBOL", string("STORE"));
		uint256 initialSupplyUnits = vm.envOr("INITIAL_SUPPLY_UNITS", uint256(1_000_000));
		uint256 pyusdLiquidity = vm.envOr("PYUSD_LIQUIDITY", uint256(100 * 1e6)); // 6 decimals

		address owner = vm.addr(pk);
		console.log("Owner:", owner);
		console.log("Store:", store);
		console.log("PYUSD balance before:", IERC20(pyusd).balanceOf(owner));

		vm.startBroadcast(pk);
		// Approve the store to pull PYUSD for liquidity
		IERC20(pyusd).approve(store, 0);
		IERC20(pyusd).approve(store, pyusdLiquidity);

		// Initialize
		RetailContract(store).initializeStore(
			storeName,
			storeDesc,
			tokenName,
			tokenSymbol,
			initialSupplyUnits,
			router,
			pyusd,
			pyusdLiquidity
		);
		vm.stopBroadcast();

		console.log("PYUSD balance after:", IERC20(pyusd).balanceOf(owner));
	}
}


