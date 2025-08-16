# Retail Contract System

This repository contains a comprehensive retail contract system that allows retail owners to deploy and initialize stores with their own tokens for customer transactions.

## Overview

The system consists of two main contracts:

1. **RetailToken.sol** - An ERC20 token contract for store-specific tokens
2. **RetailContract.sol** - The main retail contract that manages the store, products, and transactions

## Key Features

- ✅ **Store Initialization**: Deploy and initialize a retail store with custom tokens
- ✅ **Product Management**: Add, update, and manage product inventory
- ✅ **Token-based Purchases**: Customers can buy products using store tokens
- ✅ **Token Distribution**: Store owners can distribute tokens to customers
- ✅ **Revenue Tracking**: Track total store revenue and transaction history
- ✅ **Access Control**: Owner-only functions for store management
- ✅ **Security**: Built with OpenZeppelin's security standards

## Contract Architecture

### RetailContract.sol

The main contract that handles:

- Store initialization with custom tokens
- Product management (add, update, inventory tracking)
- Customer purchases with token payments
- Token distribution to customers
- Revenue and transaction tracking

### RetailToken.sol

An ERC20 token contract that provides:

- Custom token name, symbol, and decimals
- Minting capabilities for the store owner
- Standard ERC20 functionality

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) installed
- Basic understanding of Solidity and smart contracts

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd eth-global-be

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

### Deployment

#### Option 1: Deploy and Initialize in One Transaction

Use the provided deployment script:

```bash
forge script script/RetailContract.s.sol:RetailContractScript --rpc-url <your-rpc-url> --private-key <your-private-key> --broadcast
```

#### Option 2: Deploy First, Initialize Later

Deploy the contract first:

```bash
forge script script/RetailContract.s.sol:RetailContractScript --sig "deployOnly()" --rpc-url <your-rpc-url> --private-key <your-private-key> --broadcast
```

Then initialize with your custom parameters:

```solidity
// Call initializeStore with your parameters
retailContract.initializeStore(
    "Your Store Name",
    "Your Store Description",
    "Your Token Name",
    "TOKEN_SYMBOL",
    18, // decimals
    1000000 // initial supply
);
```

## Usage Examples

### 1. Initialize Your Store

```solidity
// Initialize store with 1 million tokens
retailContract.initializeStore(
    "Tech Store",
    "Electronics and gadgets store",
    "TechToken",
    "TECH",
    18,
    1000000
);
```

### 2. Add Products

```solidity
// Add products to your store
retailContract.addProduct("iPhone 15", "Latest iPhone model", 1000 * 10**18, 50);
retailContract.addProduct("MacBook Pro", "High-performance laptop", 2500 * 10**18, 20);
```

### 3. Distribute Tokens to Customers

```solidity
address[] memory customers = new address[](2);
uint256[] memory amounts = new uint256[](2);

customers[0] = 0x1234567890123456789012345678901234567890;
customers[1] = 0x0987654321098765432109876543210987654321;
amounts[0] = 500 * 10**18; // 500 tokens
amounts[1] = 300 * 10**18; // 300 tokens

retailContract.distributeTokens(customers, amounts);
```

### 4. Customer Purchase Flow

```solidity
// Customer approves token spending
storeToken.approve(address(retailContract), 1000 * 10**18);

// Customer purchases product
retailContract.purchaseProduct(1, 1); // Buy 1 unit of product ID 1
```

## Main Functions

### Store Management (Owner Only)

- `initializeStore()` - Initialize the store with tokens and details
- `addProduct()` - Add new products to the store
- `updateProduct()` - Update product details, price, and stock
- `distributeTokens()` - Distribute tokens to customers
- `withdrawTokens()` - Withdraw tokens from the contract

### Customer Functions

- `purchaseProduct()` - Purchase products using store tokens
- `getCustomerTokenBalance()` - Check token balance

### View Functions

- `getStoreInfo()` - Get store information
- `getProduct()` - Get product details
- `getPurchaseHistory()` - Get all purchase transactions
- `getContractTokenBalance()` - Get contract's token balance

## Events

The contract emits the following events for tracking:

- `StoreInitialized` - When store is initialized
- `ProductAdded` - When a new product is added
- `ProductPurchased` - When a product is purchased
- `TokensWithdrawn` - When tokens are withdrawn
- `CustomerBalanceUpdated` - When customer balance changes

## Security Features

- **Access Control**: Critical functions are protected with `onlyOwner` modifier
- **Reentrancy Protection**: Uses OpenZeppelin's `ReentrancyGuard`
- **Safe Token Transfers**: Uses OpenZeppelin's `SafeERC20` library
- **Input Validation**: Comprehensive checks for all parameters
- **State Consistency**: Proper state updates and balance tracking

## Testing

Run the comprehensive test suite:

```bash
forge test -vv
```

The tests cover:

- Store initialization
- Product management
- Token distribution
- Purchase transactions
- Access control
- Error conditions

## Custom Configuration

You can customize the deployment script (`script/RetailContract.s.sol`) to set your specific:

- Store name and description
- Token name and symbol
- Token decimals
- Initial token supply
- Initial products

## License

This project is licensed under the MIT License.

## Support

For questions or issues, please create an issue in the repository or contact the development team.
