// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {RetailFactory} from "../src/RetailFactory.sol";

contract RetailFactoryScript is Script {
	RetailFactory public factory;

	function run() public {
		uint256 pk = vm.envUint("PRIVATE_KEY");
		vm.startBroadcast(pk);
		factory = new RetailFactory();
		console.log("RetailFactory deployed:", address(factory));
		vm.stopBroadcast();
	}
}


