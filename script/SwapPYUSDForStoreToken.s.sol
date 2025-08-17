// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2RouterLikeSwap {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
}

interface IRetailContractView {
	function storeInfo()
		external
		view
		returns (
			string memory name,
			string memory description,
			address tokenAddress,
			uint256 tokenBalance,
			bool isActive,
			uint256 createdAt
		);
}

contract SwapPYUSDForStoreTokenScript is Script {
	address public RETAIL_CONTRACT_ADDRESS;
	address public UNISWAP_V2_ROUTER;
	address public PYUSD_ADDRESS;

	function setUp() public {}

	function run() public {
		// Load env
		uint256 pk = vm.envUint("PRIVATE_KEY");
		RETAIL_CONTRACT_ADDRESS = vm.envAddress("RETAIL_CONTRACT_ADDRESS");
		UNISWAP_V2_ROUTER = vm.envAddress("UNISWAP_V2_ROUTER");
		PYUSD_ADDRESS = vm.envAddress("PYUSD_ADDRESS");

		// Optional swap amount override; default 10 PYUSD (6 decimals)
		uint256 amountIn = vm.envOr("SWAP_AMOUNT_IN", uint256(10 * 1e6));
		uint256 amountOutMin = vm.envOr("SWAP_AMOUNT_OUT_MIN", uint256(0));

		vm.startBroadcast(pk);

		// Resolve store token address from deployed RetailContract
		(address storeTokenAddr) = _getStoreToken(RETAIL_CONTRACT_ADDRESS);

		// Approve router to spend PYUSD
		IERC20(PYUSD_ADDRESS).approve(UNISWAP_V2_ROUTER, amountIn);

		// Build swap path PYUSD -> StoreToken
		address[] memory path = new address[](2);
		path[0] = PYUSD_ADDRESS;
		path[1] = storeTokenAddr;

		// Logs before
		console.log("Sender:", msg.sender);
		console.log("PYUSD before:", IERC20(PYUSD_ADDRESS).balanceOf(msg.sender));
		console.log("Token before:", IERC20(storeTokenAddr).balanceOf(msg.sender));

		// Perform swap
		uint256 deadline = block.timestamp + 30 minutes;
		uint256[] memory amounts = IUniswapV2RouterLikeSwap(UNISWAP_V2_ROUTER)
			.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, deadline);

		// Logs after
		console.log("Swapped PYUSD -> Token amounts[0], amounts[1]:", amounts[0], amounts[1]);
		console.log("PYUSD after:", IERC20(PYUSD_ADDRESS).balanceOf(msg.sender));
		console.log("Token after:", IERC20(storeTokenAddr).balanceOf(msg.sender));

		vm.stopBroadcast();
	}

	function _getStoreToken(address retail) internal view returns (address token) {
		(
			,
			,
			token,
			,
			,
			
		) = IRetailContractView(retail).storeInfo();
	}
}


