// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {RetailContract} from "../src/RetailContract.sol";
import {RetailToken} from "../src/RetailToken.sol";

contract TestPurchaseScript is Script {
    RetailContract public retailContract;
    RetailToken public storeToken;
    address public constant CONTRACT_ADDRESS =
        0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address public constant CUSTOMER =
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public constant OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {}

    function run() public {
        // Start with owner to distribute tokens
        vm.startBroadcast(
            0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        );

        // Get the deployed contracts
        retailContract = RetailContract(CONTRACT_ADDRESS);
        (, , address tokenAddress, , , ) = retailContract.storeInfo();
        storeToken = RetailToken(tokenAddress);

        // Print initial balances
        console.log(
            "Initial Customer Token Balance:",
            storeToken.balanceOf(CUSTOMER)
        );

        // Distribute tokens to customer (500 tokens)
        address[] memory customers = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        customers[0] = CUSTOMER;
        amounts[0] = 500 * 10 ** 18; // 500 tokens
        retailContract.distributeTokens(customers, amounts);

        console.log(
            "Customer Token Balance after distribution:",
            storeToken.balanceOf(CUSTOMER)
        );
        vm.stopBroadcast();

        // Switch to customer account for purchase
        vm.startBroadcast(
            0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        );

        // Approve tokens for spending
        storeToken.approve(CONTRACT_ADDRESS, 100 * 10 ** 18);

        // Purchase 1 T-shirt
        retailContract.purchaseProduct(1, 1);

        console.log(
            "Customer Token Balance after purchase:",
            storeToken.balanceOf(CUSTOMER)
        );

        // Get updated product info
        RetailContract.Product memory product = retailContract.getProduct(1);
        console.log("\nUpdated Product Stock:", product.stock);

        vm.stopBroadcast();
    }
}
