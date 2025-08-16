// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {RetailContract} from "../src/RetailContract.sol";

contract RetailContractScript is Script {
    RetailContract public retailContract;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the retail contract
        retailContract = new RetailContract();

        // Example initialization - you can modify these parameters as needed
        string memory storeName = "My Retail Store";
        string
            memory storeDescription = "A comprehensive retail store with token-based payments";
        string memory tokenName = "Store Token";
        string memory tokenSymbol = "STORE";
        uint8 tokenDecimals = 18;
        uint256 initialTokenSupply = 1000000; // 1 million tokens

        // Initialize the store with tokens
        retailContract.initializeStore(
            storeName,
            storeDescription,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            initialTokenSupply
        );

        // Optional: Add some sample products
        retailContract.addProduct(
            "T-Shirt",
            "Comfortable cotton t-shirt",
            100 * 10 ** tokenDecimals,
            50
        );
        retailContract.addProduct(
            "Jeans",
            "Premium denim jeans",
            250 * 10 ** tokenDecimals,
            30
        );
        retailContract.addProduct(
            "Sneakers",
            "Athletic sneakers",
            300 * 10 ** tokenDecimals,
            20
        );

        vm.stopBroadcast();
    }

    // Helper function to deploy without initialization (if you want to initialize later)
    function deployOnly() public {
        vm.startBroadcast();
        retailContract = new RetailContract();
        vm.stopBroadcast();
    }
}
