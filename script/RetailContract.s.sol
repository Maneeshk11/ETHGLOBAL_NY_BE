// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {RetailContract} from "../src/RetailContract.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract RetailContractScript is Script {
    RetailContract public retailContract;

    function setUp() public {}

    function run() public {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        // Deploy the retail contract
        retailContract = new RetailContract();

        // Example initialization (configure via env for real networks)
        string memory storeName = "My Retail Store";
        string memory storeDescription = "A comprehensive retail store with token-based payments";
        string memory tokenName = "Store Token";
        string memory tokenSymbol = "STORE";
        uint256 initialTokenSupplyUnits = 1_000_000; // human units, 6 decimals

        // Router and PYUSD addresses (set in .env or pass via --env)
        // e.g., export UNISWAP_V2_ROUTER=0x...
        //       export PYUSD_ADDRESS=0x...
        address uniswapRouter = vm.envAddress("UNISWAP_V2_ROUTER");
        address pyusd = vm.envAddress("PYUSD_ADDRESS");

        // Liquidity seed amounts (base units, 6 decimals)
        uint256 tokenLiquidity = 100 * 1e6; // 100 tokens
        uint256 pyusdLiquidity = 100 * 1e6; // 100 PYUSD

        // Approve the retail contract to pull PYUSD during initializeStore
        IERC20(pyusd).approve(address(retailContract), pyusdLiquidity);

        // Initialize the store with LP seeding
        retailContract.initializeStore(
            storeName,
            storeDescription,
            tokenName,
            tokenSymbol,
            initialTokenSupplyUnits,
            uniswapRouter,
            pyusd,
            tokenLiquidity,
            pyusdLiquidity
        );

        // Optional: Add some sample products
        retailContract.addProduct(
            "T-Shirt",
            "Comfortable cotton t-shirt",
            100 * 1e6,
            50
        );

        vm.stopBroadcast();
    }

}
