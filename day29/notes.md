# SimpleStablecoin: A Beginner-Friendly Collateralized Stablecoin

Stablecoins are essential in Web3: they anchor value for trading, payments, savings, lending, and everyday transactions without crypto’s extreme volatility. This tutorial distills the core mechanics behind a collateral-backed stablecoin and walks through a clean, self-contained SimpleStablecoin implementation you can deploy and test.

## Why Stablecoins Matter

- Crypto is volatile; fiat-priced stability enables practical payments and finance.
- Stablecoins typically peg 1:1 to a reference (e.g., USD) via reserves, overcollateralization, or algorithms.
- DeFi infrastructure (DEXs, lending, NFT markets) heavily relies on stablecoins as the unit of account and settlement asset.

## Scope: What We’re Building (Not Production-Grade)

We’ll implement SimpleStablecoin — a minimal, educational, overcollateralized stablecoin:
- Users deposit a trusted ERC-20 collateral token.
- The contract uses a Chainlink price feed to determine mintable sUSD.
- A collateralization ratio (default 150%) ensures safety margins.
- Users can redeem sUSD to recover collateral by burning their stablecoins.
- Ownership and role-based controls let admins update key parameters.

This design is for learning. It omits real-world complexities (multi-asset collateral, liquidations, governance, audits, regulatory compliance, multi-oracle aggregation, circuit breakers).

## High-Level Mechanics

- Minting:
  1. User specifies sUSD amount to mint.
  2. Contract fetches collateral’s live price from Chainlink.
  3. Computes required collateral with the current collateralization ratio (≥ 100%).
  4. Transfers collateral into the contract and mints sUSD to the user.

- Redeeming:
  1. User specifies sUSD amount to redeem.
  2. Contract fetches the latest collateral price.
  3. Computes the collateral amount to return (reflecting the overcollateralization).
  4. Burns sUSD and transfers collateral back to the user.

- Safety:
  - ReentrancyGuard protects mint/redeem.
  - SafeERC20 ensures safe token transfers.
  - AccessControl + Ownable restrict sensitive actions.
  - Custom errors provide gas-efficient failures.

## Contract Overview

Bases and Libraries:
- ERC20 (OpenZeppelin): standard token behavior
- Ownable: owner-only controls
- ReentrancyGuard: protect external entry points
- AccessControl: granular role management (Price Feed Manager)
- SafeERC20: robust ERC-20 interactions
- IERC20Metadata: read collateral token decimals
- Chainlink AggregatorV3Interface: fetch live collateral prices

Key State:
- collateralToken (immutable): ERC-20 used as collateral
- collateralDecimals (immutable): decimals of the collateralToken
- priceFeed: Chainlink oracle for collateral/USD (or other quote)
- collateralizationRatio: percentage (e.g., 150 for 150%)
- PRICE_FEED_MANAGER_ROLE: role to update price feed

Events:
- Minted(user, amount, collateralDeposited)
- Redeemed(user, amount, collateralReturned)
- PriceFeedUpdated(newPriceFeed)
- CollateralizationRatioUpdated(newRatio)

Custom Errors:
- InvalidCollateralTokenAddress
- InvalidPriceFeedAddress
- MintAmountIsZero
- InsufficientStablecoinBalance
- CollateralizationRatioTooLow

## Core Functions

- getCurrentPrice(): reads latest price from Chainlink; requires > 0
- mint(amount):
  - Validates amount > 0
  - Computes required collateral using:
    - sUSD decimals (assumed 18 from ERC20 default unless overridden)
    - collateralizationRatio
    - Chainlink price (respecting feed decimals)
    - collateral token decimals
  - Transfers collateral via safeTransferFrom and mints sUSD
  - Emits Minted
- redeem(amount):
  - Validates amount > 0 and user balance sufficient
  - Computes collateral to return using the same decimal-safe approach
  - Burns sUSD and transfers collateral
  - Emits Redeemed
- setCollateralizationRatio(newRatio) [onlyOwner]:
  - Enforces newRatio ≥ 100
  - Updates ratio and emits event
- setPriceFeedContract(newPriceFeed) [PRICE_FEED_MANAGER_ROLE]:
  - Validates nonzero address
  - Updates oracle and emits event
- getRequiredCollateralForMint(amount) [view]:
  - Preview helper mirroring mint math
- getCollateralForRedeem(amount) [view]:
  - Preview helper mirroring redeem math

## Math and Decimals (Consistency Notes)

- sUSD uses ERC20’s default 18 decimals (decimals()):
  - All USD-value math scales by 10^18 for stablecoin amounts.
- Chainlink price feeds have their own decimals (priceFeed.decimals()):
  - Adjust computed collateral by dividing/multiplying to align with oracle precision.
- Collateral tokens may have 6 or 18 decimals (e.g., USDC 6, WETH 18):
  - Convert final collateral amounts into collateral token units using collateralDecimals.

This tutorial reconciles minor wording differences and keeps math consistent across sUSD, the oracle’s decimals, and collateral token decimals.

## Example Deployment (Remix, Mainnet Fork)

1. Open Remix IDE.
2. Environment: “Remix VM - Mainnet fork”.
3. Deploy a simple ERC-20 collateral token (e.g., MyToken with 18 decimals).
4. Identify a Chainlink collateral/USD feed (e.g., ETH/USD on mainnet, decimals = 8). Confirm current addresses via Chainlink docs.
5. Compile and deploy SimpleStablecoin with:
   - _collateralToken: address of your ERC-20
   - _initialOwner: your admin address
   - _priceFeed: Chainlink aggregator address
6. Approve spending:
   - From collateral token, approve SimpleStablecoin for a sufficient amount.
7. Mint:
   - Call mint(amount) with desired sUSD units (18 decimals).
8. Redeem:
   - Call redeem(amount) to burn sUSD and receive collateral.
9. Admin operations:
   - setCollateralizationRatio(newRatio ≥ 100)
   - setPriceFeedContract(newPriceFeed) via PRICE_FEED_MANAGER_ROLE

## Production Considerations (Out of Scope Here)

- Liquidations for undercollateralized positions
- Multi-asset collateral, risk parameters per asset
- Oracle aggregation, stale-data checks, and circuit breakers
- Governance and role rotation
- Reserves transparency/audits, compliance
- Fee models and treasury management
- Cross-chain deployments and bridge risks


## Quick User Flow (Mint/Redeem)

- Mint:
  - Input desired sUSD amount → fetch price → compute required collateral → transfer collateral → mint → emit event.
- Redeem:
  - Input sUSD amount → check balance → fetch price → compute collateral to return → burn → transfer collateral → emit event.
- Admin:
  - Update price feed (role-gated).
  - Update collateralization ratio (owner-only, min 100%).

## Testing Tips

- Always approve the SimpleStablecoin contract to spend your collateral before minting.
- Verify feed decimals and collateral token decimals; mismatch is a common source of off-by-decimals errors.
- Use the preview functions to estimate amounts before sending transactions.