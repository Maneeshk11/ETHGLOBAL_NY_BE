// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {RetailFactory} from "../src/RetailFactory.sol";

contract CreateStoreScript is Script {
	function run() public {
		uint256 pk = vm.envUint("PRIVATE_KEY");
		address factoryAddr = vm.envAddress("RETAIL_FACTORY_ADDRESS");
		address owner = vm.addr(pk);

		RetailFactory factory = RetailFactory(factoryAddr);

		vm.startBroadcast(pk);
		address newStore = factory.createStore();
		vm.stopBroadcast();

		console.log("Owner:", owner);
		console.log("Factory:", factoryAddr);
		console.log("New store:", newStore);
	}
}


