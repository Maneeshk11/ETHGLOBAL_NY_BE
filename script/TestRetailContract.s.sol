// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {RetailContract} from "../src/RetailContract.sol";
import {RetailToken} from "../src/RetailToken.sol";

contract TestRetailContractScript is Script {
    RetailContract public retailContract;
    RetailToken public storeToken;
    address public constant CONTRACT_ADDRESS =
        0xA396463c453262d459969103646046ef5fe50ed2;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Get the deployed contract
        retailContract = RetailContract(CONTRACT_ADDRESS);

        // Get store info
        (
            string memory name,
            string memory description,
            address tokenAddress,
            uint256 tokenBalance,
            bool isActive,
            uint256 createdAt
        ) = retailContract.storeInfo();

        // Print store info
        console.log("Store Name:", name);
        console.log("Description:", description);
        console.log("Token Address:", tokenAddress);
        console.log("Token Balance:", tokenBalance); // base units (6 decimals)
        console.log("Is Active:", isActive);
        console.log("Created At:", createdAt);

        // Get the first product
        RetailContract.Product memory product = retailContract.getProduct(1);

        // Print product info
        console.log("\nProduct Info:");
        console.log("ID:", product.id);
        console.log("Name:", product.name);
        console.log("Description:", product.description);
        console.log("Price:", product.price);
        console.log("Stock:", product.stock);
        console.log("Is Active:", product.isActive);

        vm.stopBroadcast();
    }
}
