// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "./RetailToken.sol";

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

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Initialize the retail contract with store details and tokens
     * @param _storeName Name of the retail store
     * @param _storeDescription Description of the store
     * @param _tokenName Name of the store token
     * @param _tokenSymbol Symbol of the store token
     * @param _tokenDecimals Decimals for the token
     * @param _initialTokenSupply Initial supply of tokens to mint
     */
    function initializeStore(
        string memory _storeName,
        string memory _storeDescription,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals,
        uint256 _initialTokenSupply
    ) external onlyOwner {
        require(!storeInfo.isActive, "Store already initialized");
        require(bytes(_storeName).length > 0, "Store name cannot be empty");
        require(
            _initialTokenSupply > 0,
            "Initial token supply must be greater than 0"
        );

        // Deploy the store token
        storeToken = new RetailToken(
            _tokenName,
            _tokenSymbol,
            _tokenDecimals,
            _initialTokenSupply,
            address(this)
        );

        // Initialize store info
        storeInfo = StoreInfo({
            name: _storeName,
            description: _storeDescription,
            tokenAddress: address(storeToken),
            tokenBalance: _initialTokenSupply * 10 ** _tokenDecimals,
            isActive: true,
            createdAt: block.timestamp
        });

        emit StoreInitialized(
            _storeName,
            address(storeToken),
            storeInfo.tokenBalance
        );
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
        require(storeInfo.isActive, "Store not active");
        require(products[_productId].isActive, "Product not available");
        require(products[_productId].stock >= _quantity, "Insufficient stock");
        require(_quantity > 0, "Quantity must be greater than 0");

        uint256 totalPrice = products[_productId].price * _quantity;
        require(
            storeToken.balanceOf(msg.sender) >= totalPrice,
            "Insufficient token balance"
        );

        // Transfer tokens from buyer to contract
        IERC20(address(storeToken)).safeTransferFrom(
            msg.sender,
            address(this),
            totalPrice
        );

        // Update product stock
        products[_productId].stock -= _quantity;

        // Update store revenue
        totalRevenue += totalPrice;
        storeInfo.tokenBalance += totalPrice;

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

    function getCustomerTokenBalance(
        address _customer
    ) external view returns (uint256) {
        return storeToken.balanceOf(_customer);
    }

    function getContractTokenBalance() external view returns (uint256) {
        return storeToken.balanceOf(address(this));
    }
}
