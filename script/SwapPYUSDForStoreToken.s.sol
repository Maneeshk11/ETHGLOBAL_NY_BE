// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2RouterMinimal {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);
}

contract UniV2SwapPYUSDScript is Script {
	// Hardcoded Sepolia addresses
	address public constant ROUTER = 0xeE567Fe1712Faf6149d80dA1E6934E354124CfE3; // UniswapV2 router on Sepolia
	address public constant PYUSD = 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9;
	address public constant STORE = 0x3BfB466E93D726d7e4f1366Ed6CFd01A51cEd75f;
	address public constant EXPECTED_SWAPPER = 0x881041A0f75276dD79F53f9988bf850c686F33a7;

	function run() public {
		uint256 pk = vm.envUint("PRIVATE_KEY");
		address swapper = vm.addr(pk);
		require(swapper == EXPECTED_SWAPPER, "PRIVATE_KEY does not match target address");

		// Check balance and decide amountIn (use 10 PYUSD or full balance if lower)
		uint256 bal = IERC20(PYUSD).balanceOf(swapper);
		console.log("Swapper:", swapper);
		console.log("PYUSD balance:", bal);
		require(bal > 0, "No PYUSD balance");

		uint256 amountIn = bal >= 10 * 1e6 ? 10 * 1e6 : bal; // PYUSD has 6 decimals
		uint256 amountOutMin = 0; // simple swap, no slippage protection

		address[] memory path = new address[](2);
		path[0] = PYUSD;
		path[1] = STORE;

		vm.startBroadcast(pk);

		// Approve and swap
		IERC20(PYUSD).approve(ROUTER, 0);
		IERC20(PYUSD).approve(ROUTER, amountIn);

		uint256 deadline = block.timestamp + 30 minutes;
		uint256[] memory amounts = IUniswapV2RouterMinimal(ROUTER)
			.swapExactTokensForTokens(amountIn, amountOutMin, path, swapper, deadline);

		console.log("Swapped in/out:", amounts[0], amounts[1]);
		console.log("PYUSD after:", IERC20(PYUSD).balanceOf(swapper));
		console.log("STORE after:", IERC20(STORE).balanceOf(swapper));

		vm.stopBroadcast();
	}
}

