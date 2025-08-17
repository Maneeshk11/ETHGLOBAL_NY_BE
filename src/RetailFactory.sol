// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RetailContract} from "./RetailContract.sol";

/**
 * Deploys new RetailContract instances and keeps an on-chain index
 * mapping creator/owner addresses to their deployed store contract addresses.
 *
 * Note: This factory does NOT call initializeStore, because that function pulls
 * PYUSD via transferFrom(msg.sender). The factory would not hold the user's PYUSD.
 * Instead, the factory transfers ownership to the caller and records the store address.
 * The owner should call initializeStore on the deployed contract afterwards.
 */
contract RetailFactory {
	// creator/owner => list of their store contract addresses
	mapping(address => address[]) private ownerToStores;
	// store contract address => owner
	mapping(address => address) public storeToOwner;

	event StoreDeployed(address indexed owner, address indexed store);

	function createStore() external returns (address storeAddress) {
		RetailContract store = new RetailContract();
		// Transfer ownership to the caller so they can initialize and manage
		store.transferOwnership(msg.sender);

		storeAddress = address(store);
		ownerToStores[msg.sender].push(storeAddress);
		storeToOwner[storeAddress] = msg.sender;

		emit StoreDeployed(msg.sender, storeAddress);
	}

	function getStoresByOwner(address owner) external view returns (address[] memory) {
		return ownerToStores[owner];
	}
}


