// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {RetailFactory} from "../src/RetailFactory.sol";
import {RetailContract} from "../src/RetailContract.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TestRetailFactoryScript is Script {
	// Deployed factory address on Sepolia
	address public constant FACTORY = 0x935c367772E914C160A728b389baa6A031cC2149;
	RetailFactory public factory;

	// Sepolia addresses
	address public constant UNISWAP_V2_ROUTER = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3;
	address public constant PYUSD = 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9;

	function run() public {
		uint256 pk = vm.envUint("PRIVATE_KEY");
		address owner = vm.addr(pk);

		require(FACTORY != address(0), "Set FACTORY address");
		factory = RetailFactory(FACTORY);

		vm.startBroadcast(pk);
		address newStore = factory.createStore();
		console.log("Store created:", newStore);

		// Approve PYUSD for liquidity seeding
		uint256 pyusdLiquidity = 20 * 1e6; // 20 PYUSD (6 decimals)
		IERC20(PYUSD).approve(newStore, pyusdLiquidity);

		// Initialize the store (supply in whole tokens; contract applies 6 decimals)
		RetailContract(newStore).initializeStore(
			"My Retail Store",
			"A comprehensive retail store with token-based payments",
			"Store Token",
			"STORE",
			1_000_000,
			UNISWAP_V2_ROUTER,
			PYUSD,
			pyusdLiquidity
		);
		vm.stopBroadcast();

		address[] memory stores = factory.getStoresByOwner(owner);
		console.log("Owner:", owner);
		console.log("Stores count:", stores.length);
		for (uint256 i = 0; i < stores.length; i++) {
			console.log(i, stores[i]);
		}
	}
}

