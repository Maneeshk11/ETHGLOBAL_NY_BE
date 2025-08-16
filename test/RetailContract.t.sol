// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RetailContract} from "../src/RetailContract.sol";
import {RetailToken} from "../src/RetailToken.sol";

contract RetailContractTest is Test {
    RetailContract public retailContract;
    RetailToken public storeToken;
    address public owner;
    address public customer;

    function setUp() public {
        owner = address(this);
        customer = address(0x123);

        // Deploy retail contract
        retailContract = new RetailContract();

        // Initialize store
        retailContract.initializeStore(
            "Test Store",
            "A test retail store",
            "Test Token",
            "TEST",
            18,
            1000000
        );

        // Get the store token
        (, , address tokenAddress, , , ) = retailContract.storeInfo();
        storeToken = RetailToken(tokenAddress);
    }

    function testStoreInitialization() public view {
        (
            string memory name,
            string memory description,
            address tokenAddress,
            uint256 tokenBalance,
            bool isActive,
            uint256 createdAt
        ) = retailContract.storeInfo();

        assertEq(name, "Test Store");
        assertEq(description, "A test retail store");
        assertTrue(isActive);
        assertGt(tokenBalance, 0);
        assertGt(createdAt, 0);
        assertTrue(tokenAddress != address(0));
    }

    function testAddProduct() public {
        retailContract.addProduct(
            "Test Product",
            "A test product",
            100 ether,
            10
        );

        RetailContract.Product memory product = retailContract.getProduct(1);

        assertEq(product.id, 1);
        assertEq(product.name, "Test Product");
        assertEq(product.description, "A test product");
        assertEq(product.price, 100 ether);
        assertEq(product.stock, 10);
        assertTrue(product.isActive);
    }

    function testTokenDistribution() public {
        address[] memory customers = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        customers[0] = customer;
        amounts[0] = 1000 ether;

        retailContract.distributeTokens(customers, amounts);

        uint256 customerBalance = storeToken.balanceOf(customer);
        assertEq(customerBalance, 1000 ether);
    }

    function testProductPurchase() public {
        // Add a product
        retailContract.addProduct(
            "Test Product",
            "A test product",
            100 ether,
            10
        );

        // Distribute tokens to customer
        address[] memory customers = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        customers[0] = customer;
        amounts[0] = 1000 ether;
        retailContract.distributeTokens(customers, amounts);

        // Customer purchases product
        vm.startPrank(customer);
        storeToken.approve(address(retailContract), 200 ether);
        retailContract.purchaseProduct(1, 2);
        vm.stopPrank();

        // Check customer balance decreased
        uint256 customerBalance = storeToken.balanceOf(customer);
        assertEq(customerBalance, 800 ether);

        // Check product stock decreased
        RetailContract.Product memory updatedProduct = retailContract
            .getProduct(1);
        assertEq(updatedProduct.stock, 8);

        // Check total revenue
        uint256 totalRevenue = retailContract.totalRevenue();
        assertEq(totalRevenue, 200 ether);
    }

    function test_RevertWhen_DoubleInitialization() public {
        // This should fail since store is already initialized
        vm.expectRevert("Store already initialized");
        retailContract.initializeStore(
            "Another Store",
            "Another description",
            "Another Token",
            "ANO",
            18,
            500000
        );
    }
}
