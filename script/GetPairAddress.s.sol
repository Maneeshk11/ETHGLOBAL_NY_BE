// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {RetailContract} from "../src/RetailContract.sol";

contract GetPairAddressScript is Script {
	function run() public {
		address store = vm.envAddress("RETAIL_STORE_ADDRESS");

		address pair = RetailContract(store).getPairAddress();
		address token = address(RetailContract(store).storeToken());
		address pyusd = RetailContract(store).pyusdToken();

		console.log("Store:", store);
		console.log("Store token:", token);
		console.log("PYUSD:", pyusd);
		console.log("Pair:", pair);

		require(pair != address(0), "Pair not found; ensure liquidity added");
	}
}


