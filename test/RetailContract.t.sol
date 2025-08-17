// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RetailContract} from "../src/RetailContract.sol";
import {RetailToken} from "../src/RetailToken.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Mock PYUSD (6 decimals)
contract MockERC20 is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// Minimal V2-like router that pulls tokens from msg.sender and "locks" them
contract MockV2Router is RetailContract { // inherit to reuse interface type if needed
    address public sink = address(0xdead);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 /*amountAMin*/,
        uint256 /*amountBMin*/,
        address /*to*/,
        uint256 /*deadline*/
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        amountA = amountADesired;
        amountB = amountBDesired;
        IERC20(tokenA).transferFrom(msg.sender, sink, amountA);
        IERC20(tokenB).transferFrom(msg.sender, sink, amountB);
        liquidity = amountA + amountB;
    }
}

contract RetailContractTest is Test {
    RetailContract public retailContract;
    RetailToken public storeToken;
    MockERC20 public pyusd;
    MockV2Router public router;
    address public owner;
    address public customer;

    uint256 constant DECIMALS = 1e6; // 6 decimals
    uint256 constant INITIAL_SUPPLY_UNITS = 1_000_000; // human units
    uint256 constant INITIAL_SUPPLY = INITIAL_SUPPLY_UNITS * DECIMALS; // base units
    uint256 constant SEED_LIQUIDITY_UNITS = 200_000; // human units
    uint256 constant SEED_LIQUIDITY = SEED_LIQUIDITY_UNITS * DECIMALS; // base units

    function setUp() public {
        owner = address(this);
        customer = address(0x123);

        // Deploy retail contract
        retailContract = new RetailContract();

        // Deploy mocks
        pyusd = new MockERC20("PayPal USD", "PYUSD", 6);
        router = new MockV2Router();

        // Fund owner with PYUSD and approve retail contract to pull for LP
        pyusd.mint(owner, 10_000_000 * DECIMALS);
        IERC20(address(pyusd)).approve(address(retailContract), type(uint256).max);

        // Initialize store
        retailContract.initializeStore(
            "Test Store",
            "A test retail store",
            "Test Token",
            "TEST",
            INITIAL_SUPPLY_UNITS,
            address(router),
            address(pyusd),
            SEED_LIQUIDITY
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
        // All minted tokens are supplied to LP at initialization
        assertEq(tokenBalance, 0);
        assertGt(createdAt, 0);
        assertTrue(tokenAddress != address(0));
    }

    function testAddProduct() public {
        retailContract.addProduct(
            "Test Product",
            "A test product",
            100 * DECIMALS,
            10
        );

        RetailContract.Product memory product = retailContract.getProduct(1);

        assertEq(product.id, 1);
        assertEq(product.name, "Test Product");
        assertEq(product.description, "A test product");
        assertEq(product.price, 100 * DECIMALS);
        assertEq(product.stock, 10);
        assertTrue(product.isActive);
    }

    function testTokenDistribution() public {
        address[] memory customers = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        customers[0] = customer;
        amounts[0] = 1_000 * DECIMALS;

        retailContract.distributeTokens(customers, amounts);

        uint256 customerBalance = storeToken.balanceOf(customer);
        assertEq(customerBalance, 1_000 * DECIMALS);
    }

    function testProductPurchase() public {
        // Add a product
        retailContract.addProduct(
            "Test Product",
            "A test product",
            100 * DECIMALS,
            10
        );

        // Distribute tokens to customer
        address[] memory customers = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        customers[0] = customer;
        amounts[0] = 1_000 * DECIMALS;
        retailContract.distributeTokens(customers, amounts);

        // Customer purchases product
        vm.startPrank(customer);
        storeToken.approve(address(retailContract), 200 * DECIMALS);
        retailContract.purchaseProduct(1, 2);
        vm.stopPrank();

        // Check customer balance decreased
        uint256 customerBalance = storeToken.balanceOf(customer);
        assertEq(customerBalance, 800 * DECIMALS);

        // Check product stock decreased
        RetailContract.Product memory updatedProduct = retailContract
            .getProduct(1);
        assertEq(updatedProduct.stock, 8);

        // Check total revenue
        uint256 totalRevenue = retailContract.totalRevenue();
        assertEq(totalRevenue, 200 * DECIMALS);
    }

    function test_RevertWhen_DoubleInitialization() public {
        // This should fail since store is already initialized
        vm.expectRevert("Store already initialized");
        retailContract.initializeStore(
            "Another Store",
            "Another description",
            "Another Token",
            "ANO",
            500_000,
            address(router),
            address(pyusd),
            10_000 * DECIMALS
        );
    }
}
