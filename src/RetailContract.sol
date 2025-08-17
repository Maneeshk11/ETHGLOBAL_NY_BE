// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./RetailToken.sol";

interface IUniswapV2RouterLike {
	function factory() external view returns (address);
	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

interface IUniswapV2FactoryLike {
	function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract RetailContract is Ownable, ReentrancyGuard {
	using SafeERC20 for IERC20;

	// Retail store information
	struct StoreInfo {
		string name;
		string description;
		address tokenAddress;
		uint256 tokenBalance;
		bool isActive;
		uint256 createdAt;
	}

	// Product information
	struct Product {
		uint256 id;
		string name;
		string description;
		uint256 price; // Price in tokens
		uint256 stock;
		bool isActive;
	}

	// Purchase information
	struct Purchase {
		uint256 productId;
		address buyer;
		uint256 quantity;
		uint256 totalPrice;
		uint256 timestamp;
	}

	StoreInfo public storeInfo;
	RetailToken public storeToken;

	// External integrations
	address public pyusdToken;
	address public uniswapV2Router;

	mapping(uint256 => Product) public products;
	mapping(address => uint256) public customerBalances;
	Purchase[] public purchases;

	uint256 public nextProductId = 1;
	uint256 public totalRevenue;

	// Events
	event StoreInitialized(
		string name,
		address tokenAddress,
		uint256 initialTokens
	);
	event ProductAdded(
		uint256 indexed productId,
		string name,
		uint256 price,
		uint256 stock
	);
	event ProductPurchased(
		uint256 indexed productId,
		address indexed buyer,
		uint256 quantity,
		uint256 totalPrice
	);
	event TokensWithdrawn(address indexed owner, uint256 amount);
	event CustomerBalanceUpdated(address indexed customer, uint256 newBalance);
	event LiquidityAdded(uint256 tokenAmount, uint256 pyusdAmount, uint256 liquidity);

	constructor() Ownable(msg.sender) {}

	/**
	 * @dev Initialize the retail contract and seed a Uniswap V2-style pool using ALL minted store tokens
	 *      paired with the provided PYUSD amount from the owner.
	 * @param _storeName Name of the retail store
	 * @param _storeDescription Description of the store
	 * @param _tokenName Name of the store token
	 * @param _tokenSymbol Symbol of the store token
	 * @param _initialTokenSupply Initial supply of tokens to mint (human units; contract applies 6 decimals)
	 * @param _uniswapV2Router Address of the Uniswap V2-compatible router
	 * @param _pyusdToken Address of PYUSD token to pair with
	 * @param _pyusdLiquidity Amount of PYUSD (base units, 6 decimals) to add as initial liquidity (pulled from owner)
	 */
	function initializeStore(
		string memory _storeName,
		string memory _storeDescription,
		string memory _tokenName,
		string memory _tokenSymbol,
		uint256 _initialTokenSupply,
		address _uniswapV2Router,
		address _pyusdToken,
		uint256 _pyusdLiquidity
	) external onlyOwner {
		require(!storeInfo.isActive, "Store already initialized");
		require(bytes(_storeName).length > 0, "Store name cannot be empty");
		require(
			_initialTokenSupply > 0,
			"Initial token supply must be greater than 0"
		);
		require(_uniswapV2Router != address(0), "Invalid router");
		require(_pyusdToken != address(0), "Invalid PYUSD");
		require(_pyusdLiquidity > 0, "Invalid liquidity");

		uniswapV2Router = _uniswapV2Router;
		pyusdToken = _pyusdToken;

		// Deploy the store token - minted to this contract
		storeToken = new RetailToken(
			_tokenName,
			_tokenSymbol,
			_initialTokenSupply,
			address(this)
		);

		// Initialize store info with full minted balance
		storeInfo = StoreInfo({
			name: _storeName,
			description: _storeDescription,
			tokenAddress: address(storeToken),
			tokenBalance: _initialTokenSupply * 10 ** 6,
			isActive: true,
			createdAt: block.timestamp
		});

		// Pull PYUSD from owner into this contract
		IERC20(pyusdToken).transferFrom(msg.sender, address(this), _pyusdLiquidity);

		// Use the entire minted token balance as liquidity
		uint256 tokenLiquidity = storeToken.balanceOf(address(this));
		require(tokenLiquidity > 0, "No minted token balance");

		// Approve router to pull tokens
		IERC20(address(storeToken)).forceApprove(uniswapV2Router, 0);
		IERC20(address(storeToken)).forceApprove(uniswapV2Router, tokenLiquidity);
		IERC20(pyusdToken).forceApprove(uniswapV2Router, 0);
		IERC20(pyusdToken).forceApprove(uniswapV2Router, _pyusdLiquidity);

		// Add liquidity at 1:1 with strict mins (new pool expected)
		(uint256 amountA, uint256 amountB, uint256 liquidity) = IUniswapV2RouterLike(uniswapV2Router).addLiquidity(
			address(storeToken),
			pyusdToken,
			tokenLiquidity,
			_pyusdLiquidity,
			tokenLiquidity,
			_pyusdLiquidity,
			owner(),
			block.timestamp + 1 hours
		);

		// Update internal accounting: tokens moved out to LP
		storeInfo.tokenBalance -= amountA;

		emit StoreInitialized(
			_storeName,
			address(storeToken),
			storeInfo.tokenBalance
		);

		emit LiquidityAdded(amountA, amountB, liquidity);
	}

	/**
	 * @dev Add a new product to the store
	 * @param _name Name of the product
	 * @param _description Description of the product
	 * @param _price Price in tokens
	 * @param _stock Initial stock quantity
	 */
	function addProduct(
		string memory _name,
		string memory _description,
		uint256 _price,
		uint256 _stock
	) external onlyOwner {
		require(storeInfo.isActive, "Store not initialized");
		require(bytes(_name).length > 0, "Product name cannot be empty");
		require(_price > 0, "Price must be greater than 0");

		products[nextProductId] = Product({
			id: nextProductId,
			name: _name,
			description: _description,
			price: _price,
			stock: _stock,
			isActive: true
		});

		emit ProductAdded(nextProductId, _name, _price, _stock);
		nextProductId++;
	}

	/**
	 * @dev Purchase a product using store tokens
	 * @param _productId ID of the product to purchase
	 * @param _quantity Quantity to purchase
	 */
	function purchaseProduct(
		uint256 _productId,
		uint256 _quantity
	) external nonReentrant {
		//Checks
		require(storeInfo.isActive, "Store not active");
		require(products[_productId].isActive, "Product not available");
		require(products[_productId].stock >= _quantity, "Insufficient stock");
		require(_quantity > 0, "Quantity must be greater than 0");

		uint256 totalPrice = products[_productId].price * _quantity;
		require(
			storeToken.balanceOf(msg.sender) >= totalPrice,
			"Insufficient token balance"
		);

		// Burn tokens from buyer (requires allowance to this contract)
		storeToken.burnFrom(msg.sender, totalPrice);

		// Update product stock
		products[_productId].stock -= _quantity;

		// Update store revenue (tracks total tokens spent)
		totalRevenue += totalPrice;

		// Record purchase
		purchases.push(
			Purchase({
				productId: _productId,
				buyer: msg.sender,
				quantity: _quantity,
				totalPrice: totalPrice,
				timestamp: block.timestamp
			})
		);

		emit ProductPurchased(_productId, msg.sender, _quantity, totalPrice);
	}

	/**
	 * @dev Distribute tokens to customers
	 * @param _customers Array of customer addresses
	 * @param _amounts Array of token amounts to distribute
	 */
	function distributeTokens(
		address[] memory _customers,
		uint256[] memory _amounts
	) external onlyOwner {
		require(storeInfo.isActive, "Store not initialized");
		require(_customers.length == _amounts.length, "Arrays length mismatch");

		for (uint256 i = 0; i < _customers.length; i++) {
			require(_customers[i] != address(0), "Invalid customer address");
			require(_amounts[i] > 0, "Amount must be greater than 0");

			IERC20(address(storeToken)).safeTransfer(
				_customers[i],
				_amounts[i]
			);
			customerBalances[_customers[i]] += _amounts[i];
			storeInfo.tokenBalance -= _amounts[i];

			emit CustomerBalanceUpdated(
				_customers[i],
				customerBalances[_customers[i]]
			);
		}
	}

	/**
	 * @dev Withdraw tokens from the contract (owner only)
	 * @param _amount Amount of tokens to withdraw
	 */
	function withdrawTokens(uint256 _amount) external onlyOwner {
		require(storeInfo.isActive, "Store not initialized");
		require(_amount > 0, "Amount must be greater than 0");
		require(
			storeToken.balanceOf(address(this)) >= _amount,
			"Insufficient contract balance"
		);

		IERC20(address(storeToken)).safeTransfer(owner(), _amount);
		storeInfo.tokenBalance -= _amount;

		emit TokensWithdrawn(owner(), _amount);
	}

	/**
	 * @dev Update product details
	 * @param _productId ID of the product to update
	 * @param _price New price
	 * @param _stock New stock quantity
	 * @param _isActive Whether the product is active
	 */
	function updateProduct(
		uint256 _productId,
		uint256 _price,
		uint256 _stock,
		bool _isActive
	) external onlyOwner {
		require(products[_productId].id != 0, "Product does not exist");

		products[_productId].price = _price;
		products[_productId].stock = _stock;
		products[_productId].isActive = _isActive;
	}

	function mintAndAddLiquidity(
		uint256 _tokenAmount,
		uint256 _pyusdAmount
	) external onlyOwner {
		require(storeInfo.isActive, "Store not initialized");
		require(uniswapV2Router != address(0) && pyusdToken != address(0), "Router/PYUSD not set");
		require(_tokenAmount > 0 && _pyusdAmount > 0, "Invalid amounts");

		// Mint new tokens to this contract
		storeToken.mint(address(this), _tokenAmount);

		// Accounting: reflect minted tokens held by contract
		storeInfo.tokenBalance += _tokenAmount;

		// Pull PYUSD from owner into this contract
		IERC20(pyusdToken).transferFrom(msg.sender, address(this), _pyusdAmount);

		// Approve router to pull tokens
		IERC20(address(storeToken)).forceApprove(uniswapV2Router, 0);
		IERC20(address(storeToken)).forceApprove(uniswapV2Router, _tokenAmount);
		IERC20(pyusdToken).forceApprove(uniswapV2Router, 0);
		IERC20(pyusdToken).forceApprove(uniswapV2Router, _pyusdAmount);

		// Add liquidity; accept partials (mins = 0) to avoid slippage reverts
		(uint256 amountA, uint256 amountB, uint256 liquidity) = IUniswapV2RouterLike(uniswapV2Router).addLiquidity(
			address(storeToken),
			pyusdToken,
			_tokenAmount,
			_pyusdAmount,
			0,
			0,
			owner(),
			block.timestamp + 1 hours
		);

		// Update internal accounting based on actual token used
		storeInfo.tokenBalance -= amountA;

		emit LiquidityAdded(amountA, amountB, liquidity);
	}

	// View functions
	function getStoreInfo() external view returns (StoreInfo memory) {
		return storeInfo;
	}

	function getProduct(
		uint256 _productId
	) external view returns (Product memory) {
		return products[_productId];
	}

	function getPurchaseHistory() external view returns (Purchase[] memory) {
		return purchases;
	}

	function getPairAddress() external view returns (address) {
		require(uniswapV2Router != address(0) && pyusdToken != address(0), "Router/PYUSD not set");
		address factoryAddress = IUniswapV2RouterLike(uniswapV2Router).factory();
		return IUniswapV2FactoryLike(factoryAddress).getPair(address(storeToken), pyusdToken);
	}

	function getCustomerTokenBalance(
		address _customer
	) external view returns (uint256) {
		return storeToken.balanceOf(_customer);
	}

	function getContractTokenBalance() external view returns (uint256) {
		return storeToken.balanceOf(address(this));
	}
}
