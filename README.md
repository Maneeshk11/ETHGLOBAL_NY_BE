## Retail Contract System (Foundry)

This repository contains a retail system where an owner deploys a store-specific ERC-20 token and a retail contract. The token is 6 decimals (USDC/PYUSD-like). On initialization, the system can immediately seed a Uniswap V2-style liquidity pool against PYUSD so the token is tradable from the start. Customers purchase products using the token with a burn-on-purchase model.

### Contracts

- `src/RetailToken.sol`
  - ERC-20 with fixed 6 decimals
  - Minting (owner-only), burning, and `burnFrom`
- `src/RetailContract.sol`
  - Store initialization, product catalog, purchases, distributions
  - LP seeding on init via a Uniswap V2-compatible router
  - Additional function to mint tokens and add directly to LP later

### Key Capabilities

- **Initialize Store + LP**: Deploy `RetailToken`, pull PYUSD from owner, and add initial liquidity via a V2 router at deploy time.
- **Burn-on-Purchase**: Buying a product burns the buyer’s tokens (`burnFrom`). No treasury accumulation by default.
- **Product Management**: Add/update products with price and stock tracking.
- **Token Distribution**: Owner can distribute tokens to customers.
- **Mint + Add Liquidity**: Owner can mint new tokens and immediately add them to the existing LP pair by supplying matching PYUSD.

---

## How It Works

### Initialization Flow (adds V2-style liquidity)

Owner calls `initializeStore`:

```solidity
function initializeStore(
    string memory _storeName,
    string memory _storeDescription,
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _initialTokenSupply,
    address _uniswapV2Router,
    address _pyusdToken,
    uint256 _tokenLiquidity,
    uint256 _pyusdLiquidity
) external onlyOwner
```

- Deploys `RetailToken` (6 decimals) minted to the contract.
- Pulls `_pyusdLiquidity` PYUSD from `owner()` into the contract. The owner must pre-approve the retail contract to spend PYUSD.
- Approves the router and calls `addLiquidity(token, PYUSD, _tokenLiquidity, _pyusdLiquidity, ...)`.
- LP tokens are sent to `owner()`; trading is live immediately.

Notes:
- Provide equal `_tokenLiquidity` and `_pyusdLiquidity` to target an initial 1:1 price.
- Router must be V2-compatible (e.g., UniswapV2-like) and addresses must be valid on your target chain.

### Mint and Add Liquidity Later

Owner can grow liquidity over time:

```solidity
function mintAndAddLiquidity(uint256 _tokenAmount, uint256 _pyusdAmount) external onlyOwner
```

- Mints `_tokenAmount` `RetailToken` to the contract.
- Pulls `_pyusdAmount` PYUSD from `owner()` (requires approval).
- Adds liquidity via the configured router; LP tokens go to `owner()`.

### Purchasing (Burn Model)

```solidity
function purchaseProduct(uint256 _productId, uint256 _quantity) external
```

- Computes `totalPrice = price * quantity`.
- Requires the buyer to have balance and allowance; calls `storeToken.burnFrom(buyer, totalPrice)`.
- Decreases product stock, records purchase, increments `totalRevenue`.

### Product Management

- `addProduct(string name, string description, uint256 price, uint256 stock)` (owner-only)
- `updateProduct(uint256 id, uint256 price, uint256 stock, bool isActive)` (owner-only)

### Token Distribution

```solidity
function distributeTokens(address[] memory customers, uint256[] memory amounts) external onlyOwner
```

- Transfers tokens from the contract to each listed customer.

---

## Required Approvals

- Before `initializeStore`: Owner must `approve` the retail contract to `transferFrom` the `_pyusdLiquidity` amount of PYUSD.
- Before `mintAndAddLiquidity`: Owner must `approve` the retail contract to `transferFrom` the `_pyusdAmount` of PYUSD.
- Before customer purchases: Buyer must `approve` the retail contract to burn (`burnFrom`) the required amount of `RetailToken`.

---

## Build, Test, and Deploy

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Format

```bash
forge fmt
```

### Local Node

```bash
anvil
```

### Example Deployment Script

Provide your own script that deploys `RetailContract` and then calls `initializeStore(...)` with the proper router/PYUSD addresses and liquidity amounts for your network.

```bash
forge script script/RetailContract.s.sol:RetailContractScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast
```

---

## File Map

- `src/RetailToken.sol` – ERC-20 token (6 decimals) with owner minting, burning
- `src/RetailContract.sol` – Store logic, LP seeding, purchases (burn), distributions
- `script/` – Add your deployment scripts here
- `test/` – Add/extend tests for your flows

---

## Notes

- Decimals are fixed to 6 throughout.
- This repository assumes a V2-compatible router and a PYUSD ERC-20 on your target chain; pass their addresses to `initializeStore`.

---

## Foundry Docs

See the Foundry Book: `https://book.getfoundry.sh/`
