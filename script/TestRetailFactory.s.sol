// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {RetailFactory} from "../src/RetailFactory.sol";

contract TestRetailFactoryScript is Script {
	// Deployed factory address on Sepolia
	address public constant FACTORY = 0x73219DB51691ac68b8B3F4575A2D54e80ebCc954;
	RetailFactory public factory;

	function run() public {
		uint256 pk = vm.envUint("PRIVATE_KEY");
		address owner = vm.addr(pk);

		require(FACTORY != address(0), "Set FACTORY address");
		factory = RetailFactory(FACTORY);

		vm.startBroadcast(pk);
		address newStore = factory.createStore();
		console.log("Store created:", newStore);
		vm.stopBroadcast();

		address[] memory stores = factory.getStoresByOwner(owner);
		console.log("Owner:", owner);
		console.log("Stores count:", stores.length);
		for (uint256 i = 0; i < stores.length; i++) {
			console.log(i, stores[i]);
		}
	}
}


