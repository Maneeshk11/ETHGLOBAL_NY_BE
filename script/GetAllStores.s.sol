// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {RetailFactory} from "../src/RetailFactory.sol";

contract GetAllStoresScript is Script {
	// Factory on Sepolia
	address public constant FACTORY = 0xA8E26B8a731d0aBeF824311aF59F8c0EFd3daC23;

	function run() public view {
		RetailFactory factory = RetailFactory(FACTORY);
		address[] memory stores = factory.getAllStores();
		console.log("Factory:", FACTORY);
		console.log("Total stores:", stores.length);
		for (uint256 i = 0; i < stores.length; i++) {
			console.log(i, stores[i]);
		}
	}
}


